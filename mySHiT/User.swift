//
//  User.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-19.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import Foundation
import FirebaseMessaging

class User : NSObject, NSCoding {
    static let sharedUser = User()
    
    // Keyed archiver configuration
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveUserURL = DocumentsDirectory.appendingPathComponent("user")

    // Private properties
    fileprivate var srvUserId:Int?
    fileprivate var srvUserName:String?
    fileprivate var srvCommonName:String?
    fileprivate var srvFullName:String?
    fileprivate var srvInitials:String?
    fileprivate var srvShortName:String?
    
    fileprivate var rsRequest: RSTransactionRequest = RSTransactionRequest()
    fileprivate var rsTransGetUser: RSTransaction = RSTransaction(transactionType: RSTransactionType.get, baseURL: "https://www.shitt.no/mySHiT", path: "user", parameters: ["userName":"dummy@default.com","password":"******"])
    

    // Prevent other classes from instantiating - User is singleton!
    override fileprivate init () {
        super.init()
        loadUser()
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

    // Public properties
    var userName:String? {
        get {
            return srvUserName
            //let defaults = UserDefaults.standard
            //return defaults.string(forKey: "user_name")
        }
        set(newName) {
            srvUserName = newName
            saveUser()
            //let defaults = UserDefaults.standard
            //defaults.set(newName, forKey: "user_name")
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
                print("Setting password for \(userName)")
                Keychain.setString(newPassword, forAccount: userName, synchronizable: true, background: true)
            } else if let userName = userName {
                print("Deleting password for \(userName)")
                Keychain.deleteAccount(userName)
            } else {
                print("Invalid user name or password")
            }
        }
    }
    var urlsafePassword:String? {
        let rawPassword = password ?? ""
        let safePassword = rawPassword.replacingOccurrences(of: " ", with: "+", options: NSString.CompareOptions.literal, range: nil)
        
        return safePassword

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
    

    func logon(userName: String, password: String) {
        //rsTransGetUser.parameters = ["userName":userName!,"password":urlsafePassword!]
        let urlsafePassword = password.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        rsTransGetUser.parameters = ["userName":userName,"password":urlsafePassword]
        rsRequest.dictionaryFromRSTransaction(rsTransGetUser, completionHandler: {(response : URLResponse?, responseDictionary: NSDictionary?, error: Error?) -> Void in
            if let error = error    {
                if error._domain == "HTTP" && error._code == 401 {
                    print("Authentication failed")
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.logonFailed), object: self)
                }
                print("Network error : \(error.localizedDescription)")
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.networkError), object: self)
            } else if let error = responseDictionary?[Constant.JSON.queryError] {
                let errMsg = error as! String
                print("Server error : \(errMsg)")
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.logonFailed), object: self)
            } else {
                //User.sharedUser.userName = userName
                self.srvUserName = userName
                User.sharedUser.password = password
                self.srvCommonName = responseDictionary?[Constant.JSON.userCommonName] as? String
                self.srvFullName = responseDictionary?[Constant.JSON.userFullName] as? String
                self.srvUserId = responseDictionary?[Constant.JSON.userId] as? Int
                self.srvInitials = responseDictionary?[Constant.JSON.userInitials] as? String
                self.srvShortName = responseDictionary?[Constant.JSON.userShortName] as? String
                
                print("User logged on. User ID = \(String(describing: self.srvUserId)), Common name = \(String(describing:self.srvCommonName))")
                self.registerForPushNotifications()
                self.saveUser()

                NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.logonSuccessful), object: self)
            }
        })
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
            print("Unsubscribing from topic '\(topicUser)")
            FIRMessaging.messaging().unsubscribe(fromTopic: topicUser)
        }
    }
    
    
    func registerForPushNotifications() {
        if let userId = userId {
            let topicUser = Constant.Firebase.topicRootUser + String(userId)
            print("Subscribing to topic '\(topicUser)")
            FIRMessaging.messaging().subscribe(toTopic: topicUser)
        } else {
            print("User ID not available, can't register for notifications")
        }
    }

    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(srvUserId, forKey: PropertyKey.userIdKey)
        aCoder.encode(srvUserName, forKey: PropertyKey.userNameKey)
        aCoder.encode(srvFullName, forKey: PropertyKey.fullNameKey)
        aCoder.encode(srvCommonName, forKey: PropertyKey.commonNameKey)
    }
    
    
    func saveUser() {
        print("Saving user to iOS keyed archive")
        //User.sharedUser.saveToArchive(User.ArchiveUserURL.path)
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(self, toFile: User.ArchiveUserURL.path)
        if !isSuccessfulSave {
            print("Failed to save user...")
        } else {
            print("User saved to iOS keyed archive")
        }
    }
    
    func loadUser() {
        print("Loading user from iOS keyed archive")
        //TripList.sharedList.loadFromArchive(TripListViewController.ArchiveTripsURL.path)
        if try! FileManager.default.fileExists(atPath: User.ArchiveUserURL.path) && FileManager.default.attributesOfItem(atPath: User.ArchiveUserURL.path)[FileAttributeKey.size] as! Int > 0 {
            let fileSize = try! FileManager.default.attributesOfItem(atPath: User.ArchiveUserURL.path)[FileAttributeKey.size] as! NSNumber
            print("User archive size = " + fileSize.stringValue)
            if let newUser = NSKeyedUnarchiver.unarchiveObject(withFile: User.ArchiveUserURL.path) as? User {
                self.srvUserId     = newUser.srvUserId
                self.srvUserName   = newUser.srvUserName
                self.srvFullName   = newUser.fullName
                self.srvCommonName = newUser.commonName
            }
        }
        
        //User.sharedUser = newUser ?? User()
        //return sectionList
    }

}
