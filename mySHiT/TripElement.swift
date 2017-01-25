//
//  TripElement.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-20.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation
import UIKit

class TripElement: NSObject, NSCoding {
    static let RefTag_Type      = "type"
    static let RefTag_RefNo     = "refNo"
    static let RefTag_LookupURL = "urlLookup"
    
    var type: String!
    var subType: String!
    var id: Int!
    var references: [ [String:String] ]?
    var serverData: NSDictionary?
    
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
    }
    
    // MARK: Factory
    class func createFromDictionary( _ elementData: NSDictionary! ) -> TripElement? {
        let elemType = elementData[Constant.JSON.elementType] as? String ?? ""
        let elemSubType = elementData[Constant.JSON.elementSubType] as? String ?? ""

        var elem: TripElement?
        switch (elemType, elemSubType) {
        case ("TRA", "AIR"):
            elem = Flight(fromDictionary: elementData)
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
    }
    
    
    // MARK: Initialisers
    required init?(coder aDecoder: NSCoder) {
        // NB: use conditional cast (as?) for any optional properties
        //let visible  = aDecoder.decodeObjectForKey(PropertyKey.visibleKey) as! Bool
        type  = aDecoder.decodeObject(forKey: PropertyKey.typeKey) as! String
        subType = aDecoder.decodeObject(forKey: PropertyKey.subTypeKey) as! String
        //id = aDecoder.decodeInteger(forKey: PropertyKey.idKey)
        id = aDecoder.decodeObject(forKey: PropertyKey.idKey) as? Int ?? aDecoder.decodeInteger(forKey: PropertyKey.idKey)
        
        references = aDecoder.decodeObject(forKey: PropertyKey.referencesKey) as? [[String:String]]
        serverData = aDecoder.decodeObject(forKey: PropertyKey.serverDataKey) as? NSDictionary
        //references = [ [String:String] ]() //NSDictionary()

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
        id = elementData[Constant.JSON.elementId] as! Int
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
        // Subclasses that support notifications must override this method
    }

}
