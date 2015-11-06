//
//  Trip.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-21.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation
import UIKit

class Trip: NSObject, NSCoding {
    var id: Int!
    var startDate: NSDate?
    var endDate: NSDate?
    var tripDescription: String?
    var code: String?
    var name: String?
    var type: String?
    var elements: [AnnotatedTripElement]?
    
    var startTime: NSDate? {
        return startDate
    }
    var endTime: NSDate? {
        return endDate
    }
    var title: String? {
        return name
    }
    var dateInfo: String? {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
        
        return dateFormatter.stringFromDate(startDate!) + " - " + dateFormatter.stringFromDate(endDate!)
    }
    var detailInfo: String? {
        return tripDescription
    }
    var tense: Tenses? {
        if let startTime = self.startTime {
            let today = NSDate()
            // If end time isn't set, assume duration of 1 day
            let endTime = self.endTime ?? startTime.addDays(1)
            
            if today.isGreaterThanDate(endTime) {
                return .past
            } else if today.isLessThanDate(startTime) {
                return .future
            } else {
                return .present
            }
        } else {
            return nil
        }
    }
    var icon: UIImage? {
        let basePath = "trip/"
        
        var path: String! = basePath
        switch tense! {
        case .past:
            path = basePath + "historic/"
        case .present:
            path = basePath + "active/"
        case .future:
            path = basePath
        }
        var imageName = path + type!
        
        // First try exact match
        if let image = UIImage(named: imageName) {
            return image
        }
        
        // Try default variant for trip type
        imageName = basePath + type!
        if let image = UIImage(named: imageName) {
            return image
        }
        
        // Try dummy image
        imageName = basePath + "UNKNOWN"
        if let image = UIImage(named: imageName) {
            return image
        }

        return nil
    }
    
    struct PropertyKey {
        static let idKey = "id"
        static let startDateKey = "startDate"
        static let endDateKey = "endDate"
        static let tripDescriptionKey = "description"
        static let codeKey = "code"
        static let nameKey = "name"
        static let typeKey = "type"
        static let elementsKey = "elements"
    }

    static let webServiceRootPath = "trip/code/"
    var rsRequest: RSTransactionRequest = RSTransactionRequest()
    var rsTransGetTripList: RSTransaction = RSTransaction(transactionType: RSTransactionType.GET, baseURL: "https://www.shitt.no/mySHiT", path: webServiceRootPath, parameters: ["userName":"dummy@default.com","password":"******"])

    // MARK: Factory
    class func createFromDictionary( elementData: NSDictionary! ) -> Trip? {
        let tripType = elementData["type"] as? String ?? ""
        
        var trip: Trip?
        switch (tripType) {
        case (_):
            trip = Trip(fromDictionary: elementData)
        default:
            trip = Trip(fromDictionary: elementData)
        }
        
