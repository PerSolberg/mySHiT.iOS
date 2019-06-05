//
//  DeepLinkableViewController.swift
//  mySHiT
//
//  Created by Per Solberg on 2019-06-02.
//  Copyright © 2019 &More AS. All rights reserved.
//

import Foundation
import UIKit

protocol DeepLinkableViewController {
    var wasDeepLinked: Bool { get set }
}
