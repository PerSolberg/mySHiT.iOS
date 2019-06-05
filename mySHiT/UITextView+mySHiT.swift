//
//  UITextView+mySHiT.swift
//  mySHiT
//
//  Created by Per Solberg on 2019-05-20.
//  Copyright © 2019 &More AS. All rights reserved.
//

import Foundation
import UIKit

extension UITextView
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
    
    func alignBaseline(to label:UILabel!) {
        var baselineShift:CGFloat = 0.0
        if let myFont = self.font {
            baselineShift = (label.font.ascender - myFont.ascender)
        }
        self.textContainerInset = UIEdgeInsets(top: baselineShift, left: 0, bottom: 0, right: 0)
    }
}
