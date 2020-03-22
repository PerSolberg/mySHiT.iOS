//
//  AnnotatedTrip.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-18.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation

class AnnotatedTrip: NSObject, NSCoding {
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
    func encode(with aCoder: NSCoder) {
        aCoder.encode(modified.rawValue, forKey: PropertyKey.modifiedKey)
        aCoder.encode(section.rawValue, forKey: PropertyKey.sectionKey)
        aCoder.encode(trip, forKey: PropertyKey.tripKey)
    }
    
    
    required convenience init?(coder aDecoder: NSCoder) {
        let _modified   = aDecoder.decodeObject(forKey: PropertyKey.modifiedKey) as? String
        var modified:ChangeState = .Unchanged
        if (_modified != nil) {
            modified  = ChangeState(rawValue: _modified!)!
        }

        let section  = aDecoder.decodeObject(forKey: PropertyKey.sectionKey) as? TripListSection ?? .Historic
        let trip = aDecoder.decodeObject(forKey: PropertyKey.tripKey) as! Trip
        
        self.init(section: section, trip: trip, modified: modified)
    }

    
    init?(section: TripListSection, trip: Trip, modified: ChangeState) {
        self.modified = modified
        self.section = section
        self.trip = trip
        
        super.init()
    }
}
