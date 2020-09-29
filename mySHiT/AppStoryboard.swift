//
//  AppStoryboard.swift
//  mySHiT
//
//  Created by Per Solberg on 2020-08-22.
//  Copyright © 2020 &More AS. All rights reserved.
//

import Foundation
import UIKit

enum AppStoryboard:String {
    case Main
    
    var instance:UIStoryboard {
        return UIStoryboard(name: self.rawValue, bundle: Bundle.main)
    }
    
    func viewController<T:UIViewController>(ofClass vcClass: T.Type) -> T {
        let storyboardID = (vcClass as UIViewController.Type).storyboardID
        return instance.instantiateViewController(withIdentifier: storyboardID) as! T
    }
    
    func localizedString(_ stringToLocalize:String) -> String {
        return Bundle.main.localizedString(forKey: stringToLocalize, value: nil, table: self.rawValue)
    }
}
