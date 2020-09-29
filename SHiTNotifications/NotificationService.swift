//
//  NotificationService.swift
//  SHiTNotifications
//
//  Created by Per Solberg on 2020-07-22.
//  Copyright © 2020 &More AS. All rights reserved.
//

import os
import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        let userInfo = UserInfo(request.content.userInfo)
        guard let startTimestampString = userInfo[.startTimestamp] as? String, let bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent) else {
            contentHandler(request.content)
            return
        }
        
        guard let defaults = UserDefaults(suiteName: Constant.Group.defaults) else {
            os_log("Unable to access defaults", log: OSLog.notification, type: .error)
            contentHandler(request.content)
            return
        }

        guard let muteInterval = defaults.string(forKey: Constant.Settings.notificationMute) else {
            os_log("Could not find setting %{public}s", log: OSLog.notification, type: .error, Constant.Settings.notificationMute)
            contentHandler(request.content)
            return
        }

        // Modify the notification content
        var mute = false

        switch (muteInterval) {
        case Constant.Settings.MuteInterval.always:
            mute = true
            
        case Constant.Settings.MuteInterval.never:
            mute = false

        default:
            var muteTime:Date! = Date()
            let intervalUnit = String(muteInterval.suffix(1))
            let intervalValueStr = muteInterval.trimSuffix(intervalUnit)
            if let intervalValue = Int(intervalValueStr) {
                switch (intervalUnit) {
                case Constant.Settings.MuteInterval.day:
                    muteTime = Calendar.current.date(byAdding: .day, value: intervalValue, to: muteTime)
                case Constant.Settings.MuteInterval.week:
                    muteTime = Calendar.current.date(byAdding: .day, value: 7 * intervalValue, to: muteTime)
                case Constant.Settings.MuteInterval.month:
                    muteTime = Calendar.current.date(byAdding: .month, value: intervalValue, to: muteTime)
                default:
                    os_log("Unknown unit in interval %{public}s", log: OSLog.notification, type: .error, muteInterval)
                    muteTime = nil
                    mute = false
                }
                if let muteTime = muteTime {
                    os_log("Mute time %{public}s", log: OSLog.notification, type: .debug, String(describing: muteTime))

                    var timezoneName:String? = nil
                    if let startTimezoneInfo = userInfo[.startTimezone] as? String, let startTimezoneData = startTimezoneInfo.data(using: .utf8), let jsonTimezoneInfo  = try? JSONSerialization.jsonObject(with: startTimezoneData, options: []) as? [String:String] {
                        timezoneName = jsonTimezoneInfo[Constant.deviceType] ?? jsonTimezoneInfo[Constant.deviceTypeDefault]
                    }
                    
                    if let startTimestamp = ServerDate.convertServerDate(startTimestampString, timeZoneName: timezoneName) {
                        mute = startTimestamp > muteTime
                        os_log("Notification at %{public}s (%{public}s %{public}s)", log: OSLog.notification, type: .debug, String(describing: startTimestamp), startTimestampString, timezoneName ?? "<None>")
                    }
                }
            } else {
                os_log("Unable to parse interval %{public}s", log: OSLog.notification, type: .error, muteInterval)
            }
        }
        
        if mute {
            os_log("Muting notification", log: OSLog.notification, type: .debug)
            bestAttemptContent.sound = nil
        } else if bestAttemptContent.sound == nil {
            os_log("Unmuting notification", log: OSLog.notification, type: .debug)
            bestAttemptContent.sound = UNNotificationSound.default
        }
        contentHandler(bestAttemptContent)
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Deliver "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
