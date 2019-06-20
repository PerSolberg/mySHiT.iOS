//
//  OSLog+mySHiT.swift
//  mySHiT
//
//  Created by Per Solberg on 2019-06-19.
//  Copyright © 2019 &More AS. All rights reserved.
//

import Foundation
import os

extension OSLog {
    static let notification = OSLog(category: "Notification")
    static let webService = OSLog(category: "WebService")
    static let network = OSLog(category: "Network")
    static let delta = OSLog(category: "Delta")
    static let general = OSLog(category: "General")

    private convenience init(category: String, bundle: Bundle = Bundle.main) {
        let identifier = bundle.infoDictionary?["CFBundleIdentifier"] as? String
        self.init(subsystem: (identifier ?? ""), category: category)
    }
}
