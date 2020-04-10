//
//  GlobalFunctions.swift
//  mySHiT
//
//  Created by Per Solberg on 2020-03-26.
//  Copyright © 2020 &More AS. All rights reserved.
//

import Foundation

func printStack(filterMySHiT: Bool) {
    for symbol in Thread.callStackSymbols {
        if symbol.contains("mySHiT") || !filterMySHiT {
            print(symbol)
        }
    }
}
