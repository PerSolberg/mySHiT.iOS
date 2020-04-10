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
    

    /*Checks to see if a host is reachable*/
    open class func isNetworkAvailable(_ hostname: /*NS*/String) -> Bool {
        let hostnameNS = NSString(string: hostname)
        let reachabilityRef = SCNetworkReachabilityCreateWithName(nil, hostnameNS.utf8String!)
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(reachabilityRef!, &flags)

        let ret = (flags.rawValue & SCNetworkReachabilityFlags.reachable.rawValue) != 0
        return ret
        
    }
    
    /*Determines the type of network which is available*/
//    open class func networkConnectionType(_ hostname: NSString) -> ConnectionType {
//        let reachabilityRef = SCNetworkReachabilityCreateWithName(nil,hostname.utf8String!)
//
//        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags()
//        SCNetworkReachabilityGetFlags(reachabilityRef!, &flags)
//
//        let reachable: Bool = (flags.rawValue & SCNetworkReachabilityFlags.reachable.rawValue) != 0
//        let needsConnection: Bool = (flags.rawValue & SCNetworkReachabilityFlags.connectionRequired.rawValue) != 0
//        if reachable && !needsConnection {
//            // determine what type of connection is available
//            let isCellularConnection = (flags.rawValue & SCNetworkReachabilityFlags.isWWAN.rawValue) != 0
//            if isCellularConnection {
//                return ConnectionType.mobile3GNETWORK
//            } else {
//                return ConnectionType.wifinetwork
//            }
//        }
//        return ConnectionType.nonetwork
//    }
    
}
