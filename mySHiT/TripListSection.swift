//
//  TripListSection.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-18.
//  Copyright © 2015 Per Solberg. All rights reserved.
//


import Foundation

enum TripListSection:String {
    case Future, Upcoming, Current, Historic
    
    // Iteration support
    static let allValues = [Future, Upcoming, Current, Historic]
}

class TripListSectionInfo: NSObject, NSCoding {
    var visible: Bool!
    var type: TripListSection!
    var firstTrip: Int!

    struct PropertyKey {
        static let visibleKey = "visible"
        static let typeKey = "type"
        static let firstTripKey = "firstTrip"
    }
    
    // MARK: NSCoding
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(visible, forKey: PropertyKey.visibleKey)
        aCoder.encodeObject(type.rawValue, forKey: PropertyKey.typeKey)
        aCoder.encodeInteger(firstTrip, forKey: PropertyKey.firstTripKey)
    }

    required convenience init?(coder aDecoder: NSCoder) {
        // NB: use conditional cast (as?) for any optional properties
        let visible  = aDecoder.decodeObjectForKey(PropertyKey.visibleKey) as! Bool
        let type = TripListSection(rawValue: aDecoder.decodeObjectForKey(PropertyKey.typeKey) as! String)!
        let firstTrip = aDecoder.decodeIntegerForKey(PropertyKey.firstTripKey)

        // Must call designated initializer.
        self.init(visible: visible, type: type, firstTrip: firstTrip)
    }
    
    init?(visible: Bool, type: TripListSection, firstTrip: Int) {
        // Initialize stored properties.
        self.visible = visible
        self.type = type
        self.firstTrip = firstTrip
        
        super.init()
        
        // Initialization should fail if there is no name
        if type.rawValue.isEmpty {
            return nil
        }
    }
}