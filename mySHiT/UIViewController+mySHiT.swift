//
//  UIViewController+mySHiT.swift
//  mySHiT
//
//  Created by Per Solberg on 2018-01-24.
//  Copyright © 2018 &More AS. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController
{
    @objc func isSame(_ vc:UIViewController) -> Bool {
        if type(of:vc) != type(of:self) {
            return false
        } else {
            print("Not sure if view controllers are identical - probably not")
            return false
        }
    }
    
    func getAttributedReferences(_ refList: [ [String:String] ], typeKey: String, refKey: String, urlKey: String) -> NSDictionary {
        let refDict = NSMutableDictionary()
        for ref in refList {
            if let refType = ref[typeKey], let refNo = ref[refKey] {
                var refText:NSAttributedString?
                if let refUrl = ref[urlKey], let url = URL(string: refUrl) {
                    let hyperlinkText = NSMutableAttributedString(string: refNo)
                    hyperlinkText.addAttribute(NSAttributedString.Key.link, value: url, range: NSMakeRange(0, hyperlinkText.length))
                    refText = hyperlinkText
                } else {
                    refText = NSAttributedString(string:refNo)
                }
                refDict[refType] = refText
            }
        }
        
        return refDict
    }

    /*
    var isModal: Bool {
        return self.presentingViewController?.presentedViewController == self
            || (self.navigationController != nil && self.navigationController?.presentingViewController?.presentedViewController == self.navigationController && self.navigationController?.viewControllers[0] == self)
            || self.tabBarController?.presentingViewController is UITabBarController
    }
     */
}
