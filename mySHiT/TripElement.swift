//
//  TripElement.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-20.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications
import os

class TripElement: NSObject, NSCoding {
    static let RefTag_Type      = "type"
    static let RefTag_RefNo     = "refNo"
    static let RefTag_LookupURL = "urlLookup"
    
    static let MinimumNotificationSeparation : TimeInterval = 10 * 60  // Minutes between notifications for same trip element
    
    var type: String!
    var subType: String!
    var id: Int!
    var references: [ [String:String] ]?
    var serverData: NSDictionary?
    
//    var changedAttributes = Set<String>()
    
    // Notifications created for this element (used to avoid recreating notifications after they have been triggered)
    var notifications = [ String: NotificationInfo ]()
    
    var startTime: Date? {
        return nil
    }
    var startTimeZone: String? {
        return nil
    }
    var endTime: Date? {
        return nil
    }
    var endTimeZone: String? {
        return nil
    }
    var title: String? {
        return nil
    }
    var startInfo: String? {
        return nil
    }
    var endInfo: String? {
        return nil
    }
    var detailInfo: String? {
        return nil
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
        let basePath = "tripelement/"
        
        var iconName: String = "default"
        switch tense! {
        case .past:
            iconName = "historic"
        case .present:
            iconName = "active"
        default:
            break
        }
        
        var imageName = basePath + type! + "/" + subType + "/" + iconName
        // First try exact match
        if let image = UIImage(named: imageName) {
            return image
        }
        
        // Try ignoring subtype
        imageName = basePath + type! + "/" + iconName
        if let image = UIImage(named: imageName) {
            return image
        }
        
        // Try defaults
        imageName = basePath + iconName
        if let image = UIImage(named: imageName) {
            return image
        }
        
        return nil
    }

    struct PropertyKey {
        //static let visibleKey = "visible"
        static let typeKey = "type"
        static let subTypeKey = "subtype"
        static let idKey = "id"
        static let referencesKey = "refs"
        static let serverDataKey = "serverData"
        static let notificationsKey = "notifications"
    }
    
    // MARK: Factory
    class func createFromDictionary( _ elementData: NSDictionary! ) -> TripElement? {
        let elemType = elementData[Constant.JSON.elementType] as? String ?? ""
        let elemSubType = elementData[Constant.JSON.elementSubType] as? String ?? ""

        var elem: TripElement?
        switch (elemType, elemSubType) {
        case ("TRA", "AIR"):
            elem = Flight(fromDictionary: elementData)
        case ("TRA", "BUS"):
            elem = ScheduledTransport(fromDictionary: elementData)
        case ("TRA", "TRN"):
            elem = ScheduledTransport(fromDictionary: elementData)
        case ("TRA", "BOAT"):
            elem = ScheduledTransport(fromDictionary: elementData)
        case ("TRA", _):
            elem = GenericTransport(fromDictionary: elementData)
        case ("ACM", _):
            elem = Hotel(fromDictionary: elementData)
        case ("EVT", _):
            elem = Event(fromDictionary: elementData)
        default:
            elem = nil
        }

