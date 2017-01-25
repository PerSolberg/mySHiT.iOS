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
        DispatchQueue.main.async(execute: {
            self.alertListTable.reloadData()
        })
    }
    
    
    func refreshAlertList() {
        DispatchQueue.main.async(execute: {
            self.alertListTable.reloadData()
        })
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: UITableViewDataSource methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let notifications = UIApplication.shared.scheduledLocalNotifications {
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

        if let notifications = UIApplication.shared.scheduledLocalNotifications {
            if indexPath.row >= notifications.count {
                cell!.textLabel!.text = "Unknown notification! Deleted?"  /* LOCALISE */
                cell!.detailTextLabel!.text = ""
            } else {
                let notification = notifications[indexPath.row]

                let timeZoneName = notification.userInfo!["TimeZone"] as? String ?? "UTC"
                dateFormatter.timeZone = TimeZone(identifier: timeZoneName )
                var notificationTime: String = dateFormatter.string(from: notification.fireDate!)
                if timeZoneName != "UTC" {
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
                    dateFormatter.timeZone = TimeZone(identifier: "UTC")
                    notificationTime += " (" + dateFormatter.string(from: notification.fireDate!) + " UTC)"
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

