//
//  Hotel.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-21.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation

class Hotel: TripElement {
    // MARK: Properties
    var checkInDate: NSDate?
    var checkOutDate: NSDate?
    var hotelName: String?
    var address: String?
    var postCode: String?
    var city: String?
    var phone: String?
    var transferInfo: String?
    var timezone: String?
    
    override var startTime:NSDate? {
        return checkInDate
    }
    override var endTime:NSDate? {
        return checkOutDate
    }
    override var title: String? {
        return hotelName
    }
    override var startInfo: String? {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle

        return dateFormatter.stringFromDate(checkInDate!) + " - " + dateFormatter.stringFromDate(checkOutDate!)
    }
    override var endInfo: String? {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
        
        return nil
        //return dateFormatter.stringFromDate(checkOutTime!)
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

    
    // MARK: NSCoding
    override func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        aCoder.encodeObject(checkInDate, forKey: PropertyKey.checkInDateKey)
        aCoder.encodeObject(checkOutDate, forKey: PropertyKey.checkOutDateKey)
        aCoder.encodeObject(hotelName, forKey: PropertyKey.hotelNameKey)
        aCoder.encodeObject(address, forKey: PropertyKey.addressKey)
        aCoder.encodeObject(postCode, forKey: PropertyKey.postCodeKey)
        aCoder.encodeObject(city, forKey: PropertyKey.cityKey)
        aCoder.encodeObject(phone, forKey: PropertyKey.phoneKey)
        aCoder.encodeObject(transferInfo, forKey: PropertyKey.transferInfoKey)
        aCoder.encodeObject(timezone, forKey: PropertyKey.timezoneKey)
    }
    
    
    // MARK: Initialisers
    required init?(coder aDecoder: NSCoder) {
        // NB: use conditional cast (as?) for any optional properties
        super.init(coder: aDecoder)
        checkInDate = aDecoder.decodeObjectForKey(PropertyKey.checkInDateKey) as? NSDate
        checkOutDate = aDecoder.decodeObjectForKey(PropertyKey.checkOutDateKey) as? NSDate
        hotelName = aDecoder.decodeObjectForKey(PropertyKey.hotelNameKey) as? String
        address = aDecoder.decodeObjectForKey(PropertyKey.addressKey) as? String
        postCode = aDecoder.decodeObjectForKey(PropertyKey.postCodeKey) as? String
        city = aDecoder.decodeObjectForKey(PropertyKey.cityKey) as? String
        phone = aDecoder.decodeObjectForKey(PropertyKey.phoneKey) as? String
        transferInfo = aDecoder.decodeObjectForKey(PropertyKey.transferInfoKey) as? String
        timezone = aDecoder.decodeObjectForKey(PropertyKey.timezoneKey) as? String
    }
    
    
    required init?(fromDictionary elementData: NSDictionary!) {
        super.init(fromDictionary: elementData)
        
        if let checkInDateText = elementData[Constant.JSON.hotelCheckIn] as? String {
            checkInDate = ServerDate.convertServerDate(checkInDateText, timeZoneName: timezone)
        }
        if let checkOutDateText = elementData[Constant.JSON.hotelCheckOut] as? String {
            checkOutDate = ServerDate.convertServerDate(checkOutDateText, timeZoneName: timezone)
        }
        
        hotelName = elementData[Constant.JSON.hotelName] as? String
        address = elementData[Constant.JSON.hotelAddress] as? String
        postCode = elementData[Constant.JSON.hotelPostCode] as? String
        city = elementData[Constant.JSON.hotelCity] as? String
        phone = elementData[Constant.JSON.hotelPhone] as? String
        transferInfo = elementData[Constant.JSON.hotelTransferInfo] as? String
    }
    
    
    // MARK: Methods
    override func isEqual(object: AnyObject?) -> Bool {
        if object_getClassName(self) != object_getClassName(object) {
            return false
        } else if let otherHotel = object as? Hotel {
            if self.checkInDate   != otherHotel.checkInDate       { return false }
            if self.checkOutDate  != otherHotel.checkOutDate      { return false }
            if self.hotelName     != otherHotel.hotelName         { return false }
            if self.address       != otherHotel.address           { return false }
            if self.postCode      != otherHotel.postCode          { return false }
            if self.city          != otherHotel.city              { return false }
            if self.phone         != otherHotel.phone             { return false }
            if self.transferInfo  != otherHotel.transferInfo      { return false }
            if self.timezone      != otherHotel.timezone          { return false }

            return super.isEqual(object)
        } else {
            return false
        }
    }
    
    
    override func startTime(dateStyle dateStyle: NSDateFormatterStyle, timeStyle: NSDateFormatterStyle) -> String? {
        if let checkInDate = checkInDate {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = dateStyle
            dateFormatter.timeStyle = timeStyle
            if let timeZoneName = timezone {
                let timezone = NSTimeZone(name: timeZoneName)
                if timezone != nil {
                    dateFormatter.timeZone = timezone
                }
            }
            
            return dateFormatter.stringFromDate(checkInDate)
        }
        return nil
    }

    override func endTime(dateStyle dateStyle: NSDateFormatterStyle, timeStyle: NSDateFormatterStyle) -> String? {
        if let checkOutDate = checkOutDate {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = dateStyle
            dateFormatter.timeStyle = timeStyle
            if let timeZoneName = timezone {
                let timezone = NSTimeZone(name: timeZoneName)
                if timezone != nil {
                    dateFormatter.timeZone = timezone
                }
            }
            
            return dateFormatter.stringFromDate(checkOutDate)
        }
        return nil
    }
    
}