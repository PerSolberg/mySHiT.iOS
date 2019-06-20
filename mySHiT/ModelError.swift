//
//  ModelError.swift
//  mySHiT
//
//  Created by Per Solberg on 2019-06-16.
//  Copyright © 2019 &More AS. All rights reserved.
//

import Foundation

enum ModelError: Error {
    case compareTypeMismatch (selfType: String, otherType: String)
}
