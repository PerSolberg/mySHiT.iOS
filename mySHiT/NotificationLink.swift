//
//  NotificationLink.swift
//  mySHiT
//
//  Created by Per Solberg on 2018-01-16.
//  Copyright © 2018 &More AS. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications
import os

class NotificationLink : DeepLink {
    var userInfo: UserInfo

    init(userInfo: UserInfo) {
        self.userInfo = userInfo
    }
    
    func handle() {
        guard let notification = RemoteNotification(from: userInfo) else {
            os_log("Invalid notification in deep link", log: OSLog.notification, type: .error)
            return
        }
        
        os_log("Handling notification link for change type '%{public}s'", log: OSLog.general, type: .debug, notification.changeType)
        
        switch (notification.changeType, notification.changeOperation) {
        case (Constant.changeType.chatMessage, Constant.changeOperation.insert):
            ChatViewController.pushDeepLinked(for: notification.tripId)
            
        case (Constant.changeType.chatMessage, Constant.changeOperation.update):
            os_log("Ignoring chat update (read notification)", log: OSLog.general, type: .debug)
            
        case (Constant.changeType.chatMessage, _):
            os_log("Unknown change type/operation: (%{public}s, %{public}s)", log: OSLog.notification, type: .error, notification.changeType, notification.changeOperation)
            
        case (_, Constant.changeOperation.insert):
            fallthrough
        case (_, Constant.changeOperation.update):
            TripDetailsViewController.pushDeepLinked(for: notification.tripId)
            
        default:
            // Don't do anything
            break
        }
    }
}
