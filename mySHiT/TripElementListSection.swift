//
//  TripElementListSection.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-19.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation

/*
enum TripElementListSection:String {
    case Future, Next, Current, Historic
    
    // Iteration support
    static let allValues = [Future, Next, Current, Historic]

}
*/

class TripElementListSectionInfo: NSObject, NSCoding {
    var visible: Bool!
    var title: String!
    var firstTripElement: Int!
    
    struct PropertyKey {
        static let visibleKey = "visible"
        static let titleKey = "title"
        static let firstTripElementKey = "firstTripElement"
    }
    
    // MARK: NSCoding
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(visible, forKey: PropertyKey.visibleKey)
        aCoder.encodeObject(title, forKey: PropertyKey.titleKey)
        aCoder.encodeObject(firstTripElement, forKey: PropertyKey.firstTripElementKey)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        // NB: use conditional cast (as?) for any optional properties
        let visible  = aDecoder.decodeObjectForKey(PropertyKey.visibleKey) as! Bool
        let title = aDecoder.decodeObjectForKey(PropertyKey.titleKey) as! String
        let firstTripElement = aDecoder.decodeIntegerForKey(PropertyKey.firstTripElementKey)
        
        // Must call designated initializer.
        self.init(visible: visible, title: title, firstTripElement: firstTripElement)
    }
    
    init?(visible: Bool, title: String!, firstTripElement: Int) {
        // Initialize stored properties.
        self.visible = visible
        self.title = title
        self.firstTripElement = firstTripElement
        
        super.init()
        
        // Initialization should fail if there is no name
        if title.isEmpty {
            return nil
        }
    }
}