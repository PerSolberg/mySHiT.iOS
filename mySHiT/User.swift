//
//  User.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-19.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation
import FirebaseMessaging
import os

class User : NSObject, NSCoding {
    static let sharedUser = User()
    
    // Keyed archiver configuration
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveUserURL = DocumentsDirectory.appendingPathComponent("user")

    //
    // MARK: Properties
    //
    fileprivate var srvUserId:Int?
    fileprivate var srvUserName:String?
    fileprivate var srvCommonName:String?
    fileprivate var srvFullName:String?
    fileprivate var srvInitials:String?
    fileprivate var srvShortName:String?
    
 
    // Public properties
    var userName:String? {
        get {
            return srvUserName
        }
        set(newName) {
            srvUserName = newName
            saveUser()
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
            if let userName = userName, let newPassword = newPassword {
                Keychain.setString(newPassword, forAccount: userName, synchronizable: true, background: true)
            } else if let userName = userName {
                Keychain.deleteAccount(userName)
            } else {
                os_log("Invalid user name or password", log: OSLog.general, type: .error)
            }
        }
    }
    var userId:Int? {
        return srvUserId
    }
    var commonName:String? {
        return srvCommonName
    }
    var fullName:String? {
        return srvFullName
    }
    var initials:String! {
        return srvInitials
    }
    var shortName:String! {
        return srvShortName
    }

    struct PropertyKey {
        static let userIdKey = "userId"
        static let userNameKey = "userName"
        static let fullNameKey = "fullName"
        static let commonNameKey = "commonName"
        static let shortNameKey = "shortName"
        static let initialsKey = "initals"
    }
    
    
    //
    // MARK: Initialisers
    //
    // Prevent other classes from instantiating - User is singleton!
    override fileprivate init () {
        super.init()
        loadUser()
    }

    
    //
    // MARK: NSCoding
    //
    func encode(with aCoder: NSCoder) {
        aCoder.encode(srvUserId, forKey: PropertyKey.userIdKey)
        aCoder.encode(srvUserName, forKey: PropertyKey.userNameKey)
        aCoder.encode(srvFullName, forKey: PropertyKey.fullNameKey)
        aCoder.encode(srvCommonName, forKey: PropertyKey.commonNameKey)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        // NB: use conditional cast (as?) for any optional properties
        //id = aDecoder.decodeInteger(forKey: PropertyKey.idKey)
        srvUserId = aDecoder.decodeObject(forKey: PropertyKey.userIdKey) as? Int ?? aDecoder.decodeInteger(forKey: PropertyKey.userIdKey)
        srvUserName = aDecoder.decodeObject(forKey: PropertyKey.userNameKey) as? String
        srvFullName  = aDecoder.decodeObject(forKey: PropertyKey.fullNameKey) as? String
        srvCommonName  = aDecoder.decodeObject(forKey: PropertyKey.commonNameKey) as? String
        srvShortName  = aDecoder.decodeObject(forKey: PropertyKey.shortNameKey) as? String
        srvInitials = aDecoder.decodeObject(forKey: PropertyKey.initialsKey) as? String
    }


    //
    // MARK: Functions
    //
    func hasCredentials() -> Bool {
        if userName == nil || userName == "" || password == nil || password == "" {
            return false
        }
        return true
    }


    func getCredentials() -> (name:String?, password:String?, urlsafePassword:String?) {
        return (name: userName, password:password, urlsafePassword:nil /*urlsafePassword*/)
    }
    

    func logon(userName: String, password: String) {
        let userResource = SHiTResource.user(parameters: [ URLQueryItem(name: SHiTResource.Param.userName, value: userName), URLQueryItem(name: SHiTResource.Param.password, value: password) ])
        RESTRequest.get(userResource) {(response : URLResponse?, responseDictionary: NSDictionary?, error: Error?) -> Void in
            let status = SHiTResource.checkStatus(response: response, responseDictionary: responseDictionary, error: error)
            if status.status == .ok {
                self.srvUserName = userName
                User.sharedUser.password = password
                self.srvCommonName = responseDictionary?[Constant.JSON.userCommonName] as? String
                self.srvFullName = responseDictionary?[Constant.JSON.userFullName] as? String
                self.srvUserId = responseDictionary?[Constant.JSON.userId] as? Int
                self.srvInitials = responseDictionary?[Constant.JSON.userInitials] as? String
                self.srvShortName = responseDictionary?[Constant.JSON.userShortName] as? String
                
                self.registerForPushNotifications()
                self.saveUser()

                NotificationCenter.default.post(name: Constant.notification.logonSuccessful, object: self)
            } else if status.status == .serverError {
                NotificationCenter.default.post(name: Constant.notification.logonFailed, object: self)
            }
        }
    }


    func logout() {
        deregisterPushNotifications()
        TripList.sharedList.deregisterPushNotifications()

        // Must clear password first, otherwise the missing user name will prevent deleting the password
        password = nil
        userName = nil
        srvFullName = nil
        srvCommonName = nil
        srvUserId = nil

        // Delete all keychain entries just to make sure nothing is left
        Keychain.deleteAllAccounts()
    }


    func deregisterPushNotifications() {
        if let userId = userId {
            let topicUser = Constant.Firebase.topicRootUser + String(userId)
            Messaging.messaging().unsubscribe(fromTopic: topicUser)
        }
    }
    
    
    func registerForPushNotifications() {
        if let userId = userId {
            let topicUser = Constant.Firebase.topicRootUser + String(userId)
            Messaging.messaging().subscribe(toTopic: topicUser)
        } else {
            os_log("User ID not available, can't register for notifications", log: OSLog.notification, type: .error)
        }
    }

    
    func saveUser() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(self, toFile: User.ArchiveUserURL.path)
        if !isSuccessfulSave {
            os_log("Failed to save user", log: OSLog.general, type: .error)
        }
    }
    
    func loadUser() {
        if try! FileManager.default.fileExists(atPath: User.ArchiveUserURL.path) && FileManager.default.attributesOfItem(atPath: User.ArchiveUserURL.path)[FileAttributeKey.size] as! Int > 0 {
            if let newUser = NSKeyedUnarchiver.unarchiveObject(withFile: User.ArchiveUserURL.path) as? User {
                self.srvUserId     = newUser.srvUserId
                self.srvUserName   = newUser.srvUserName
                self.srvFullName   = newUser.fullName
                self.srvCommonName = newUser.commonName
            }
        }
    }

}
