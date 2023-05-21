//
//  GenericTransport.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-20.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation
import UIKit
import os

class GenericTransport: TripElement {
    struct Format {
        static let TerminalOnly = NSLocalizedString("FMT.TRANSPORT.TERMINAL", comment:"")
        static let StopNameOnly = NSLocalizedString("FMT.TRANSPORT.STOP", comment:"")
        static let StopAndTerminal = NSLocalizedString("FMT.TRANSPORT.STOP_AND_TERMINAL", comment:"")

        static let RouteName = NSLocalizedString("FMT.TRANSPORT.ROUTE_NAME", comment:"")

        static let DepartureOnly = NSLocalizedString("FMT.TRANSPORT.DEPARTURE", comment:"")
        static let ArrivalOnly = NSLocalizedString("FMT.TRANSPORT.ARRIVAL", comment:"")
        static let DepartureAndArrival = NSLocalizedString("FMT.TRANSPORT.DEPT_AND_ARRIVAL", comment:"")
    }
    
    //
    // MARK: Properties
    //
    var segmentId: Int? { willSet { checkChange(segmentId, newValue) } }
    var segmentCode: String? { willSet { checkChange(segmentCode, newValue) } }
    var legNo: Int? { willSet { checkChange(legNo, newValue) } }
    var departureTime: Date? { willSet { checkChange(departureTime, newValue) } }
    var departureLocation: String?  { willSet { checkChange(departureLocation, newValue) } }
    var departureStop: String?  { willSet { checkChange(departureStop, newValue) } }
    var departureAddress: String?  { willSet { checkChange(departureAddress, newValue) } }
    var departureTimeZone: String?  { willSet { checkChange(departureTimeZone, newValue) } }
    var departureCoordinates: String?  { willSet { checkChange(departureCoordinates, newValue) } }
    var departureTerminalCode: String?  { willSet { checkChange(departureTerminalCode, newValue) } }
    var departureTerminalName: String?  { willSet { checkChange(departureTerminalName, newValue) } }
    var arrivalTime: Date? { willSet { checkChange(arrivalTime, newValue) } }
    var arrivalLocation: String? { willSet { checkChange(arrivalLocation, newValue) } }
    var arrivalStop: String? { willSet { checkChange(arrivalStop, newValue) } }
    var arrivalAddress: String? { willSet { checkChange(arrivalAddress, newValue) } }
    var arrivalTimeZone: String? { willSet { checkChange(arrivalTimeZone, newValue) } }
    var arrivalCoordinates: String? { willSet { checkChange(arrivalCoordinates, newValue) } }
    var arrivalTerminalCode: String? { willSet { checkChange(arrivalTerminalCode, newValue) } }
    var arrivalTerminalName: String? { willSet { checkChange(arrivalTerminalName, newValue) } }
    var routeNo: String? { willSet { checkChange(routeNo, newValue) } }
    var companyName: String? { willSet { checkChange(companyName, newValue) } }
    var companyPhone: String? { willSet { checkChange(companyPhone, newValue) } }
    
    override var startTime:Date? {
        return departureTime
    }
    override var startTimeZone:String? {
        return departureTimeZone
    }
    override var endTime:Date? {
        return arrivalTime
    }
    override var endTimeZone:String? {
        return arrivalTimeZone
    }
    override var title: String? {
        return companyName
    }
    override var startInfo: String? {
        return departureLocation
    }
    override var endInfo: String? {
        return arrivalLocation
    }
    override var detailInfo: String? {
        return referenceList(separator: TripElement.Format.refListSeparator)
    }
    var routeName: String? {
        switch (companyName, routeNo) {
        case (nil, nil):
            return nil
        case (nil, let route?):
            return route
        case (let company?, nil):
            return company
        case (let company?, let route?):
            return String.localizedStringWithFormat(Format.RouteName, company, route)
        }
    }
    var locationInfo: String? {
        switch (departureLocation, arrivalLocation) {
        case (nil, nil):
            return nil
        case (nil, let arrLoc?):
            return String.localizedStringWithFormat(Format.ArrivalOnly, arrLoc)
        case (let depLoc?, nil):
            return String.localizedStringWithFormat(Format.DepartureOnly, depLoc)
        case (let depLoc?, let arrLoc?) where depLoc == arrLoc:
            return String.localizedStringWithFormat(Format.DepartureOnly, depLoc)
        case (let depLoc?, let arrLoc?) :
            return String.localizedStringWithFormat(Format.DepartureAndArrival, depLoc, arrLoc)
        }
    }
    var departureStopInfo:String? {
        return stopInfo(stop: departureStop, terminal: departureTerminalCode)
    }
    var arrivalStopInfo:String? {
        return stopInfo(stop: arrivalStop, terminal: arrivalTerminalCode)
    }

