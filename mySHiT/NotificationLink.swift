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
            guard let changeType = userInfo[.changeType] as? String else {
                fatalError("Invalid remote notification, no changeType element")
            }
            guard let changeOperation = userInfo[.changeOperation] as? String else {
                fatalError("Invalid remote notification, no changeOperation element")
            }
            guard let ntfTripId = userInfo[.tripId] as? String, let tripId = Int(ntfTripId) else {
                fatalError("TripId missing or invalid")
            }
            
            os_log("Recevied notification for change type '%{public}s'", log: OSLog.general, type: .debug, changeType)
            
            switch (changeType, changeOperation) {
            case (Constant.changeType.chatMessage, Constant.changeOperation.insert):
                guard let rootVC = UIApplication.shared.keyWindow?.rootViewController, let navVC = rootVC as? UINavigationController else {
                    os_log("Unable to get root view controller or it is not a navigation controller", log: OSLog.general, type: .error)
                    return
                }
                if let chatVC = navVC.visibleViewController as? ChatViewController, let trip = chatVC.trip?.trip, trip.id == tripId {
                    os_log("Message for current chat - No need to do anything, already handled by AppDelegate", log: OSLog.general, type: .debug)
                } else {
                    // If current view controller was deep linked, pop it from the navigation stack
                    if let dlVC = navVC.visibleViewController as? DeepLinkableViewController, dlVC.wasDeepLinked {
                        navVC.popViewController(animated: true)
                    }

                    // Push correct view controller onto navigation stack
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let viewController = storyboard.instantiateViewController(withIdentifier: "ChatViewController")
                    if let chatViewController = viewController as? ChatViewController, let annotatedTrip = TripList.sharedList.trip(byId: tripId) {
                        chatViewController.wasDeepLinked = true
                        chatViewController.trip = annotatedTrip
                        navVC.pushViewController(chatViewController, animated: true)
                    } else {
                        os_log("Unable to get chat view controller or trip", log: OSLog.general, type: .error)
                    }
                }
                
            case (Constant.changeType.chatMessage, Constant.changeOperation.update):
                os_log("Ignoring chat update (read notification)", log: OSLog.general, type: .debug)
                
            case (Constant.changeType.chatMessage, _):
                fatalError("Unknown change type/operation: (\(changeType), \(changeOperation))")
                
            case (_, Constant.changeOperation.insert):
                fallthrough
                
            case (_, Constant.changeOperation.update):
                guard let rootVC = UIApplication.shared.keyWindow?.rootViewController, let navVC = rootVC as? UINavigationController else {
                    os_log("Unable to get root view controller or it is not a navigation controller", log: OSLog.general, type: .error)
                    return
                }

                if let tripVC = navVC.visibleViewController as? TripDetailsViewController, let trip = tripVC.trip?.trip, trip.id == tripId {
                    os_log("Update for current trip - No need to do anything, already handled by AppDelegate", log: OSLog.general, type: .debug)
                } else {
                    // If current view controller was deep linked, pop it from the navigation stack
                    if let dlVC = navVC.visibleViewController as? DeepLinkableViewController, dlVC.wasDeepLinked {
                        navVC.popViewController(animated: true)
                    }

                    // Push correct view controller onto navigation stack
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let viewController = storyboard.instantiateViewController(withIdentifier: "TripDetailsViewController")
                    if let tripViewController = viewController as? TripDetailsViewController, let annotatedTrip = TripList.sharedList.trip(byId: tripId) {
                        tripViewController.wasDeepLinked = true
                        tripViewController.trip = annotatedTrip
                        tripViewController.tripCode = annotatedTrip.trip.code
                        navVC.pushViewController(tripViewController, animated: true)
                    } else {
                        os_log("Unable to get trip details view controller or trip", log: OSLog.general, type: .error)
                    }                    
                }
                
            default:
                // Don't do anything
                break
            }
    }
}
