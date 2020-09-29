//
//  MessageReadByInfoDictionary.swift
//  mySHiT
//
//  Created by Per Solberg on 2020-09-08.
//  Copyright © 2020 &More AS. All rights reserved.
//

import Foundation
import os

enum MessageReadByInfoKey:String, CaseIterable {
    case id
    case name
}

typealias MessageReadByInfo = Dictionary<MessageReadByInfoKey,Any>

extension Dictionary where Key == MessageReadByInfoKey, Value == Any {
    init?(_ source: [AnyHashable: Any]? ) {
        self.init()
        if let source = source {
            for (k, v) in source {
                if let sk = k as? String, let rk = MessageReadByInfoKey(rawValue: sk) {
                    self[rk] = v
                } else {
                    os_log("MessageReadByInfo source contained unknown key: %{public}s", log: OSLog.general, String(describing:k))
                }
            }
        } else {
            return nil
        }
    }
    
    func propertyList() -> [String:Any] {
        return reduce(into: [:]) { (result: inout [String: Any], tuple: (key: MessageReadByInfoKey, value: Any)) in
            result[tuple.key.rawValue] = tuple.value
        }
    }

    func securePropertyList() -> [String:NSSecureCoding] {
        return reduce(into: [:]) { (result: inout [String: NSSecureCoding], tuple: (key: MessageReadByInfoKey, value: Any)) in
            if let scValue = tuple.value as? NSSecureCoding {
                result[tuple.key.rawValue] = scValue
            } else {
                os_log("Cannot convert MessageReadByInfo element to NSSecureCoding", log: OSLog.general, type: .error)
            }
        }
    }
}
