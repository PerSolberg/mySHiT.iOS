//
//  UIWindow+mySHiT.swift
//  mySHiT
//
//  Created by Per Solberg on 2020-05-24.
//  Copyright © 2020 &More AS. All rights reserved.
//

//import Foundation
import UIKit

extension UIWindow {
    static var key: UIWindow? {
        if #available(iOS 13, *) {
            return UIApplication.shared.windows.first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.keyWindow
        }
    }
}
