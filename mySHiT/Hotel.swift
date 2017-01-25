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
    var checkInDate: Date?
    var checkOutDate: Date?
    var hotelName: String?
    var address: String?
    var postCode: String?
    var city: String?
    var phone: String?
    var transferInfo: String?
    var timezone: String?
    
    override var startTime:Date? {
        return checkInDate
    }
    override var endTime:Date? {
        return checkOutDate
    }
    override var title: String? {
        return hotelName
    }
    override var startInfo: String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeStyle = DateFormatter.Style.none

        return dateFormatter.string(from: checkInDate!) + " - " + dateFormatter.string(from: checkOutDate!)
    }
    override var endInfo: String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeStyle = DateFormatter.Style.none
        
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
    
    
    // MARK: Initialisers
    required init?(coder aDecoder: NSCoder) {
        // NB: use conditional cast (as?) for any optional properties
        super.init(coder: aDecoder)
        checkInDate = aDecoder.decodeObject(forKey: PropertyKey.checkInDateKey) as? Date
        checkOutDate = aDecoder.decodeObject(forKey: PropertyKey.checkOutDateKey) as? Date
        hotelName = aDecoder.decodeObject(forKey: PropertyKey.hotelNameKey) as? String
        address = aDecoder.decodeObject(forKey: PropertyKey.addressKey) as? String
        postCode = aDecoder.decodeObject(forKey: PropertyKey.postCodeKey) as? String
        city = aDecoder.decodeObject(forKey: PropertyKey.cityKey) as? String
        phone = aDecoder.decodeObject(forKey: PropertyKey.phoneKey) as? String
        transferInfo = aDecoder.decodeObject(forKey: PropertyKey.transferInfoKey) as? String
        timezone = aDecoder.decodeObject(forKey: PropertyKey.timezoneKey) as? String
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
    override func isEqual(_ object: Any?) -> Bool {
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
    
}
