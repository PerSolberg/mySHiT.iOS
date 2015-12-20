//
//  TripDetailsViewController.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-19.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import UIKit

class TripDetailsViewController: UITableViewController {
    
    // MARK: Properties
    @IBOutlet var tripDetailsTable: UITableView!
    
    // Passed from TripListViewController
    var tripCode:String?
    var tripSection:TripListSection?
    
    // Retrieved based on tripCode
    var trip:AnnotatedTrip?

    // Section data
    var sections: [TripElementListSectionInfo]! = [TripElementListSectionInfo]()


    // MARK: Navigation
    
    // Prepare for navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        if let segueId = segue.identifier, selectedTripCell = sender as? UITableViewCell {
            print("Trip Details: Preparing for segue '\(segueId)'")
            let indexPath = tableView.indexPathForCell(selectedTripCell)!
            let s = getSectionById(indexPath.section)
            let selectedElement = trip!.trip.elements![s!.section.firstTripElement + indexPath.row]
            
            switch (segueId) {
            case "showFlightInfoSegue":
                let destinationController = segue.destinationViewController as! FlightDetailsViewController
                destinationController.tripElement = selectedElement
                destinationController.trip = trip
                
            case "showHotelInfoSegue":
                let destinationController = segue.destinationViewController as! HotelDetailsViewController
                destinationController.tripElement = selectedElement
                destinationController.trip = trip
                
            case "showScheduledTransportInfoSegue":
                let destinationController = segue.destinationViewController as! ScheduledTransportDetailsViewController
                destinationController.tripElement = selectedElement
                destinationController.trip = trip
                
            case "showPrivateTransportInfoSegue":
                let destinationController = segue.destinationViewController as! PrivateTransportDetailsViewController
                destinationController.tripElement = selectedElement
                destinationController.trip = trip
                
            default:
                let destinationController = segue.destinationViewController as! UnknownElementDetailsViewController
                destinationController.tripElement = selectedElement
                destinationController.trip = trip
            }
        }
        else {
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

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshTripElements", name: "RefreshTripElements", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshTripElements", name: "dataRefreshed", object: nil)

        if let trip = TripList.sharedList.trip(byCode: tripCode!) {
            self.trip = trip    
            if trip.trip.elements != nil && trip.trip.elements?.count > 0 {
                print("Trip details already loaded")
                updateSections()
                refreshTripElements()
            } else {
                // Load details from server
                trip.trip.loadDetails()
            }
        }
        tripDetailsTable.estimatedRowHeight = 40
        tripDetailsTable.rowHeight = UITableViewAutomaticDimension
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: UITableViewDataSource methods
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        var sectionCount = 0
        for s in sections {
            if s.firstTripElement > -1 {
                sectionCount++
            }
        }
        return sectionCount
    }
    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let s = getSectionById(section) {
            return s.section.title
        } else {
            print("Section header not available")
            return nil
        }
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let kCellIdentifier: String = "myTripDetailsCell"
        
        //tablecell optional to see if we can reuse cell
        var cell : UITableViewCell?
        cell = tableView.dequeueReusableCellWithIdentifier(kCellIdentifier)
        
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
            imgView.image = tripElement.icon
            
            //cell!.imageView!.image = tripElement.icon
        } else {
            // ERROR!!!
        }

        return cell!
    }
    
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRectMake(0, 0, self.tripDetailsTable.frame.size.width, 40))
        headerView.backgroundColor = UIColor.lightGrayColor()
        headerView.tag = section
        
        let headerString = UILabel(frame: CGRect(x: 10, y: 5, width: self.tripDetailsTable.frame.size.width-10, height: 20)) as UILabel
        if let s = getSectionById(section) {
            headerString.text = s.section.title
        }
        
        headerView.addSubview(headerString)
        
        let headerTapped = UITapGestureRecognizer (target: self, action:"sectionHeaderTapped:")
        headerView.addGestureRecognizer(headerTapped)
        
        return headerView
    }

    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let s = getSectionById(indexPath.section) {
            let rowIdx = s.section.firstTripElement + indexPath.row
            let tripElement = trip!.trip.elements![rowIdx].tripElement
            let selectedCell = tableView.cellForRowAtIndexPath(indexPath)
            switch (tripElement.type, tripElement.subType) {
            case ("ACM", "HTL"):
                performSegueWithIdentifier("showHotelInfoSegue", sender: selectedCell)
            case ("TRA", "AIR"):
                performSegueWithIdentifier("showFlightInfoSegue", sender: selectedCell)
            case ("TRA", "BUS"):
                performSegueWithIdentifier("showScheduledTransportInfoSegue", sender: selectedCell)
            case ("TRA", "TRN"):
                performSegueWithIdentifier("showScheduledTransportInfoSegue", sender: selectedCell)
            case ("TRA", "BOAT"):
                performSegueWithIdentifier("showScheduledTransportInfoSegue", sender: selectedCell)
            case ("TRA", "LIMO"):
                performSegueWithIdentifier("showPrivateTransportInfoSegue", sender: selectedCell)
            case ("TRA", "PBUS"):
                performSegueWithIdentifier("showPrivateTransportInfoSegue", sender: selectedCell)
            //case ("TRA", _):
            //    performSegueWithIdentifier("showFlightInfoSegue", sender: selectedCell)
            default:
                performSegueWithIdentifier("showUnknownInfoSegue", sender: selectedCell)
                break
            }
        }
    }
    
    
    // MARK: Section header callbacks
    func sectionHeaderTapped(recognizer: UITapGestureRecognizer) {
        let indexPath : NSIndexPath = NSIndexPath(forRow: 0, inSection:(recognizer.view?.tag as Int!)!)
        if let s = getSectionById(indexPath.section) {
            sections[s.index].visible = !sections[s.index].visible
            
            //reload specific section animated
            let range = NSMakeRange(indexPath.section, 1)
            let sectionToReload = NSIndexSet(indexesInRange: range)
            self.tripDetailsTable.reloadSections(sectionToReload, withRowAnimation:UITableViewRowAnimation.Fade)
        }
    }
    
    
    // MARK: Actions
    
    
    // MARK: Functions
    func refreshTripElements() {
        print("Refreshing trip details - probably because data were refreshed")
        updateSections()
        dispatch_async(dispatch_get_main_queue(), {
            self.title = self.trip?.trip.name
            self.tripDetailsTable.reloadData()
        })
    }


    func updateSections() {
        //let dateFormatter = NSDateFormatter()
        //dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        //dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle

        sections = [TripElementListSectionInfo]()
        var lastSectionTitle = ""
        var lastElementTense = Tenses.future
        if let trip = trip, elements = trip.trip.elements {
            for i in elements.indices {
                //let elemStartDate = dateFormatter.stringFromDate(elements[i].tripElement.startTime!)
                let elemStartDate = elements[i].tripElement.startTime(dateStyle: .MediumStyle, timeStyle: .NoStyle) ?? lastSectionTitle
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
    
    
    func getSectionById(sectionNo:Int) -> (index: Int, section:TripElementListSectionInfo, itemCount:Int)? {
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

