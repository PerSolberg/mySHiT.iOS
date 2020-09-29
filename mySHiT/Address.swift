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
    struct Format {
        static let postCodeAndCity = NSLocalizedString("FMT.ADDRESS.POSTCODE_AND_CITY", comment: "")
    }
    
    static let appleMapsUrl = "http://maps.apple.com/?q="
    
    class func getMapLink(_ address:String) -> String? {
        let trimmed = address.replacingOccurrences(of: Constant.RegExPattern.whitespace, with: Constant.space, options: .regularExpression)
        guard let encodedValue = trimmed.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else { return nil }
        return appleMapsUrl + encodedValue
    }
}
