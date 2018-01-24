//
//  AlertListViewController.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-27.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import UIKit
import UserNotifications

class AlertListViewController: UITableViewController {
    // MARK: Constants
    
    
    // MARK: Properties
    @IBOutlet weak var alertListTable: UITableView!
    
    var notifications:[UNNotificationRequest]? = nil
    
    // MARK: Navigation
    // Prepare for navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
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
        getNotifications()
        //DispatchQueue.main.async(execute: {
        //    self.alertListTable.reloadData()
        //})
    }
    
    
    func refreshAlertList() {
        getNotifications()
        //DispatchQueue.main.async(execute: {
        //    self.alertListTable.reloadData()
        //})
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: UITableViewDataSource methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let notifications = notifications /*UIApplication.shared.scheduledLocalNotifications*/ {
            return notifications.count
        } else {
            return 0
        }
    }
    

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let kCellIdentifier: String = "MyAlertCell"
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        //tablecell optional to see if we can reuse cell
        var cell : UITableViewCell?
        cell = tableView.dequeueReusableCell(withIdentifier: kCellIdentifier)
        
        //If we did not get a reuseable cell, then create a new one
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: kCellIdentifier)
        }

        if let notifications = notifications /*UIApplication.shared.scheduledLocalNotifications*/ {
            if indexPath.row >= notifications.count {
                cell!.textLabel!.text = "Unknown notification! Deleted?"  /* LOCALISE */
                cell!.detailTextLabel!.text = ""
            } else {
                let notification = notifications[indexPath.row]

                let timeZoneName = notification.content.userInfo["TimeZone"] as? String ?? "UTC"
                dateFormatter.timeZone = TimeZone(identifier: timeZoneName )
                if let ntfTrigger = notification.trigger as? UNCalendarNotificationTrigger, let ntfTime = ntfTrigger.nextTriggerDate() {
                    var notificationTime: String = dateFormatter.string(from: ntfTime)
                    if timeZoneName != "UTC" {
                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
                        dateFormatter.timeZone = TimeZone(identifier: "UTC")
                        notificationTime += " (" + dateFormatter.string(from: ntfTime) + " UTC)"
                    }
                    cell!.textLabel!.text = notificationTime
                } else {
                    cell!.textLabel!.text = "Unknown"
                }
                cell!.detailTextLabel!.text = "\(notification.content.body)"
            }
        }
        
        return cell!
    }
    
    
    // MARK: Actions
    func getNotifications() -> Void {
        UNUserNotificationCenter.current().getPendingNotificationRequests { (_ ntfList: [UNNotificationRequest]) in
            self.notifications = ntfList

            DispatchQueue.main.async(execute: {
                self.alertListTable.reloadData()
            })
        }
    }
    
    // MARK: Functions
    
}

