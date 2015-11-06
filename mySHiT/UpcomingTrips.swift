//
//  UpcomingTrips.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-19.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation
enum UserPrefUpcomingTrips:String {
    case NextOnly           = "N"
    case Within7Days        = "7"
    case Within30Days       = "30"
    case NextOrWithin7Days  = "N7"
    case NextOrWithin30Days = "N30"
}