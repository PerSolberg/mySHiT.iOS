//
//  NSDate+mySHiT.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-18.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation
extension Date
{
    func isGreaterThanDate(_ dateToCompare : Date) -> Bool
    {
        return self.compare(dateToCompare) == ComparisonResult.orderedDescending
//        var isGreater = false
//
//        if self.compare(dateToCompare) == ComparisonResult.orderedDescending
//        {
//            isGreater = true
//        }
//
//        return isGreater
    }
    
    
    func isLessThanDate(_ dateToCompare : Date) -> Bool
    {
        return self.compare(dateToCompare) == ComparisonResult.orderedAscending

//        var isLess = false
//
//        if self.compare(dateToCompare) == ComparisonResult.orderedAscending
//        {
//            isLess = true
//        }
//
//        return isLess
    }

    func addDays(_ daysToAdd : Int) -> Date
    {
        let secondsInDays : TimeInterval = Double(daysToAdd) * 60 * 60 * 24
        let dateWithDaysAdded : Date = self.addingTimeInterval(secondsInDays)
        
        return dateWithDaysAdded
    }

    func addHours(_ hoursToAdd : Int) -> Date
    {
        let secondsInHours : TimeInterval = Double(hoursToAdd) * 60 * 60
        let dateWithHoursAdded : Date = self.addingTimeInterval(secondsInHours)
        
        return dateWithHoursAdded
    }

    func addMinutes(_ minutesToAdd : Int) -> Date
    {
        let secondsInMinutes : TimeInterval = Double(minutesToAdd) * 60
        let dateWithMinutesAdded : Date = self.addingTimeInterval(secondsInMinutes)
        
        return dateWithMinutesAdded
    }

    func addSeconds(_ secondsToAdd : Int) -> Date
    {
        let seconds : TimeInterval = Double(secondsToAdd)
        let dateWithSecondsAdded : Date = self.addingTimeInterval(seconds)
        
        return dateWithSecondsAdded
    }
}
