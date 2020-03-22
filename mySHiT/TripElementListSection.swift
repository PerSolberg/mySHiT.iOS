//
//  TripElementListSection.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-19.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation


class TripElementListSectionInfo: NSObject, NSCoding {
    var visible: Bool
    var title: String
    var firstTripElement: Int?
    
    struct PropertyKey {
        static let visibleKey = "visible"
        static let titleKey = "title"
        static let firstTripElementKey = "firstTripElement"
    }
    
    
    //
    // MARK: Initialisers
    //
    init(visible: Bool, title: String, firstTripElement: Int?) {
        // Initialize stored properties.
        self.visible = visible
        self.title = title
        self.firstTripElement = firstTripElement
        
        super.init()
    }


    //
    // MARK: NSCoding
    //
    func encode(with aCoder: NSCoder) {
        aCoder.encode(visible, forKey: PropertyKey.visibleKey)
        aCoder.encode(title, forKey: PropertyKey.titleKey)
        aCoder.encode(firstTripElement, forKey: PropertyKey.firstTripElementKey)
    }
    
    
    required convenience init(coder aDecoder: NSCoder) {
        // NB: use conditional cast (as?) for any optional properties
        let visible  = aDecoder.decodeObject(forKey: PropertyKey.visibleKey) as? Bool ?? aDecoder.decodeBool(forKey: PropertyKey.visibleKey)
        let title = aDecoder.decodeObject(forKey: PropertyKey.titleKey) as! String
        var firstTripElement = aDecoder.decodeObject(forKey: PropertyKey.firstTripElementKey) as? Int // ?? aDecoder.decodeInteger(forKey: PropertyKey.firstTripElementKey)
        
        // Legacy cupport
        if let firstTripElementDecoded = firstTripElement, firstTripElementDecoded == -1 {
            firstTripElement = nil
        }

        self.init(visible: visible, title: title, firstTripElement: firstTripElement)
    }
}
