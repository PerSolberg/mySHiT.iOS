//
//  Flight.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-20.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation

class Flight: GenericTransport {
    // MARK: Properties
    var airlineCode: String?
    
    struct PropertyKey {
        static let airlineCodeKey = "airlineCode"
    }
    

    override var title: String? {
        return (airlineCode ?? "XX") + " " + (routeNo ?? "***") + ": " + (departureLocation ?? "<Departure>") + " - " + (arrivalLocation ?? "<Arrival>")
    }
    override var startInfo: String? {
        let timeInfo = startTime(dateStyle: .NoStyle, timeStyle: .ShortStyle)
        let airportName = departureStop ?? "<Departure Airport>"
        let terminalInfo = (departureTerminalCode != nil && departureTerminalCode != "" ? " [" + departureTerminalCode! + "]" : "")
        return (timeInfo != nil ? timeInfo! + ": " : "") + airportName + terminalInfo
    }
    override var endInfo: String? {
        let timeInfo = endTime(dateStyle: .NoStyle, timeStyle: .ShortStyle)
        let airportName = arrivalStop ?? "<Arrival Airport>"
        let terminalInfo = (arrivalTerminalCode != nil && arrivalTerminalCode != "" ? " [" + arrivalTerminalCode! + "]" : "")
        return (timeInfo != nil ? timeInfo! + ": " : "") + airportName + terminalInfo
    }
    override var detailInfo: String? {
        if let references = references {
            var refList: String = ""
            for ref in references {
                if ref["type"] != "ETKT" {
                    refList = refList + (refList == "" ? "" : ", ") + ref["type"]! + ": " + ref["refNo"]!
                }
            }
            return refList
        }
        return nil
    }

    // MARK: NSCoding
    override func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        aCoder.encodeObject(airlineCode, forKey: PropertyKey.airlineCodeKey)
    }
    
    
    // MARK: Initialisers
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // NB: use conditional cast (as?) for any optional properties
        airlineCode = aDecoder.decodeObjectForKey(PropertyKey.airlineCodeKey) as? String
        setNotification()
    }
    
    
    required init?(fromDictionary elementData: NSDictionary!) {
        super.init(fromDictionary: elementData)
        airlineCode = elementData["companyCode"] as? String
        setNotification()
    }
}