//
//  AnnotatedTripElement.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-19.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation

class AnnotatedTripElement: NSObject, NSCoding {
    var modified: ChangeState
    var tripElement: TripElement
    
    struct PropertyKey {
        static let modifiedKey = "modified"
        static let tripElementKey = "tripElement"
    }
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(modified.rawValue, forKey: PropertyKey.modifiedKey)
        aCoder.encode(tripElement, forKey: PropertyKey.tripElementKey)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        // NB: use conditional cast (as?) for any optional properties
        let _modified   = aDecoder.decodeObject(forKey: PropertyKey.modifiedKey) as? String
        var modified:ChangeState = .Unchanged
        if (_modified != nil) {
            modified  = ChangeState(rawValue: _modified!)!
        }
        let tripElement = aDecoder.decodeObject(forKey: PropertyKey.tripElementKey) as! TripElement
        
        // Must call designated initializer.
        self.init(tripElement: tripElement, modified: modified)
    }
    
    init?(tripElement: TripElement) {
        // Initialize stored properties.
        self.modified = .Unchanged
        self.tripElement = tripElement
        
        super.init()
    }

    init?(tripElement: TripElement, modified: ChangeState) {
        // Initialize stored properties.
        self.modified = modified
        self.tripElement = tripElement
        
        super.init()
    }
}
