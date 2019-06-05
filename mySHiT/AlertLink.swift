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

class AlertLink : DeepLink {
    var userInfo: [AnyHashable : Any]
    
    init(userInfo: [AnyHashable : Any]) {
        self.userInfo = userInfo
    }
    
    func handle() {
        if let tripElementId = userInfo[Constant.ntfUserInfo.tripElementId] as? Int {
            print("Notification for trip element \(tripElementId)")
            guard let rootVC = UIApplication.shared.keyWindow?.rootViewController, let navVC = rootVC as? UINavigationController else {
                print("Unable to get root view controller or it is not a navigation controller")
                return
            }
            guard let (trip, tripElement) = TripList.sharedList.tripElement(byId: tripElementId) else {
                print("Unknown trip element")
                return
            }
            if let vc = tripElement.tripElement.viewController(trip: trip, element: tripElement) {
                if let visVC = navVC.visibleViewController, vc.isSame(visVC) {
                    print("Already showing correct element")
                } else {
                    print("Pushing element view controller onto stack")
                    navVC.pushViewController(vc, animated: true)
                }
            }
        } else if let tripId = userInfo[Constant.ntfUserInfo.tripId] as? Int {
            print("Notification for trip \(tripId)")
        } else {
            print("Unable to figure out what to do with alert")
        }
    }
}
