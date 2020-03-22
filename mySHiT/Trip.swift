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
import UserNotifications
import os

class Trip: NSObject, NSCoding {
    var id: Int { willSet { checkChange(id, newValue) } }
    var itineraryId: Int? { willSet { checkChange(itineraryId, newValue) } }
    var startDate: Date? { willSet { checkChange(startDate, newValue) } }
    var endDate: Date? { willSet { checkChange(endDate, newValue) } }
    var tripDescription: String? { willSet { checkChange(tripDescription, newValue) } }
    var code: String? { willSet { checkChange(code, newValue) } }
    var name: String? { willSet { checkChange(name, newValue) } }
    var type: String? { willSet { checkChange(type, newValue) } }
    var elements: [AnnotatedTripElement]?
    var chatThread:ChatThread
    var lastUpdateTS:ServerTimestamp?
    
    var changed = false

    // Notifications created for this element (used to avoid recreating notifications after they have been triggered)
    var notifications = [ String: NotificationInfo ]()

    var startTime: Date? {
        return startDate
    }
    var startTimeZone: String? {
        if let elements = elements, elements.count > 0 {
            return elements[0].tripElement.startTimeZone
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
        static let chatThreadKey = "chatThread"
        static let notificationsKey = "notifications"
        static let lastUpdateTSKey = "lastUpdateTS"
    }

    var rsRequest: RSTransactionRequest = RSTransactionRequest()
    var rsTransGetTripList: RSTransaction = RSTransaction(transactionType: RSTransactionType.get, baseURL: Constant.REST.mySHiT.baseUrl, path: Constant.REST.mySHiT.Resource.trip, parameters: [:] )

    //
    // MARK: Factory
    //
    class func createFromDictionary( _ elementData: NSDictionary!, updateTS: ServerTimestamp ) -> Trip? {
        var trip: Trip?
        trip = Trip(fromDictionary: elementData, updateTS: updateTS)
        
        return trip
    }
    

    func checkChange<T:Equatable>(_ old: T, _ new: T) {
        changed = changed || (old != new)
    }
    
        
    //
    // MARK: NSCoding
    //
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
        aCoder.encode(chatThread, forKey: PropertyKey.chatThreadKey)
        aCoder.encode(notifications, forKey: PropertyKey.notificationsKey)
        aCoder.encode(lastUpdateTS, forKey: PropertyKey.lastUpdateTSKey)
    }


    //
    // MARK: Initialisers
    //
    required init?(coder aDecoder: NSCoder) {
        let id = aDecoder.decodeObject(forKey: PropertyKey.idKey) as? Int ?? aDecoder.decodeInteger(forKey: PropertyKey.idKey)
        self.id = id
        chatThread = (aDecoder.decodeObject(forKey: PropertyKey.chatThreadKey) as? ChatThread) ?? ChatThread(tripId: id)
        super.init()
        // NB: use conditional cast (as?) for any optional properties
        itineraryId = aDecoder.decodeObject(forKey: PropertyKey.itineraryIdKey) as? Int? ?? aDecoder.decodeInteger(forKey: PropertyKey.itineraryIdKey)
        startDate  = aDecoder.decodeObject(forKey: PropertyKey.startDateKey) as? Date
        endDate  = aDecoder.decodeObject(forKey: PropertyKey.endDateKey) as? Date
        tripDescription  = aDecoder.decodeObject(forKey: PropertyKey.tripDescriptionKey) as? String
        code  = aDecoder.decodeObject(forKey: PropertyKey.codeKey) as? String
        name  = aDecoder.decodeObject(forKey: PropertyKey.nameKey) as? String
        type  = aDecoder.decodeObject(forKey: PropertyKey.typeKey) as? String
        elements  = aDecoder.decodeObject(forKey: PropertyKey.elementsKey) as? [AnnotatedTripElement]
        notifications = aDecoder.decodeObject(forKey: PropertyKey.notificationsKey) as? [String:NotificationInfo] ?? [String:NotificationInfo]()

        lastUpdateTS = aDecoder.decodeObject(forKey: PropertyKey.lastUpdateTSKey) as? ServerTimestamp
        setNotification()
    }
    
    
    required init?(fromDictionary elementData: NSDictionary!, updateTS: ServerTimestamp) {
        let inputId = elementData[Constant.JSON.tripId] as? Int
        if inputId == nil {
            return nil
        }
        id = inputId!
        chatThread = ChatThread(tripId: id)
        super.init()

        lastUpdateTS = updateTS
        itineraryId = elementData[Constant.JSON.tripItineraryId] as? Int
        startDate = ServerDate.convertServerDate(elementData[Constant.JSON.tripStartDate] as? String, timeZoneName: nil)
        endDate = ServerDate.convertServerDate(elementData[Constant.JSON.tripEndDate] as? String, timeZoneName: nil)
        tripDescription = elementData[Constant.JSON.tripDescription] as? String
        code = elementData[Constant.JSON.tripCode] as? String
        name = elementData[Constant.JSON.tripName] as? String
        type = elementData[Constant.JSON.tripType] as? String

        if let tripElements = elementData[Constant.JSON.tripElements] as? NSArray {
            elements = [AnnotatedTripElement]()
            for svrElement in tripElements {
                if let tripElement = TripElement.createFromDictionary(svrElement as? NSDictionary) {
                    elements!.append( AnnotatedTripElement(tripElement: tripElement)! )
                }
            }
        }
    }
    

