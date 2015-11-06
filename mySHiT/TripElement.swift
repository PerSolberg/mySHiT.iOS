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
    var type: String!
    var subType: String!
    var id: Int!
    var references: [ [String:String] ]?
    var serverData: NSDictionary?
    
    var startTime: NSDate? {
        return nil
    }
    var endTime: NSDate? {
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
    class func createFromDictionary( elementData: NSDictionary! ) -> TripElement? {
        let elemType = elementData["type"] as? String ?? ""
        let elemSubType = elementData["subType"] as? String ?? ""

        var elem: TripElement?
        switch (elemType, elemSubType) {
        case ("TRA", "AIR"):
            elem = Flight(fromDictionary: elementData)
        case ("TRA", _):
            elem = GenericTransport(fromDictionary: elementData)
        case ("ACM", _):
            elem = Hotel(fromDictionary: elementData)
        default:
            elem = nil
        }

        return elem
    }

    
    // MARK: NSCoding
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(type, forKey: PropertyKey.typeKey)
        aCoder.encodeObject(subType, forKey: PropertyKey.subTypeKey)
        aCoder.encodeInteger(id, forKey: PropertyKey.idKey)
        aCoder.encodeObject(references, forKey: PropertyKey.referencesKey)
        aCoder.encodeObject(serverData, forKey: PropertyKey.serverDataKey)
    }
    
    
    // MARK: Initialisers
    required init?(coder aDecoder: NSCoder) {
        // NB: use conditional cast (as?) for any optional properties
        //let visible  = aDecoder.decodeObjectForKey(PropertyKey.visibleKey) as! Bool
        type  = aDecoder.decodeObjectForKey(PropertyKey.typeKey) as! String
        subType = aDecoder.decodeObjectForKey(PropertyKey.subTypeKey) as! String
        id = aDecoder.decodeIntegerForKey(PropertyKey.idKey)
        references = aDecoder.decodeObjectForKey(PropertyKey.referencesKey) as? [[String:String]]
        serverData = aDecoder.decodeObjectForKey(PropertyKey.serverDataKey) as? NSDictionary
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
        id = elementData["id"] as! Int
        type = elementData["type"] as? String
        subType = elementData["subType"] as? String
        references = elementData["references"] as? [ [String:String] ]
        
        serverData = elementData
    }
    
    
    // MARK: Methods
    func startTime(dateStyle dateStyle: NSDateFormatterStyle, timeStyle: NSDateFormatterStyle) -> String? {
        return nil
    }

    func endTime(dateStyle dateStyle: NSDateFormatterStyle, timeStyle: NSDateFormatterStyle) -> String? {
        return nil
    }
    
    func setNotification() {
        // Generic trip element can't have notifications (start date/time not known)
        // Subclasses that support notifications must override this method
    }

}