//
//  ScheduledTransport.swift
//  mySHiT
//
//  Created by Per Solberg on 2017-03-01.
//  Copyright © 2017 &More AS. All rights reserved.
//

import Foundation
import UIKit

class ScheduledTransport: GenericTransport {
    // MARK: Properties
    override var title: String? {
        return (companyName ?? "XX") + " " + (routeNo ?? "***") + ": " + (departureLocation ?? "<Departure>") + " - " + (arrivalLocation ?? "<Arrival>")
    }
    override var startInfo: String? {
        let timeInfo = startTime(dateStyle: .none, timeStyle: .short)
        let airportName = departureStop ?? "<Departure Station>"
        let terminalInfo = (departureTerminalCode != nil && departureTerminalCode != "" ? " [" + departureTerminalCode! + "]" : "")
        return (timeInfo != nil ? timeInfo! + ": " : "") + airportName + terminalInfo
    }
    override var endInfo: String? {
        let timeInfo = endTime(dateStyle: .none, timeStyle: .short)
        let airportName = arrivalStop ?? "<Arrival Station>"
        let terminalInfo = (arrivalTerminalCode != nil && arrivalTerminalCode != "" ? " [" + arrivalTerminalCode! + "]" : "")
        return (timeInfo != nil ? timeInfo! + ": " : "") + airportName + terminalInfo
    }
    override var detailInfo: String? {
        if let references = references {
            var refList: String = ""
            for ref in references {
                refList = refList + (refList == "" ? "" : ", ") + ref[TripElement.RefTag_Type]! + ": " + ref[TripElement.RefTag_RefNo]!
            }
            return refList
        }
        return nil
    }
    
    // MARK: NSCoding
    
    // MARK: Initialisers
    
