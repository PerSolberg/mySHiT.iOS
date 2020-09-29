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
        aCoder.encode(srvShortName, forKey: PropertyKey.shortNameKey)
        aCoder.encode(srvInitials, forKey: PropertyKey.initialsKey)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        srvUserId = aDecoder.decodeObject(forKey: PropertyKey.userIdKey) as? Int
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


    func getCredentials() -> (name:String?, password:String?) {
        return (name: userName, password:password)
    }
    

    func logon(userName: String, password: String) {
        let userResource = SHiTResource.user(parameters: [ URLQueryItem(name: SHiTResource.Param.userName, value: userName), URLQueryItem(name: SHiTResource.Param.password, value: password) ])
        RESTRequest.get(userResource) {(response : URLResponse?, responseDictionary: NSDictionary?, error: Error?) -> Void in
            let status = SHiTResource.checkStatus(response: response, responseDictionary: responseDictionary, error: error)
            if status.status == .ok {
                if let userJSON =  responseDictionary?[Constant.JSON.queryUser] as? NSDictionary {
                    self.srvUserName = userName
                    User.sharedUser.password = password
                    self.srvCommonName = userJSON[Constant.JSON.userCommonName] as? String
                    self.srvFullName = userJSON[Constant.JSON.userFullName] as? String
                    self.srvUserId = userJSON[Constant.JSON.userId] as? Int
                    self.srvInitials = userJSON[Constant.JSON.userInitials] as? String
                    self.srvShortName = userJSON[Constant.JSON.userShortName] as? String
                    
                    self.registerForPushNotifications()
                    self.saveUser()

                    NotificationCenter.default.post(name: Constant.Notification.logonSuccessful, object: self)
                } else {
                    os_log("Incorrect web service response, element '%{public}s' not found", log: OSLog.webService, type: .error, Constant.JSON.queryUser)
                }
            } else if status.status == .serverError {
                NotificationCenter.default.post(name: Constant.Notification.logonFailed, object: self)
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
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
            try data.write(to: Constant.Archive.userURL)
        } catch {
            os_log("Failed to save user: %{public}s", log: OSLog.general, type: .error, error.localizedDescription)
        }
    }
    
    func loadUser() {
        if try! FileManager.default.fileExists(atPath: Constant.Archive.userURL.path) && FileManager.default.attributesOfItem(atPath: Constant.Archive.userURL.path)[FileAttributeKey.size] as! Int > 0 {
            do {
                let fileData = try Data(contentsOf: Constant.Archive.userURL)
                if let newUser = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(fileData) as? User {
                    self.srvUserId     = newUser.srvUserId
                    self.srvUserName   = newUser.srvUserName
                    self.srvFullName   = newUser.fullName
                    self.srvCommonName = newUser.commonName
                    self.srvInitials   = newUser.srvInitials
                    self.srvShortName  = newUser.srvShortName
                }
            } catch {
                os_log("Failed to load user: %{public}s", log: OSLog.general, type: .error, error.localizedDescription)
            }
        }
    }
}
