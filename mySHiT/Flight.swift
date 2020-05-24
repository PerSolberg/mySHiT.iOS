//
//  Flight.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-20.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation
import UIKit

class Flight: ScheduledTransport {
    static let RefType_ETicketNo  = "ETKT"
    static let RefType_Amadeus    = "Amadeus"
    
    //
    // MARK: Properties
    //
    var airlineCode: String?  { willSet { checkChange(airlineCode, newValue) } }
    
    struct PropertyKey {
        static let airlineCodeKey = "airlineCode"
    }
    
    override var title: String? {
        let code = airlineCode ?? "XX"
        let route = routeNo ?? "***"
        let deptLocation = departureLocation ?? "<Departure>"
        let arrLocation = arrivalLocation ?? "<Arrival>"
        return code + " " + route + ": " + deptLocation + " - " + arrLocation
    }
    override var detailInfo: String? {
        if let references = references {
            var refList: String = ""
            for ref in references {
                if ref[TripElement.RefTag_Type] != Flight.RefType_ETicketNo {
                    refList = refList + (refList == "" ? "" : ", ") + ref[TripElement.RefTag_Type]! + ": " + ref[TripElement.RefTag_RefNo]!
                }
            }
            return refList
        }
        return nil
    }
    var flightNo: String? {
        let code = airlineCode ?? "XX"
        let route = routeNo ?? "***"
        return code + " " + route
    }

    
    //
    // MARK: NSCoding
    //
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(airlineCode, forKey: PropertyKey.airlineCodeKey)
    }
    
    
    //
    // MARK: Initialisers
    //
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        airlineCode = aDecoder.decodeObject(forKey: PropertyKey.airlineCodeKey) as? String
        setNotification()
    }
    
    
    required init?(fromDictionary elementData: NSDictionary!) {
        super.init(fromDictionary: elementData)
        airlineCode = elementData[Constant.JSON.airlineCompanyCode] as? String
//        setNotification()
    }
    
    
    //
    // MARK: Methods
    //
    override func update(fromDictionary elementData: NSDictionary!) -> Bool {
        changed = super.update(fromDictionary: elementData)

        airlineCode = elementData[Constant.JSON.airlineCompanyCode] as? String
                
        return changed
    }

    
    override func viewController(trip:AnnotatedTrip, element:AnnotatedTripElement) -> UIViewController? {
        guard element.tripElement == self else {
            fatalError("Inconsistent trip element and annotated trip element")
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "FlightDetailsViewController")
        if let fvc = vc as? FlightDetailsViewController {
            fvc.tripElement = element
            fvc.trip = trip
            return fvc
        }
        return nil
    }
}

