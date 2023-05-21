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
import Combine

class TripElement: NSObject, NSSecureCoding {
    static let RefTag_Type      = "type"
    static let RefTag_RefNo     = "refNo"
    static let RefTag_LookupURL = "urlLookup"
    
    enum IconStatus {
        case missing
        case downloaded
        case pending
    }

    struct ElementType:Hashable { var type, subType: String? }
    struct IconKey:Hashable {
        var type: String?
        var subType: String?
        var tense: Tenses

        static let TenseNames:[Tenses?:String] = [ Tenses.past : "historic", Tenses.present : "active" ]
        static let DefaultName = "default"

        var tenseName:String {
            return TripElement.IconKey.TenseNames[tense] ?? TripElement.IconKey.DefaultName
        }
        func pathComponent(_ name: String?, _ separator: String) -> String {
            return name == nil ? "" : name! + separator
        }
        var assetPath:String {
            return "tripelement/" + pathComponent(type, "/") + pathComponent(subType, "/") + tenseName
        }
        var downloadPath:String {
            return "https://shitt.no/mySHiT/v2/icons/tripelement/" + pathComponent(type, ".") + pathComponent(subType, ".") + tenseName + ".png"
        }
        var parentKey:IconKey? {
            if type == nil {
                return nil
            } else if subType == nil {
                return IconKey(tense: tense)
            } else {
                return IconKey(type: type, tense: tense)
            }
        }
    }
    static var handlingClasses:[ElementType:TripElement.Type] = [:]
    static var iconCache:[IconKey:(status:IconStatus, icon:UIImage?)] = [:]
    static let iconCacheSemaphore = DispatchSemaphore(value: 1)
    
    struct Format {
        static let taggedReference = NSLocalizedString("FMT.BOOKINGREF.TAGGED", comment: "")
        static let refListSeparator = NSLocalizedString("FMT.BOOKINGREF.LIST.SEPARATOR", comment: "")
    }

    static let MinimumNotificationSeparation : TimeInterval = 10 * 60  // Minutes between notifications for same trip element
    
    struct MainType {
        static let Transport = "TRA"
        static let Accommodation = "ACM"
        static let Event = "EVT"
    }
    struct SubType {
        static let Airline = "AIR"
        static let Bus = "BUS"
        static let Train = "TRN"
        static let Boat = "BOAT"
        static let Hotel = "HTL"
        static let Limo = "LIMO"
        static let PrivateBus = "PBUS"
    }
    
    var type: String { willSet { checkChange(type, newValue) } }
    var subType: String { willSet { checkChange(subType, newValue) } }
    var id: Int { willSet { checkChange(id, newValue) } }
    var references: Set<[String:String]>? { willSet { checkChange(references, newValue) } }
    var serverData: NSDictionary?
    
    var changed = false
    
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
        // First try exact match
        var iconKey:IconKey? = IconKey(type: type, subType: subType, tense: tense ?? .future)

        repeat {
            if let image = UIImage(named: iconKey!.assetPath ) {
                return image
            }

            // Check cache
            if let cached = TripElement.iconCache[iconKey!] {
                switch (cached.status) {
                case .missing, .pending:
                    break
                case .downloaded:
                    return cached.icon
                }
            } else {
                // Initiate download
                self.downloadImage(iconKey!)
            }

            iconKey = iconKey!.parentKey
        } while iconKey != nil

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

    
    //
    // MARK: Factory
    //
    class func canHandle(_ elemType: ElementType!) -> Bool {
        return false
    }

    
    class func createFromDictionary( _ elementData: NSDictionary! ) -> TripElement? {
        let elemType = elementData[Constant.JSON.elementType] as? String ?? ""
        let elemSubType = elementData[Constant.JSON.elementSubType] as? String ?? ""
        let typeKey = ElementType(type: elemType, subType: elemSubType)

        var elem: TripElement?
        if let handlingClass = handlingClasses[typeKey] {
            elem = handlingClass.init(fromDictionary: elementData)
        } else {
            // First check if any of the subclasses can handle til element
            let subclasses = Runtime.directSubclasses(of: self)
            for sc in subclasses {
                if let sc = sc as? TripElement.Type {
                    elem = sc.createFromDictionary(elementData)
                    
                    if elem != nil {
                        break
                    }
                }
            }
            // If not, check if this class can handle it
            if elem == nil && canHandle(typeKey) {
                elem = self.init(fromDictionary: elementData)
            }
            // Cache the mapping to avoid traversing the class hierarchy every time
            if let elem = elem {
                handlingClasses[typeKey] = Swift.type(of: elem)
            }
        }

        return elem
    }


    //
    // MARK: NSCoding
    //
    public class var supportsSecureCoding: Bool { return true }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(type, forKey: PropertyKey.typeKey)
        aCoder.encode(subType, forKey: PropertyKey.subTypeKey)
        aCoder.encode(id, forKey: PropertyKey.idKey)
        aCoder.encode(references, forKey: PropertyKey.referencesKey)
        aCoder.encode(serverData, forKey: PropertyKey.serverDataKey)
        aCoder.encode(notifications, forKey: PropertyKey.notificationsKey)
    }
    
    
    //
    // MARK: Initialisers
    //
    required init?(coder aDecoder: NSCoder) {
        type  = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.typeKey)! as String
        subType = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.subTypeKey)! as String
        id = aDecoder.decodeInteger(forKey: PropertyKey.idKey)
        
        if let refSet = aDecoder.decodeObject(of: [NSSet.self, NSDictionary.self, NSString.self], forKey: PropertyKey.referencesKey) as? Set<[String:String]> {
            references = refSet
        } else if let refList = aDecoder.decodeObject(of: [NSArray.self, NSDictionary.self, NSString.self], forKey: PropertyKey.referencesKey) as? [[String:String]] {
            references = Set(refList)
        }
        serverData = aDecoder.decodeObject(of: [NSDictionary.self, NSArray.self, NSString.self, NSNumber.self, NSNull.self], forKey: PropertyKey.serverDataKey) as? NSDictionary
