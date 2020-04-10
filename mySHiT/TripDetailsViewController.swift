//
//  TripDetailsViewController.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-19.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import UIKit
import os

class TripDetailsViewController: UITableViewController, DeepLinkableViewController {
    
    // MARK: Properties
    @IBOutlet var tripDetailsTable: UITableView!
    @IBOutlet weak var barButtonChat: UIBarButtonItem!
    
    var elementToRefresh: IndexPath?
    
    // Passed from TripListViewController
    var tripCode:String?
    var tripSection:TripListSection?
    
    // Retrieved based on tripCode
    var trip:AnnotatedTrip?

    // Section data
    var sections:[TripElementListSectionInfo] = [TripElementListSectionInfo]()

    // DeepLinkableViewController
    var wasDeepLinked: Bool
    
    // MARK: Navigation
    @IBAction func openSettings(_ sender: AnyObject) {
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
        }
    }
    
        
    // Prepare for navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        if let segueId = segue.identifier, let selectedTripCell = sender as? UITableViewCell {
            let indexPath = tableView.indexPath(for: selectedTripCell)!
            let s = getSectionById(indexPath.section)
            let selectedElement = trip!.trip.elements![s!.section.firstTripElement! + indexPath.row]
            
            switch (segueId) {
            case Constant.segue.showFlightInfo:
                let destinationController = segue.destination as! FlightDetailsViewController
                destinationController.tripElement = selectedElement
                destinationController.trip = trip
                
            case Constant.segue.showHotelInfo:
                let destinationController = segue.destination as! HotelDetailsViewController
                destinationController.tripElement = selectedElement
                destinationController.trip = trip
                
            case Constant.segue.showScheduledTransport:
                let destinationController = segue.destination as! ScheduledTransportDetailsViewController
                destinationController.tripElement = selectedElement
                destinationController.trip = trip
                
            case Constant.segue.showPrivateTransport:
                let destinationController = segue.destination as! PrivateTransportDetailsViewController
                destinationController.tripElement = selectedElement
                destinationController.trip = trip
                
            case Constant.segue.showEventInfo:
                let destinationController = segue.destination as! EventDetailsViewController
                destinationController.tripElement = selectedElement
                destinationController.trip = trip
                
            default:
                let destinationController = segue.destination as! UnknownElementDetailsViewController
                destinationController.tripElement = selectedElement
                destinationController.trip = trip
            }
            if selectedElement.modified == .New || selectedElement.modified == .Changed {
                elementToRefresh = indexPath
            }
        } else if let segueId = segue.identifier {
            switch (segueId) {
            case Constant.segue.showChatTable:
                let destinationController = segue.destination as! ChatTableController
                destinationController.trip = trip

            case Constant.segue.showChatView:
                let destinationController = segue.destination as! ChatViewController
                destinationController.trip = trip
                
            default:
                // No special preparation necessary
                break
            }
        } else {
            os_log("Preparing for unidentified segue", log: OSLog.general, type: .error)
        }
    }
    
    
    // MARK: Constructors
    required init?(coder: NSCoder) {
        wasDeepLinked = false
        super.init(coder: coder)
    }
    
    
    // MARK: Callbacks
    override func viewDidLoad() {
        super.viewDidLoad()

        tripDetailsTable.estimatedRowHeight = 40
        tripDetailsTable.rowHeight = UITableView.automaticDimension
        tripDetailsTable.contentInset = UIEdgeInsets.zero
        
        // Set up refresh
        refreshControl = UIRefreshControl()
        refreshControl!.backgroundColor = tripDetailsTable.backgroundColor
        refreshControl!.tintColor = UIColor.blue
        refreshControl!.addTarget(self, action: #selector(TripDetailsViewController.reloadTripDetailsFromServer), for: .valueChanged)

        NotificationCenter.default.addObserver(self, selector: #selector(refreshTripElements), name: Constant.notification.refreshTripElements, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshTripElements), name: Constant.notification.dataRefreshed, object: nil)
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(handleNetworkError), name: Constant.notification.networkError, object: nil)
        if let trip = TripList.sharedList.trip(byCode: tripCode!) {
            self.trip = trip
            self.title = trip.trip.name
            if let elements = trip.trip.elements, elements.count > 0 {
                updateSections()
            } else {
                tripDetailsTable.setBackgroundMessage(Constant.msg.retrievingTripDetails)

                trip.trip.loadDetails()
            }
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: Constant.notification.networkError, object: nil)
    }

    
    override func viewDidAppear(_ animated: Bool) {
        if let indexPath = elementToRefresh {
            let s = getSectionById(indexPath.section)
            let rowIdx = s!.section.firstTripElement! + indexPath.row
            let selectedElement = trip!.trip.elements![rowIdx]
            let tripElement = selectedElement.tripElement

            selectedElement.modified = .Unchanged
            if let cell = tripDetailsTable.cellForRow(at: indexPath), let imgView = cell.viewWithTag(5) as? UIImageView {
                imgView.image = tripElement.icon?.overlayBadge(selectedElement.modified)
            }
            
            TripList.sharedList.saveToArchive()
            
            elementToRefresh = nil
            UIApplication.shared.applicationIconBadgeNumber = TripList.sharedList.changes()
        }
    }


    //
    // MARK: UITableViewDataSource methods
    //
    override func numberOfSections(in tableView: UITableView) -> Int {
        let activeSections = sections.filter { $0.firstTripElement != nil }
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
            return s.section.title
        } else {
            os_log("Section header not available for section %d", log: OSLog.general, type: .error, section)
            return nil
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let kCellIdentifier: String = "myTripDetailsCell"
        
        //tablecell optional to see if we can reuse cell
        var cell : UITableViewCell?
        cell = tableView.dequeueReusableCell(withIdentifier: kCellIdentifier)
        
        //Get data from TripList element
        if let s = getSectionById(indexPath.section) {
            let rowIdx = s.section.firstTripElement! + indexPath.row
            let tripElement = trip!.trip.elements![rowIdx].tripElement
            
            let lblName = cell!.viewWithTag(1) as! UILabel
            let lblStartTime = cell!.viewWithTag(2) as! UILabel
            let lblEndTime = cell!.viewWithTag(3) as! UILabel
            let lblDesc  = cell!.viewWithTag(4) as! UITextView
            let imgView = cell!.viewWithTag(5) as! UIImageView

            lblName.text = tripElement.title ?? "Unknown element"
            lblStartTime.text = tripElement.startInfo ?? "Unknown start"
            lblEndTime.text = tripElement.endInfo
            lblDesc.text = tripElement.detailInfo ?? "No details available"
            imgView.image = tripElement.icon?.overlayBadge(trip!.trip.elements![rowIdx].modified)
        } else {
            // ERROR!!!
        }

        return cell!
    }
    
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.tripDetailsTable.frame.size.width, height: 40))
        headerView.backgroundColor = UIColor.lightGray
        headerView.tag = section
        
        let headerString = UILabel(frame: CGRect(x: 10, y: 5, width: self.tripDetailsTable.frame.size.width-10, height: 20)) as UILabel
        if let s = getSectionById(section) {
            headerString.text = s.section.title
        }
        
        headerView.addSubview(headerString)
        
        let headerTapped = UITapGestureRecognizer (target: self, action:#selector(TripDetailsViewController.sectionHeaderTapped(_:)))
        headerView.addGestureRecognizer(headerTapped)
        
        return headerView
    }

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let s = getSectionById(indexPath.section) {
            let rowIdx = s.section.firstTripElement! + indexPath.row
            let tripElement = trip!.trip.elements![rowIdx].tripElement
            let selectedCell = tableView.cellForRow(at: indexPath)
            switch (tripElement.type, tripElement.subType) {
            case ("ACM", "HTL"):
                performSegue(withIdentifier: "showHotelInfoSegue", sender: selectedCell)
            case ("EVT", _):
                performSegue(withIdentifier: "showEventInfoSegue", sender: selectedCell)
            case ("TRA", "AIR"):
                performSegue(withIdentifier: "showFlightInfoSegue", sender: selectedCell)
            case ("TRA", "BUS"):
                performSegue(withIdentifier: "showScheduledTransportInfoSegue", sender: selectedCell)
            case ("TRA", "TRN"):
                performSegue(withIdentifier: "showScheduledTransportInfoSegue", sender: selectedCell)
            case ("TRA", "BOAT"):
                performSegue(withIdentifier: "showScheduledTransportInfoSegue", sender: selectedCell)
            case ("TRA", "LIMO"):
                performSegue(withIdentifier: "showPrivateTransportInfoSegue", sender: selectedCell)
            case ("TRA", "PBUS"):
                performSegue(withIdentifier: "showPrivateTransportInfoSegue", sender: selectedCell)
            default:
                performSegue(withIdentifier: "showUnknownInfoSegue", sender: selectedCell)
                break
            }
        }
    }
    
    
    //
    // MARK: Section header callbacks
    //
    @objc func sectionHeaderTapped(_ recognizer: UITapGestureRecognizer) {
        let indexPath : IndexPath = IndexPath(row: 0, section: recognizer.view!.tag)
        if let s = getSectionById(indexPath.section) {
            sections[s.index].visible = !sections[s.index].visible
            
            //reload specific section animated
            let range = indexPath.section ..< (indexPath.section + 1)
            let sectionToReload = IndexSet(integersIn: range)
            self.tripDetailsTable.reloadSections(sectionToReload, with:UITableView.RowAnimation.fade)
        }
    }
    
    
    //
    // MARK: Functions
    //
    @objc func reloadTripDetailsFromServer() {
        tripDetailsTable.setBackgroundMessage(Constant.msg.retrievingTripDetails)
        if let trip = TripList.sharedList.trip(byCode: tripCode!) {
            self.trip = trip
            trip.trip.loadDetails()
        }
    }
    

    @objc func handleNetworkError() {
        // Should only be called if this view controller is displayed (notification observers
        // added in viewWillAppear and removed in viewWillDisappear
        
        // Notify user - and stop refresh in completion handler to ensure screen is properly updated
        // (ending refresh first, either in a separate DispatchQueue.main.sync call or in the alert async
        // closure didn't always dismiss the refrech control)
        os_log("Handling network error in TripDetails", log: OSLog.general, type:.info)
        showAlert(title: Constant.msg.alertBoxTitle, message: Constant.msg.connectError) { self.endRefreshing() }
        
        if let trip = TripList.sharedList.trip(byCode: tripCode!) {
            if trip.trip.elements == nil || trip.trip.elements!.count == 0 {
                tripDetailsTable.setBackgroundMessage(Constant.msg.networkUnavailable)
            } else {
                tripDetailsTable.setBackgroundMessage(nil)
            }
        }
    }
    
    
