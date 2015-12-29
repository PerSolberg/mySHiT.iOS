//
//  ViewController.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-09.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import UIKit
//import Security

class TripListViewController: UITableViewController /*, UITextFieldDelegate */ {
    // MARK: Constants


    // MARK: Properties
    @IBOutlet var tripListTable: UITableView!

    var sections: [TripListSectionInfo]!
    var tripToRefresh: NSIndexPath?

    // MARK: Archiving paths
    static let DocumentsDirectory = NSFileManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
    static let ArchiveTripsURL = DocumentsDirectory.URLByAppendingPathComponent("trips")
    static let ArchiveSectionsURL = DocumentsDirectory.URLByAppendingPathComponent("sections")

    
    // MARK: Navigation
    @IBAction func unwindToMain(sender: UIStoryboardSegue)
    {
        setBackgroundMessage("Retrieving your trips from SHiT")
        TripList.sharedList.getFromServer()
        return
    }
    

    // Prepare for navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // print("Preparing for segue '\(segue.identifier)'")

        if let segueId = segue.identifier {
            switch (segueId) {
            case "logoutSegue":
                logout()
            
            case "tripDetails":
                let destinationController = segue.destinationViewController as! TripDetailsViewController
                if let selectedTripCell = sender as? UITableViewCell {
                    let indexPath = tableView.indexPathForCell(selectedTripCell)!
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


    override init(style: UITableViewStyle) {
        super.init(style: style)
        initCommon()
    }

    
    // MARK: Callbacks
    override func viewDidLoad() {
        print("Trip List View loaded")
        print("Current language = \(NSLocale.currentLocale().objectForKey(NSLocaleLanguageCode)!)")
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "logonComplete:", name:"logonSuccessful", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshTripList", name: "RefreshTripList", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshTripList", name: "dataRefreshed", object: nil)
        
        if (!RSUtilities.isNetworkAvailable("www.shitt.no")) {
            _ = RSUtilities.networkConnectionType("www.shitt.no")
            
            //If host is not reachable, display a UIAlertController informing the user
            let alert = UIAlertController(title: "Alert", message: "You are not connected to the Internet", preferredStyle: UIAlertControllerStyle.Alert)
            
            //Add alert action
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            
            //Present alert
            self.presentViewController(alert, animated: true, completion: nil)
        }

        // Load data & check if section list is complete (if not, add missing elements)
        var sectionList = loadTrips()
        if sectionList == nil {
            sectionList = [TripListSectionInfo]()
        }
        sections = sectionList
        classifyTrips()
        updateSections()
        saveTrips()
        print("Data should be ready - refresh list")
        tripListTable.estimatedRowHeight = 40
        tripListTable.rowHeight = UITableViewAutomaticDimension
        dispatch_async(dispatch_get_main_queue(), {
            self.tripListTable.reloadData()
        })
        
        // Set up refresh
        refreshControl = UIRefreshControl()
        refreshControl!.backgroundColor = tripListTable.backgroundColor //UIColor.cyanColor()
        refreshControl!.tintColor = UIColor.blueColor()  //whiteColor()
        refreshControl!.addTarget(self, action: "reloadTripsFromServer", forControlEvents: .ValueChanged)
    }


    override func viewDidAppear(animated: Bool) {
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
            //tripListTable.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
            
            if let cell = tableView.cellForRowAtIndexPath(indexPath), imgView = cell.viewWithTag(4) as? UIImageView {
                imgView.image = selectedTrip.trip.icon?.overlayBadge(selectedTrip.modified)
            }

            tripToRefresh = nil
        }
    }
    
    
    func refreshTripList() {
        refreshControl!.endRefreshing()
        print("TripListView: Refreshing list, probably because data were updated")
        if (TripList.sharedList.count == 0) {
            setBackgroundMessage("You have no SHiT trips yet.")
        } else {
            setBackgroundMessage(nil)
        }
        classifyTrips()
        updateSections()
        dispatch_async(dispatch_get_main_queue(), {
            self.tripListTable.reloadData()
        })
        saveTrips()
    }

    
    func reloadTripsFromServer() {
        setBackgroundMessage("Retrieving your trips from SHiT")
        TripList.sharedList.getFromServer()
        refreshTripList()
    }

    func logonComplete(notification:NSNotification) {
        print("TripListView: Logon complete")
        reloadTripsFromServer()
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // MARK: UITableViewDataSource methods
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        var sectionCount = 0
        for s in sections {
            if s.firstTrip > -1 {
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
            let showText = NSLocalizedString(s.section.type.rawValue, comment: "test")
            return showText
        } else {
            print("Section header not available")
            return nil
        }
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let kCellIdentifier: String = "MyTripCell"
        
        //tablecell optional to see if we can reuse cell
        var cell : UITableViewCell?
        cell = tableView.dequeueReusableCellWithIdentifier(kCellIdentifier)

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
    

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRectMake(0, 0, self.tripListTable.frame.size.width, 40))
        headerView.backgroundColor = UIColor.lightGrayColor()
        headerView.tag = section

        let headerString = UILabel(frame: CGRect(x: 10, y: 5, width: self.tripListTable.frame.size.width-10, height: 20)) as UILabel
        if let s = getSectionById(section) {
            let baseText = s.section.type.rawValue
            let showText = NSLocalizedString(baseText, comment: "test")
            headerString.text = showText
        }
        
        headerView.addSubview(headerString)
        
        let headerTapped = UITapGestureRecognizer (target: self, action:"sectionHeaderTapped:")
        headerView.addGestureRecognizer(headerTapped)
        
        return headerView
    }


    // MARK: Section header callbacks
    func sectionHeaderTapped(recognizer: UITapGestureRecognizer) {
        let indexPath : NSIndexPath = NSIndexPath(forRow: 0, inSection:(recognizer.view?.tag as Int!)!)
        if let s = getSectionById(indexPath.section) {
            sections[s.index].visible = !sections[s.index].visible
            
            //reload specific section animated
            let range = NSMakeRange(indexPath.section, 1)
            let sectionToReload = NSIndexSet(indexesInRange: range)
            self.tripListTable.reloadSections(sectionToReload, withRowAnimation:UITableViewRowAnimation.Fade)
            saveSections()
        }
    }
    

    // MARK: NSCoding
    func saveTrips() {
        TripList.sharedList.saveToArchive(TripListViewController.ArchiveTripsURL.path!)
        saveSections()
    }

    
    func saveSections() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(sections, toFile: TripListViewController.ArchiveSectionsURL.path!)
        if !isSuccessfulSave {
            print("Failed to save sections...")
        } else {
            print("Trip sections saved to iOS keyed archive")
        }
    }
    
    
    func loadTrips() -> [TripListSectionInfo]? {
        print("Loading trips from iOS keyed archive")
        TripList.sharedList.loadFromArchive(TripListViewController.ArchiveTripsURL.path!)
        print("Loading sections from iOS keyed archive")
        let sectionList = NSKeyedUnarchiver.unarchiveObjectWithFile(TripListViewController.ArchiveSectionsURL.path!) as? [TripListSectionInfo]
        return sectionList
    }
    

    
    
// ----------------------------------------------------------------------------
    /*
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return heightForBasicCellAtIndexPath(indexPath)
    }
    
    func heightForBasicCellAtIndexPath(indexPath:NSIndexPath) -> CGFloat {
        var sizingCell:UITableViewCell?
        var onceToken = dispatch_once_t()
        dispatch_once(&onceToken, {
            sizingCell = self.tableView.dequeueReusableCellWithIdentifier("MyTripCell")
        });
        
        
        //[self configureBasicCell:sizingCell atIndexPath:indexPath];
        
        return calculateHeightForConfiguredSizingCell(sizingCell!);
    }
    
    func calculateHeightForConfiguredSizingCell(sizingCell: UITableViewCell) -> CGFloat {
        sizingCell.setNeedsLayout()
        sizingCell.layoutIfNeeded()
    
        let size:CGSize = sizingCell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
        return size.height + 1.0 // Add 1.0f for the cell separator height
    }
    */
// ----------------------------------------------------------------------------
    
    
    // MARK: Actions

    
    // MARK: Functions

