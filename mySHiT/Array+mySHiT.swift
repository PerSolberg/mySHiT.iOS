//
//  Array+mySHiT.swift
//  mySHiT
//
//  Created by Per Solberg on 2019-06-16.
//  Copyright © 2019 &More AS. All rights reserved.
//

import Foundation

extension Array {
    mutating func appendOpt(_ newElement: Element?) {
        if let newElement = newElement {
            append(newElement)
        }
    }
}
