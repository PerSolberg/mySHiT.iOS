//
//  Phone.swift
//  mySHiT
//
//  Created by Per Solberg on 2019-05-20.
//  Copyright © 2019 &More AS. All rights reserved.
//

import Foundation
import UIKit

class Phone:NSObject {
    static let LinkPrefix = "tel:"
    static let Separator = "/"

    class func annotate(_ phoneNo:String?) -> NSAttributedString? {
        guard let phoneNo = phoneNo else {
            return nil
        }
        
        let phoneString = NSMutableAttributedString(string: phoneNo)
        var startPos = 0
        for pn in phoneNo.components(separatedBy: Separator) {
            let pnTrim = pn.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if pnTrim != "" {
                let pnLink = LinkPrefix + pnTrim
                phoneString.addAttribute(NSAttributedString.Key.link, value: pnLink, range: NSMakeRange(startPos, pn.count))
            }
            startPos += 1 + pn.count
        }
        return phoneString
    }
}
