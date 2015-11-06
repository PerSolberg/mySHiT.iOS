//
//  AnnotatedTripElement.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-19.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation

class AnnotatedTripElement: NSObject, NSCoding {
    //var visible: Bool
    //var section: TripElementListSection
    //var tripElementData: NSDictionary
    var tripElement: TripElement
    
    struct PropertyKey {
        //static let visibleKey = "visible"
        //static let sectionKey = "section"
        static let tripElementKey = "tripElement"
    }
    
    // MARK: NSCoding
    func encodeWithCoder(aCoder: NSCoder) {
        //aCoder.encodeObject(visible, forKey: PropertyKey.visibleKey)
        //aCoder.encodeObject(section.rawValue, forKey: PropertyKey.sectionKey)
        //aCoder.encodeObject(tripElementData, forKey: PropertyKey.tripElementKey)
        aCoder.encodeObject(tripElement, forKey: PropertyKey.tripElementKey)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        // NB: use conditional cast (as?) for any optional properties
        //let visible  = aDecoder.decodeObjectForKey(PropertyKey.visibleKey) as! Bool
        //let section         = aDecoder.decodeObjectForKey(PropertyKey.sectionKey) as! TripElementListSection
        //let tripElementData = aDecoder.decodeObjectForKey(PropertyKey.tripElementKey) as! NSDictionary
        let tripElement = aDecoder.decodeObjectForKey(PropertyKey.tripElementKey) as! TripElement
        
        // Must call designated initializer.
        self.init(tripElement: tripElement)
    }
    
    //init?(section: TripElementListSection, tripElement: NSDictionary) {
    init?(tripElement: TripElement) {
        // Initialize stored properties.
        //self.visible = visible
        //self.section = section
        self.tripElement = tripElement
        
        super.init()
    }
}