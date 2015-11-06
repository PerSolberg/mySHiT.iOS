//
//  AlertListViewController.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-27.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import UIKit

class AlertListViewController: UITableViewController {
    // MARK: Constants
    
    
    // MARK: Properties
    @IBOutlet weak var alertListTable: UITableView!
    
    // MARK: Navigation
    // Prepare for navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // print("Preparing for segue '\(segue.identifier)'")
    }
    
    
    // MARK: Constructors
    required init?( coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    override init(style: UITableViewStyle) {
        super.init(style: style)
    }
    
    
    // MARK: Callbacks
    override func viewDidLoad() {
        super.viewDidLoad()

        // Load data & check if section list is complete (if not, add missing elements)
        dispatch_async(dispatch_get_main_queue(), {
            self.alertListTable.reloadData()
        })
    }
    
    
    func refreshAlertList() {
        dispatch_async(dispatch_get_main_queue(), {
            self.alertListTable.reloadData()
        })
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: UITableViewDataSource methods
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let notifications = UIApplication.sharedApplication().scheduledLocalNotifications {
            return notifications.count
        } else {
            return 0
        }
    }
    

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let kCellIdentifier: String = "MyAlertCell"
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .MediumStyle
        dateFormatter.timeStyle = .ShortStyle
        
        //tablecell optional to see if we can reuse cell
        var cell : UITableViewCell?
        cell = tableView.dequeueReusableCellWithIdentifier(kCellIdentifier)
        
        //If we did not get a reuseable cell, then create a new one
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: kCellIdentifier)
        }

        if let notifications = UIApplication.sharedApplication().scheduledLocalNotifications {
            if indexPath.row >= notifications.count {
                cell!.textLabel!.text = "Unknown notification! Deleted?"
                cell!.detailTextLabel!.text = ""
            } else {
                let notification = notifications[indexPath.row]
                var itemId: String = ""
                /*
                if let tripId = notification.userInfo!["TripID"] as? Int {
                    itemId = itemId + (itemId == "" ? "" : ", ")  + "TripID = \(tripId)"
                }
                if let tripElementId = notification.userInfo!["TripElementID"] as? Int {
                    itemId = itemId + (itemId == "" ? "" : ", ") + "TripElementID = \(tripElementId)"
                }
                */

                let timeZoneName = notification.userInfo!["TimeZone"] as? String ?? "UTC"
                dateFormatter.timeZone = NSTimeZone(name: timeZoneName )
                var notificationTime: String = dateFormatter.stringFromDate(notification.fireDate!)
                if timeZoneName != "UTC" {
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
                    dateFormatter.timeZone = NSTimeZone(name: "UTC")
                    notificationTime += " (" + dateFormatter.stringFromDate(notification.fireDate!) + " UTC)"
                }
                cell!.textLabel!.text = notificationTime
                cell!.detailTextLabel!.text = "\(notification.alertBody!)"
            }
        }
        
        return cell!
    }
    
    
    // MARK: Actions
    
    
    // MARK: Functions
    
}

