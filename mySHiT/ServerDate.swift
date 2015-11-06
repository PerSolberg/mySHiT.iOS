//
//  ServerDate.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-20.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation

class ServerDate {
    typealias DayHourMinute = (days:Int, hours:Int, minutes:Int)
    
    static let dateFormats:[String:String] = [
        "^[0-9]{4}-[0-9]{2}-[0-9]{2}$": "yyyy-MM-dd" ,
        "^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$": "yyyy-MM-dd HH:mm:ss" ,
        "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}$": "yyyy-MM-dd'T'HH:mm:ss"
    ]
    static var dateFormatter = NSDateFormatter()
    
    class func findFormatString (serverDateString: String) -> String? {
        for (pattern, format) in dateFormats {
            if let _ = serverDateString.rangeOfString(pattern, options: .RegularExpressionSearch) {
                return format
            }
        }
        return nil
    }
    
    class func convertServerDate (serverDateString: String, timeZoneName: String?) -> NSDate? {
        if let formatString = findFormatString(serverDateString) {
            if let timeZoneName = timeZoneName {
                let timezone = NSTimeZone(name: timeZoneName)
                if timezone != nil {
                    dateFormatter.timeZone = timezone
                }
            }
            let locale = NSLocale(localeIdentifier: "en_US_POSIX")
            dateFormatter.dateFormat = formatString
            dateFormatter.locale = locale
            return dateFormatter.dateFromString(serverDateString)
        } else {
            return nil
        }
    }
}