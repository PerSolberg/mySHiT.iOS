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
    //var tripData: NSDictionary
    
    struct PropertyKey {
        //static let visibleKey = "visible"
        static let sectionKey = "section"
        static let tripKey = "trip"
    }
    
    // MARK: NSCoding
    func encodeWithCoder(aCoder: NSCoder) {
        //aCoder.encodeObject(visible, forKey: PropertyKey.visibleKey)
        aCoder.encodeObject(section.rawValue, forKey: PropertyKey.sectionKey)
        aCoder.encodeObject(trip, forKey: PropertyKey.tripKey)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        // NB: use conditional cast (as?) for any optional properties
        //let visible  = aDecoder.decodeObjectForKey(PropertyKey.visibleKey) as! Bool
        let section  = aDecoder.decodeObjectForKey(PropertyKey.sectionKey) as? TripListSection ?? .Historic
        let trip = aDecoder.decodeObjectForKey(PropertyKey.tripKey) as! Trip
        
        // Must call designated initializer.
        self.init(section: section, trip: trip)
    }
    
    init?(section: TripListSection, trip: Trip) {
        // Initialize stored properties.
        //self.visible = visible
        self.section = section
        self.trip = trip
        
        super.init()
    }
}