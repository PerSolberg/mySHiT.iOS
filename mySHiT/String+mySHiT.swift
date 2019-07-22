//
//  String+mySHiT.swift
//  mySHiT
//
//  Created by Per Solberg on 2019-07-03.
//  Copyright © 2019 &More AS. All rights reserved.
//

//import Foundation

extension String {
    func trimPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }

    func trimSuffix(_ suffix: String) -> String {
        guard self.hasSuffix(suffix) else { return self }
        return String(self.dropLast(suffix.count))
    }
}
