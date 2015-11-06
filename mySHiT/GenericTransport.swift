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
    var departureTime: NSDate?
    var departureLocation: String?
    var departureStop: String?
    var departureAddress: String?
    var departureTimeZone: String?
    var departureCoordinates: String?
    var departureTerminalCode: String?
    var departureTerminalName: String?
    var arrivalTime: NSDate?
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
    
    override var startTime:NSDate? {
        return departureTime
    }
    override var endTime:NSDate? {
        return arrivalTime
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
                refList = refList + (refList == "" ? "" : ", ") + ref["refNo"]!
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
    override func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        aCoder.encodeObject(segmentId, forKey: PropertyKey.segmentIdKey)
        aCoder.encodeObject(segmentCode, forKey: PropertyKey.segmentCodeKey)
        aCoder.encodeObject(legNo, forKey: PropertyKey.legNoKey)
        aCoder.encodeObject(departureTime, forKey: PropertyKey.departureTimeKey)
        aCoder.encodeObject(departureLocation, forKey: PropertyKey.departureLocationKey)
        aCoder.encodeObject(departureStop, forKey: PropertyKey.departureStopKey)
        aCoder.encodeObject(departureAddress, forKey: PropertyKey.departureAddressKey)
        aCoder.encodeObject(departureTimeZone, forKey: PropertyKey.departureTimeZoneKey)
        aCoder.encodeObject(departureCoordinates, forKey: PropertyKey.departureCoordinatesKey)
        aCoder.encodeObject(departureTerminalCode, forKey: PropertyKey.departureTerminalCodeKey)
        aCoder.encodeObject(departureTerminalName, forKey: PropertyKey.departureTerminalNameKey)
        aCoder.encodeObject(arrivalTime, forKey: PropertyKey.arrivalTimeKey)
        aCoder.encodeObject(arrivalLocation, forKey: PropertyKey.arrivalLocationKey)
        aCoder.encodeObject(arrivalStop, forKey: PropertyKey.arrivalStopKey)
        aCoder.encodeObject(arrivalAddress, forKey: PropertyKey.arrivalAddressKey)
        aCoder.encodeObject(arrivalTimeZone, forKey: PropertyKey.arrivalTimeZoneKey)
        aCoder.encodeObject(arrivalCoordinates, forKey: PropertyKey.arrivalCoordinatesKey)
        aCoder.encodeObject(arrivalTerminalCode, forKey: PropertyKey.arrivalTerminalCodeKey)
        aCoder.encodeObject(arrivalTerminalName, forKey: PropertyKey.arrivalTerminalNameKey)
        aCoder.encodeObject(routeNo, forKey: PropertyKey.routeNoKey)
        aCoder.encodeObject(companyName, forKey: PropertyKey.companyNameKey)
        aCoder.encodeObject(companyPhone, forKey: PropertyKey.companyPhoneKey)
    }
    
    
    // MARK: Initialisers
    required init?(coder aDecoder: NSCoder) {
        // NB: use conditional cast (as?) for any optional properties
        super.init(coder: aDecoder)
        segmentId = aDecoder.decodeObjectForKey(PropertyKey.segmentIdKey) as? Int
        segmentCode = aDecoder.decodeObjectForKey(PropertyKey.segmentCodeKey) as? String
        legNo = aDecoder.decodeObjectForKey(PropertyKey.legNoKey) as? Int
        departureTime  = aDecoder.decodeObjectForKey(PropertyKey.departureTimeKey) as? NSDate
        departureLocation = aDecoder.decodeObjectForKey(PropertyKey.departureLocationKey) as? String
        departureStop = aDecoder.decodeObjectForKey(PropertyKey.departureStopKey) as? String
        departureAddress = aDecoder.decodeObjectForKey(PropertyKey.departureAddressKey) as? String
        departureTimeZone = aDecoder.decodeObjectForKey(PropertyKey.departureTimeZoneKey) as? String
        departureCoordinates = aDecoder.decodeObjectForKey(PropertyKey.departureCoordinatesKey) as? String
        departureTerminalCode = aDecoder.decodeObjectForKey(PropertyKey.departureTerminalCodeKey) as? String
        departureTerminalName = aDecoder.decodeObjectForKey(PropertyKey.departureTerminalNameKey) as? String
        arrivalTime = aDecoder.decodeObjectForKey(PropertyKey.arrivalTimeKey) as? NSDate
        arrivalLocation = aDecoder.decodeObjectForKey(PropertyKey.arrivalLocationKey) as? String
        arrivalStop = aDecoder.decodeObjectForKey(PropertyKey.arrivalStopKey) as? String
        arrivalAddress = aDecoder.decodeObjectForKey(PropertyKey.arrivalAddressKey) as? String
        arrivalTimeZone = aDecoder.decodeObjectForKey(PropertyKey.arrivalTimeZoneKey) as? String
        arrivalCoordinates = aDecoder.decodeObjectForKey(PropertyKey.arrivalCoordinatesKey) as? String
        arrivalTerminalCode = aDecoder.decodeObjectForKey(PropertyKey.arrivalTerminalCodeKey) as? String
        arrivalTerminalName = aDecoder.decodeObjectForKey(PropertyKey.arrivalTerminalNameKey) as? String
        routeNo = aDecoder.decodeObjectForKey(PropertyKey.routeNoKey) as? String
        companyName = aDecoder.decodeObjectForKey(PropertyKey.companyNameKey) as? String
        companyPhone = aDecoder.decodeObjectForKey(PropertyKey.companyPhoneKey) as? String
    }
    
    
    required init?(fromDictionary elementData: NSDictionary!) {
        super.init(fromDictionary: elementData)
        segmentId = elementData["segmentId"] as? Int
        segmentCode = elementData["segmentCode"] as? String
        legNo = elementData["legNo"] as? Int
        departureLocation = elementData["departureLocation"] as? String
        departureStop = elementData["departureStop"] as? String
        departureAddress = elementData["departureAddress"] as? String
        departureTimeZone = elementData["departureTimezone"] as? String
        if let departureTimeText = elementData["departureTime"] as? String {
            departureTime = ServerDate.convertServerDate(departureTimeText, timeZoneName: departureTimeZone)
        }
        departureCoordinates = elementData["departureCoordinates"] as? String
        departureTerminalCode = elementData["departureTerminalCode"] as? String
        departureTerminalName = elementData["departureTerminalName"] as? String
        
        arrivalLocation = elementData["arrivalLocation"] as? String
        arrivalStop = elementData["arrivalStop"] as? String
        arrivalAddress = elementData["arrivalAddress"] as? String
        arrivalTimeZone = elementData["arrivalTimezone"] as? String
        if let arrivalTimeText = elementData["arrivalTime"] as? String {
            arrivalTime = ServerDate.convertServerDate(arrivalTimeText, timeZoneName: arrivalTimeZone)
        }
        arrivalCoordinates = elementData["arrivalCoordinates"] as? String
        arrivalTerminalCode = elementData["arrivalTerminalCode"] as? String
        arrivalTerminalName = elementData["arrivalTerminalName"] as? String
        
        routeNo = elementData["routeNo"] as? String
        companyName = elementData["company"] as? String
        companyPhone = elementData["companyPhone"] as? String
    }

    
    // MARK: Methods
    override func startTime(dateStyle dateStyle: NSDateFormatterStyle, timeStyle: NSDateFormatterStyle) -> String? {
        if let departureTime = departureTime {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = dateStyle
            dateFormatter.timeStyle = timeStyle
            if let timeZoneName = departureTimeZone {
                let timezone = NSTimeZone(name: timeZoneName)
                if timezone != nil {
                    dateFormatter.timeZone = timezone
                }
            }
        
            return dateFormatter.stringFromDate(departureTime)
        }
        return nil
    }

    override func endTime(dateStyle dateStyle: NSDateFormatterStyle, timeStyle: NSDateFormatterStyle) -> String? {
        if let arrivalTime = arrivalTime {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = dateStyle
            dateFormatter.timeStyle = timeStyle
            if let timeZoneName = arrivalTimeZone {
                let timezone = NSTimeZone(name: timeZoneName)
                if timezone != nil {
                    dateFormatter.timeZone = timezone
                }
            }

            return dateFormatter.stringFromDate(arrivalTime)
        }
        return nil
    }
    
    override func setNotification() {
        // First delete any existing notifications for this trip element (either one or two)
        for notification in UIApplication.sharedApplication().scheduledLocalNotifications! as [UILocalNotification] {
            if (notification.userInfo!["TripElementID"] as? Int == id) {
                UIApplication.sharedApplication().cancelLocalNotification(notification)
            }
        }
        
        // Set notification (if we have a start date)
        if let tripStart = startTime {
            if tense == .future {
                let defaults = NSUserDefaults.standardUserDefaults()
                let departureLeadtime = Int(defaults.floatForKey("dept_notification_leadtime"))
                let legLeadtime = Int(defaults.floatForKey("leg_notification_leadtime"))
                let startTimeText = startTime(dateStyle: .NoStyle, timeStyle: .ShortStyle)
                let now = NSDate()
                let dcf = NSDateComponentsFormatter()
                let genericAlertMessage = NSLocalizedString("%@ departs in %@, at %@", comment: "Some dummy comment")

                dcf.unitsStyle = .Short
                dcf.zeroFormattingBehavior = .DropAll

                var userInfo: [String:NSObject] = ["TripElementID": id]
                if let departureTimeZone = departureTimeZone {
                    userInfo["TimeZone"] = departureTimeZone
                }


                if (departureLeadtime ?? -1) > 0 && (legNo ?? 1) == 1 {
                    var alertTime = tripStart.addMinutes( -departureLeadtime )
                    // If we're already past the warning time, set a notification for right now instead
                    if alertTime.isLessThanDate(now) {
                        alertTime = now
                    }
                    let notification = UILocalNotification()
                    
                    let actualLeadTime = tripStart.timeIntervalSinceDate(alertTime)
                    let leadTimeText = dcf.stringFromTimeInterval(actualLeadTime)
                    //notification.alertBody = "\(title!) departs in \(leadTimeText!), at \(startTimeText!)"
                    notification.alertBody = NSString.localizedStringWithFormat(genericAlertMessage, title!, leadTimeText!, startTimeText!) as String
                    //notification.alertAction = "open" // text that is displayed after "slide to..." on the lock screen - defaults to "slide to view"
                    notification.fireDate = alertTime
                    notification.soundName = UILocalNotificationDefaultSoundName
                    notification.userInfo = userInfo
                    notification.category = "SHiT"
                    UIApplication.sharedApplication().scheduleLocalNotification(notification)
                }
                setLegNotification: if (legLeadtime ?? -1) > 0 {
                    var alertTime = tripStart.addMinutes( -legLeadtime )
                    // If we're already past the warning time, set a notification for right now instead
                    // unless it's the first leg, in which case we already have one from above
                    if alertTime.isLessThanDate(now) {
                        if (legNo ?? 1) == 1 {
                            break setLegNotification
                        } else {
                            alertTime = now
                        }
                    }
                    let notification = UILocalNotification()
                    
                    let actualLeadTime = tripStart.timeIntervalSinceDate(alertTime)
                    let leadTimeText = dcf.stringFromTimeInterval(actualLeadTime)

                    notification.alertBody = NSString.localizedStringWithFormat(genericAlertMessage, title!, leadTimeText!, startTimeText!) as String
                    //"\(title!) departs in \(leadTimeText!), at \(startTimeText!)"
                    //notification.alertAction = "open" // text that is displayed after "slide to..." on the lock screen - defaults to "slide to view"
                    notification.fireDate = alertTime
                    notification.soundName = UILocalNotificationDefaultSoundName
                    notification.userInfo = userInfo
                    notification.category = "SHiT"
                    UIApplication.sharedApplication().scheduleLocalNotification(notification)
                }
            }
        }
    }
}