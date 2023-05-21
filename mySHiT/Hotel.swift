//
//  Hotel.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-21.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation
import UIKit
import os

class Hotel: TripElement {
    let defaultCheckInTime = ( hour: 16, minute: 0 )
    let defaultCheckOutTime = ( hour: 10, minute: 0 )
    
    //
    // MARK: Properties
    //
    var checkInDate: Date? { willSet { checkChange(checkInDate, newValue) } }
    var checkOutDate: Date? { willSet { checkChange(checkOutDate, newValue) } }
    var hotelName: String? { willSet { checkChange(hotelName, newValue) } }
    var address: String? { willSet { checkChange(address, newValue) } }
    var postCode: String? { willSet { checkChange(postCode, newValue) } }
    var city: String? { willSet { checkChange(city, newValue) } }
    var phone: String? { willSet { checkChange(phone, newValue) } }
    var transferInfo: String? { willSet { checkChange(transferInfo, newValue) } }
    var timezone: String? { willSet { checkChange(timezone, newValue) } }
    
    override var startTime:Date? {
        if let checkInDate = checkInDate {
            return checkInDate.addHours(defaultCheckInTime.hour).addMinutes(defaultCheckInTime.minute)
        }
        return nil
    }
    override var endTime:Date? {
        if let checkOutDate = checkOutDate {
            return checkOutDate.addHours(defaultCheckOutTime.hour).addMinutes(defaultCheckOutTime.minute)
        }
        return nil
    }
    override var title: String? {
        return hotelName
    }
    override var startInfo: String? {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: checkInDate!, to: checkOutDate!)
    }
    override var endInfo: String? {
        return nil
    }
    override var detailInfo: String? {
        return referenceList(separator: TripElement.Format.refListSeparator)
    }
    
    
    struct PropertyKey {
        static let checkInDateKey = "checkInDate"
        static let checkOutDateKey = "checkOutDate"
        static let hotelNameKey = "hotelName"
        static let addressKey = "address"
        static let postCodeKey = "postCode"
        static let cityKey = "city"
        static let phoneKey = "phone"
        static let transferInfoKey = "transferInfo"
        static let timezoneKey = "timezone"
    }

    
    //
    // MARK: NSCoding
    //
    override class var supportsSecureCoding: Bool { return true }

    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(checkInDate, forKey: PropertyKey.checkInDateKey)
        aCoder.encode(checkOutDate, forKey: PropertyKey.checkOutDateKey)
        aCoder.encode(hotelName, forKey: PropertyKey.hotelNameKey)
        aCoder.encode(address, forKey: PropertyKey.addressKey)
        aCoder.encode(postCode, forKey: PropertyKey.postCodeKey)
        aCoder.encode(city, forKey: PropertyKey.cityKey)
        aCoder.encode(phone, forKey: PropertyKey.phoneKey)
        aCoder.encode(transferInfo, forKey: PropertyKey.transferInfoKey)
        aCoder.encode(timezone, forKey: PropertyKey.timezoneKey)
    }
    
    
    //
    // MARK: Initialisers
    //
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        checkInDate = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.checkInDateKey) as? Date
        checkOutDate = aDecoder.decodeObject(of: NSDate.self, forKey: PropertyKey.checkOutDateKey) as? Date
        hotelName = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.hotelNameKey) as? String
        address = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.addressKey) as? String
        postCode = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.postCodeKey) as? String
        city = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.cityKey) as? String
        phone = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.phoneKey) as? String
        transferInfo = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.transferInfoKey) as? String
        timezone = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.timezoneKey) as? String
    }
    
    
    required init?(fromDictionary elementData: NSDictionary!) {
        super.init(fromDictionary: elementData)
        
        let dictTimezone = elementData[Constant.JSON.hotelTimezone] as? String
        checkInDate = ServerDate.convertServerDate(elementData[Constant.JSON.hotelCheckIn] as? String, timeZoneName: dictTimezone)
        checkOutDate = ServerDate.convertServerDate(elementData[Constant.JSON.hotelCheckOut] as? String, timeZoneName: dictTimezone)

        hotelName = elementData[Constant.JSON.hotelName] as? String
        address = elementData[Constant.JSON.hotelAddress] as? String
        postCode = elementData[Constant.JSON.hotelPostCode] as? String
        city = elementData[Constant.JSON.hotelCity] as? String
        phone = elementData[Constant.JSON.hotelPhone] as? String
        transferInfo = elementData[Constant.JSON.hotelTransferInfo] as? String
    }
    
    
    //
    // MARK: Dynamic construction
    //
    override class func canHandle(_ elemType: ElementType!) -> Bool {
        switch (elemType.type, elemType.subType) {
        case (TripElement.MainType.Accommodation, _):
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

        let dictTimezone = elementData[Constant.JSON.hotelTimezone] as? String
        checkInDate = ServerDate.convertServerDate(elementData[Constant.JSON.hotelCheckIn] as? String, timeZoneName: dictTimezone)
        checkOutDate = ServerDate.convertServerDate(elementData[Constant.JSON.hotelCheckOut] as? String, timeZoneName: dictTimezone)

        hotelName = elementData[Constant.JSON.hotelName] as? String
        address = elementData[Constant.JSON.hotelAddress] as? String
        postCode = elementData[Constant.JSON.hotelPostCode] as? String
        city = elementData[Constant.JSON.hotelCity] as? String
        phone = elementData[Constant.JSON.hotelPhone] as? String
        transferInfo = elementData[Constant.JSON.hotelTransferInfo] as? String

        return changed
    }

    
    override func startTime(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String? {
        if let checkInDate = checkInDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = dateStyle
            dateFormatter.timeStyle = timeStyle
            if let timeZoneName = timezone {
                let timezone = TimeZone(identifier: timeZoneName)
                if timezone != nil {
                    dateFormatter.timeZone = timezone
                }
            }
            
            return dateFormatter.string(from: checkInDate)
        }
        return nil
    }

    
    override func endTime(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String? {
        if let checkOutDate = checkOutDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = dateStyle
            dateFormatter.timeStyle = timeStyle
            if let timeZoneName = timezone {
                let timezone = TimeZone(identifier: timeZoneName)
                if timezone != nil {
                    dateFormatter.timeZone = timezone
                }
            }
            
            return dateFormatter.string(from: checkOutDate)
        }
        return nil
    }
    
    
    override func viewController() -> UIViewController? {
        let hvc = HotelDetailsViewController.instantiate(fromAppStoryboard: .Main)
        hvc.tripElement = self
        return hvc
    }

}

