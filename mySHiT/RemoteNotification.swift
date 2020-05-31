//
//  RemoteNotification.swift
//  mySHiT
//
//  Created by Per Solberg on 2020-05-25.
//  Copyright © 2020 &More AS. All rights reserved.
//

import Foundation
import os
import UIKit

class RemoteNotification {
    let changeType:String
    let changeOperation:String
    let tripId:Int
    let trip:Trip?
    let fromUserId:Int?
    let lastSeenByUsers:NSDictionary?
    let lastSeenVersion:Int?

    init?(from userInfo:UserInfo) {
        guard let changeType = userInfo[.changeType] as? String, let changeOperation = userInfo[.changeOperation] as? String else {
            os_log("Invalid remote notification, no changeType or changeOperation element", log: OSLog.notification, type: .error)
            return nil
        }
        self.changeType = changeType
        self.changeOperation = changeOperation
        guard let ntfTripId = userInfo[.tripId] as? String, let tripId = Int(ntfTripId) else {
            os_log("Invalid remote notification, no trip ID", log: OSLog.notification, type: .error)
            return nil
        }
        self.tripId = tripId

        switch (changeType, changeOperation) {
        case (Constant.changeType.chatMessage, Constant.changeOperation.insert):
            guard let ntfFromUserId = userInfo[.fromUserId] as? String, let fromUserId = Int(ntfFromUserId) else {
                os_log("Invalid remote notification, chat message without aps data or sending user ID", log: OSLog.notification, type: .error)
                return nil
            }
            self.fromUserId = fromUserId
            self.lastSeenByUsers = nil
            self.lastSeenVersion = nil

        case (Constant.changeType.chatMessage, Constant.changeOperation.update):
            self.fromUserId = nil

            guard let strLastSeenInfo = userInfo[.lastSeenInfo] as? String else {
                os_log("Invalid remote notification, no last seen info: %{public}s", log: OSLog.notification, type: .error, String(describing: userInfo))
                return nil
            }
            var jsonLastSeenInfo:Any?
            do {
                jsonLastSeenInfo = try JSONSerialization.jsonObject(with: strLastSeenInfo.data(using: .utf8)!, options: JSONSerialization.ReadingOptions.allowFragments)
            } catch {
                os_log("Invalid remote notification, invalid JSON: %{public}s", log: OSLog.notification, type: .error, strLastSeenInfo)
                return nil
            }
            guard let lastSeenInfo = jsonLastSeenInfo as? NSDictionary, let lastSeenByUsers = lastSeenInfo[ Constant.JSON.messageLastSeenByOthers] as? NSDictionary, let lastSeenVersion = lastSeenInfo[Constant.JSON.lastSeenVersion] as? Int else {
                os_log("Invalid remote notification, invalid last seen info: %{public}s", log: OSLog.notification, type: .error, String(describing: jsonLastSeenInfo))
                return nil
            }
            self.lastSeenByUsers = lastSeenByUsers
            self.lastSeenVersion = lastSeenVersion
            
        case (Constant.changeType.chatMessage, _):
            os_log("Unknown change type/operation: %{public}s, %{public}s", log: OSLog.notification, type: .error, changeType, changeOperation)
            return nil

        default:
            self.fromUserId = nil
            self.lastSeenByUsers = nil
            self.lastSeenVersion = nil
        }

        if let trip = TripList.sharedList.trip(byId: tripId) {
            self.trip = trip.trip
        } else {
            self.trip = nil
        }
    }

    
    convenience init?(from userInfo:[AnyHashable: Any]?) {
        self.init(from: UserInfo(userInfo))
    }
    
}

