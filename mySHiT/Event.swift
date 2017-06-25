//
//  Event.swift
//  mySHiT
//
//  Created by Per Solberg on 2017-01-23.
//  Copyright © 2017 &More AS. All rights reserved.
//

import Foundation
import UIKit


class Event: TripElement {
    // MARK: Properties
    var eventStartTime: Date?
    var travelTime: Int?
    var venueName: String?
    var venueAddress: String?
    var venuePostCode: String?
    var venueCity: String?
    var venuePhone: String?
    var accessInfo: String?
    var timezone: String?

    
    //private String startTimeText;  // Hold original value for saving in archive


    override var startTime:Date? {
        return eventStartTime
    }
    override var startTimeZone: String? {
        return timezone
    }
    override var title: String? {
        return venueName
    }
    override var startInfo: String? {
        /*
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.none
        dateFormatter.timeStyle = DateFormatter.Style.short
        
        return dateFormatter.string(from: eventStartTime!)
        */
        return startTime(dateStyle: .none, timeStyle: .short)
    }
    override var endInfo: String? {
        return nil
        //return dateFormatter.stringFromDate(checkOutTime!)
    }
    var travelTimeInfo: String? {
        if let travelTime = travelTime {
            //let ti = T
            return DateComponentsFormatter().string(from: Double(travelTime) * 60.0)
        }
        return nil
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
        static let eventStartTimeKey = "startTime"
        static let travelTimeKey = "travelTime"
        static let venueNameKey = "venueName"
        static let venueAddressKey = "venueAddress"
        static let venuePostCodeKey = "venuePostCode"
        static let venueCityKey = "venueCity"
        static let venuePhoneKey = "venuePhone"
        static let accessInfoKey = "accessInfo"
        static let timezoneKey = "timezone"
    }
    
    // MARK: NSCoding
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(eventStartTime, forKey: PropertyKey.eventStartTimeKey)
        aCoder.encode(travelTime, forKey: PropertyKey.travelTimeKey)
        aCoder.encode(venueName, forKey: PropertyKey.venueNameKey)
        aCoder.encode(venueAddress, forKey: PropertyKey.venueAddressKey)
        aCoder.encode(venuePostCode, forKey: PropertyKey.venuePostCodeKey)
        aCoder.encode(venueCity, forKey: PropertyKey.venueCityKey)
        aCoder.encode(venuePhone, forKey: PropertyKey.venuePhoneKey)
        aCoder.encode(accessInfo, forKey: PropertyKey.accessInfoKey)
        aCoder.encode(timezone, forKey: PropertyKey.timezoneKey)
    }
        
    // MARK: Initialisers
    required init?(coder aDecoder: NSCoder) {
        // NB: use conditional cast (as?) for any optional properties
        super.init(coder: aDecoder)
        eventStartTime = aDecoder.decodeObject(forKey: PropertyKey.eventStartTimeKey) as? Date
        travelTime = aDecoder.decodeObject(forKey: PropertyKey.travelTimeKey) as? Int? ?? aDecoder.decodeInteger(forKey: PropertyKey.travelTimeKey)
        venueName = aDecoder.decodeObject(forKey: PropertyKey.venueNameKey) as? String
        venueAddress = aDecoder.decodeObject(forKey: PropertyKey.venueAddressKey) as? String
        venuePostCode = aDecoder.decodeObject(forKey: PropertyKey.venuePostCodeKey) as? String
        venueCity = aDecoder.decodeObject(forKey: PropertyKey.venueCityKey) as? String
        venuePhone = aDecoder.decodeObject(forKey: PropertyKey.venuePhoneKey) as? String
        accessInfo = aDecoder.decodeObject(forKey: PropertyKey.accessInfoKey) as? String
        timezone = aDecoder.decodeObject(forKey: PropertyKey.timezoneKey) as? String
    }
    
    
    required init?(fromDictionary elementData: NSDictionary!) {
        super.init(fromDictionary: elementData)
        
        timezone = elementData[Constant.JSON.eventTimezone] as? String
        if let eventStartTimeText = elementData[Constant.JSON.eventStartTime] as? String {
            eventStartTime = ServerDate.convertServerDate(eventStartTimeText, timeZoneName: timezone)
        }

        travelTime = elementData[Constant.JSON.eventTravelTime] as? Int
        venueName = elementData[Constant.JSON.eventVenueName] as? String
        venueAddress = elementData[Constant.JSON.eventVenueAddress] as? String
        venuePostCode = elementData[Constant.JSON.eventVenuePostCode] as? String
        venueCity = elementData[Constant.JSON.eventVenueCity] as? String
        venuePhone = elementData[Constant.JSON.eventVenuePhone] as? String
        accessInfo = elementData[Constant.JSON.eventAccessInfo] as? String
    }
    
    
    // MARK: Methods
    override func isEqual(_ object: Any?) -> Bool {
        if object_getClassName(self) != object_getClassName(object) {
            return false
        } else if let otherEvent = object as? Event {
            if self.eventStartTime  != otherEvent.eventStartTime    { return false }
            if self.travelTime      != otherEvent.travelTime        { return false }
            if self.venueName       != otherEvent.venueName         { return false }
            if self.venueAddress    != otherEvent.venueAddress      { return false }
            if self.venuePostCode   != otherEvent.venuePostCode     { return false }
            if self.venueCity       != otherEvent.venueCity         { return false }
            if self.venuePhone      != otherEvent.venuePhone        { return false }
            if self.accessInfo      != otherEvent.accessInfo        { return false }
            if self.timezone        != otherEvent.timezone          { return false }
            
            return super.isEqual(object)
        } else {
            return false
        }
    }
    
    
    override func startTime(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String? {
        if let eventStartTime = eventStartTime {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = dateStyle
            dateFormatter.timeStyle = timeStyle
            if let timeZoneName = timezone {
                let timezone = TimeZone(identifier: timeZoneName)
                if timezone != nil {
                    dateFormatter.timeZone = timezone
                }
            }
            
            return dateFormatter.string(from: eventStartTime)
        }
        return nil
    }
    
    override func setNotification() {
        // First delete any existing notifications for this trip element
        cancelNotifications()
        
        // Set notification (if we have a start time)
        if (tense ?? .past) == .future {
            let defaults = UserDefaults.standard
            var eventLeadtime = Int(defaults.float(forKey: Constant.Settings.eventLeadTime))
            let genericAlertMessage = NSLocalizedString(Constant.msg.eventAlertMessage, comment: "Some dummy comment")
            
            if let travelTime = travelTime {
                eventLeadtime += travelTime;
            }
            
            setNotification(notificationType: Constant.Settings.eventLeadTime, leadTime: eventLeadtime, alertMessage: genericAlertMessage, userInfo: nil)
        }
    }

}
