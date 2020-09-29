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
    struct CellIdentifier {
        static let alertCell = "MyAlertCell"
    }
    struct Format {
        static let localTimeOnly = NSLocalizedString("FMT.ALERTLIST.LOCAL_TIME_ONLY", comment: "")
        static let localTimeAndUTC = NSLocalizedString("FMT.ALERTLIST.LOCAL_TIME_AND_UTC", comment: "")
    }

    //
    // MARK: Properties
    //
    @IBOutlet weak var alertListTable: UITableView!
    
    var notifications:[UNNotificationRequest]? = nil
    
    
    //
    // MARK: Navigation
    //
    
    
    //
    // MARK: Constructors
    //
    required init?( coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    override init(style: UITableView.Style) {
        super.init(style: style)
    }
    
    
    //
    // MARK: Callbacks
    //
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getNotifications()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    
    //
    // MARK: UITableViewDataSource methods
    //
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let notifications = notifications {
            return notifications.count
        } else {
            return 0
        }
    }
    

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.alertCell) ?? UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: CellIdentifier.alertCell)

        if let notifications = notifications {
            if indexPath.row >= notifications.count {
                cell.textLabel!.text = Constant.Message.alertListNotificationNotFound
                cell.detailTextLabel!.text = ""
            } else {
                let notification = notifications[indexPath.row]
                let userInfo = UserInfo(notification.content.userInfo)

                let timeZoneName = userInfo[.timeZone] as? String ?? Constant.timezoneNameUTC
                dateFormatter.timeZone = TimeZone(identifier: timeZoneName )
                if let ntfTrigger = notification.trigger as? UNCalendarNotificationTrigger, let ntfTime = ntfTrigger.nextTriggerDate() {
                    let localTime = dateFormatter.string(from: ntfTime)
                    var notificationTime: String
                    if timeZoneName != Constant.timezoneNameUTC {
                        dateFormatter.dateFormat = Constant.DateFormat.isoYearToMinuteWithSpace
                        dateFormatter.timeZone = TimeZone(identifier: Constant.timezoneNameUTC)
                        let utcTime = dateFormatter.string(from: ntfTime)
                        notificationTime = String.localizedStringWithFormat(Format.localTimeAndUTC, localTime, utcTime)
                    } else {
                        notificationTime = String.localizedStringWithFormat(Format.localTimeOnly, localTime)
                    }
                    cell.textLabel!.text = notificationTime
                } else {
                    cell.textLabel!.text = Constant.Message.alertListUnknownTime
                }
                cell.detailTextLabel!.text = notification.content.body
            }
        }
        
        return cell
    }
    
    
    //
    // MARK: Actions
    //
    func getNotifications() -> Void {
        UNUserNotificationCenter.current().getPendingNotificationRequests { (_ ntfList: [UNNotificationRequest]) in
            self.notifications = ntfList

            DispatchQueue.main.async(execute: {
                self.alertListTable.reloadData()
            })
        }
    }

}

