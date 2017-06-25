//
//  GenericTransport.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-20.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation
import UIKit

class GenericTransport: TripElement {
    // MARK: Properties
    var segmentId: Int?
    var segmentCode: String?
    var legNo: Int?
    var departureTime: Date?
    var departureLocation: String?
    var departureStop: String?
    var departureAddress: String?
    var departureTimeZone: String?
    var departureCoordinates: String?
    var departureTerminalCode: String?
    var departureTerminalName: String?
    var arrivalTime: Date?
    var arrivalLocation: String?
    var arrivalStop: String?
    var arrivalAddress: String?
    var arrivalTimeZone: String?
    var arrivalCoordinates: String?
    var arrivalTerminalCode: String?
    var arrivalTerminalName: String?
    var routeNo: String?
    var companyName: String?
    var companyPhone: String?
    
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
        if let references = references {
            var refList: String = ""
            for ref in references {
                refList = refList + (refList == "" ? "" : ", ") + ref[TripElement.RefTag_RefNo]!
            }
            return refList
        }
        return nil
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
    
    // MARK: NSCoding
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
    
    
    // MARK: Initialisers
    required init?(coder aDecoder: NSCoder) {
        // NB: use conditional cast (as?) for any optional properties
        super.init(coder: aDecoder)
        //segmentId = aDecoder.decodeObject(forKey: PropertyKey.segmentIdKey) as? Int
        segmentId = aDecoder.decodeObject(forKey: PropertyKey.segmentIdKey) as? Int ?? aDecoder.decodeInteger(forKey: PropertyKey.segmentIdKey)
        segmentCode = aDecoder.decodeObject(forKey: PropertyKey.segmentCodeKey) as? String
        //legNo = aDecoder.decodeObject(forKey: PropertyKey.legNoKey) as? Int
        legNo = aDecoder.decodeObject(forKey: PropertyKey.legNoKey) as? Int ?? aDecoder.decodeInteger(forKey: PropertyKey.legNoKey)
        departureTime  = aDecoder.decodeObject(forKey: PropertyKey.departureTimeKey) as? Date
        departureLocation = aDecoder.decodeObject(forKey: PropertyKey.departureLocationKey) as? String
        departureStop = aDecoder.decodeObject(forKey: PropertyKey.departureStopKey) as? String
        departureAddress = aDecoder.decodeObject(forKey: PropertyKey.departureAddressKey) as? String
        departureTimeZone = aDecoder.decodeObject(forKey: PropertyKey.departureTimeZoneKey) as? String
        departureCoordinates = aDecoder.decodeObject(forKey: PropertyKey.departureCoordinatesKey) as? String
        departureTerminalCode = aDecoder.decodeObject(forKey: PropertyKey.departureTerminalCodeKey) as? String
        departureTerminalName = aDecoder.decodeObject(forKey: PropertyKey.departureTerminalNameKey) as? String
        arrivalTime = aDecoder.decodeObject(forKey: PropertyKey.arrivalTimeKey) as? Date
        arrivalLocation = aDecoder.decodeObject(forKey: PropertyKey.arrivalLocationKey) as? String
        arrivalStop = aDecoder.decodeObject(forKey: PropertyKey.arrivalStopKey) as? String
        arrivalAddress = aDecoder.decodeObject(forKey: PropertyKey.arrivalAddressKey) as? String
        arrivalTimeZone = aDecoder.decodeObject(forKey: PropertyKey.arrivalTimeZoneKey) as? String
        arrivalCoordinates = aDecoder.decodeObject(forKey: PropertyKey.arrivalCoordinatesKey) as? String
        arrivalTerminalCode = aDecoder.decodeObject(forKey: PropertyKey.arrivalTerminalCodeKey) as? String
        arrivalTerminalName = aDecoder.decodeObject(forKey: PropertyKey.arrivalTerminalNameKey) as? String
        routeNo = aDecoder.decodeObject(forKey: PropertyKey.routeNoKey) as? String
        companyName = aDecoder.decodeObject(forKey: PropertyKey.companyNameKey) as? String
        companyPhone = aDecoder.decodeObject(forKey: PropertyKey.companyPhoneKey) as? String
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

    
    // MARK: Methods
    override func isEqual(_ object: Any?) -> Bool {
        if object_getClassName(self) != object_getClassName(object) {
            return false
        } else if let otherTransport = object as? GenericTransport {
            if self.segmentId             != otherTransport.segmentId              { return false }
            if self.segmentCode           != otherTransport.segmentCode            { return false }
            if self.legNo                 != otherTransport.legNo                  { return false }
            if self.departureTime         != otherTransport.departureTime          { return false }
            if self.departureLocation     != otherTransport.departureLocation      { return false }
            if self.departureStop         != otherTransport.departureStop          { return false }
            if self.departureAddress      != otherTransport.departureAddress       { return false }
            if self.departureTimeZone     != otherTransport.departureTimeZone      { return false }
            if self.departureCoordinates  != otherTransport.departureCoordinates   { return false }
            if self.departureTerminalCode != otherTransport.departureTerminalCode  { return false }
            if self.departureTerminalName != otherTransport.departureTerminalName  { return false }
            if self.arrivalTime           != otherTransport.arrivalTime            { return false }
            if self.arrivalLocation       != otherTransport.arrivalLocation        { return false }
            if self.arrivalStop           != otherTransport.arrivalStop            { return false }
            if self.arrivalAddress        != otherTransport.arrivalAddress         { return false }
            if self.arrivalTimeZone       != otherTransport.arrivalTimeZone        { return false }
            if self.arrivalCoordinates    != otherTransport.arrivalCoordinates     { return false }
            if self.arrivalTerminalCode   != otherTransport.arrivalTerminalCode    { return false }
            if self.arrivalTerminalName   != otherTransport.arrivalTerminalName    { return false }
            if self.routeNo               != otherTransport.routeNo                { return false }
            if self.companyName           != otherTransport.companyName            { return false }
            if self.companyPhone          != otherTransport.companyPhone           { return false }

            return super.isEqual(object)
        } else {
            return false
        }
    }
    
    
    override func startTime(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String? {
        if let departureTime = departureTime {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = dateStyle
            dateFormatter.timeStyle = timeStyle
            if let timeZoneName = departureTimeZone {
                let timezone = TimeZone(identifier: timeZoneName)
                if timezone != nil {
                    dateFormatter.timeZone = timezone
                }
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
            if let timeZoneName = arrivalTimeZone {
                let timezone = TimeZone(identifier: timeZoneName)
                if timezone != nil {
                    dateFormatter.timeZone = timezone
                }
            }

            return dateFormatter.string(from: arrivalTime)
        }
        return nil
    }

}
