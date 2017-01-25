//
//  Trip.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-21.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation
import UIKit
import FirebaseMessaging

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class Trip: NSObject, NSCoding {
    var id: Int!
    var itineraryId: Int?
    var startDate: Date?
    var endDate: Date?
    var tripDescription: String?
    var code: String?
    var name: String?
    var type: String?
    var elements: [AnnotatedTripElement]?
    
    var startTime: Date? {
        return startDate
    }
    var startTimeZone: String? {
        if elements != nil && elements?.count > 0 {
            return elements![0].tripElement.startTimeZone
        }
        return nil
    }
    var endTime: Date? {
        return endDate
    }
    var title: String? {
        return name
    }
    var dateInfo: String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeStyle = DateFormatter.Style.none
        
        return dateFormatter.string(from: startDate!) + " - " + dateFormatter.string(from: endDate!)
    }
    var detailInfo: String? {
        return tripDescription
    }
    var tense: Tenses? {
        if let startTime = self.startTime {
            let today = Date()
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
        static let itineraryIdKey = "itineraryId"
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
    var rsTransGetTripList: RSTransaction = RSTransaction(transactionType: RSTransactionType.get, baseURL: "https://www.shitt.no/mySHiT", path: webServiceRootPath, parameters: ["userName":"dummy@default.com","password":"******"])

    // MARK: Factory
    class func createFromDictionary( _ elementData: NSDictionary! ) -> Trip? {
        //let tripType = elementData["type"] as? String ?? ""
        
        var trip: Trip?
        trip = Trip(fromDictionary: elementData)
        /*
        switch (tripType) {
        case (_):
            trip = Trip(fromDictionary: elementData)
        default:
            trip = Trip(fromDictionary: elementData)
        }
        */
        
        return trip
    }
    
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: PropertyKey.idKey)
        aCoder.encode(itineraryId, forKey: PropertyKey.itineraryIdKey)
        aCoder.encode(startDate, forKey: PropertyKey.startDateKey)
        aCoder.encode(endDate, forKey: PropertyKey.endDateKey)
        aCoder.encode(tripDescription, forKey: PropertyKey.tripDescriptionKey)
        aCoder.encode(code, forKey: PropertyKey.codeKey)
        aCoder.encode(name, forKey: PropertyKey.nameKey)
        aCoder.encode(type, forKey: PropertyKey.typeKey)
        aCoder.encode(elements, forKey: PropertyKey.elementsKey)
    }

    
    // MARK: Initialisers
    required init?(coder aDecoder: NSCoder) {
        super.init()
        // NB: use conditional cast (as?) for any optional properties
        //id = aDecoder.decodeInteger(forKey: PropertyKey.idKey)
        id = aDecoder.decodeObject(forKey: PropertyKey.idKey) as? Int ?? aDecoder.decodeInteger(forKey: PropertyKey.idKey)
        itineraryId = aDecoder.decodeObject(forKey: PropertyKey.itineraryIdKey) as? Int? ?? aDecoder.decodeInteger(forKey: PropertyKey.itineraryIdKey)
        startDate  = aDecoder.decodeObject(forKey: PropertyKey.startDateKey) as? Date
        endDate  = aDecoder.decodeObject(forKey: PropertyKey.endDateKey) as? Date
        tripDescription  = aDecoder.decodeObject(forKey: PropertyKey.tripDescriptionKey) as? String
        code  = aDecoder.decodeObject(forKey: PropertyKey.codeKey) as? String
        name  = aDecoder.decodeObject(forKey: PropertyKey.nameKey) as? String
        type  = aDecoder.decodeObject(forKey: PropertyKey.typeKey) as? String
        elements  = aDecoder.decodeObject(forKey: PropertyKey.elementsKey) as? [AnnotatedTripElement]
        
        setNotification()
    }
    
    
    required init?(fromDictionary elementData: NSDictionary!) {
        super.init()
        id = elementData[Constant.JSON.tripId] as! Int  // "id"
        itineraryId = elementData[Constant.JSON.tripItineraryId] as? Int
        startDate = ServerDate.convertServerDate(elementData[Constant.JSON.tripStartDate] as! String, timeZoneName: nil)
        endDate = ServerDate.convertServerDate(elementData[Constant.JSON.tripEndDate] as! String, timeZoneName: nil)
        tripDescription = elementData[Constant.JSON.tripDescription] as? String
        code = elementData[Constant.JSON.tripCode] as? String
        name = elementData[Constant.JSON.tripName] as? String
        type = elementData[Constant.JSON.tripType] as? String
        //elements = elementData["elements"] as? NSArray
        if let tripElements = elementData[Constant.JSON.tripElements] as? NSArray {
            elements = [AnnotatedTripElement]()
            for svrElement in tripElements {
                if let tripElement = TripElement.createFromDictionary(svrElement as! NSDictionary) {
                    elements!.append( AnnotatedTripElement(tripElement: tripElement)! )
                }
            }
        }
        
        setNotification()
    }
    

    // MARK: Methods
    override func isEqual(_ object: Any?) -> Bool {
        //print("Comparing objects: self.class = \(object_getClassName(self)), object.class = \(object_getClassName(object!))")
        //print("Comparing objects: self.class = \(_stdlib_getDemangledTypeName(self)), object.class = \(_stdlib_getDemangledTypeName(object!))")
        if object_getClassName(self) != object_getClassName(object) {
            return false
        } else if let otherTrip = object as? Trip {
            if self.id              != otherTrip.id              { return false }
            if self.itineraryId     != otherTrip.itineraryId     { return false }
            if self.startDate       != otherTrip.startDate       { return false }
            if self.endDate         != otherTrip.endDate         { return false }
            if self.tripDescription != otherTrip.tripDescription { return false }
            if self.code            != otherTrip.code            { return false }
            if self.name            != otherTrip.name            { return false }
            if self.type            != otherTrip.type            { return false }
            if let elements = elements {
                for e in elements {
                    if (e.modified == .New || e.modified == .Changed) { return false }
                }
            }
            return true
        } else {
            return false
        }
    }


    func compareTripElements(_ otherTrip: Trip) {
        if elements == nil || otherTrip.elements == nil {
            return
        }

        // Determine changes
        for element in elements! {
            let matchingOtherElements = otherTrip.elements!.filter( { (e:AnnotatedTripElement) -> Bool in
                    return e.tripElement.id == element.tripElement.id
                })
            if matchingOtherElements.isEmpty {
                element.modified = .New
            } else {
                if !element.tripElement.isEqual(matchingOtherElements[0].tripElement) {
                    element.modified = .Changed
                } else {
                    element.modified = matchingOtherElements[0].modified;
                }
            }
        }
    }


    func changes() -> Int {
        var changes = 0
        if let elements = elements {
            for element in elements {
                if element.modified != .Unchanged {
                    changes += 1
                }
            }
        }
        return changes
    }


    func startTime(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String? {
        if let departureTime = startTime {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = dateStyle
            dateFormatter.timeStyle = timeStyle
            //if let timeZoneName = departureTimeZone {
            if let timeZoneName = startTimeZone {
                let timezone = TimeZone(identifier: timeZoneName)
                if timezone != nil {
                    dateFormatter.timeZone = timezone
                }
            }
            
            return dateFormatter.string(from: departureTime)
        }
        return nil
    }
    

    func setNotification() {
        // First delete any existing notifications for this trip
        for notification in UIApplication.shared.scheduledLocalNotifications! as [UILocalNotification] {
            if (notification.userInfo!["TripID"] as? Int == id) {
                UIApplication.shared.cancelLocalNotification(notification)
                // there should be a maximum of one match on TripID
                break
            }
        }

        // Set notification (if we have a start date)
        if let tripStart = startTime {
            if tense == .future {
                let defaults = UserDefaults.standard
                let tripLeadtime = Int(defaults.float(forKey: "trip_notification_leadtime"))
                let startTimeText = startTime(dateStyle: .short, timeStyle: .short)
                let now = Date()
                let dcf = DateComponentsFormatter()
                let genericAlertMessage = NSLocalizedString(Constant.msg.tripAlertMessage, comment: "Some dummy comment")
                
                dcf.unitsStyle = .short
                dcf.zeroFormattingBehavior = .dropAll
                
                var userInfo: [String:NSObject] = ["TripID": id as NSObject]
                if let startTimeZone = startTimeZone {
                    userInfo["TimeZone"] = startTimeZone as NSObject?
                }
                
                if tripLeadtime > 0 {
                    var alertTime = tripStart.addHours( -tripLeadtime )
                    // If we're already past the warning time, set a notification for right now instead
                    if alertTime.isLessThanDate(now) {
                        alertTime = now
                    }
                    let notification = UILocalNotification()
                    
                    let actualLeadTime = tripStart.timeIntervalSince(alertTime)
                    let leadTimeText = dcf.string(from: actualLeadTime)
                    //notification.alertBody = NSString.localizedStringWithFormat(genericAlertMessage, title!, leadTimeText!, startTimeText!) as String
                    notification.alertBody = String.localizedStringWithFormat(genericAlertMessage, title!, leadTimeText!, startTimeText!) as String
                    notification.fireDate = alertTime
                    notification.soundName = UILocalNotificationDefaultSoundName
                    notification.userInfo = userInfo
                    notification.category = "SHiT"
                    UIApplication.shared.scheduleLocalNotification(notification)
                }
            }
        }
    }

    func refreshNotifications() {
        setNotification()
        if let elements = elements {
            for e in elements {
                e.tripElement.setNotification()
            }
        }
    }
    
    func loadDetails() {
        let userCred = User.sharedUser.getCredentials()
        
        assert( userCred.name != nil );
        assert( userCred.password != nil );
        assert( userCred.urlsafePassword != nil );
        
        //Set the parameters for the RSTransaction object
        rsTransGetTripList.path = type(of: self).webServiceRootPath + code!
        rsTransGetTripList.parameters = [ "userName":userCred.name!,
            "password":userCred.urlsafePassword! ]
        
        //Send request
        rsRequest.dictionaryFromRSTransaction(rsTransGetTripList, completionHandler: {(response : URLResponse?, responseDictionary: NSDictionary?, error: Error?) -> Void in
            if let error = error {
                //If there was an error, log it
                print("Error : \(error.localizedDescription)")
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.networkError), object: self)
            } else if let error = responseDictionary?[Constant.JSON.queryError] {
                let errMsg = error as! String
                print("Error : \(errMsg)")
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.networkError), object: self)
            } else {
                //Set the tableData NSArray to the results returned from www.shitt.no
                print("Trip details retrieved from server")
                if let tripsFound = responseDictionary?[Constant.JSON.queryCount] as? Int {
                    if tripsFound != 1 {
                        print("ERROR: Found \(tripsFound) for trip code \(self.code)")
                    }
                    else {
                        let serverData = (responseDictionary?[Constant.JSON.queryResults] as! NSArray)[0] as! NSDictionary
                        if let newTrip = Trip.createFromDictionary(serverData) {
                            newTrip.compareTripElements(self)
                            self.id              = newTrip.id
                            self.itineraryId     = newTrip.itineraryId
                            self.startDate       = newTrip.startDate
                            self.endDate         = newTrip.endDate
                            self.tripDescription = newTrip.tripDescription
                            self.code            = newTrip.code
                            self.name            = newTrip.name
                            self.type            = newTrip.type
                            self.elements        = newTrip.elements
                            
                            UIApplication.shared.applicationIconBadgeNumber = TripList.sharedList.changes()
                        }

                        //let tripName = serverData["name"] as! String
                        //let srvElementList = serverData["elements"] as? NSArray ?? NSArray()
                        //self.copyServerData(srvElementList)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.tripElementsRefreshed), object: self)
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


    func deregisterPushNotifications() {
        let topicTrip = Constant.Firebase.topicRootTrip + String(id)
        //print("Unsubscribing from topic '\(topicTrip)")
        FIRMessaging.messaging().unsubscribe(fromTopic: topicTrip)
            
        if let itineraryId = itineraryId {
            let topicItinerary = Constant.Firebase.topicRootItinerary + String(itineraryId)
            //print("Unsubscribing from topic '\(topicItinerary)")
            FIRMessaging.messaging().unsubscribe(fromTopic: topicItinerary)
        }
    }

    
    func registerForPushNotifications() {
        let topicTrip = Constant.Firebase.topicRootTrip + String(id)
        //print("Subscribing to topic '\(topicTrip)")
        FIRMessaging.messaging().subscribe(toTopic: topicTrip)
            
        if let itineraryId = itineraryId {
            let topicItinerary = Constant.Firebase.topicRootItinerary + String(itineraryId)
            //print("Subscribing to topic '\(topicItinerary)")
            FIRMessaging.messaging().subscribe(toTopic: topicItinerary)
        }
    }
    

}
