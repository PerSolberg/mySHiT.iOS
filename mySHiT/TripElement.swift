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
    typealias ChangedAttribute = (attr:String, old:String, new:String)
    
    static let RefTag_Type      = "type"
    static let RefTag_RefNo     = "refNo"
    static let RefTag_LookupURL = "urlLookup"
    
    static let MinimumNotificationSeparation : TimeInterval = 10 * 60  // Minutes between notifications for same trip element
    
    var type: String!
    var subType: String!
    var id: Int!
    var references: [ [String:String] ]?
    var serverData: NSDictionary?
    
    var changedAttributes:[(attr:String, old:String, new:String)] = []

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
    }
    
    
    init?(id: Int?, type: String?, subType: String?, references: [ [String:String] ]?) {
        // Initialize stored properties.
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
    override final func isEqual(_ object: Any?) -> Bool {
        if object_getClassName(self) != object_getClassName(object) {
            return false
        } else if let otherTripElement = object as? TripElement {
            do {
                let changes = try compareProperties(otherTripElement)
                
                if changes.count != 0 {
//                    print("Changes: \(String(describing: changes))")
                    os_log("Changes: %s", log: OSLog.delta, type: .debug, String(describing: changes))
                }
                return changes.count == 0
            }
            catch ModelError.compareTypeMismatch(let selfType, let otherType) {
                os_log("Compare type mismatch: %s vs %s", log: OSLog.delta, type: .error, selfType, otherType)
                return false
            }
            catch {
                fatalError("Unexpected error: \(error)")
            }
        } else {
            return false
        }
    }
    

    func compareProperties(_ otherTripElement: TripElement) throws -> [ChangedAttribute] {
        var changes = [ChangedAttribute]()
        changes.appendOpt(checkProperty(PropertyKey.typeKey, new: self.type, old: otherTripElement.type))
        changes.appendOpt(checkProperty(PropertyKey.subTypeKey, new: self.subType, old: otherTripElement.subType))
        changes.appendOpt(checkProperty(PropertyKey.idKey, new: self.id, old: otherTripElement.id))

        if let myRefs = self.references, let otherRefs = otherTripElement.references {
            if myRefs.count != otherRefs.count { changes.append(("references.count", String(myRefs.count), String(otherRefs.count))) }
            check_refs: for myRef in myRefs {
                for otherRef in otherRefs {
                    if (otherRef == myRef) {
                        continue check_refs
                    }
                }
                let refType = myRef["type"] ?? "<None>"
                let refNo = myRef["refNo"] ?? "<None>"
                changes.append(("references.\(refType)", new: refNo, old: ""))
            }
        } else if (self.references != nil || otherTripElement.references != nil) {
            changes.append(("references", self.references == nil ? "none" : String(self.references!.count), otherTripElement.references == nil ? "none" : String(otherTripElement.references!.count)))
        }

        return changes
    }


    func checkProperty(_ name: String, new: String?, old: String?) -> ChangedAttribute? {
        if let old = old, let new = new, old == new {
            return nil
        } else if old == nil && new == nil {
            return nil
        } else {
            return (name, old ?? "", new ?? "")
        }
    }
    
    func checkProperty(_ name: String, new: Int?, old: Int?) -> ChangedAttribute? {
        if let old = old, let new = new, old == new {
            return nil
        } else if old == nil && new == nil {
            return nil
        } else {
            return (name, old == nil ? "nil" : String(old!), new == nil ? "nil" : String(new!) )
        }
    }

    func checkProperty(_ name: String, new: Date?, old: Date?) -> ChangedAttribute? {
        if let old = old, let new = new, old == new {
            return nil
        } else if old == nil && new == nil {
            return nil
        } else {
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withSpaceBetweenDateAndTime, .withFullDate, .withFullTime, .withTimeZone]
//            let dateFormatter = DateFormatter()
//            dateFormatter.dateStyle = .full  //dateStyle
//            dateFormatter.timeStyle = .full //timeStyle
//            dateFormatter.timeZone = Constant.timezoneUTC
            
            var oldDate = "nil", newDate = "nil"
            if let old = old {
                oldDate = isoFormatter.string(from: old)
            }
            if let new = new {
                newDate = isoFormatter.string(from: new)
            }
            
            return (name, oldDate, newDate )
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
                        os_log("Unable to schedule notification: %{public}s", log: OSLog.notification, type: .error, error as CVarArg)
                    }
                }
                
            } else {
                os_log("Not setting '%{public}s' notification for trip element %d, combined with other notification", log: OSLog.notification, type: .info, notificationType, id)
            }
            
            notifications[notificationType] = newInfo
        } else {
            os_log("Not refreshing '%{public}s' notification for trip element %d, already triggered", log: OSLog.notification, type: .info, notificationType, id)
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
