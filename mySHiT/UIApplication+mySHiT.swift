//
//  UIApplication+mySHiT.swift
//  mySHiT
//
//  Created by Per Solberg on 2020-05-31.
//  Copyright © 2020 &More AS. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication {
    static var rootViewController: UIViewController? {
        return UIWindow.key?.rootViewController
    }
    static var rootNavigationController: UINavigationController? {
        return rootViewController as? UINavigationController
    }
}
