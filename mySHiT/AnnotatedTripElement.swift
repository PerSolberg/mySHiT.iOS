//
//  AnnotatedTripElement.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-19.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation

class AnnotatedTripElement: NSObject, NSSecureCoding {
    var modified: ChangeState
    var tripElement: TripElement
    
    struct PropertyKey {
        static let modifiedKey = "modified"
        static let tripElementKey = "tripElement"
    }
    
    
    //
    // MARK: NSCoding
    //
    public class var supportsSecureCoding: Bool { return true }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(modified.rawValue, forKey: PropertyKey.modifiedKey)
        aCoder.encode(tripElement, forKey: PropertyKey.tripElementKey)
    }
    
    
    required convenience init?(coder aDecoder: NSCoder) {
        let _modified   = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.modifiedKey) as? String
        var modified:ChangeState = .Unchanged
        if (_modified != nil) {
            modified  = ChangeState(rawValue: _modified!)!
        }
        let tripElement = aDecoder.decodeObject(of: TripElement.self, forKey: PropertyKey.tripElementKey)
        
        self.init(tripElement: tripElement!, modified: modified)
    }
        
    init?(tripElement: TripElement) {
        self.modified = .Unchanged
        self.tripElement = tripElement
        
        super.init()
    }

    
    init?(tripElement: TripElement, modified: ChangeState) {
        self.modified = modified
        self.tripElement = tripElement
        
        super.init()
    }
}
