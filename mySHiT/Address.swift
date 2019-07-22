//
//  Address.swift
//  mySHiT
//
//  Created by Per Solberg on 2019-07-22.
//  Copyright © 2019 &More AS. All rights reserved.
//

import Foundation
import UIKit

class Address {
    class func getMapLink(_ address:String) -> String? {
        let trimmed = address.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        guard let encodedValue = trimmed.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else { return nil }
        return "http://maps.apple.com/?q=" + encodedValue        
    }
}
