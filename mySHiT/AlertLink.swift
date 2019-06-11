//
//  AlertLink.swift
//  mySHiT
//
//  Created by Per Solberg on 2018-01-24.
//  Copyright © 2018 &More AS. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications
import os

class AlertLink : DeepLink {
    var userInfo: UserInfo
    
    init(userInfo: UserInfo) {
        self.userInfo = userInfo
    }
    
    func handle() {
        if let tripElementId = userInfo[.tripElementId] as? Int {
            print("Notification for trip element \(tripElementId)")
            guard let rootVC = UIApplication.shared.keyWindow?.rootViewController, let navVC = rootVC as? UINavigationController else {
                os_log("Unable to get root view controller or it is not a navigation controller", type: .error)
                return
            }
            guard let (trip, tripElement) = TripList.sharedList.tripElement(byId: tripElementId) else {
                os_log("Unknown trip element", type: .info)
                return
            }
            if let vc = tripElement.tripElement.viewController(trip: trip, element: tripElement) {
                if let visVC = navVC.visibleViewController, vc.isSame(visVC) {
                    //print("Already showing correct element")
                } else {
                    navVC.pushViewController(vc, animated: true)
                }
            }
        } else if let tripId = userInfo[.tripId] as? Int {
            print("Notification for trip \(tripId)")
        } else {
            os_log("Unable to figure out what to do with alert", type: .error)
        }
    }
}
