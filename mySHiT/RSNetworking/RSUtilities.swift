//
//  RSUtilities.swift
//  RSNetworkSample
//
//  Created by Jon Hoffman on 7/26/14.
//  Copyright (c) 2014 Jon Hoffman. All rights reserved.
//

import UIKit
import SystemConfiguration

open class RSUtilities: NSObject {
    
    public enum ConnectionType {
        case nonetwork
        case mobile3GNETWORK
        case wifinetwork
    }
    

    // Check to see if a host is reachable
    open class func isNetworkAvailable(_ hostname: String) -> Bool {
        let hostnameNS = NSString(string: hostname)
        let reachabilityRef = SCNetworkReachabilityCreateWithName(nil, hostnameNS.utf8String!)
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(reachabilityRef!, &flags)

        let ret = (flags.rawValue & SCNetworkReachabilityFlags.reachable.rawValue) != 0
        return ret
        
    }
    
}
