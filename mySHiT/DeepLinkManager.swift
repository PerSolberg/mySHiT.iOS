//
//  DeepLinkManager.swift
//  mySHiT
//
//  Created by Per Solberg on 2018-01-15.
//  Copyright © 2018 &More AS. All rights reserved.
//

import Foundation
import UserNotifications

class DeepLinkManager {
    // Private properties
    private static let sharedMgr = DeepLinkManager()
    private var deepLink : DeepLink?
    
    // Prevent other classes from instantiating - DeepLinkManager is singleton!
    fileprivate init () {
    }
    
    // Public properties
    
    
    // MARK: Public functions
    static func current() -> DeepLinkManager {
        return sharedMgr
    }

    func set(linkHandler:DeepLink) {
        deepLink = linkHandler
    }

    func checkAndHandle() {
        // Check if deep link has been set; if so, handle it and reset
        guard let deepLink = deepLink else {
            return
        }
        
        deepLink.handle()
        self.deepLink = nil
    }
}
