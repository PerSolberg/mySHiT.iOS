//
//  ServerTimestamp.swift
//  mySHiT
//
//  Created by Per Solberg on 2020-03-17.
//  Copyright © 2020 &More AS. All rights reserved.
//

import Foundation
import os

class ServerTimestamp:NSObject, NSCoding, Comparable {
    var formattedTS:String!
    var epochSeconds:Int!
    var epochMicroSec:Int!

    struct PropertyKey {
        static let formattedKey = "formatted"
        static let secondsKey = "sec"
        static let microSecondsKey = "microsec"
    }

    required init?(fromDictionary elementData: NSDictionary!) {
        guard let inFormatted = elementData[Constant.JSON.srvTSFormatted] as? String, let epoch = elementData[Constant.JSON.srvTSEpoch] as? NSDictionary, let inSec = epoch[Constant.JSON.srvTSEpochSec] as? Int, let inMicro = epoch[Constant.JSON.srvTSEpochMicrosec] as? Int else {
            os_log("Unable to parse server timestamp: %{public}s", log: OSLog.general, type: .error, String(describing: elementData))
            return nil
        }
        formattedTS = inFormatted
        epochSeconds = inSec
        epochMicroSec = inMicro
    }


    //
    // MARK: Initialisers
    //
    required init?(coder aDecoder: NSCoder) {
        // NB: use conditional cast (as?) for any optional properties
        formattedTS = aDecoder.decodeObject(forKey: PropertyKey.formattedKey) as? String
        epochSeconds = aDecoder.decodeObject(forKey: PropertyKey.secondsKey) as? Int
        epochMicroSec = aDecoder.decodeObject(forKey: PropertyKey.microSecondsKey) as? Int
    }
    
    
    //
    // MARK: NSCoding
    //
    func encode(with aCoder: NSCoder) {
        aCoder.encode(formattedTS, forKey: PropertyKey.formattedKey)
        aCoder.encode(epochSeconds, forKey: PropertyKey.secondsKey)
        aCoder.encode(epochMicroSec, forKey: PropertyKey.microSecondsKey)
    }
    
    
    //
    // MARK: Comparators
    //
    static func == (lhs:ServerTimestamp, rhs:ServerTimestamp) -> Bool {
        return lhs.epochSeconds == rhs.epochSeconds && lhs.epochMicroSec == rhs.epochMicroSec
    }

    
    static func < (lhs:ServerTimestamp, rhs:ServerTimestamp) -> Bool {
        return lhs.epochSeconds < rhs.epochSeconds || ( lhs.epochSeconds == rhs.epochSeconds && lhs.epochMicroSec < rhs.epochMicroSec)
    }
    
    
    static func <= (lhs:ServerTimestamp, rhs:ServerTimestamp) -> Bool {
        return lhs.epochSeconds < rhs.epochSeconds || ( lhs.epochSeconds == rhs.epochSeconds && lhs.epochMicroSec <= rhs.epochMicroSec)
    }
    
    
    static func > (lhs:ServerTimestamp, rhs:ServerTimestamp) -> Bool {
        return lhs.epochSeconds > rhs.epochSeconds || ( lhs.epochSeconds == rhs.epochSeconds && lhs.epochMicroSec > rhs.epochMicroSec)
    }

    
    static func >= (lhs:ServerTimestamp, rhs:ServerTimestamp) -> Bool {
        return lhs.epochSeconds > rhs.epochSeconds || ( lhs.epochSeconds == rhs.epochSeconds && lhs.epochMicroSec >= rhs.epochMicroSec)
    }
}
