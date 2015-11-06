//
//  SecurityWrapper.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-21.
//  Initial code from Chris Hulberg, http://www.splinter.com.au/2015/06/21/swift-keychain-wrapper/
//  Copyright © 2015 Per Solberg. All rights reserved.
//

//import Foundation
import Security
import UIKit

enum KeychainError: ErrorType {
    case Unimplemented
    case Param
    case Allocate
    case NotAvailable
    case AuthFailed
    case DuplicateItem
    case ItemNotFound
    case InteractionNotAllowed
    case Decode
    case Unknown
    
    /// Returns the appropriate error for the status, or nil if it
    /// was successful, or Unknown for a code that doesn't match.
    static func errorFromOSStatus(rawStatus: OSStatus) ->
        KeychainError? {
            if rawStatus == errSecSuccess {
                return nil
            } else {
                // If the mapping doesn't find a match, return unknown.
                return mapping[rawStatus] ?? .Unknown
            }
    }
    
    static let mapping: [Int32: KeychainError] = [
        errSecUnimplemented: .Unimplemented,
        errSecParam: .Param,
        errSecAllocate: .Allocate,
        errSecNotAvailable: .NotAvailable,
        errSecAuthFailed: .AuthFailed,
        errSecDuplicateItem: .DuplicateItem,
        errSecItemNotFound: .ItemNotFound,
        errSecInteractionNotAllowed: .InteractionNotAllowed,
        errSecDecode: .Decode
    ]
}

struct SecItemWrapper {
    static func matching(query: [String: AnyObject]) throws -> AnyObject? {
        var rawResult: AnyObject?
        let rawStatus = SecItemCopyMatching(query, &rawResult)
        
        if let error = KeychainError.errorFromOSStatus(rawStatus) {
            throw error
        }
        return rawResult
    }
    
    static func add(attributes: [String: AnyObject]) throws -> AnyObject? {
        var rawResult: AnyObject?
        let rawStatus = SecItemAdd(attributes, &rawResult)
        
        if let error = KeychainError.errorFromOSStatus(rawStatus) {
            throw error
        }
        return rawResult
    }
    
    static func update(query: [String: AnyObject],
        attributesToUpdate: [String: AnyObject]) throws {
            let rawStatus = SecItemUpdate(query, attributesToUpdate)
            if let error = KeychainError.errorFromOSStatus(rawStatus) {
                throw error
            }
    }
    
    static func delete(query: [String: AnyObject]) throws {
        let rawStatus = SecItemDelete(query)
        if let error = KeychainError.errorFromOSStatus(rawStatus) {
            throw error
        }
    }
}

struct Keychain {
    
    static func deleteAccount(account: String) {
        do {
            try SecItemWrapper.delete([
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: Constants.service,
                kSecAttrAccount as String: account,
                kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
                ])
        } catch KeychainError.ItemNotFound {
            // Ignore this error.
        } catch let error {
            NSLog("deleteAccount error: \(error)")
        }
    }
    
    static func dataForAccount(account: String) -> NSData? {
        do {
            let query = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: Constants.service,
                kSecAttrAccount as String: account,
                kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
                kSecReturnData as String: kCFBooleanTrue as CFTypeRef,
            ]
            let result = try SecItemWrapper.matching(query)
            return result as? NSData
        } catch KeychainError.ItemNotFound {
            // Ignore this error, simply return nil.
            return nil
        } catch let error {
            NSLog("dataForAccount error: \(error)")
            return nil
        }
    }
    
    static func stringForAccount(account: String) -> String? {
        if let data = dataForAccount(account) {
            return NSString(data: data,
                encoding: NSUTF8StringEncoding) as? String
        } else {
            return nil
        }
    }
    
    static func setData(data: NSData,
        forAccount account: String,
        synchronizable: Bool,
        background: Bool) {
            do {
                // Remove the item if it already exists.
                // This saves having to deal with SecItemUpdate.
                // Reasonable people may disagree with this approach.
                deleteAccount(account)
                
                // Add it.
                try SecItemWrapper.add([
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: Constants.service,
                    kSecAttrAccount as String: account,
                    kSecAttrSynchronizable as String: synchronizable ?
                        kCFBooleanTrue : kCFBooleanFalse,
                    kSecValueData as String: data,
                    kSecAttrAccessible as String: background ?
                        kSecAttrAccessibleAfterFirstUnlock :
                    kSecAttrAccessibleWhenUnlocked,
                    ])
            } catch let error {
                NSLog("setData error: \(error)")
            }
    }


    static func setString(string: String,
        forAccount account: String,
        synchronizable: Bool,
        background: Bool) {
            let data = string.dataUsingEncoding(NSUTF8StringEncoding)!
            setData(data,
                forAccount: account,
                synchronizable: synchronizable,
                background: background)
    }


    static func listAccounts() {
        do {
            let query = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: Constants.service,
                kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
                kSecReturnAttributes as String: kCFBooleanTrue as CFTypeRef,
                kSecMatchLimit as String: kSecMatchLimitAll
            ]
            let accountListRaw = try SecItemWrapper.matching(query)
            
            if let accountList = accountListRaw as? [NSMutableDictionary] {
                print("Found \(accountList.count) accounts in Keychain: ", terminator: "")
                var sep = ""
                for account in accountList {
                    let userName = account[kSecAttrAccount as NSString] ?? "<Unknown>"
                    print("\(sep)\(userName!)", terminator: "")
                    sep = ", "
                }
                print("")
            }
        } catch KeychainError.ItemNotFound {
            // Ignore this error, simply return nil.
        } catch let error {
            NSLog("listAccounts error: \(error)")
        }
    }

    static func deleteAllAccounts() {
        do {
            try SecItemWrapper.delete([
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: Constants.service,
                //kSecAttrAccount as String: account,
                kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
                ])
        } catch KeychainError.ItemNotFound {
            // Ignore this error.
        } catch let error {
            NSLog("deleteAllAccounts error: \(error)")
        }
    }
    
    
    struct Constants {
        // FIXME: Change this to the name of your app or company!
        static let service = "MySHiT"
    }
}