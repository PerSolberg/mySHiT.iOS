//
//  ViewController.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-09.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import UIKit
import os
//import Security

class TripListViewController: UITableViewController {
    //
    // MARK: Properties
    //
    @IBOutlet var tripListTable: UITableView!

    var sections = [TripListSectionInfo]()
    var tripToRefresh: IndexPath?
    var activeSections:[(offset:Int, element:TripListSectionInfo)] {
        return sections.enumerated().filter { return $0.element.firstTrip != nil }
    }

    
    //
    // MARK: Navigation
    //
    @IBAction func unwindToMain(_ sender: UIStoryboardSegue)
    {
        tripListTable.setBackgroundMessage(Constant.msg.retrievingTrips)
        TripList.sharedList.getFromServer()
        return
    }
    

    @IBAction func openSettings(_ sender: AnyObject) {
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
        }
    }


    // Prepare for navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.

        if let segueId = segue.identifier {
            switch (segueId) {
            case Constant.segue.logout:
                logout()
            
            case Constant.segue.showTripDetails:
                let destinationController = segue.destination as! TripDetailsViewController
                if let selectedTripCell = sender as? UITableViewCell {
                    let indexPath = tableView.indexPath(for: selectedTripCell)!
                    let s = getSectionById(indexPath.section)
                    
                    let selectedTrip = TripList.sharedList[s!.section.firstTrip! + indexPath.row]!
                    tripToRefresh = indexPath
                    destinationController.tripCode = selectedTrip.trip.code
                    destinationController.tripSection = s!.section.type
                }
                
            default:
                // No particular preparation needed.
                break
            }
        }
    }
    

    //
    // MARK: Constructors
    //
    func addMissingSections() {
        for tls in TripListSection.allValues {
            let found = sections.contains { return $0.type == tls }
            if !found {
                sections.append( TripListSectionInfo(visible: true, type: tls, firstTrip: -1) )
            }
        }
    }


    required init?( coder: NSCoder) {
        super.init(coder: coder)
        addMissingSections()
    }


    override init(style: UITableView.Style) {
        super.init(style: style)
        addMissingSections()
    }

    
    //
    // MARK: Callbacks
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up refresh
        refreshControl = UIRefreshControl()
        refreshControl!.backgroundColor = tripListTable.backgroundColor
        refreshControl!.tintColor = UIColor.blue
        refreshControl!.addTarget(self, action: #selector(reloadTripsFromServer), for: .valueChanged)

        NotificationCenter.default.addObserver(self, selector: #selector(logonComplete(_:)), name: Constant.notification.logonSuccessful, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshTripList), name: Constant.notification.refreshTripList, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshTripList), name: Constant.notification.dataRefreshed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(authenticationFailed(_:)), name: Constant.notification.logonFailed, object: nil)
    }

    
    func showLogonScreen(animated: Bool) {
        DispatchQueue.main.async {
            // Get login screen from storyboard and present it
            let storyboard: UIStoryboard = UIStoryboard(name:"Main", bundle: nil)
            let logonVC = storyboard.instantiateViewController(withIdentifier: "logonScreen") as! LogonViewController
            
            guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else {
                os_log("Unable to get root view controller", log: OSLog.general, type: .error)
                return
            }
            rootVC.present(logonVC, animated: true, completion: nil)
        }
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        os_log("TripList viewWillAppear", log: OSLog.general, type:.debug)

        // Load data & check if section list is complete (if not, add missing elements)
        // No need to reload every time, only when launching
        if TripList.sharedList.count == 0 {
            loadTrips()
        }

        tripListTable.estimatedRowHeight = 40
        tripListTable.rowHeight = UITableView.automaticDimension
        refreshTripList()

        NotificationCenter.default.addObserver(self, selector: #selector(handleNetworkError), name: Constant.notification.networkError, object: nil)
    }
 
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: Constant.notification.networkError, object: nil)
    }

    
    override func viewDidAppear(_ animated: Bool) {
        if !User.sharedUser.hasCredentials() {
            showLogonScreen(animated: false)
            tripToRefresh = nil
        }

        if let indexPath = tripToRefresh, let s = getSectionById(indexPath.section) {
            let selectedTrip = TripList.sharedList[s.section.firstTrip! + indexPath.row]!
            
            let prevModStatus = selectedTrip.modified
            selectedTrip.modified = selectedTrip.trip.changes() > 0 ? .Changed : .Unchanged
            
            UIApplication.shared.applicationIconBadgeNumber = TripList.sharedList.changes()
            
            if let cell = tableView.cellForRow(at: indexPath), let imgView = cell.viewWithTag(4) as? UIImageView {
                imgView.image = selectedTrip.trip.icon?.overlayBadge(selectedTrip.modified)
            }

            tripToRefresh = nil
            if (selectedTrip.modified != prevModStatus) {
                TripList.sharedList.saveToArchive()
            }
        }
    }
    
    
    @objc func refreshTripList() {
        endRefreshing()
        if (TripList.sharedList.count == 0) {
            tripListTable.setBackgroundMessage(Constant.msg.noTrips)
        } else {
            tripListTable.setBackgroundMessage(nil)
        }

        updateSections()
        DispatchQueue.main.async(execute: {
            self.tripListTable.reloadData()
        })
        saveSections()
    }

    
    @objc func handleNetworkError() {
        // Should only be called if this view controller is displayed (notification observers
        // added in viewWillAppear and removed in viewWillDisappear

        // Notify user - and stop refresh in completion handler to ensure screen is properly updated
        // (ending refresh first, either in a separate DispatchQueue.main.sync call or in the alert async
        // closure didn't always dismiss the refrech control)
        os_log("Handling network error in TripList", log: OSLog.general, type:.info)
        showAlert(title: Constant.msg.alertBoxTitle, message: Constant.msg.connectError) { self.endRefreshing() }

        if (TripList.sharedList.count == 0) {
            tripListTable.setBackgroundMessage(Constant.msg.networkUnavailable)
        } else {
            tripListTable.setBackgroundMessage(nil)
        }
    }
    
    
    @objc func authenticationFailed(_ notification:Notification) {
        os_log("Handling authentication failure", log: OSLog.general, type: .debug)
        logout()
        endRefreshing()
        var poppedVCs:[UIViewController]?
        DispatchQueue.main.sync {
            guard let rootVC = UIApplication.shared.keyWindow?.rootViewController, let navVC = rootVC as? UINavigationController else {
                os_log("Unable to get root view controller or it is not a navigation controller", log: OSLog.general, type: .error)
                return
            }
            poppedVCs = navVC.popToRootViewController(animated: false)
        }
        NotificationCenter.default.removeObserver(self, name: Constant.notification.logonFailed, object: nil)
        if poppedVCs == nil || poppedVCs?.count == 0 {
            // If not view controllers were popped, we were already on Trip List, so we need to show the logon screen
            // Otherwise, viewWillAppear will take care of it.
            showLogonScreen(animated: false)
        }
    }


    @objc func reloadTripsFromServer() {
        tripListTable.setBackgroundMessage(Constant.msg.retrievingTrips)
        TripList.sharedList.getFromServer()
    }

    
    @objc func logonComplete(_ notification:Notification) {
        NotificationCenter.default.addObserver(self, selector: #selector(authenticationFailed(_:)), name: Constant.notification.logonFailed, object: nil)
        reloadTripsFromServer()
    }


    //
    // MARK: UITableViewDataSource methods
    //
    override func numberOfSections(in tableView: UITableView) -> Int {
        return activeSections.count
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let s = getSectionById(section) {
            if s.section.visible {
                return s.itemCount
            } else {
                return 0
            }
        } else {
            return 0
        }
    }

    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let s = getSectionById(section) {
            let showText = NSLocalizedString(s.section.type.rawValue, comment: "test")
            return showText
        } else {
            os_log("Section header not available", log: OSLog.general, type: .error)
            return nil
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let kCellIdentifier: String = "MyTripCell"
        
        //tablecell optional to see if we can reuse cell
        var cell : UITableViewCell?
        cell = tableView.dequeueReusableCell(withIdentifier: kCellIdentifier)

        if let s = getSectionById(indexPath.section) {
            let rowIdx = s.section.firstTrip! + indexPath.row
            let trip = TripList.sharedList[rowIdx]!.trip

            let lblName = cell!.viewWithTag(1) as! UILabel
            let lblDates = cell!.viewWithTag(2) as! UILabel
            let lblDesc  = cell!.viewWithTag(3) as! UITextView
            let imgView = cell!.viewWithTag(4) as! UIImageView
            
            lblName.text = trip.title
            lblDates.text = trip.dateInfo
            lblDesc.text  = trip.detailInfo
            
            imgView.image = trip.icon?.overlayBadge(TripList.sharedList[rowIdx]!.modified)
            //cell!.colourSubviews()
        } else {
            os_log("Section not found", log: OSLog.general, type: .error)
        }
        
        return cell!
    }
    

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.tripListTable.frame.size.width, height: 40))
        headerView.backgroundColor = UIColor.lightGray
        headerView.tag = section

        let headerString = UILabel(frame: CGRect(x: 10, y: 5, width: self.tripListTable.frame.size.width-10, height: 20)) as UILabel
        if let s = getSectionById(section) {
            let baseText = s.section.type.rawValue
            let showText = NSLocalizedString(baseText, comment: "test")
            headerString.text = showText
        }
        
        headerView.addSubview(headerString)
        
        let headerTapped = UITapGestureRecognizer (target: self, action:#selector(TripListViewController.sectionHeaderTapped(_:)))
        headerView.addGestureRecognizer(headerTapped)
        
        return headerView
    }


    //
    // MARK: Section header callbacks
    //
    @objc func sectionHeaderTapped(_ recognizer: UITapGestureRecognizer) {
        let indexPath : IndexPath = IndexPath(row: 0, section: (recognizer.view!.tag))
        if let s = getSectionById(indexPath.section) {
            sections[s.index].visible = !sections[s.index].visible
            
            //reload specific section animated
            let range = indexPath.section ..< (indexPath.section + 1)
            let sectionToReload = IndexSet(integersIn: range)
            self.tripListTable.reloadSections(sectionToReload, with:UITableView.RowAnimation.fade)
            saveSections()
        }
    }
    

    //
    // MARK: NSCoding
    //
    func saveTrips() {
        TripList.sharedList.saveToArchive()
        saveSections()
    }

    
    func saveSections() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(sections, toFile:  Constant.archive.sectionsURL.path)
        if !isSuccessfulSave {
            os_log("Failed to save sections", log: OSLog.general, type: .error)
        }
    }
    
    
    func loadTrips() {
        TripList.sharedList.loadFromArchive()
        sections = NSKeyedUnarchiver.unarchiveObject(withFile: Constant.archive.sectionsURL.path ) as? [TripListSectionInfo] ?? [TripListSectionInfo]()
    }
    

    //
    // MARK: Actions
    //

    
    //
    // MARK: Functions
    //
    func updateSections() {
        let defaults = UserDefaults.standard
        let upcomingPref:UserPrefUpcomingTrips! = UserPrefUpcomingTrips(rawValue: (defaults.string(forKey: "upcoming_trips") ?? UserPrefUpcomingTrips.NextOrWithin7Days.rawValue))!

        let today = Date()

        addMissingSections()
        for s in sections {
            s.firstTrip = nil
        }
        
        var prevSection:TripListSection = .Historic
        for (ix, aTrip) in TripList.sharedList.enumerated().reversed() {
            if aTrip.trip.tense == .past {
                aTrip.section = .Historic
            } else if aTrip.trip.tense == .present {
                aTrip.section = .Current
            } else {
                if prevSection == .Upcoming && upcomingPref == .NextOnly {
                    aTrip.section = .Future
                } else if (prevSection == .Current || prevSection == .Historic) && (upcomingPref == .NextOnly || upcomingPref == .NextOrWithin7Days || upcomingPref == .NextOrWithin30Days) {
                    aTrip.section = .Upcoming
                } else if (upcomingPref == .NextOrWithin7Days || upcomingPref == .Within7Days) && today.addDays(7).isGreaterThanDate(aTrip.trip.startTime!){
                    aTrip.section = .Upcoming
                } else if (upcomingPref == .NextOrWithin30Days || upcomingPref == .Within30Days) && today.addDays(30).isGreaterThanDate(aTrip.trip.startTime!){
                    aTrip.section = .Upcoming
                } else {
                    aTrip.section = .Future
                }
            }
            if prevSection != aTrip.section || ix == 0 {
                let section = sections.first { return $0.type == aTrip.section }
                section!.firstTrip = ix
            }
            prevSection = aTrip.section
        }
    }

    
    func getSectionById(_ sectionNo:Int) -> (index: Int, section:TripListSectionInfo, itemCount:Int)? {
        let activeSections = self.activeSections
        if sectionNo >= activeSections.count {
            return nil
        }
        var firstTripNextSection = TripList.sharedList.count
        if sectionNo + 1 < activeSections.count {
            firstTripNextSection = activeSections[sectionNo + 1].element.firstTrip!
        }

        let sectionIdx = activeSections[sectionNo].offset
        return (sectionIdx, sections[sectionIdx], firstTripNextSection - sections[sectionIdx].firstTrip!)
    }
    

    func logout() {
        // Empty memory structures, clear notification (part of clear) and update keyed archive
        TripList.sharedList.clear()
        sections = [TripListSectionInfo]()
        tripToRefresh = nil
        saveTrips()
        
        // Refresh list to avoid previous user's trips "flashing" while loading trips for new user
        DispatchQueue.main.async(execute: {
            self.tripListTable.reloadData()
        })

        // Log out and clear credentials
        User.sharedUser.logout()
    }
}