    //
    // MARK: Methods
    //
    func update(fromDictionary elementData: NSDictionary!, updateTS: ServerTimestamp) -> Bool {
        guard let dictId = elementData[Constant.JSON.tripId] as? Int else {
            os_log("Update error: Trip data doesn't have ID", log: OSLog.general, type: .error)
            return false
        }
        guard dictId == id else {
            os_log("Update error: Trip ID mismatch", log: OSLog.general, type: .error)
            return false
        }
        
        if let lastUpdateTS = lastUpdateTS, updateTS <= lastUpdateTS {
            // Old update - ignore
            return false
        }
        
        changed = false
        
        lastUpdateTS = updateTS
        itineraryId = elementData[Constant.JSON.tripItineraryId] as? Int
        startDate = ServerDate.convertServerDate(elementData[Constant.JSON.tripStartDate] as? String, timeZoneName: nil)
        endDate = ServerDate.convertServerDate(elementData[Constant.JSON.tripEndDate] as? String, timeZoneName: nil)
        tripDescription = elementData[Constant.JSON.tripDescription] as? String
        code = elementData[Constant.JSON.tripCode] as? String
        name = elementData[Constant.JSON.tripName] as? String
        type = elementData[Constant.JSON.tripType] as? String

        if let tripElements = elementData[Constant.JSON.tripElements] as? NSArray {
            changed = changed || updateElements(fromDictionary: tripElements)
        }

        if changed {
            setNotification()
        }

        return changed
    }
    
    
    func updateElements(fromDictionary elementList: NSArray!) -> Bool {
        // This function should only be called if we received details from the server
        if elements == nil {
            elements = [AnnotatedTripElement]()
        }

        var elementIDs:[Int] = []
        var added = false
        var changed = false
        
        // Add or update trips received from server
        for elementObj in elementList {
            if let elementDict = elementObj as? NSDictionary, let elementId = elementDict[Constant.JSON.elementId] as? Int {
                elementIDs.append(elementId)
                if let aElement = tripElement(byId: elementId) {
                    let elementChanged = aElement.tripElement.update(fromDictionary: elementDict)
                    aElement.modified = elementChanged ? .Changed : aElement.modified
                    changed = changed || elementChanged
                } else {
                    if let newElement = TripElement.createFromDictionary(elementDict) {
                        elements!.append( AnnotatedTripElement(tripElement: newElement)! )
                    }
                    added = true
                }
            } else {
                os_log("Element data is not dictionary or doesn't have ID", log: OSLog.general, type: .error)
            }
        }
        
        // Remove elements no longer in list
        for (ix, element) in elements!.reversed().enumerated() {
            if !elementIDs.contains(element.tripElement.id) {
                changed = true
                elements!.remove(at: ix)
            }
        }
        
        // If new elements were added, sort the list in same order as the server list
        if added {
            elements!.sort(by:{ elementIDs.firstIndex(of: $0.tripElement.id)! < elementIDs.firstIndex(of: $1.tripElement.id)! })
        }
        
        return changed
    }

    
    func isBefore(_ otherTrip: Trip!) -> Bool? {
        if let myStartTime = self.startTime, let otherStartTime = otherTrip.startTime {
            if myStartTime.isLessThanDate(otherStartTime) {
                return true
            } else if myStartTime.isGreaterThanDate(otherStartTime) {
                return false
            } else {
                if let myEndTime = self.endTime, let otherEndTime = otherTrip.endTime {
                    return myEndTime.isLessThanDate(otherEndTime)
                } else {
                    return nil
                }
            }
        } else {
            return nil
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
    
    
    func tripElement(byId tripElementId: Int) -> AnnotatedTripElement? {
        if let elements = elements {
            for te in elements {
                if te.tripElement.id == tripElementId {
                    return te
                }
            }
        }
        return nil
    }

    
    func setNotification() {
        // First delete any existing notifications for this trip
        let ntfIdentifier = Constant.Settings.tripLeadTime + String(id)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [ntfIdentifier])

        // Set notification (if we have a start date)
        if let tripStart = startTime {
            if tense == .future {
                let defaults = UserDefaults.standard
                let tripLeadtime = Int(defaults.float(forKey: Constant.Settings.tripLeadTime))
                let startTimeText = startTime(dateStyle: .short, timeStyle: .short)
                let dcf = DateComponentsFormatter()
                let genericAlertMessage = NSLocalizedString(Constant.msg.tripAlertMessage, comment: Constant.dummyLocalisationComment)
                
                dcf.unitsStyle = .short
                dcf.zeroFormattingBehavior = .dropAll
                
                var userInfo: UserInfo = [.tripId: id as NSObject]
                if let startTimeZone = startTimeZone {
                    userInfo[.timeZone] = startTimeZone as NSObject?
                }
                
                if tripLeadtime > 0 {
                    // NotificationInfo expects lead time to be minutes
                    let oldInfo = notifications[Constant.Settings.tripLeadTime]
                    let newInfo = NotificationInfo(baseDate: tripStart, leadTime: tripLeadtime * 60)

                    if (oldInfo == nil || oldInfo!.needsRefresh(newNotification: newInfo!)) {
                        os_log("Setting notification for trip %d at %s", log: OSLog.notification, type: .debug, id, String(describing: newInfo?.notificationDate))
                        userInfo[.leadTimeType] = Constant.Settings.tripLeadTime as NSObject?
                        
                        let actualLeadTime = tripStart.timeIntervalSince((newInfo?.notificationDate)!)
                        let leadTimeText = dcf.string(from: actualLeadTime)
                        
                        let ntfContent = UNMutableNotificationContent()
                        ntfContent.body = String.localizedStringWithFormat(genericAlertMessage, title!, leadTimeText!, startTimeText!) as String
                        ntfContent.sound = UNNotificationSound.default
                        ntfContent.userInfo = userInfo.securePropertyList()
                        ntfContent.categoryIdentifier = "SHiT"
                        
                        let ntfDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: (newInfo?.notificationDate)!)
                        
                        let ntfTrigger = UNCalendarNotificationTrigger(dateMatching: ntfDateComponents, repeats: false)
                        let notification = UNNotificationRequest(identifier: ntfIdentifier, content: ntfContent, trigger: ntfTrigger)
                        
                        UNUserNotificationCenter.current().add(notification) {(error) in
                            if let error = error {
                                os_log("Unable to schedule trip notification: %{public}s", log: OSLog.notification, type:.error, String(describing: error))
                            }
                        }

                        notifications[Constant.Settings.tripLeadTime] = newInfo
                    } else {
                        os_log("Not refreshing notification for trip %d, already triggered", log: OSLog.notification, type:.debug, id)
                    }
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
        rsTransGetTripList.path = Constant.REST.mySHiT.Resource.trip + "/" + code!
        rsTransGetTripList.parameters = [ "userName":userCred.name!,
            "password":userCred.urlsafePassword! ]
        
        //Send request
        rsRequest.dictionaryFromRSTransaction(rsTransGetTripList, completionHandler: {(response : URLResponse?, responseDictionary: NSDictionary?, error: Error?) -> Void in
            if let error = error {
                //If there was an error, log it
                print("Error : \(error.localizedDescription)")
                NotificationCenter.default.post(name: Constant.notification.networkError, object: self)
            } else if let error = responseDictionary?[Constant.JSON.queryError] {
                let errMsg = error as! String
                print("Error : \(errMsg)")
                NotificationCenter.default.post(name: Constant.notification.networkError, object: self)
            } else {
                //Set the tableData NSArray to the results returned from www.shitt.no
                if let tripsFound = responseDictionary?[Constant.JSON.queryCount] as? Int {
                    if tripsFound != 1 {
                        print("ERROR: Found \(tripsFound) trips for code \(String(describing: self.code))")
                    } else {
                        TripList.sharedList.update(fromDictionary: responseDictionary)

                        NotificationCenter.default.post(name: Constant.notification.dataRefreshed, object: self)
                    }
                } else {
                    print("ERROR: Didn't find expected elements in dictionary: \(String(describing: responseDictionary))")
                }
            }
        })
    }

    
    func refreshMessages() {
        chatThread.refresh(mode:.full)
    }

    
    func deregisterPushNotifications() {
        let topicTrip = Constant.Firebase.topicRootTrip + String(id)
        Messaging.messaging().unsubscribe(fromTopic: topicTrip)
            
        if let itineraryId = itineraryId {
            let topicItinerary = Constant.Firebase.topicRootItinerary + String(itineraryId)
            Messaging.messaging().unsubscribe(fromTopic: topicItinerary)
        }
    }

    
    func registerForPushNotifications() {
        let topicTrip = Constant.Firebase.topicRootTrip + String(id)
        Messaging.messaging().subscribe(toTopic: topicTrip)
            
        if let itineraryId = itineraryId {
            let topicItinerary = Constant.Firebase.topicRootItinerary + String(itineraryId)
            Messaging.messaging().subscribe(toTopic: topicItinerary)
        }
    }

}
