//
//  RSTransaction.swift
//  RSNetworkSample
//
//  Created by Jon Hoffman on 7/25/14.
//  Copyright (c) 2014 Jon Hoffman. All rights reserved.
//

import Foundation

enum RSTransactionType {
    case get
    case post
    case unknown
}

class RSTransaction: NSObject {
    var transactionType = RSTransactionType.unknown
    var baseURL: String
    var path: String
    var parameters : [String:String]
    var payload : [String: String]?
    
    convenience init(transactionType: RSTransactionType, baseURL: String,  path: String, parameters: [String: String]) {
        //self.transactionType = transactionType
        //self.baseURL = baseURL
        //self.path = path
        //self.parameters = parameters
        self.init(transactionType: transactionType, baseURL: baseURL, path: path, parameters: parameters, payload: nil)
    }
    
    init(transactionType: RSTransactionType, baseURL: String,  path: String, parameters: [String: String], payload: [String: String]?) {
        self.transactionType = transactionType
        self.baseURL = baseURL
        self.path = path
        self.parameters = parameters
        self.payload = payload
    }
    
    func getFullURLString() -> String {
        return removeSlashFromEndOfString(self.baseURL) + "/" + removeSlashFromStartOfString(self.path)
    }
    
    
    fileprivate func removeSlashFromEndOfString(_ string: String) -> String
    {
        if string.hasSuffix("/") {
            return string.substring(to: string.characters.index(before: string.endIndex))
        } else {
            return string
        }
        
    }
    
    fileprivate func removeSlashFromStartOfString(_ string : String) -> String {
        if string.hasPrefix("/") {
            return string.substring(from: string.characters.index(after: string.startIndex))
        } else {
            return string
        }
    }
}
