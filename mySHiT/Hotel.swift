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
                refList = refList + (refList == "" ? "" : ", ") + ref["refNo"]!
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
        
        if let checkInDateText = elementData["checkIn"] as? String {
            checkInDate = ServerDate.convertServerDate(checkInDateText, timeZoneName: timezone)
        }
        if let checkOutDateText = elementData["checkOut"] as? String {
            checkOutDate = ServerDate.convertServerDate(checkOutDateText, timeZoneName: timezone)
        }
        
        hotelName = elementData["hotelName"] as? String
        address = elementData["address"] as? String
        postCode = elementData["postCode"] as? String
        city = elementData["city"] as? String
        phone = elementData["phone"] as? String
        transferInfo = elementData["transferInfo"] as? String
    }
    
    
    // MARK: Methods
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