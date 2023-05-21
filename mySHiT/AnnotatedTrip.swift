//
//  AnnotatedTrip.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-18.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation

public class AnnotatedTrip: NSObject, NSSecureCoding {
    var section: TripListSection
    var trip: Trip
    var modified: ChangeState
    
    struct PropertyKey {
        static let modifiedKey = "modified"
        static let sectionKey = "section"
        static let tripKey = "trip"
    }
        
    //
    // MARK: NSCoding
    //
    public class var supportsSecureCoding: Bool { return true }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(modified.rawValue, forKey: PropertyKey.modifiedKey)
        aCoder.encode(section.rawValue, forKey: PropertyKey.sectionKey)
        aCoder.encode(trip, forKey: PropertyKey.tripKey)
    }
        
    required public convenience init?(coder aDecoder: NSCoder) {
        let _modified   = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.modifiedKey) as? String
        var modified:ChangeState = .Unchanged
        if (_modified != nil) {
            modified  = ChangeState(rawValue: _modified!)!
        }

        let sectionString = aDecoder.decodeObject(of: NSString.self, forKey: PropertyKey.sectionKey) as? String
        let section = TripListSection(rawValue: sectionString!) ?? .Historic
        let trip = aDecoder.decodeObject(of: Trip.self, forKey: PropertyKey.tripKey)!
        
        self.init(section: section, trip: trip, modified: modified)
    }

    
    init?(section: TripListSection, trip: Trip, modified: ChangeState) {
        self.modified = modified
        self.section = section
        self.trip = trip
        
        super.init()
    }
}