    // MARK: Methods
    override func setNotification() {
        // First delete any existing notifications for this trip element (either one or two)
        cancelNotifications()

        // Set notification (if we have a start date)
        //if let _ = startTime {
            if (tense ?? .past) == .future {
                let defaults = UserDefaults.standard
                let departureLeadtime = Int(defaults.float(forKey: Constant.Settings.deptLeadTime))
                let legLeadtime = Int(defaults.float(forKey: Constant.Settings.legLeadTime))

                let genericAlertMessage = NSLocalizedString(Constant.msg.transportAlertMessage, comment: "Some dummy comment")

                if departureLeadtime > 0 && legNo == 1 {
                    setNotification(notificationType: Constant.Settings.deptLeadTime, leadTime: departureLeadtime, alertMessage: genericAlertMessage, userInfo: nil)
                }
                if legLeadtime > 0 {
                    setNotification(notificationType: Constant.Settings.legLeadTime, leadTime: legLeadtime, alertMessage: genericAlertMessage, userInfo: nil)
                }
                /*
                let defaults = UserDefaults.standard
                let departureLeadtime = Int(defaults.float(forKey: Constant.Settings.deptLeadTime))
                let legLeadtime = Int(defaults.float(forKey: Constant.Settings.legLeadTime))
                let startTimeText = startTime(dateStyle: .none, timeStyle: .short)
                //let now = Date()
                let dcf = DateComponentsFormatter()
                let genericAlertMessage = NSLocalizedString(Constant.msg.transportAlertMessage, comment: "Some dummy comment")
                
                dcf.unitsStyle = .short
                dcf.zeroFormattingBehavior = .dropAll
                
                var userInfo: [String:NSObject] = [Constant.notificationUserInfo.tripElementId: id as NSObject]
                if let departureTimeZone = departureTimeZone {
                    userInfo[Constant.notificationUserInfo.timeZone] = departureTimeZone as NSObject?
                }
                
                if departureLeadtime > 0 && legNo == 1 {
                    /*
                     var alertTime = tripStart.addMinutes( -departureLeadtime )
                     // If we're already past the warning time, set a notification for right now instead
                     if alertTime.isLessThanDate(now) {
                     // Add 5 seconds to ensure alert time doesn't lapse while still processing
                     alertTime = now.addSeconds(5)
                     }
                     */
                    let oldInfo = notifications[Constant.Settings.deptLeadTime]
                    let newInfo = NotificationInfo(baseDate: tripStart, leadTime: departureLeadtime)
                    
                    if (oldInfo == nil || oldInfo!.needsRefresh(newNotification: newInfo!)) {
                        print("Setting departure notification for trip element \(id) at \(newInfo?.notificationDate)")
                        let notification = UILocalNotification()
                        
                        userInfo[Constant.notificationUserInfo.leadTimeType] = Constant.Settings.deptLeadTime as NSObject?
                        
                        let actualLeadTime = tripStart.timeIntervalSince((newInfo?.notificationDate)!) //alertTime)
                        let leadTimeText = dcf.string(from: actualLeadTime)
                        //notification.alertBody = "\(title!) departs in \(leadTimeText!), at \(startTimeText!)"
                        notification.alertBody = String.localizedStringWithFormat(genericAlertMessage, title!, leadTimeText!, startTimeText!) as String
                        //notification.alertAction = "open" // text that is displayed after "slide to..." on the lock screen - defaults to "slide to view"
                        notification.fireDate = newInfo?.notificationDate // alertTime
                        notification.soundName = UILocalNotificationDefaultSoundName
                        notification.userInfo = userInfo
                        notification.category = "SHiT"
                        UIApplication.shared.scheduleLocalNotification(notification)
                        
                        notifications[Constant.Settings.deptLeadTime] = newInfo
                    } else {
                        print("Not refreshing departure notification for trip element \(id), already triggered")
                    }
                }
                setLegNotification: if legLeadtime > 0 {
                    /*
                     var alertTime = tripStart.addMinutes( -legLeadtime )
                     // If we're already past the warning time, set a notification for right now instead
                     // unless it's the first leg, in which case we already have one from above
                     if alertTime.isLessThanDate(now) {
                     if (legNo ?? 1) == 1 {
                     break setLegNotification
                     } else {
                     // Add 5 seconds to ensure alert time doesn't lapse while still processing
                     alertTime = now.addSeconds(5)
                     }
                     }
                     */
                    let oldInfo = notifications[Constant.Settings.legLeadTime]
                    let newInfo = NotificationInfo(baseDate: tripStart, leadTime: departureLeadtime)
                    
                    if (oldInfo == nil || oldInfo!.needsRefresh(newNotification: newInfo!)) {
                        print("Setting leg notification for trip element \(id) at \(newInfo?.notificationDate)")
                        
                        let notification = UILocalNotification()
                        
                        userInfo[Constant.notificationUserInfo.leadTimeType] = Constant.Settings.legLeadTime as NSObject?
                        
                        let actualLeadTime = tripStart.timeIntervalSince((newInfo?.notificationDate)!) // alertTime)
                        let leadTimeText = dcf.string(from: actualLeadTime)
                        
                        notification.alertBody = String.localizedStringWithFormat(genericAlertMessage, title!, leadTimeText!, startTimeText!) as String
                        //"\(title!) departs in \(leadTimeText!), at \(startTimeText!)"
                        //notification.alertAction = "open" // text that is displayed after "slide to..." on the lock screen - defaults to "slide to view"
                        notification.fireDate = newInfo?.notificationDate // alertTime
                        notification.soundName = UILocalNotificationDefaultSoundName
                        notification.userInfo = userInfo
                        notification.category = "SHiT"
                        UIApplication.shared.scheduleLocalNotification(notification)
                        
                        notifications[Constant.Settings.legLeadTime] = newInfo
                    } else {
                        print("Not refreshing leg notification for trip element \(id), already triggered")
                    }
                }
                */
            } else {
                //print("Not setting notifications for past trip element \(id)")
            }
        //}
    }
}