    func classifyTrips() {
        let defaults = NSUserDefaults.standardUserDefaults()
        let upcomingPref:UserPrefUpcomingTrips! = UserPrefUpcomingTrips(rawValue: (defaults.stringForKey("upcoming_trips") ?? UserPrefUpcomingTrips.NextOrWithin7Days.rawValue))!

        let today = NSDate()
        let updatedSections = sections
        for s in updatedSections {
            s.firstTrip = -1
        }

        var prevSection:TripListSection! = .Historic
        for aTrip in TripList.sharedList.reverse() {
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
    
    
    func setBackgroundMessage(messageText:String?) {
        if let messageText = messageText {
            let messageLabel = UILabel()

            messageLabel.text = messageText
            messageLabel.textAlignment = .Center
            messageLabel.sizeToFit()
            tripListTable.backgroundView = messageLabel
        }
        else
        {
            tripListTable.backgroundView = nil
        }
        
    }
    
    
    func getSectionById(sectionNo:Int) -> (index: Int, section:TripListSectionInfo, itemCount:Int)? {
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
                sectionCount++
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
        // Empty memory structures an update keyed archive
        TripList.sharedList.clear()
        sections = [TripListSectionInfo]()
        saveTrips()
        
        // Log out and clear credentials
        User.sharedUser.logout()

        // Clear any scheduled notifications
        if let notifications = UIApplication.sharedApplication().scheduledLocalNotifications {
            for n in notifications {
                UIApplication.sharedApplication().cancelLocalNotification(n)
            }
        }
    }
}

