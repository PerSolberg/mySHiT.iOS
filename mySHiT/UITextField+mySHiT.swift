//
//  UITextField+mySHiT.swift
//  mySHiT
//
//  Created by Per Solberg on 2019-05-30.
//  Copyright © 2019 &More AS. All rights reserved.
//

import Foundation
import UIKit

extension UITextField
{
    func setText(_ value: String?, detectChanges: Bool) {
        if (detectChanges && value != text) {
            backgroundColor = UIColor.yellow
        }
        text = value
    }
    
    func setText(_ value: NSAttributedString?, detectChanges: Bool) {
        if (detectChanges && value != attributedText) {
            backgroundColor = UIColor.yellow
        }
        attributedText = value
    }
}
