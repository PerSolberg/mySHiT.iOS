//
//  UIViewController+mySHiT.swift
//  mySHiT
//
//  Created by Per Solberg on 2018-01-24.
//  Copyright © 2018 &More AS. All rights reserved.
//

import Foundation
import UIKit
import os

extension UIViewController
{
    @objc func isSame(_ vc:UIViewController) -> Bool {
        if type(of:vc) != type(of:self) {
            return false
        } else {
            // Not sure if view controllers are identical - probably not
            return false
        }
    }

    
    func getAttributedReferences(_ refList: Set<[String:String]>, typeKey: String, refKey: String, urlKey: String) -> NSDictionary {
        let refDict = NSMutableDictionary()
        for ref in refList {
            if let refType = ref[typeKey], let refNo = ref[refKey] {
                var refText:NSAttributedString?
                if let refUrl = ref[urlKey] {
                    let hyperlinkText = NSMutableAttributedString(string: refNo)
                    hyperlinkText.addLink(for: ".+") { match -> String? in
                        return refUrl
                    }
                    refText = hyperlinkText
                } else {
                    refText = NSAttributedString(string:refNo)
                }
                refDict[refType] = refText
            }
        }
        
        return refDict
    }

    
    func showAlert(title: String, message: String, completion completionHandler: ( () -> Void )?) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: title,
                message: message,
                preferredStyle: UIAlertController.Style.alert)
            alert.addAction(Constant.alert.actionOK)
            self.present(alert, animated: true, completion: completionHandler)
        }
    }
    
}
