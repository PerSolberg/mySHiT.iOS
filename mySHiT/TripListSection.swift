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
    var visible: Bool
    var type: TripListSection
    var firstTrip: Int?

    struct PropertyKey {
        static let visibleKey = "visible"
        static let typeKey = "type"
        static let firstTripKey = "firstTrip"
    }

    
    //
    // MARK: Initialisers
    //
    required convenience init(coder aDecoder: NSCoder) {
        // NB: use conditional cast (as?) for any optional properties
        let visible  = aDecoder.decodeObject(forKey: PropertyKey.visibleKey) as? Bool ?? aDecoder.decodeBool(forKey: PropertyKey.visibleKey)
        let type = TripListSection(rawValue: aDecoder.decodeObject(forKey: PropertyKey.typeKey) as! String)!
        var firstTrip = aDecoder.decodeObject(forKey: PropertyKey.firstTripKey) as? Int //?? aDecoder.decodeInteger(forKey: PropertyKey.firstTripKey)

        // Legacy support
        if let firstTripDecoded = firstTrip, firstTripDecoded == -1 {
            firstTrip = nil
        }
        self.init(visible: visible, type: type, firstTrip: firstTrip)
    }

    
    //
    // MARK: NSCoding
    //
    func encode(with aCoder: NSCoder) {
        aCoder.encode(visible, forKey: PropertyKey.visibleKey)
        aCoder.encode(type.rawValue, forKey: PropertyKey.typeKey)
        aCoder.encode(firstTrip, forKey: PropertyKey.firstTripKey)
    }

    
    init(visible: Bool, type: TripListSection, firstTrip: Int?) {
        // Initialize stored properties.
        self.visible = visible
        self.type = type
        self.firstTrip = firstTrip
        
        super.init()
    }
}
