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
            os_log("Notification link for trip element '%d'", log: OSLog.general, type: .debug, tripElementId)
            guard let navVC = UIApplication.rootNavigationController else {
                os_log("Unable to get root navigation controller", log: OSLog.general, type: .error)
                return
            }
            guard let (trip, tripElement) = TripList.sharedList.tripElement(byId: tripElementId) else {
                os_log("Unknown trip element", log: OSLog.general, type: .info)
                return
            }
            if let vc = tripElement.tripElement.viewController(trip: trip, element: tripElement) {
                if let visVC = navVC.visibleViewController, !vc.isSame(visVC) {
                    navVC.pushViewController(vc, animated: true)
                }
            }
        } else if let tripId = userInfo[.tripId] as? Int {
            os_log("Notification link for trip '%d'", log: OSLog.general, type: .debug, tripId)
        } else {
            os_log("Unable to figure out what to do with alert", log: OSLog.general, type: .error)
        }
    }
}
