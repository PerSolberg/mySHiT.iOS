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

class TripListViewController: UITableViewController /*, UITextFieldDelegate */ {
    // MARK: Constants


    // MARK: Properties
    @IBOutlet var tripListTable: UITableView!

    var sections: [TripListSectionInfo]!
    var tripToRefresh: IndexPath?

    // MARK: Archiving paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveTripsURL = DocumentsDirectory.appendingPathComponent("trips")
    static let ArchiveSectionsURL = DocumentsDirectory.appendingPathComponent("sections")

    
    // MARK: Navigation
    @IBAction func unwindToMain(_ sender: UIStoryboardSegue)
    {
        tripListTable.setBackgroundMessage(NSLocalizedString(Constant.msg.retrievingTrips, comment: Constant.dummyLocalisationComment))
        TripList.sharedList.getFromServer()
        return
    }
    

    @IBAction func openSettings(_ sender: AnyObject) {
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(appSettings, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
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
                    
                    let selectedTrip = TripList.sharedList[s!.section.firstTrip + indexPath.row]!
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
    

    // MARK: Constructors
    func initCommon() {
        sections = [TripListSectionInfo]()
        for tls in TripListSection.allValues {
            sections.append( TripListSectionInfo(visible: true, type: tls, firstTrip: -1)! )
        }
    }


    required init?( coder: NSCoder) {
        super.init(coder: coder)
        initCommon()
    }


    override init(style: UITableView.Style) {
        super.init(style: style)
        initCommon()
    }

    
    // MARK: Callbacks
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up refresh
        refreshControl = UIRefreshControl()
        refreshControl!.backgroundColor = tripListTable.backgroundColor
        refreshControl!.tintColor = UIColor.blue
        refreshControl!.addTarget(self, action: #selector(/*TripListViewController.*/reloadTripsFromServer), for: .valueChanged)
    }

    func showLogonScreen(animated: Bool) {
        let storyboard: UIStoryboard = UIStoryboard(name:"Main", bundle: nil)
        let logonVC = storyboard.instantiateViewController(withIdentifier: "logonScreen") as! LogonViewController
        view.window!.makeKeyAndVisible()
        view.window!.rootViewController?.present(logonVC, animated: true, completion: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Load data & check if section list is complete (if not, add missing elements)
        var sectionList = loadTrips()
        if sectionList == nil {
            sectionList = [TripListSectionInfo]()
        }
        sections = sectionList
        classifyTrips()
        updateSections()
        saveTrips()
        tripListTable.estimatedRowHeight = 40
        tripListTable.rowHeight = UITableView.automaticDimension
        DispatchQueue.main.async(execute: {
            self.tripListTable.reloadData()
        })

        NotificationCenter.default.addObserver(self, selector: #selector(logonComplete(_:)), name: Constant.notification.logonSuccessful, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshTripList), name: Constant.notification.refreshTripList, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshTripList), name: Constant.notification.dataRefreshed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNetworkError), name: Constant.notification.networkError, object: nil)
    }
 
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if isMovingToParent {
            NotificationCenter.default.removeObserver(self)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        if !User.sharedUser.hasCredentials() {
            showLogonScreen(animated: false)
        }

        if let indexPath = tripToRefresh {
            let s = getSectionById(indexPath.section)
            let selectedTrip = TripList.sharedList[s!.section.firstTrip + indexPath.row]!
            
            selectedTrip.modified = .Unchanged
            if let elements = selectedTrip.trip.elements {
                for element in elements {
                    if element.modified == .Changed {
                        selectedTrip.modified = .Changed
                        break
                    }
                }
            }
            UIApplication.shared.applicationIconBadgeNumber = TripList.sharedList.changes()
            
            if let cell = tableView.cellForRow(at: indexPath), let imgView = cell.viewWithTag(4) as? UIImageView {
                imgView.image = selectedTrip.trip.icon?.overlayBadge(selectedTrip.modified)
            }

            tripToRefresh = nil
            TripList.sharedList.saveToArchive(TripListViewController.ArchiveTripsURL.path)
        }
    }
    
    
    @objc func refreshTripList() {
        if let refreshControl = refreshControl {
            DispatchQueue.main.async(execute: {
                if refreshControl.isRefreshing {
                    refreshControl.endRefreshing()
                }
            })
        }
        if (TripList.sharedList.count == 0) {
            tripListTable.setBackgroundMessage(NSLocalizedString(Constant.msg.noTrips, comment: Constant.dummyLocalisationComment))
        } else {
            tripListTable.setBackgroundMessage(nil)
        }
        classifyTrips()
        updateSections()
        DispatchQueue.main.async(execute: {
            self.tripListTable.reloadData()
        })
        saveTrips()
    }

    
    @objc func handleNetworkError() {
        // Should only be called if this view controller is displayed (notification observers
        // added in viewWillAppear and removed in viewWillDisappear

        // Notify user - and stop refresh in completion handler to ensure screen is properly updated
        // (ending refresh first, either in a separate DispatchQueue.main.sync call or in the alert async
        // closure didn't always dismiss the refrech control)
        DispatchQueue.main.async(execute: {
            let alert = UIAlertController(
                title: NSLocalizedString(Constant.msg.alertBoxTitle, comment: Constant.dummyLocalisationComment),
                message: NSLocalizedString(Constant.msg.connectError, comment: Constant.dummyLocalisationComment),
                preferredStyle: UIAlertController.Style.alert)
            alert.addAction(Constant.alert.actionOK)
            self.present(alert, animated: true, completion: {
                DispatchQueue.main.async {
                    if let refreshControl = self.refreshControl {
                        if refreshControl.isRefreshing {
                            refreshControl.endRefreshing()
                        }
                    }
                }
            })
        })

        if (TripList.sharedList.count == 0) {
            tripListTable.setBackgroundMessage(NSLocalizedString(Constant.msg.networkUnavailable, comment: Constant.dummyLocalisationComment))
        } else {
            tripListTable.setBackgroundMessage(nil)
        }
    }
    
    
    @objc func reloadTripsFromServer() {
        tripListTable.setBackgroundMessage(NSLocalizedString(Constant.msg.retrievingTrips, comment: Constant.dummyLocalisationComment))
        TripList.sharedList.getFromServer()
    }

    
    @objc func logonComplete(_ notification:Notification) {
        reloadTripsFromServer()
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // MARK: UITableViewDataSource methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        var sectionCount = 0
        for s in sections {
            if s.firstTrip > -1 {
                sectionCount += 1
            }
        }
        return sectionCount
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let s = getSectionById(section) {
            if s.section.visible! {
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

        //print("RowIndex: section = \(indexPath.section), row = \(indexPath.row)")
        if let s = getSectionById(indexPath.section) {
            let rowIdx = s.section.firstTrip + indexPath.row
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
            // ERROR!!!
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


    // MARK: Section header callbacks
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
    

    // MARK: NSCoding
    func saveTrips() {
        TripList.sharedList.saveToArchive(TripListViewController.ArchiveTripsURL.path)
        saveSections()
    }

    
    func saveSections() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(sections!, toFile: TripListViewController.ArchiveSectionsURL.path)
        if !isSuccessfulSave {
            print("Failed to save sections...")
        } else {
//            print("Trip sections saved to iOS keyed archive")
        }
    }
    
    
    func loadTrips() -> [TripListSectionInfo]? {        TripList.sharedList.loadFromArchive(TripListViewController.ArchiveTripsURL.path)
        let sectionList = NSKeyedUnarchiver.unarchiveObject(withFile: TripListViewController.ArchiveSectionsURL.path) as? [TripListSectionInfo]
        return sectionList
    }
    


    // MARK: Actions

    
    // MARK: Functions
    func classifyTrips() {
        let defaults = UserDefaults.standard
        let upcomingPref:UserPrefUpcomingTrips! = UserPrefUpcomingTrips(rawValue: (defaults.string(forKey: "upcoming_trips") ?? UserPrefUpcomingTrips.NextOrWithin7Days.rawValue))!

        let today = Date()
        let updatedSections = sections
        for s in updatedSections! {
            s.firstTrip = -1
        }

        var prevSection:TripListSection! = .Historic
        for aTrip in TripList.sharedList.reverse() {
            //print(aTrip)
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
            prevSection = aTrip.section
        }
    }

    
    func updateSections() {
        // First add any missing sections
        for tls in TripListSection.allValues {
            var found = false
            for s in sections {
                if s.type == tls {
                    found = true
                    break
                }
            }
            if !found {
                sections.append( TripListSectionInfo(visible: true, type: tls, firstTrip: -1)! )
            }
        }

        // Then update section parameter
        for s in sections {
            s.firstTrip = -1
            for ti in TripList.sharedList.indices {
                if TripList.sharedList[ti]!.section == s.type {
                    s.firstTrip = ti
                    break
                }
            }
        }
    }

    
    func getSectionById(_ sectionNo:Int) -> (index: Int, section:TripListSectionInfo, itemCount:Int)? {
        // Find section in section list
        var sectionCount = 0
        var sectionIdx:Int?
        var firstTripThisSection:Int?
        var firstTripNextSection:Int?
        for ix in sections.indices {
            if sections[ix].firstTrip > -1 {
                // Found section containing data
                if sectionCount == sectionNo {
                    // Found desired section
                    sectionIdx = ix
                    firstTripThisSection = sections[ix].firstTrip
                } else if sectionCount > sectionNo && firstTripNextSection == nil {
                    // Found next section containing data
                    firstTripNextSection = sections[ix].firstTrip
                }
                sectionCount += 1
            }
        }
        if let sectionIdx = sectionIdx {
            if firstTripNextSection == nil {
                firstTripNextSection = TripList.sharedList.count
            }
            return (sectionIdx, sections[sectionIdx], firstTripNextSection! - firstTripThisSection!)
        } else {
            return nil
        }
    }
    
    func logout() {
        // Empty memory structures, clear notification (part of clear) and update keyed archive
        TripList.sharedList.clear()
        sections = [TripListSectionInfo]()
        saveTrips()
        
        // Refresh list to avoid previous user's trips "flashing" while loading trips for new user
        DispatchQueue.main.async(execute: {
            self.tripListTable.reloadData()
        })

        // Log out and clear credentials
        User.sharedUser.logout()
    }
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