        return elem
    }

    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(type, forKey: PropertyKey.typeKey)
        aCoder.encode(subType, forKey: PropertyKey.subTypeKey)
        aCoder.encode(id, forKey: PropertyKey.idKey)
        aCoder.encode(references, forKey: PropertyKey.referencesKey)
        aCoder.encode(serverData, forKey: PropertyKey.serverDataKey)
        aCoder.encode(notifications, forKey: PropertyKey.notificationsKey)
    }
    
    
    // MARK: Initialisers
    required init?(coder aDecoder: NSCoder) {
        // NB: use conditional cast (as?) for any optional properties
        type  = aDecoder.decodeObject(forKey: PropertyKey.typeKey) as? String
        subType = aDecoder.decodeObject(forKey: PropertyKey.subTypeKey) as? String
        id = aDecoder.decodeObject(forKey: PropertyKey.idKey) as? Int ?? aDecoder.decodeInteger(forKey: PropertyKey.idKey)
        
        references = aDecoder.decodeObject(forKey: PropertyKey.referencesKey) as? [[String:String]]
        serverData = aDecoder.decodeObject(forKey: PropertyKey.serverDataKey) as? NSDictionary
        notifications = aDecoder.decodeObject(forKey: PropertyKey.notificationsKey) as? [String:NotificationInfo] ?? [String:NotificationInfo]()

        // Must call designated initializer.
        //self.init(type: type, subType: subType)
    }
    
    
    init?(id: Int?, type: String?, subType: String?, references: [ [String:String] ]?) {
        // Initialize stored properties.
        //self.visible = visible
        super.init()
        if id == nil || type == nil || subType == nil {
            return nil
        }

        self.id = id
        self.type = type
        self.subType = subType
        self.references = references
    }
    
    
    required init?(fromDictionary elementData: NSDictionary!) {
        id = elementData[Constant.JSON.elementId] as? Int
        type = elementData[Constant.JSON.elementType] as? String
        subType = elementData[Constant.JSON.elementSubType] as? String
        references = elementData[Constant.JSON.elementReferences] as? [ [String:String] ]
        serverData = elementData
    }
    
    
    // MARK: Methods
    override func isEqual(_ object: Any?) -> Bool {
        if object_getClassName(self) != object_getClassName(object) {
            return false
        } else if let otherTripElement = object as? TripElement {
            if self.type         != otherTripElement.type            { return false }
            if self.subType      != otherTripElement.subType         { return false }
            if self.id           != otherTripElement.id              { return false }
            
            if let myRefs = self.references, let otherRefs = otherTripElement.references {
                if myRefs.count != otherRefs.count { return false }
                check_refs: for myRef in myRefs {
                    for otherRef in otherRefs {
                        if (otherRef == myRef) {
                            continue check_refs
                        }
                    }
                    return false
                }
            } else if (self.references != nil || otherTripElement.references != nil) {
                return false
            }

            return true
        } else {
            return false
        }
    }
    
    
    func startTime(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String? {
        return nil
    }

    func endTime(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String? {
        return nil
    }
    
    func setNotification() {
        // Generic trip element can't have notifications (start date/time not known)
        // Subclasses that support notifications must override this method (and use method below to set notifications)
    }
    
    func setNotification(notificationType: String, leadTime: Int, alertMessage: String, userInfo: UserInfo?) {
        // Logic starts here
        let oldInfo = notifications[notificationType]
        let newInfo = NotificationInfo(baseDate: startTime, leadTime: leadTime)
        
        if (oldInfo == nil || oldInfo!.needsRefresh(newNotification: newInfo!)) {
            var combined:Bool = false
            
            var actualUserInfo = userInfo ?? UserInfo()
            actualUserInfo[.leadTimeType] = notificationType as NSObject
            actualUserInfo[.tripElementId] = id as NSObject
            if let startTimeZone = startTimeZone {
                actualUserInfo[.timeZone] = startTimeZone as NSObject
            }
            
            for (nType, n) in notifications {
                if nType == notificationType {
                    continue;
                }
                if n.notificationDate < newInfo!.notificationDate && newInfo!.notificationDate.timeIntervalSince(n.notificationDate) < TripElement.MinimumNotificationSeparation {
                    newInfo!.combine(with: n)
                    combined = true
                }
            }
            
            
            if !combined {
                let dcf = DateComponentsFormatter()
                dcf.unitsStyle = .short
                dcf.zeroFormattingBehavior = .dropAll
                
                let startTimeText = startTime(dateStyle: .none, timeStyle: .short)!                
                let actualLeadTime = startTime!.timeIntervalSince((newInfo?.notificationDate)!)
                let leadTimeText = dcf.string(from: actualLeadTime)

                let ntfContent = UNMutableNotificationContent()
                ntfContent.body = String.localizedStringWithFormat(alertMessage, title!, leadTimeText!, startTimeText) as String
                ntfContent.sound = UNNotificationSound.default
                ntfContent.userInfo = actualUserInfo.propertyList()
                ntfContent.categoryIdentifier = "SHiT"
                
                let ntfDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: (newInfo?.notificationDate)!)
                
                let ntfTrigger = UNCalendarNotificationTrigger(dateMatching: ntfDateComponents, repeats: false)
                let notification10 = UNNotificationRequest(identifier: notificationType + String(id), content: ntfContent, trigger: ntfTrigger)
                
                UNUserNotificationCenter.current().add(notification10) {(error) in
                    if let error = error {
                        os_log("Unable to schedule notification: %s", type: .error, error as CVarArg)
                    }
                }
                
            } else {
                print("Not setting \(String(describing:notificationType)) notification for trip element \(String(describing:id)), combined with other notification")
            }
            
            notifications[notificationType] = newInfo
        } else {
            print("Not refreshing \(String(describing:notificationType)) notification for trip element \(String(describing:id)), already triggered")
        }
        
    }
    
    func cancelNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Constant.Settings.deptLeadTime + String(id), Constant.Settings.legLeadTime + String(id)])
    }

    func copyState(from: TripElement) {
        self.notifications = from.notifications
    }
    
    func viewController(trip:AnnotatedTrip, element:AnnotatedTripElement) -> UIViewController? {
        guard element.tripElement == self else {
            fatalError("Inconsistent trip element and annotated trip element")
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "UnknownElementDetailsViewController")
        if let uevc = vc as? UnknownElementDetailsViewController {
            uevc.tripElement = element
            uevc.trip = trip
            return uevc
        }
        return nil
    }
}