//        notifications = aDecoder.decodeObject(of: [NSDictionary.self, NSString.self, NotificationInfo.self], forKey: PropertyKey.notificationsKey) as? [String:NotificationInfo] ?? [String:NotificationInfo]()
        notifications = aDecoder.decodeDictionary(
            withKeyClass: NSString.self,
            objectClass: NotificationInfo.self,
            forKey: PropertyKey.notificationsKey) as? [String:NotificationInfo] ?? [String:NotificationInfo]()
    }
    
    
    init?(id: Int, type: String, subType: String, references: Set<[String:String]>?) {
        // Initialize stored properties.
        self.id = id
        self.type = type
        self.subType = subType
        self.references = references
        super.init()
    }
    
    
    required init?(fromDictionary elementData: NSDictionary!) {
        let inputId = elementData[Constant.JSON.elementId] as? Int
        let inputType = elementData[Constant.JSON.elementType] as? String
        let inputSubType = elementData[Constant.JSON.elementSubType] as? String
        
        if inputId == nil || inputType == nil || inputSubType == nil {
            return nil
        }
        id = inputId!
        type = inputType!
        subType = inputSubType!
        if let refList = elementData[Constant.JSON.elementReferences] as? [ [String:String] ] {
            references = Set(refList)
        }
        serverData = elementData
    }
    
    
    //
    // MARK: Methods
    //
    final func downloadImage(_ iconKey:IconKey) {
        TripElement.iconCacheSemaphore.wait()
        if TripElement.iconCache[iconKey] == nil {
            TripElement.iconCache[iconKey] = (.pending, nil)
        }
        TripElement.iconCacheSemaphore.signal()

        let imgUrl = URL(string: iconKey.downloadPath)!

        DispatchQueue.global().async {
            URLSession.shared.dataTask(with: imgUrl) { data, response, error in
                guard let gData = data,
                      let gResponse = response as? HTTPURLResponse,
                      gResponse.statusCode >= 200 && gResponse.statusCode < 300,
                      let image = UIImage(data: gData, scale: 1.0) else {
                    TripElement.iconCacheSemaphore.wait()
                    let cached = TripElement.iconCache[iconKey]!
                    if cached.status == .pending {
                        TripElement.iconCache[iconKey] = (.missing, nil)
                    }
                    TripElement.iconCacheSemaphore.signal()
                    return
                }
                //            let imgSize = image.size
                //            print("Downloaded image size = " + String(describing: imgSize))
                TripElement.iconCacheSemaphore.wait()
                TripElement.iconCache[iconKey] = (.downloaded, image)
                TripElement.iconCacheSemaphore.signal()
                NotificationCenter.default.post(name: Constant.Notification.refreshTripElements, object: self)
            }
            .resume()
        }

    }
   
    func checkChange<T:Equatable>(_ old: T, _ new: T) {
        let propertyChanged = (old != new)
        changed = changed || propertyChanged
    }


    func update(fromDictionary elementData: NSDictionary!) -> Bool {
        assert(id == elementData[Constant.JSON.elementId] as? Int, "Update error: inconsistent trip element IDs")
        changed = false

        type = elementData[Constant.JSON.elementType] as! String
        subType = elementData[Constant.JSON.elementSubType] as! String

        if let refList = elementData[Constant.JSON.elementReferences] as? [ [String:String] ] {
            references = Set(refList)
        }

        serverData = elementData

        return changed
    }

    
    func startTime(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String? {
        return nil
    }

    
    func endTime(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String? {
        return nil
    }
    
    
    func referenceList(separator: String) -> String {
        guard let references = references else {
            return ""
        }
        let refList = references.compactMap{ $0[TripElement.RefTag_RefNo] }
        return refList.joined(separator: separator)
    }

    
    func taggedReferenceList(separator: String, excludeTypes: Set<String>) -> String {
        guard let references = references else {
            return ""
        }
        let refList = references.compactMap { (refItem) -> String? in
            if let type = refItem[TripElement.RefTag_Type], let refNo = refItem[TripElement.RefTag_RefNo], !excludeTypes.contains(type) {
                return String.localizedStringWithFormat(Format.taggedReference, type, refNo)
            } else {
                return nil
            }
        }
        return refList.joined(separator: separator)
    }

    
    func taggedReferenceList(separator: String) -> String {
        return taggedReferenceList(separator: separator, excludeTypes: Set([]))
    }

        
    func setNotification() {
        // Generic trip element can't have notifications (start date/time not known)
        // Subclasses that support notifications must override this method (and use
        // method below to set notifications)
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
                ntfContent.categoryIdentifier = Constant.NotificationCategory.alertDefault
                
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


    func viewController() -> UIViewController? {
        let uevc = UnknownElementDetailsViewController.instantiate(fromAppStoryboard: .Main)
        uevc.tripElement = self
        return uevc
    }

}
