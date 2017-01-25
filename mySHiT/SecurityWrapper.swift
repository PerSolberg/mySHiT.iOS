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

enum KeychainError: Error {
    case unimplemented
    case param
    case allocate
    case notAvailable
    case authFailed
    case duplicateItem
    case itemNotFound
    case interactionNotAllowed
    case decode
    case unknown
    
    /// Returns the appropriate error for the status, or nil if it
    /// was successful, or Unknown for a code that doesn't match.
    static func errorFromOSStatus(_ rawStatus: OSStatus) ->
        KeychainError? {
            if rawStatus == errSecSuccess {
                return nil
            } else {
                // If the mapping doesn't find a match, return unknown.
                return mapping[rawStatus] ?? .unknown
            }
    }
    
    static let mapping: [Int32: KeychainError] = [
        errSecUnimplemented: .unimplemented,
        errSecParam: .param,
        errSecAllocate: .allocate,
        errSecNotAvailable: .notAvailable,
        errSecAuthFailed: .authFailed,
        errSecDuplicateItem: .duplicateItem,
        errSecItemNotFound: .itemNotFound,
        errSecInteractionNotAllowed: .interactionNotAllowed,
        errSecDecode: .decode
    ]
}

struct SecItemWrapper {
    static func matching(_ query: [String: AnyObject]) throws -> AnyObject? {
        var rawResult: AnyObject?
        let rawStatus = SecItemCopyMatching(query as CFDictionary, &rawResult)
        
        if let error = KeychainError.errorFromOSStatus(rawStatus) {
            throw error
        }
        return rawResult
    }
    
    static func add(_ attributes: [String: AnyObject]) throws -> AnyObject? {
        var rawResult: AnyObject?
        let rawStatus = SecItemAdd(attributes as CFDictionary, &rawResult)
        
        if let error = KeychainError.errorFromOSStatus(rawStatus) {
            throw error
        }
        return rawResult
    }
    
    static func update(_ query: [String: AnyObject],
        attributesToUpdate: [String: AnyObject]) throws {
            let rawStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            if let error = KeychainError.errorFromOSStatus(rawStatus) {
                throw error
            }
    }
    
    static func delete(_ query: [String: AnyObject]) throws {
        let rawStatus = SecItemDelete(query as CFDictionary)
        if let error = KeychainError.errorFromOSStatus(rawStatus) {
            throw error
        }
    }
}

struct Keychain {
    
    static func deleteAccount(_ account: String) {
        do {
            try SecItemWrapper.delete([
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: Constants.service as AnyObject,
                kSecAttrAccount as String: account as AnyObject,
                kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
                ])
        } catch KeychainError.itemNotFound {
            // Ignore this error.
        } catch let error {
            NSLog("deleteAccount error: \(error)")
        }
    }
    
    static func dataForAccount(_ account: String) -> Data? {
        do {
            let query = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: Constants.service,
                kSecAttrAccount as String: account,
                kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
                kSecReturnData as String: kCFBooleanTrue as CFTypeRef,
            ] as [String : Any]
            let result = try SecItemWrapper.matching(query as [String : AnyObject])
            return result as? Data
        } catch KeychainError.itemNotFound {
            // Ignore this error, simply return nil.
            return nil
        } catch let error {
            NSLog("dataForAccount error: \(error)")
            return nil
        }
    }
    
    static func stringForAccount(_ account: String) -> String? {
        if let data = dataForAccount(account) {
            return NSString(data: data,
                encoding: String.Encoding.utf8.rawValue) as? String
        } else {
            return nil
        }
    }
    
    static func setData(_ data: Data,
        forAccount account: String,
        synchronizable: Bool,
        background: Bool) {
            do {
                // Remove the item if it already exists.
                // This saves having to deal with SecItemUpdate.
                // Reasonable people may disagree with this approach.
                deleteAccount(account)
                
                // Add it.
                try _ = SecItemWrapper.add([
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: Constants.service as AnyObject,
                    kSecAttrAccount as String: account as AnyObject,
                    kSecAttrSynchronizable as String: synchronizable ?
                        kCFBooleanTrue : kCFBooleanFalse,
                    kSecValueData as String: data as AnyObject,
                    kSecAttrAccessible as String: background ?
                        kSecAttrAccessibleAfterFirstUnlock :
                    kSecAttrAccessibleWhenUnlocked,
                    ])
            } catch let error {
                NSLog("setData error: \(error)")
            }
    }


    static func setString(_ string: String,
        forAccount account: String,
        synchronizable: Bool,
        background: Bool) {
            let data = string.data(using: String.Encoding.utf8)!
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
            ] as [String : Any]
            let accountListRaw = try SecItemWrapper.matching(query as [String : AnyObject])
            
            if let accountList = accountListRaw as? [NSMutableDictionary] {
                print("Found \(accountList.count) accounts in Keychain: ", terminator: "")
                var sep = ""
                for account in accountList {
                    let userName = account[kSecAttrAccount as NSString] ?? "<Unknown>"
                    print("\(sep)\(userName)", terminator: "")
                    sep = ", "
                }
                print("")
            }
        } catch KeychainError.itemNotFound {
            // Ignore this error, simply return nil.
        } catch let error {
            NSLog("listAccounts error: \(error)")
        }
    }

    static func deleteAllAccounts() {
        do {
            try SecItemWrapper.delete([
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: Constants.service as AnyObject,
                //kSecAttrAccount as String: account,
                kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
                ])
        } catch KeychainError.itemNotFound {
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
