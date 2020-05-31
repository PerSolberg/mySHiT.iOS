//
//  UINavigationController+mySHiT.swift
//  mySHiT
//
//  Created by Per Solberg on 2020-05-31.
//  Copyright © 2020 &More AS. All rights reserved.
//

import Foundation
import UIKit

extension UINavigationController {
    func popDeepLinkedControllers() {
        while let dlVC = visibleViewController as? DeepLinkableViewController, dlVC.wasDeepLinked {
            popViewController(animated: true)
        }
    }
}
