//
//  User.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-19.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation

class User {
    static let sharedUser = User()

    // Prevent other classes from instantiating - User is singleton!
    private init () {
    }
    
    // Public properties
    var userName:String? {
        get {
            let defaults = NSUserDefaults.standardUserDefaults()
            return defaults.stringForKey("user_name")
        }
        set(newName) {
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setObject(newName, forKey: "user_name")
        }
    }
    var password:String? {
        get {
            if let userName = userName {
                return Keychain.stringForAccount(userName)
            } else {
                return nil
            }
        }
        set(newPassword) {
            if let userName = userName, newPassword = newPassword {
                Keychain.setString(newPassword, forAccount: userName, synchronizable: true, background: true)
            } else if let userName = userName {
                Keychain.deleteAccount(userName)
            }else {
                print("Invalid user name or password")
            }
        }
    }
    var urlsafePassword:String? {
        let rawPassword = password ?? ""
        let safePassword = rawPassword.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.LiteralSearch, range: nil)
        
        return safePassword

    }
    var commonName:String? {
        return srvCommonName
    }
    var fullName:String? {
        return srvFullName
    }

    // Private properties
    private var srvCommonName:String?
    private var srvFullName:String?
    private var rsRequest: RSTransactionRequest = RSTransactionRequest()
    private var rsTransGetUser: RSTransaction = RSTransaction(transactionType: RSTransactionType.GET, baseURL: "https://www.shitt.no/mySHiT", path: "user", parameters: ["userName":"dummy@default.com","password":"******"])


    // Functions
    func hasCredentials() -> Bool {
        if userName == nil || userName == "" || password == nil || password == "" {
            return false
        }
        return true
    }


    func getCredentials() -> (name:String?, password:String?, urlsafePassword:String?) {
        return (name: userName, password:password, urlsafePassword:urlsafePassword)
    }
    

    func logon(userName userName: String, password: String) {
        //rsTransGetUser.parameters = ["userName":userName!,"password":urlsafePassword!]
        let urlsafePassword = password.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        rsTransGetUser.parameters = ["userName":userName,"password":urlsafePassword]
        rsRequest.dictionaryFromRSTransaction(rsTransGetUser, completionHandler: {(response : NSURLResponse!, responseDictionary: NSDictionary!, error: NSError!) -> Void in
            if let error = error {
                //dispatch_async(dispatch_get_main_queue(), {
                    print("Error : \(error.description)")
                //})
            } else if let error = responseDictionary["error"] {
                //dispatch_async(dispatch_get_main_queue(), {
                    let errMsg = error as! String
                    print("Error : \(errMsg)")
                //})
            } else {
                User.sharedUser.userName = userName
                User.sharedUser.password = password
                self.srvCommonName = responseDictionary["commonName"] as? String
                self.srvFullName = responseDictionary["fullName"] as? String
                NSNotificationCenter.defaultCenter().postNotificationName("logonSuccessful", object: self)
            }
        })
    }
    
    func logout() {
        // Must clear password first, otherwise the missing user name will prevent deleting the password
        password = nil
        userName = nil
        srvFullName = nil
        srvCommonName = nil

        // Delete all keychain entries just to make sure nothing is left
        Keychain.deleteAllAccounts()
    }
}