    struct PropertyKey {
        static let segmentIdKey = "segmentId"
        static let segmentCodeKey = "segmentCode"
        static let legNoKey = "legNo"
        static let departureTimeKey = "departureTime"
        static let departureLocationKey = "departureLocation"
        static let departureStopKey = "departureStop"
        static let departureAddressKey = "departureAddress"
        static let departureTimeZoneKey = "departureTimeZone"
        static let departureCoordinatesKey = "departureCoordinates"
        static let departureTerminalCodeKey = "departureTerminalCode"
        static let departureTerminalNameKey = "departureTerminalName"
        static let arrivalTimeKey = "arrivalTime"
        static let arrivalLocationKey = "arrivalLocation"
        static let arrivalStopKey = "arrivalStop"
        static let arrivalAddressKey = "arrivalAddress"
        static let arrivalTimeZoneKey = "arrivalTimeZone"
        static let arrivalCoordinatesKey = "arrivalCoordinates"
        static let arrivalTerminalCodeKey = "arrivalTerminalCode"
        static let arrivalTerminalNameKey = "arrivalTerminalName"
        static let routeNoKey = "routeNo"
        static let companyNameKey = "companyName"
        static let companyPhoneKey = "companyPhone"
    }
    
    
    //
    // MARK: NSCoding
    //
    override class var supportsSecureCoding: Bool { return true }

    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(segmentId, forKey: PropertyKey.segmentIdKey)
        aCoder.encode(segmentCode, forKey: PropertyKey.segmentCodeKey)
        aCoder.encode(legNo, forKey: PropertyKey.legNoKey)
        aCoder.encode(departureTime, forKey: PropertyKey.departureTimeKey)
        aCoder.encode(departureLocation, forKey: PropertyKey.departureLocationKey)
        aCoder.encode(departureStop, forKey: PropertyKey.departureStopKey)
        aCoder.encode(departureAddress, forKey: PropertyKey.departureAddressKey)
        aCoder.encode(departureTimeZone, forKey: PropertyKey.departureTimeZoneKey)
        aCoder.encode(departureCoordinates, forKey: PropertyKey.departureCoordinatesKey)
        aCoder.encode(departureTerminalCode, forKey: PropertyKey.departureTerminalCodeKey)
        aCoder.encode(departureTerminalName, forKey: PropertyKey.departureTerminalNameKey)
        aCoder.encode(arrivalTime, forKey: PropertyKey.arrivalTimeKey)
        aCoder.encode(arrivalLocation, forKey: PropertyKey.arrivalLocationKey)
        aCoder.encode(arrivalStop, forKey: PropertyKey.arrivalStopKey)
        aCoder.encode(arrivalAddress, forKey: PropertyKey.arrivalAddressKey)
        aCoder.encode(arrivalTimeZone, forKey: PropertyKey.arrivalTimeZoneKey)
        aCoder.encode(arrivalCoordinates, forKey: PropertyKey.arrivalCoordinatesKey)
        aCoder.encode(arrivalTerminalCode, forKey: PropertyKey.arrivalTerminalCodeKey)
        aCoder.encode(arrivalTerminalName, forKey: PropertyKey.arrivalTerminalNameKey)
        aCoder.encode(routeNo, forKey: PropertyKey.routeNoKey)
        aCoder.encode(companyName, forKey: PropertyKey.companyNameKey)
        aCoder.encode(companyPhone, forKey: PropertyKey.companyPhoneKey)
    }
    
    
    //
    // MARK: Initialisers
    //
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        segmentId = aDecoder.decodeObject(of: NSNumber.self, forKey: PropertyKey.segmentIdKey) as? Int // ?? aDecoder.decodeInteger(forKey: PropertyKey.segmentIdKey)
        segmentCode = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.segmentCodeKey) as? String
        legNo = aDecoder.decodeObject(of: NSNumber.self, forKey: PropertyKey.legNoKey) as? Int// ?? aDecoder.decodeInteger(forKey: PropertyKey.legNoKey)
        departureTime  = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.departureTimeKey) as? Date
        departureLocation = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.departureLocationKey) as? String
        departureStop = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.departureStopKey) as? String
        departureAddress = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.departureAddressKey) as? String
        departureTimeZone = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.departureTimeZoneKey) as? String
        departureCoordinates = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.departureCoordinatesKey) as? String
        departureTerminalCode = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.departureTerminalCodeKey) as? String
        departureTerminalName = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.departureTerminalNameKey) as? String
        arrivalTime = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.arrivalTimeKey) as? Date
        arrivalLocation = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.arrivalLocationKey) as? String
        arrivalStop = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.arrivalStopKey) as? String
        arrivalAddress = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.arrivalAddressKey) as? String
        arrivalTimeZone = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.arrivalTimeZoneKey) as? String
        arrivalCoordinates = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.arrivalCoordinatesKey) as? String
        arrivalTerminalCode = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.arrivalTerminalCodeKey) as? String
        arrivalTerminalName = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.arrivalTerminalNameKey) as? String
        routeNo = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.routeNoKey) as? String
        companyName = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.companyNameKey) as? String
        companyPhone = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.companyPhoneKey) as? String
    }
    
    
    required init?(fromDictionary elementData: NSDictionary!) {
        super.init(fromDictionary: elementData)
        segmentId = elementData[Constant.JSON.transportSegmentId] as? Int
        segmentCode = elementData[Constant.JSON.transportSegmentCode] as? String
        legNo = elementData[Constant.JSON.transportLegNo] as? Int
        departureLocation = elementData[Constant.JSON.transportDeptLocation] as? String
        departureStop = elementData[Constant.JSON.transportDeptStop] as? String
        departureAddress = elementData[Constant.JSON.transportDeptAddress] as? String
        departureTimeZone = elementData[Constant.JSON.transportDeptTimezone] as? String
        if let departureTimeText = elementData[Constant.JSON.transportDeptTime] as? String {
            departureTime = ServerDate.convertServerDate(departureTimeText, timeZoneName: departureTimeZone)
        }
        departureCoordinates = elementData[Constant.JSON.transportDeptCoordinates] as? String
        departureTerminalCode = elementData[Constant.JSON.transportDeptTerminalCode] as? String
        departureTerminalName = elementData[Constant.JSON.transportDeptTerminalName] as? String
        
        arrivalLocation = elementData[Constant.JSON.transportArrLocation] as? String
        arrivalStop = elementData[Constant.JSON.transportArrStop] as? String
        arrivalAddress = elementData[Constant.JSON.transportArrAddress] as? String
        arrivalTimeZone = elementData[Constant.JSON.transportArrTimezone] as? String
        if let arrivalTimeText = elementData[Constant.JSON.transportArrTime] as? String {
            arrivalTime = ServerDate.convertServerDate(arrivalTimeText, timeZoneName: arrivalTimeZone)
        }
        arrivalCoordinates = elementData[Constant.JSON.transportArrCoordinates] as? String
        arrivalTerminalCode = elementData[Constant.JSON.transportArrTerminalCode] as? String
        arrivalTerminalName = elementData[Constant.JSON.transportArrTerminalName] as? String
        
        routeNo = elementData[Constant.JSON.transportRouteNo] as? String
        companyName = elementData[Constant.JSON.transportCompany] as? String
        companyPhone = elementData[Constant.JSON.transportCompanyPhone] as? String
    }

    
    //
    // MARK: Dynamic construction
    //
    override class func canHandle(_ elemType: ElementType!) -> Bool {
        switch (elemType.type, elemType.subType) {
        case (TripElement.MainType.Transport, _):
            return true;
        default:
            return false;
        }
    }

    //
    // MARK: Methods
    //
    override func update(fromDictionary elementData: NSDictionary!) -> Bool {
        changed = super.update(fromDictionary: elementData)

        segmentId = elementData[Constant.JSON.transportSegmentId] as? Int
        segmentCode = elementData[Constant.JSON.transportSegmentCode] as? String
        legNo = elementData[Constant.JSON.transportLegNo] as? Int
        departureLocation = elementData[Constant.JSON.transportDeptLocation] as? String
        departureStop = elementData[Constant.JSON.transportDeptStop] as? String
        departureAddress = elementData[Constant.JSON.transportDeptAddress] as? String
        departureTimeZone = elementData[Constant.JSON.transportDeptTimezone] as? String
        if let departureTimeText = elementData[Constant.JSON.transportDeptTime] as? String {
            departureTime = ServerDate.convertServerDate(departureTimeText, timeZoneName: departureTimeZone)
        }
        departureCoordinates = elementData[Constant.JSON.transportDeptCoordinates] as? String
        departureTerminalCode = elementData[Constant.JSON.transportDeptTerminalCode] as? String
        departureTerminalName = elementData[Constant.JSON.transportDeptTerminalName] as? String
        
        arrivalLocation = elementData[Constant.JSON.transportArrLocation] as? String
        arrivalStop = elementData[Constant.JSON.transportArrStop] as? String
        arrivalAddress = elementData[Constant.JSON.transportArrAddress] as? String
        arrivalTimeZone = elementData[Constant.JSON.transportArrTimezone] as? String
        if let arrivalTimeText = elementData[Constant.JSON.transportArrTime] as? String {
            arrivalTime = ServerDate.convertServerDate(arrivalTimeText, timeZoneName: arrivalTimeZone)
        }
        arrivalCoordinates = elementData[Constant.JSON.transportArrCoordinates] as? String
        arrivalTerminalCode = elementData[Constant.JSON.transportArrTerminalCode] as? String
        arrivalTerminalName = elementData[Constant.JSON.transportArrTerminalName] as? String
        
        routeNo = elementData[Constant.JSON.transportRouteNo] as? String
        companyName = elementData[Constant.JSON.transportCompany] as? String
        companyPhone = elementData[Constant.JSON.transportCompanyPhone] as? String

        return changed
    }

    
    override func startTime(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String? {
        if let departureTime = departureTime {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = dateStyle
            dateFormatter.timeStyle = timeStyle
            if let timeZoneName = departureTimeZone, let timezone = TimeZone(identifier: timeZoneName) {
                dateFormatter.timeZone = timezone
            }
        
            return dateFormatter.string(from: departureTime)
        }
        return nil
    }

    
    override func endTime(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String? {
        if let arrivalTime = arrivalTime {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = dateStyle
            dateFormatter.timeStyle = timeStyle
            if let timeZoneName = arrivalTimeZone, let timezone = TimeZone(identifier: timeZoneName) {
                dateFormatter.timeZone = timezone
            }

            return dateFormatter.string(from: arrivalTime)
        }
        return nil
    }

    
    override func viewController() -> UIViewController? {
        let ptvc = PrivateTransportDetailsViewController.instantiate(fromAppStoryboard: .Main)
        ptvc.tripElement = self
        return ptvc
    }


    func stopInfo(stop:String?, terminal:String?) -> String? {
        switch (stop, terminal) {
        case (nil, nil):
            return nil
        case (nil, let terminal?):
            return String.localizedStringWithFormat(Format.TerminalOnly, terminal)
        case (let stop?, nil):
            return String.localizedStringWithFormat(Format.StopNameOnly, stop)
        case (let stop?, let terminal?):
            return String.localizedStringWithFormat(Format.StopAndTerminal, stop, terminal)
        }
    }

}
