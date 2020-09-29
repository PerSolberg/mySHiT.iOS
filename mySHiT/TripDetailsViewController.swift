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
    struct CellIdentifier {
        static let tripDetails = "myTripDetailsCell"
    }
    
    // MARK: Properties
    @IBOutlet var tripDetailsTable: UITableView!
    @IBOutlet weak var barButtonChat: UIBarButtonItem!
    
    var elementToRefresh: IndexPath?
    
    // Passed from TripListViewController
    var tripCode:String?
    
    // Retrieved based on tripCode
    var trip:AnnotatedTrip?

    // Section data
    var sections:[TripElementListSectionInfo] = [TripElementListSectionInfo]()

    // DeepLinkableViewController
    var wasDeepLinked: Bool
    
    
    //
    // MARK: Navigation
    //
    @IBAction func openSettings(_ sender: AnyObject) {
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
        }
    }
    
        
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        if let _ = segue.identifier, let selectedTripCell = sender as? UITableViewCell {
            let indexPath = tableView.indexPath(for: selectedTripCell)!
            let s = getSectionById(indexPath.section)
            let selectedAnnotatedElement = trip!.trip.elements![s!.section.firstTripElement! + indexPath.row]
            let selectedElement = selectedAnnotatedElement.tripElement
            
            let destinationController = segue.destination as! TripElementViewController
            destinationController.tripElement = selectedElement

            if selectedAnnotatedElement.modified == .New || selectedAnnotatedElement.modified == .Changed {
                elementToRefresh = indexPath
            }
        } else if let segueId = segue.identifier {
            switch (segueId) {
            case Constant.Segue.showChatTable:
//                 Probably not used
                os_log("Segue to ChatTableController", log:OSLog.general, type: .debug)
                let destinationController = segue.destination as! ChatTableController
                destinationController.trip = trip

            case Constant.Segue.showChatView:
                os_log("Segue to ChatViewController", log:OSLog.general, type: .debug)
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
    
    
    //
    // MARK: Callbacks
    //
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

        if let trip = TripList.sharedList.trip(byCode: tripCode!) {
            self.trip = trip
            self.title = trip.trip.name
            if let elements = trip.trip.elements, elements.count > 0 {
                updateSections()
            } else {
                tripDetailsTable.setBackgroundMessage(Constant.Message.retrievingTripDetails)

                trip.trip.loadDetails(parentCompletionHandler: nil)
            }
        }

        NotificationCenter.default.addObserver(self, selector: #selector(refreshTripElements), name: Constant.Notification.refreshTripElements, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshTripElements), name: Constant.Notification.dataRefreshed, object: nil)
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(handleNetworkError), name: Constant.Notification.networkError, object: nil)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: Constant.Notification.networkError, object: nil)
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
        if let s = getSectionById(section), s.section.visible {
            return s.itemCount
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
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.tripDetails) ?? UITableViewCell(style: .default, reuseIdentifier: CellIdentifier.tripDetails)

        //Get data from TripList element
        if let s = getSectionById(indexPath.section) {
            let rowIdx = s.section.firstTripElement! + indexPath.row
            let tripElement = trip!.trip.elements![rowIdx].tripElement
            
            let lblName = cell.viewWithTag(1) as! UILabel
            let lblStartTime = cell.viewWithTag(2) as! UILabel
            let lblEndTime = cell.viewWithTag(3) as! UILabel
            let lblDesc  = cell.viewWithTag(4) as! UITextView
            let imgView = cell.viewWithTag(5) as! UIImageView

            lblName.text = tripElement.title ?? Constant.Message.tripElementTitleDefault
            lblStartTime.text = tripElement.startInfo ?? Constant.Message.tripElementStartInfoDefault
            lblEndTime.text = tripElement.endInfo
            lblDesc.text = tripElement.detailInfo ?? Constant.Message.tripElementDetailsDefault
            imgView.image = tripElement.icon?.overlayBadge(trip!.trip.elements![rowIdx].modified)
        } else {
            os_log("Section %d not found", log: OSLog.general, type: .error, indexPath.section)
        }

        return cell
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
            
            //TODO: Make more dynamic
            switch (tripElement.type, tripElement.subType) {
            case (TripElement.MainType.Accommodation, TripElement.SubType.Hotel):
                performSegue(.showHotelInfoSegue, sender: selectedCell)
            case (TripElement.MainType.Event, _):
                performSegue(.showEventInfoSegue, sender: selectedCell)
            case (TripElement.MainType.Transport, TripElement.SubType.Airline):
                performSegue(.showFlightInfoSegue, sender: selectedCell)
            case (TripElement.MainType.Transport, TripElement.SubType.Bus):
                performSegue(.showScheduledTransportInfoSegue, sender: selectedCell)
            case (TripElement.MainType.Transport, TripElement.SubType.Train):
                performSegue(.showScheduledTransportInfoSegue, sender: selectedCell)
            case (TripElement.MainType.Transport, TripElement.SubType.Boat):
                performSegue(.showScheduledTransportInfoSegue, sender: selectedCell)
            case (TripElement.MainType.Transport, TripElement.SubType.Limo):
                performSegue(.showPrivateTransportInfoSegue, sender: selectedCell)
            case (TripElement.MainType.Transport, TripElement.SubType.PrivateBus):
                performSegue(.showPrivateTransportInfoSegue, sender: selectedCell)
            default:
                performSegue(.showUnknownInfoSegue, sender: selectedCell)
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
        tripDetailsTable.setBackgroundMessage(Constant.Message.retrievingTripDetails)
        if let trip = TripList.sharedList.trip(byCode: tripCode!) {
            self.trip = trip
            trip.trip.loadDetails(parentCompletionHandler: nil)
        }
    }
    

    @objc func handleNetworkError() {
        // Should only be called if this view controller is displayed (notification observers
        // added in viewWillAppear and removed in viewWillDisappear
        
        // Notify user - and stop refresh in completion handler to ensure screen is properly updated
        // (ending refresh first, either in a separate DispatchQueue.main.sync call or in the alert async
        // closure didn't always dismiss the refrech control)
        os_log("Handling network error in TripDetails", log: OSLog.general, type:.info)
        showAlert(title: Constant.Message.alertBoxTitle, message: Constant.Message.connectError) { self.endRefreshing() }
        
        if let trip = TripList.sharedList.trip(byCode: tripCode!) {
            if trip.trip.elements == nil || trip.trip.elements!.count == 0 {
                tripDetailsTable.setBackgroundMessage(Constant.Message.networkUnavailable)
            } else {
                tripDetailsTable.setBackgroundMessage(nil)
            }
        }
    }
    
    
    @objc func refreshTripElements() {
        os_log("TripDetailsViewController refreshTripElements", log: OSLog.general, type:.debug)
        endRefreshing()
        if let trip = TripList.sharedList.trip(byCode: tripCode!) {
            self.trip = trip
            if trip.trip.elements == nil || trip.trip.elements!.count == 0 {
                tripDetailsTable.setBackgroundMessage(Constant.Message.noDetailsAvailable)
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
                    if trip.trip.tense ?? .past == .present && lastElementTense == .past {
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
    
    
    //
    // MARK: Static functions
    //
    static func pushDeepLinked(for tripId:Int) {
        guard let navVC = UIApplication.rootNavigationController else {
            os_log("Unable to get root navigation controller", log: OSLog.general, type: .error)
            return
        }
        if let tripVC = navVC.visibleViewController as? TripDetailsViewController, let trip = tripVC.trip?.trip, trip.id == tripId {
            os_log("Update for current trip - No need to do anything, already handled", log: OSLog.general, type: .debug)
        } else {
            navVC.popDeepLinkedControllers()
            // Push correct view controller onto navigation stack
            if let annotatedTrip = TripList.sharedList.trip(byId: tripId) {
                let tvc = TripDetailsViewController.instantiate(fromAppStoryboard: .Main)
                tvc.wasDeepLinked = true
                tvc.trip = annotatedTrip
                tvc.tripCode = annotatedTrip.trip.code
                navVC.pushViewController(tvc, animated: true)
            } else {
                os_log("Unable to get trip", log: OSLog.general, type: .error)
            }
        }
    }
}
