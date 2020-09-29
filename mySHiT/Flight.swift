//
//  Flight.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-20.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation
import UIKit
import os

class Flight: ScheduledTransport {
    static let RefType_ETicketNo  = "ETKT"
    static let RefType_Amadeus    = "Amadeus"
    
    struct Format {
        static let DesignatorCodeOnly = NSLocalizedString("FMT.TRANSPORT.FLIGHT_DESIGNATOR.CODE", comment:"")
        static let DesignatorNumberOnly = NSLocalizedString("FMT.TRANSPORT.FLIGHT_DESIGNATOR.NUMBER", comment:"")
        static let DesignatorCodeAndNumber = NSLocalizedString("FMT.TRANSPORT.FLIGHT_DESIGNATOR.CODE_AND_NUMBER", comment:"")
    }

    //
    // MARK: Properties
    //
    var airlineCode: String?  { willSet { checkChange(airlineCode, newValue) } }
    
    struct PropertyKey {
        static let airlineCodeKey = "airlineCode"
    }
    
    override var detailInfo: String? {
        return taggedReferenceList(separator: TripElement.Format.refListSeparator, excludeTypes: Set([Flight.RefType_ETicketNo]))
    }
    override var routeName: String? {
        switch (airlineCode, routeNo) {
        case (nil, nil):
            return nil
        case (nil, let route?):
            return String.localizedStringWithFormat(Format.DesignatorNumberOnly, route)
        case (let code?, nil):
            return String.localizedStringWithFormat(Format.DesignatorCodeOnly, code)
        case (let code?, let route?):
            return String.localizedStringWithFormat(Format.DesignatorCodeAndNumber, code, route)
        }
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
    }
    
    
    //
    // MARK: Methods
    //
    override func update(fromDictionary elementData: NSDictionary!) -> Bool {
        changed = super.update(fromDictionary: elementData)

        airlineCode = elementData[Constant.JSON.airlineCompanyCode] as? String
                
        return changed
    }

    
    override func viewController() -> UIViewController? {
        let fvc = FlightDetailsViewController.instantiate(fromAppStoryboard: .Main)
        fvc.tripElement = self
        return fvc
    }

}

