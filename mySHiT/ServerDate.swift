//
//  ServerDate.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-20.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation
import Synchronization
import os

class ServerDate {
    typealias DayHourMinute = (days:Int, hours:Int, minutes:Int)
    
    static let dateFormats:[String:String] = [
        "^[0-9]{4}-[0-9]{2}-[0-9]{2}$": "yyyy-MM-dd" ,
        "^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$": "yyyy-MM-dd HH:mm:ss" ,
        "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}$": "yyyy-MM-dd'T'HH:mm:ss"
    ]
    static let dateFormatter = Mutex<DateFormatter>(DateFormatter())
    static let isoFormatter = Mutex<ISO8601DateFormatter>(ISO8601DateFormatter())
    static let defaultLocale = Locale(identifier: "en_US_POSIX")

    static let semaphore = DispatchSemaphore(value: 1)

    class func findFormatString (_ serverDateString: String) -> String? {
        for (pattern, format) in dateFormats {
            if let _ = serverDateString.range(of: pattern, options: .regularExpression) {
                return format
            }
        }
        return nil
    }
    
    
    class func convertServerDate (_ serverDateString: String?, timeZoneName: String?) -> Date? {
        var timeZone:TimeZone?
        if let timeZoneName = timeZoneName {
            timeZone = TimeZone(identifier: timeZoneName)
        }
        return convertServerDate(serverDateString, timeZone: timeZone)
    }

    
    class func convertServerDate (_ serverDateString: String?, timeZone: TimeZone?) -> Date? {
        if let serverDateString = serverDateString {
            if let formatString = findFormatString(serverDateString) {
                var result:Date?
                dateFormatter.withLock {
                    if let timeZone = timeZone {
                        $0.timeZone = timeZone
                    } else {
                        $0.timeZone = Constant.timezoneUTC
                        os_log("Using default time zone for timestamp '%{public}s'", log: OSLog.general, type: .info, serverDateString)
                    }
                    $0.dateFormat = formatString
                    $0.locale = defaultLocale
                    result = $0.date(from: serverDateString)
                }
                /*semaphore.wait()
                    if let timeZone = timeZone {
                        dateFormatter.timeZone = timeZone
                    } else {
                        dateFormatter.timeZone = Constant.timezoneUTC
                        os_log("Using default time zone for timestamp '%{public}s'", log: OSLog.general, type: .info, serverDateString)
                    }
                    dateFormatter.dateFormat = formatString
                    dateFormatter.locale = defaultLocale
                    result = dateFormatter.date(from: serverDateString)
                semaphore.signal()*/
                return result
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    
    class func convertServerDate (_ localDate: Date, timeZone: TimeZone?) -> String {
        /*semaphore.wait()
            isoFormatter.formatOptions = [ .withFullDate, .withTime, .withColonSeparatorInTime, .withDashSeparatorInDate, .withSpaceBetweenDateAndTime ]
            isoFormatter.timeZone = timeZone
            let result = isoFormatter.string(from: localDate)
        semaphore.signal()*/
        isoFormatter.withLock {
            $0.formatOptions = [ .withFullDate, .withTime, .withColonSeparatorInTime, .withDashSeparatorInDate, .withSpaceBetweenDateAndTime ]
            $0.timeZone = timeZone
            return $0.string(from: localDate)
        }
//        return result
    }
}
