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
}
