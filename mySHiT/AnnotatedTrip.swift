//
//  AnnotatedTrip.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-18.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation

class AnnotatedTrip: NSObject, NSCoding {
    //var visible: Bool
    var section: TripListSection
    var trip: Trip
    var modified: ChangeState
    //var tripData: NSDictionary
    
    struct PropertyKey {
        static let modifiedKey = "modified"
        static let sectionKey = "section"
        static let tripKey = "trip"
    }
    
    // MARK: NSCoding
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(modified.rawValue, forKey: PropertyKey.modifiedKey)
        aCoder.encodeObject(section.rawValue, forKey: PropertyKey.sectionKey)
        aCoder.encodeObject(trip, forKey: PropertyKey.tripKey)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        // NB: use conditional cast (as?) for any optional properties
        let _modified   = aDecoder.decodeObjectForKey(PropertyKey.modifiedKey) as? String
        var modified:ChangeState = .Unchanged
        if (_modified != nil) {
            modified  = ChangeState(rawValue: _modified!)!
        }

        let section  = aDecoder.decodeObjectForKey(PropertyKey.sectionKey) as? TripListSection ?? .Historic
        let trip = aDecoder.decodeObjectForKey(PropertyKey.tripKey) as! Trip
        
        // Must call designated initializer.
        self.init(section: section, trip: trip, modified: modified)
    }

    init?(section: TripListSection, trip: Trip, modified: ChangeState) {
        // Initialize stored properties.
        self.modified = modified
        self.section = section
        self.trip = trip
        
        super.init()
    }
}