//
//  UserInfoDictionary.swift
//  mySHiT
//
//  Created by Per Solberg on 2019-06-05.
//  Copyright © 2019 &More AS. All rights reserved.
//

import Foundation
import os

enum UserInfoKeys:String, CaseIterable {
    case id
    case tripId
    case tripElementId
    case timeZone
    case leadTimeType
    case changeType
    case changeOperation
    case fromUserId
    case aps
    case lastSeenInfo
    case tableName
    case tripName
    
    // Firebase keys - not used by app itself
    case gcmMessageId = "gcm.message_id"
    case googleCAE = "google.c.a.e"

    // APNS keys - not used by app itself
    case locKey = "loc-key"
    case logArgs1 = "loc-args-1"
    case logArgs2 = "loc-args-2"
    case logArgs3 = "loc-args-3"
    case logArgs4 = "loc-args-4"
}

typealias UserInfo = Dictionary<UserInfoKeys,Any>

extension Dictionary where Key == UserInfoKeys, Value == Any {
    init(_ source: [AnyHashable: Any]? ) {
        self.init()
        if let source = source {
            for (k, v) in source {
                if let sk = k as? String, let rk = UserInfoKeys(rawValue: sk) {
                    self[rk] = v
                } else {
                    os_log("UserInfo source contained unknown key: %{public}s", log: OSLog.general, String(describing:k))
                }
            }
        }
    }
    
    func propertyList() -> [String:Any] {
        return reduce(into: [:]) { (result: inout [String: Any], tuple: (key: UserInfoKeys, value: Any)) in
            result[tuple.key.rawValue] = tuple.value
        }
    }

    func securePropertyList() -> [String:NSSecureCoding] {
        return reduce(into: [:]) { (result: inout [String: NSSecureCoding], tuple: (key: UserInfoKeys, value: Any)) in
            if let scValue = tuple.value as? NSSecureCoding {
                result[tuple.key.rawValue] = scValue
            } else {
                os_log("Cannot convert UserInfo element to NSSecureCoding", log: OSLog.general, type: .error)
            }
        }
    }
}
