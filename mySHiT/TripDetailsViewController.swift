//
//  TripDetailsViewController.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-19.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class TripDetailsViewController: UITableViewController {
    
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
    var sections: [TripElementListSectionInfo]! = [TripElementListSectionInfo]()


    // MARK: Navigation
    @IBAction func openSettings(_ sender: AnyObject) {
        if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
            //UIApplication.shared.openURL(appSettings)
        }
    }
    
        
    // Prepare for navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        if let segueId = segue.identifier, let selectedTripCell = sender as? UITableViewCell {
            print("Trip Details: Preparing for segue '\(segueId)'")
            let indexPath = tableView.indexPath(for: selectedTripCell)!
            let s = getSectionById(indexPath.section)
            let selectedElement = trip!.trip.elements![s!.section.firstTripElement + indexPath.row]
            
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
            print("Trip Details: Preparing for segue '\(segueId)' (no trip element)")
            switch (segueId) {
            case Constant.segue.showChatTable:
                let destinationController = segue.destination as! ChatTableController
                destinationController.trip = trip

            case Constant.segue.showChatView:
                let destinationController = segue.destination as! ChatViewController
                destinationController.trip = trip
                
            default:
                print("No special preparation necessary")
            }
        } else {
            print("Trip Details: Preparing for unidentified segue")
        }
    }
    
    
    // MARK: Constructors
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    // MARK: Callbacks
    override func viewDidLoad() {
        print("Trip Details View loaded")
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(TripDetailsViewController.refreshTripElements), name: NSNotification.Name(rawValue: "RefreshTripElements"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TripDetailsViewController.refreshTripElements), name: NSNotification.Name(rawValue: "dataRefreshed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TripDetailsViewController.handleNetworkError), name: NSNotification.Name(rawValue: "networkError"), object: nil)

        if let trip = TripList.sharedList.trip(byCode: tripCode!) {
            self.trip = trip
            self.title = trip.trip.name
            if trip.trip.elements != nil && trip.trip.elements?.count > 0 {
                print("Trip details already loaded")
                updateSections()
                //refreshTripElements()
            } else {
                // Load details from server
                trip.trip.loadDetails()
            }
        }
        tripDetailsTable.estimatedRowHeight = 40
        tripDetailsTable.rowHeight = UITableViewAutomaticDimension
        tripDetailsTable.contentInset = UIEdgeInsets.zero
        
        // Set up refresh
        refreshControl = UIRefreshControl()
        refreshControl!.backgroundColor = tripDetailsTable.backgroundColor
        refreshControl!.tintColor = UIColor.blue  //whiteColor()
        refreshControl!.addTarget(self, action: #selector(TripDetailsViewController.reloadTripDetailsFromServer), for: .valueChanged)
        
        // Hide chat button until chat is fully implemented
//        barButtonChat.isEnabled = false
//        barButtonChat.tintColor = UIColor.clear
    }


    override func viewDidAppear(_ animated: Bool) {
        if let indexPath = elementToRefresh {
            let s = getSectionById(indexPath.section)
            let selectedElement = trip!.trip.elements![s!.section.firstTripElement + indexPath.row]
            let rowIdx = s!.section.firstTripElement + indexPath.row
            let tripElement = trip!.trip.elements![rowIdx].tripElement
            
            selectedElement.modified = .Unchanged
            if let cell = tripDetailsTable.cellForRow(at: indexPath), let imgView = cell.viewWithTag(5) as? UIImageView {
                imgView.image = tripElement.icon?.overlayBadge(selectedElement.modified)
            }
            elementToRefresh = nil
            UIApplication.shared.applicationIconBadgeNumber = TripList.sharedList.changes()
        }
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: UITableViewDataSource methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        var sectionCount = 0
        for s in sections {
            if s.firstTripElement > -1 {
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
            return s.section.title
        } else {
            print("Section header not available")
            return nil
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //print("Refreshing cell at \(indexPath.section), \(indexPath.row)")
        let kCellIdentifier: String = "myTripDetailsCell"
        
        //tablecell optional to see if we can reuse cell
        var cell : UITableViewCell?
        cell = tableView.dequeueReusableCell(withIdentifier: kCellIdentifier)
        
        //Get data from TripList element
        if let s = getSectionById(indexPath.section) {
            let rowIdx = s.section.firstTripElement + indexPath.row
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
            let rowIdx = s.section.firstTripElement + indexPath.row
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
    
    
    // MARK: Section header callbacks
    func sectionHeaderTapped(_ recognizer: UITapGestureRecognizer) {
        let indexPath : IndexPath = IndexPath(row: 0, section:(recognizer.view?.tag as Int!)!)
        if let s = getSectionById(indexPath.section) {
            sections[s.index].visible = !sections[s.index].visible
            
            //reload specific section animated
            let range = NSMakeRange(indexPath.section, 1)
            let sectionToReload = IndexSet(integersIn: range.toRange() ?? 0..<0)
            self.tripDetailsTable.reloadSections(sectionToReload, with:UITableViewRowAnimation.fade)
        }
    }
    
    
    // MARK: Actions
    
    
    // MARK: Functions
    func reloadTripDetailsFromServer() {
        print("Reloading trip details")
        tripDetailsTable.setBackgroundMessage("Retrieving trip details from SHiT")   /* LOCALISE */
        if let trip = TripList.sharedList.trip(byCode: tripCode!) {
            self.trip = trip
            trip.trip.loadDetails()
        }
    }
    

    func handleNetworkError() {
        refreshControl!.endRefreshing()
        print("TripDetailsView: End refresh after network error")
        
        // Notify user
        if self.isViewLoaded && view.window != nil {
            DispatchQueue.main.async(execute: {
                let alert = UIAlertController(
                    title: NSLocalizedString(Constant.msg.alertBoxTitle, comment: "Some dummy comment"),
                    message: NSLocalizedString(Constant.msg.connectError, comment: "Some dummy comment"),
                    preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            })
        }
        
        if let trip = TripList.sharedList.trip(byCode: tripCode!) {
            if trip.trip.elements == nil || trip.trip.elements!.count == 0 {
                tripDetailsTable.setBackgroundMessage(NSLocalizedString(Constant.msg.networkUnavailable, comment: "Some dummy comment"))
            } else {
                tripDetailsTable.setBackgroundMessage(nil)
            }
        }
    }
    
    
    func refreshTripElements() {
        if let refreshControl = refreshControl {
            refreshControl.endRefreshing()
        }
        print("Refreshing trip details - probably because data were refreshed. Current trip is '\(String(describing: tripCode))'")
        if let trip = TripList.sharedList.trip(byCode: tripCode!) {
            self.trip = trip
            trip.trip.refreshNotifications()
            if trip.trip.elements == nil || trip.trip.elements!.count == 0 {
                tripDetailsTable.setBackgroundMessage(NSLocalizedString(Constant.msg.noDetailsAvailable, comment: "Some dummy comment"))
            } else {
                tripDetailsTable.setBackgroundMessage(nil)
            }
        }
        updateSections()
        print("Trip detail sections updated, now refreshing view")
        DispatchQueue.main.async(execute: {
            print("Refreshing trip details list view")
            self.title = self.trip?.trip.name
            self.tripDetailsTable.reloadData()
        })
    }


    func updateSections() {
        sections = [TripElementListSectionInfo]()
        var lastSectionTitle = ""
        var lastElementTense = Tenses.future
        if let trip = trip, let elements = trip.trip.elements {
            for i in elements.indices {
                //let elemStartDate = dateFormatter.stringFromDate(elements[i].tripElement.startTime!)
                let elemStartDate = elements[i].tripElement.startTime(dateStyle: .medium, timeStyle: .none) ?? lastSectionTitle
                if elemStartDate != lastSectionTitle {
                    // First check if previous section should be hidden by default
                    // For active trips, past dates are collapsed by default; active and future dates are expanded
                    // For past and future trips, all sections are expanded by default
                    if tripSection == .Current && lastElementTense == .past {
                        sections[sections.count - 1].visible = false
                    }
                    
                    sections.append( TripElementListSectionInfo(visible: true, title: elemStartDate, firstTripElement: i)! )
                    lastSectionTitle = elemStartDate
                }
                lastElementTense = elements[i].tripElement.tense!
            }
        }
    }
    
    
    func getSectionById(_ sectionNo:Int) -> (index: Int, section:TripElementListSectionInfo, itemCount:Int)? {
        if sectionNo >= sections.count {
            return nil
        }

        var firstTripNextSection: Int
        if (sectionNo + 1) < sections.count {
            firstTripNextSection = sections[sectionNo + 1].firstTripElement
        } else {
            firstTripNextSection = trip!.trip.elements!.count
        }

        return (sectionNo, sections[sectionNo], firstTripNextSection - sections[sectionNo].firstTripElement!)
    }
}