//    @objc func authenticationFailed(_ notification:Notification) {
//        print("TripDetailsViewController: authenticationFailed")
//        DispatchQueue.main.sync {
//            guard let rootVC = UIApplication.shared.keyWindow?.rootViewController, let navVC = rootVC as? UINavigationController else {
//                os_log("Unable to get root view controller or it is not a navigation controller", log: OSLog.general, type: .error)
//                return
//            }
//            navVC.popToRootViewController(animated: false)
//        }
//    }


    @objc func refreshTripElements() {
        endRefreshing()
        if let trip = TripList.sharedList.trip(byCode: tripCode!) {
            self.trip = trip
            if trip.trip.elements == nil || trip.trip.elements!.count == 0 {
                tripDetailsTable.setBackgroundMessage(Constant.msg.noDetailsAvailable)
            } else {
                tripDetailsTable.setBackgroundMessage(nil)
            }
        }
        updateSections()
        DispatchQueue.main.async(execute: {
            self.title = self.trip?.trip.name
            self.tripDetailsTable.reloadData()
        })
    }


    func updateSections() {
        sections = [TripElementListSectionInfo]()
        var lastSectionTitle = ""
        var lastElementTense = Tenses.future
        if let trip = trip, let elements = trip.trip.elements {
            for (i, element) in elements.enumerated() {
                let elemStartDate = element.tripElement.startTime(dateStyle: .medium, timeStyle: .none) ?? lastSectionTitle
                if elemStartDate != lastSectionTitle {
                    // First check if previous section should be hidden by default
                    // For active trips, past dates are collapsed by default; active and future dates are expanded
                    // For past and future trips, all sections are expanded by default
                    if tripSection == .Current && lastElementTense == .past {
                        sections[sections.count - 1].visible = false
                    }
                    
                    sections.append( TripElementListSectionInfo(visible: true, title: elemStartDate, firstTripElement: i) )
                    lastSectionTitle = elemStartDate
                }
                lastElementTense = element.tripElement.tense!
            }
        }
    }
    
    
    func getSectionById(_ sectionNo:Int) -> (index: Int, section:TripElementListSectionInfo, itemCount:Int)? {
        if sectionNo >= sections.count {
            return nil
        }

        var firstTripNextSection = trip!.trip.elements!.count
        if (sectionNo + 1) < sections.count {
            firstTripNextSection = sections[sectionNo + 1].firstTripElement!
        }

        return (sectionNo, sections[sectionNo], firstTripNextSection - sections[sectionNo].firstTripElement!)
    }
}