        return trip
    }
    
    
    // MARK: NSCoding
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInteger(id, forKey: PropertyKey.idKey)
        aCoder.encodeObject(startDate, forKey: PropertyKey.startDateKey)
        aCoder.encodeObject(endDate, forKey: PropertyKey.endDateKey)
        aCoder.encodeObject(tripDescription, forKey: PropertyKey.tripDescriptionKey)
        aCoder.encodeObject(code, forKey: PropertyKey.codeKey)
        aCoder.encodeObject(name, forKey: PropertyKey.nameKey)
        aCoder.encodeObject(type, forKey: PropertyKey.typeKey)
        aCoder.encodeObject(elements, forKey: PropertyKey.elementsKey)
    }

    
    // MARK: Initialisers
    required init?(coder aDecoder: NSCoder) {
        super.init()
        // NB: use conditional cast (as?) for any optional properties
        id  = aDecoder.decodeIntegerForKey(PropertyKey.idKey)
        startDate  = aDecoder.decodeObjectForKey(PropertyKey.startDateKey) as? NSDate
        endDate  = aDecoder.decodeObjectForKey(PropertyKey.endDateKey) as? NSDate
        tripDescription  = aDecoder.decodeObjectForKey(PropertyKey.tripDescriptionKey) as? String
        code  = aDecoder.decodeObjectForKey(PropertyKey.codeKey) as? String
        name  = aDecoder.decodeObjectForKey(PropertyKey.nameKey) as? String
        type  = aDecoder.decodeObjectForKey(PropertyKey.typeKey) as? String
        elements  = aDecoder.decodeObjectForKey(PropertyKey.elementsKey) as? [AnnotatedTripElement]
        
        setNotification()
    }
    
    
    required init?(fromDictionary elementData: NSDictionary!) {
        super.init()
        id = elementData["id"] as! Int
        startDate = ServerDate.convertServerDate(elementData["startDate"] as! String, timeZoneName: nil)
        endDate = ServerDate.convertServerDate(elementData["endDate"] as! String, timeZoneName: nil)
        tripDescription = elementData["description"] as? String
        code = elementData["code"] as? String
        name = elementData["name"] as? String
        type = elementData["type"] as? String
        //elements = elementData["elements"] as? NSArray
        if let tripElements = elementData["elements"] as? NSArray {
            elements = [AnnotatedTripElement]()
            for svrElement in tripElements {
                if let tripElement = TripElement.createFromDictionary(svrElement as! NSDictionary) {
                    elements!.append( AnnotatedTripElement(tripElement: tripElement)! )
                }
            }
        }
        
        setNotification()
    }
    

    func setNotification() {
        // First delete any existing notifications for this trip
        for notification in UIApplication.sharedApplication().scheduledLocalNotifications! as [UILocalNotification] {
            if (notification.userInfo!["TripID"] as? Int == id) {
                UIApplication.sharedApplication().cancelLocalNotification(notification)
                // there should be a maximum of one match on TripID
                break
            }
        }

        // Set notification (if we have a start date)
        if let tripStart = startTime {
            if tense == .future {
                let now = NSDate()
                var alertTime = tripStart.addHours(-6)
                // If we're already past the early warning, set a new alert for actual start
                if alertTime.isLessThanDate(now) {
                    alertTime = tripStart
                }
                let notification = UILocalNotification()
            
                notification.alertBody = "SHiT trip '\(name!)' starts in 6 hours"
                //notification.alertAction = "open" // text that is displayed after "slide to..." on the lock screen - defaults to "slide to view"
                notification.fireDate = alertTime // todo item due date (when notification will be fired)
                notification.soundName = UILocalNotificationDefaultSoundName // play default sound
                notification.userInfo = ["TripID": id] // assign a unique identifier
                notification.category = "SHiT"
                UIApplication.sharedApplication().scheduleLocalNotification(notification)
            }
        }
    }
    
    func loadDetails() {
        let userCred = User.sharedUser.getCredentials()
        
        assert( userCred.name != nil );
        assert( userCred.password != nil );
        assert( userCred.urlsafePassword != nil );
        
        //Set the parameters for the RSTransaction object
        rsTransGetTripList.path = self.dynamicType.webServiceRootPath + code!
        rsTransGetTripList.parameters = [ "userName":userCred.name!,
            "password":userCred.urlsafePassword! ]
        
        //Send request
        rsRequest.dictionaryFromRSTransaction(rsTransGetTripList, completionHandler: {(response : NSURLResponse!, responseDictionary: NSDictionary!, error: NSError!) -> Void in
            if let error = error {
                //If there was an error, log it
                print("Error : \(error.description)")
            } else if let error = responseDictionary["error"] {
                let errMsg = error as! String
                print("Error : \(errMsg)")
            } else {
                //Set the tableData NSArray to the results returned from www.shitt.no
                print("Trip details retrieved from server")
                if let tripsFound = responseDictionary["count"] as? Int {
                    if tripsFound != 1 {
                        print("ERROR: Found \(tripsFound) for trip code \(self.code)")
                    }
                    else {
                        let serverData = (responseDictionary["results"] as! NSArray)[0] as! NSDictionary
                        if let newTrip = Trip.createFromDictionary(serverData) {
                            self.id              = newTrip.id
                            self.startDate       = newTrip.startDate
                            self.endDate         = newTrip.endDate
                            self.tripDescription = newTrip.tripDescription
                            self.code            = newTrip.code
                            self.name            = newTrip.name
                            self.type            = newTrip.type
                            self.elements        = newTrip.elements
                        }

                        //let tripName = serverData["name"] as! String
                        //let srvElementList = serverData["elements"] as? NSArray ?? NSArray()
                        //self.copyServerData(srvElementList)
                        NSNotificationCenter.defaultCenter().postNotificationName("dataRefreshed", object: self)
                        /*
                        dispatch_async(dispatch_get_main_queue(), {
                            self.title = tripName
                            self.tripDetailsTable.reloadData()
                        })
                        */
                    }
                } else {
                    print("ERROR: Didn't find expected elements in dictionary: \(responseDictionary)")
                }
            }
        })
    }
}