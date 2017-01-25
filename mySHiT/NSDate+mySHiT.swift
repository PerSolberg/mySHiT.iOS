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
        //Declare Variables
        var isGreater = false
        
        //Compare Values
        if self.compare(dateToCompare) == ComparisonResult.orderedDescending
        {
            isGreater = true
        }
        
        //Return Result
        return isGreater
    }
    
    
    func isLessThanDate(_ dateToCompare : Date) -> Bool
    {
        //Declare Variables
        var isLess = false
        
        //Compare Values
        if self.compare(dateToCompare) == ComparisonResult.orderedAscending
        {
            isLess = true
        }
        
        //Return Result
        return isLess
    }

    func addDays(_ daysToAdd : Int) -> Date
    {
        let secondsInDays : TimeInterval = Double(daysToAdd) * 60 * 60 * 24
        let dateWithDaysAdded : Date = self.addingTimeInterval(secondsInDays)
        
        //Return Result
        return dateWithDaysAdded
    }

    func addHours(_ hoursToAdd : Int) -> Date
    {
        let secondsInHours : TimeInterval = Double(hoursToAdd) * 60 * 60
        let dateWithHoursAdded : Date = self.addingTimeInterval(secondsInHours)
        
        //Return Result
        return dateWithHoursAdded
    }

    func addMinutes(_ minutesToAdd : Int) -> Date
    {
        let secondsInMinutes : TimeInterval = Double(minutesToAdd) * 60
        let dateWithMinutesAdded : Date = self.addingTimeInterval(secondsInMinutes)
        
        //Return Result
        return dateWithMinutesAdded
    }

    func addSeconds(_ secondsToAdd : Int) -> Date
    {
        let seconds : TimeInterval = Double(secondsToAdd)
        let dateWithSecondsAdded : Date = self.addingTimeInterval(seconds)
        
        //Return Result
        return dateWithSecondsAdded
    }
}
