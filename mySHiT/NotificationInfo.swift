//
//  NotificationInfo.swift
//  mySHiT
//
//  Created by Per Solberg on 2017-02-27.
//  Copyright © 2017 &More AS. All rights reserved.
//

import Foundation
//import UIKit

class NotificationInfo: NSObject, NSCoding {
    var baseDate: Date!
    var notificationDate: Date!
    var leadTime: Int!
    
    struct PropertyKey {
        static let baseDateKey = "baseDate"
        static let notificationDateKey = "notificationDate"
        static let leadTimeKey = "leadTime"
    }
    
    
    //
    // MARK: NSCoding
    //
    func encode(with aCoder: NSCoder) {
        aCoder.encode(baseDate, forKey: PropertyKey.baseDateKey)
        aCoder.encode(notificationDate, forKey: PropertyKey.notificationDateKey)
        aCoder.encode(leadTime, forKey: PropertyKey.leadTimeKey)
    }
    
    
    //
    // MARK: Initialisers
    //
    required init?(coder aDecoder: NSCoder) {
        // NB: use conditional cast (as?) for any optional properties
        baseDate  = aDecoder.decodeObject(forKey: PropertyKey.baseDateKey) as? Date
        notificationDate = aDecoder.decodeObject(forKey: PropertyKey.notificationDateKey) as? Date
        leadTime = aDecoder.decodeObject(forKey: PropertyKey.leadTimeKey) as? Int ?? aDecoder.decodeInteger(forKey: PropertyKey.leadTimeKey)
    }
    
    
    init?(baseDate: Date!, leadTime: Int!) {
        // Initialize stored properties.
        super.init()

        let now = Date()

        self.baseDate = baseDate
        self.notificationDate = baseDate.addMinutes(-leadTime)
        if (self.notificationDate < now) {
            notificationDate = now.addSeconds(5)
        }
        self.leadTime = leadTime
    }

    
    //
    // MARK: Methods
    //
    func needsRefresh(baseDate: Date!, notificationDate: Date!, leadTime: Int!) -> Bool {
        let now = Date()
        if (self.notificationDate > now) {
            // Not notfied yet, we may just refresh
            return true
        } else if (baseDate.addMinutes(-leadTime) > now) {
            // New notification is in the future, probably because event time or lead time changed - refresh
            return true
        } else if (self.baseDate != baseDate) {
            // Event date changed, notify user about change
            return true
        }

        return false;
    }

    
    func needsRefresh(newNotification: NotificationInfo) -> Bool {
        return needsRefresh(baseDate: newNotification.baseDate, notificationDate: newNotification.notificationDate, leadTime: newNotification.leadTime)
    }
    
    
    func combine(with: NotificationInfo) {
        self.notificationDate = with.notificationDate
    }
}
