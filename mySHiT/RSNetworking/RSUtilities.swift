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
    
    /*isHostReachable will be depreciated in the future as it does not reflect
    *What is actually being done
    */
    
    open class func isHostnameReachable(_ hostname: NSString) -> Bool {
        return isNetworkAvailable(hostname);
    }
    /*Checks to see if a host is reachable*/
    open class func isNetworkAvailable(_ hostname: NSString) -> Bool {
        
        let reachabilityRef = SCNetworkReachabilityCreateWithName(nil,hostname.utf8String!)
        

        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(reachabilityRef!, &flags)

        let ret = (flags.rawValue & SCNetworkReachabilityFlags.reachable.rawValue) != 0
        return ret
        
    }
    
    /*Determines the type of network which is available*/
    open class func networkConnectionType(_ hostname: NSString) -> ConnectionType {
        
        let reachabilityRef = SCNetworkReachabilityCreateWithName(nil,hostname.utf8String!)
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(reachabilityRef!, &flags)
        
        let reachable: Bool = (flags.rawValue & SCNetworkReachabilityFlags.reachable.rawValue) != 0
        let needsConnection: Bool = (flags.rawValue & SCNetworkReachabilityFlags.connectionRequired.rawValue) != 0
        if reachable && !needsConnection {
            // determine what type of connection is available
            let isCellularConnection = (flags.rawValue & SCNetworkReachabilityFlags.isWWAN.rawValue) != 0
            if isCellularConnection {
                return ConnectionType.mobile3GNETWORK // cellular connection available
            } else {
                return ConnectionType.wifinetwork // wifi connection available
            }
        }
        return ConnectionType.nonetwork // no connection at all
    }
    
    
}
