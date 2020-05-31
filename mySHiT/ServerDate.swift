//
//  ServerDate.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-20.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation
import os

class ServerDate {
    typealias DayHourMinute = (days:Int, hours:Int, minutes:Int)
    
    static let dateFormats:[String:String] = [
        "^[0-9]{4}-[0-9]{2}-[0-9]{2}$": "yyyy-MM-dd" ,
        "^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$": "yyyy-MM-dd HH:mm:ss" ,
        "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}$": "yyyy-MM-dd'T'HH:mm:ss"
    ]
    static var dateFormatter = DateFormatter()
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
                semaphore.wait()
                    if let timeZone = timeZone {
                        dateFormatter.timeZone = timeZone
                    } else {
                        dateFormatter.timeZone = Constant.timezoneUTC
                        os_log("Using default time zone for timestamp '%{public}s'", log: OSLog.general, type: .info, serverDateString)
                    }
                    dateFormatter.dateFormat = formatString
                    dateFormatter.locale = defaultLocale
                    result = dateFormatter.date(from: serverDateString)
                semaphore.signal()
                return result
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    
    class func convertServerDate (_ localDate: Date, timeZoneName: String?) -> String {
        var result:String?
        semaphore.wait()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateFormatter.locale = defaultLocale
            result = dateFormatter.string(from: localDate)
        semaphore.signal()
        return result!
    }

    
    class func convertServerDate (_ localDate: Date, timeZone: TimeZone?) -> String {
        var result:String?
        semaphore.wait()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateFormatter.locale = defaultLocale
            result = dateFormatter.string(from: localDate)
        semaphore.signal()
        return result!
    }
}
