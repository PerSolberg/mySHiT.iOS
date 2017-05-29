//
//  ChatMessage.swift
//  mySHiT
//
//  Created by Per Solberg on 2017-03-24.
//  Copyright © 2017 &More AS. All rights reserved.
//

import Foundation
import UIKit

class ChatMessage: NSObject, NSCoding {
    typealias LocalId = (deviceType: String, deviceId: String, localId: String)
    static let missingLocalId:LocalId = ("", "", "")
    
    static var dateFormatter = DateFormatter()

    var id: Int?
    var userId: Int!
    var userName: String!
    var userInitials: String!
    var localId: LocalId!
    var messageText: String!
    var storedTimestamp: Date?
    var createdTimestamp: Date!

    var lastSeenBy: [String] = []
    
    var isStored:Bool {
        return (id != nil)
    }
    var savePayload:[String:String] {
        return [ "deviceType": localId.deviceType,
                 "deviceId": localId.deviceId,
                 "localId": localId.localId,
                 "message": messageText,
                 "createdTS": ServerDate.convertServerDate(createdTimestamp, timeZoneName: ChatMessage.Timezone)
               ]
    }

    static let Timezone = "UTC"

    static let webServiceChatPath = "thread"
    static let webServiceReadMessageVerb = "read"
    var rsRequest: RSTransactionRequest = RSTransactionRequest()
    var rsTransSendMsg: RSTransaction = RSTransaction(transactionType: RSTransactionType.put, baseURL: "https://www.shitt.no/mySHiT", path: webServiceChatPath, parameters: ["userName":"dummy@default.com","password":"******"])
    var rsTransReadMsg: RSTransaction = RSTransaction(transactionType: RSTransactionType.post, baseURL: "https://www.shitt.no/mySHiT", path: webServiceChatPath, parameters: ["userName":"dummy@default.com","password":"******"])

    struct PropertyKey {
        static let idKey = "id"
        static let userIdKey = "userId"
        static let userNameKey = "userName"
        static let userInitialsKey = "userInitials"
        static let deviceTypeKey = "deviceType"
        static let deviceIdKey = "deviceId"
        static let localIdKey = "localId"
        static let messageTextKey = "messageText"
        static let storedTimestampKey = "storedTS"
        static let createdTimestampKey = "createdTS"
    }
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: PropertyKey.idKey)
        aCoder.encode(userId, forKey: PropertyKey.userIdKey)
        aCoder.encode(userName, forKey: PropertyKey.userNameKey)
        aCoder.encode(userInitials, forKey: PropertyKey.userInitialsKey)
        aCoder.encode(localId.deviceType, forKey: PropertyKey.deviceTypeKey)
        aCoder.encode(localId.deviceId, forKey: PropertyKey.deviceIdKey)
        aCoder.encode(localId.localId, forKey: PropertyKey.localIdKey)
        aCoder.encode(messageText, forKey: PropertyKey.messageTextKey)
        aCoder.encode(storedTimestamp, forKey: PropertyKey.storedTimestampKey)
        aCoder.encode(createdTimestamp, forKey: PropertyKey.createdTimestampKey)
    }
    
    // MARK: Equatable
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.localId == rhs.localId
    }
    
    // MARK: Initialisers
    required init?(coder aDecoder: NSCoder) {
//        print("Decoding ChatMessage")
        // NB: use conditional cast (as?) for any optional properties
        id = aDecoder.decodeObject(forKey: PropertyKey.idKey) as? Int //?? aDecoder.decodeInteger(forKey: PropertyKey.idKey)
        userId = aDecoder.decodeObject(forKey: PropertyKey.userIdKey) as? Int ?? aDecoder.decodeInteger(forKey: PropertyKey.userIdKey)

        userName  = aDecoder.decodeObject(forKey: PropertyKey.userNameKey) as? String ?? "Unknown"
        userInitials = aDecoder.decodeObject(forKey: PropertyKey.userInitialsKey) as? String ?? "XXX"
        
        let savedDeviceType = aDecoder.decodeObject(forKey: PropertyKey.deviceTypeKey) as! String
        let savedDeviceId = aDecoder.decodeObject(forKey: PropertyKey.deviceIdKey) as! String
        let savedLocalId = aDecoder.decodeObject(forKey: PropertyKey.localIdKey) as! String
        
        localId = (savedDeviceType, savedDeviceId, savedLocalId)

        messageText = aDecoder.decodeObject(forKey: PropertyKey.messageTextKey) as! String
        storedTimestamp = aDecoder.decodeObject(forKey: PropertyKey.storedTimestampKey) as? Date
        createdTimestamp = aDecoder.decodeObject(forKey: PropertyKey.createdTimestampKey) as! Date
    }


    required init?(fromDictionary elementData: NSDictionary!) {
        //super.init(fromDictionary: elementData)
        id = elementData[Constant.JSON.msgId] as? Int
        userId = elementData[Constant.JSON.msgUserId] as! Int
        userName = elementData[Constant.JSON.msgUserName] as! String
        userInitials = elementData[Constant.JSON.msgUserInitials] as! String
        localId = ( elementData[Constant.JSON.msgDeviceType] as! String,
                    elementData[Constant.JSON.msgDeviceId] as! String,
                    elementData[Constant.JSON.msgLocalId] as! String )
        messageText = elementData[Constant.JSON.msgText] as! String
        storedTimestamp = ServerDate.convertServerDate(elementData[Constant.JSON.msgStoredTS] as? String ?? "", timeZoneName: ChatMessage.Timezone)
        createdTimestamp = ServerDate.convertServerDate(elementData[Constant.JSON.msgCreatedTS] as! String, timeZoneName: ChatMessage.Timezone)

    }
    
    init(message: String!) {
        id = nil
        userId = User.sharedUser.userId
        userName = User.sharedUser.shortName
        userInitials = User.sharedUser.initials
        localId = (Constant.deviceType, UIDevice.current.identifierForVendor!.uuidString, NSUUID().uuidString)
        messageText = message
        storedTimestamp = nil
        createdTimestamp = Date()
    }
    
    
    // MARK: Functions
    func save(tripId: Int!, responseHandler parentResponseHandler: @escaping (URLResponse?, NSDictionary?, Error?) -> Void) {
        let userCred = User.sharedUser.getCredentials()
        
        assert( userCred.name != nil );
        assert( userCred.password != nil );
        assert( userCred.urlsafePassword != nil );
        
        //Set the parameters for the RSTransaction object
        rsTransSendMsg.path = type(of: self).webServiceChatPath + "/" + String(tripId)
        rsTransSendMsg.parameters = [ "userName":userCred.name!
            , "password":userCred.urlsafePassword!
            ]
        rsTransSendMsg.payload = self.savePayload
        
        //Send request
        rsRequest.dictionaryFromRSTransaction(rsTransSendMsg, completionHandler: {(response : URLResponse?, responseDictionary: NSDictionary?, error: Error?) -> Void in
            if let error = error {
                //If there was an error, log it
                print("Error : \(error.localizedDescription)")
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.networkError), object: self)
            } else if let error = responseDictionary?[Constant.JSON.queryError] {
                let errMsg = error as! String
                print("Error : \(errMsg)")
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.networkError), object: self)
            } else {
                //Set the tableData NSArray to the results returned from www.shitt.no
                print("Chat message saved: \(String(describing: responseDictionary))")
                if let returnedMessage = responseDictionary {
                    self.id = returnedMessage["id"] as? Int
                    self.storedTimestamp = ServerDate.convertServerDate(returnedMessage["storedTS"] as? String ?? "", timeZoneName: ChatMessage.Timezone)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.chatRefreshed), object: self)
                } else {
                    print("ERROR: Incorrect response: \(String(describing: responseDictionary))")
                }
            }
            parentResponseHandler(response, responseDictionary, error)
        })
    }

    func read(tripId: Int!, responseHandler parentResponseHandler: @escaping (URLResponse?, NSDictionary?, Error?)  -> Void ) {
        guard let id = id else {
            fatalError("Cannot update read status on message without ID")
        }
        let userCred = User.sharedUser.getCredentials()

        assert( userCred.name != nil );
        assert( userCred.password != nil );
        assert( userCred.urlsafePassword != nil );

        //Set the parameters for the RSTransaction object
        rsTransReadMsg.path = type(of: self).webServiceChatPath + "/" + String(tripId) + "/" + type(of: self).webServiceReadMessageVerb + "/" + String(id)
        rsTransReadMsg.parameters = [ "userName":userCred.name!
            , "password":userCred.urlsafePassword!
        ]
        
        //Send request
        rsRequest.dictionaryFromRSTransaction(rsTransReadMsg, completionHandler: {(response : URLResponse?, responseDictionary: NSDictionary?, error: Error?) -> Void in
            if let error = error {
                //If there was an error, log it
                print("Error : \(error.localizedDescription)")
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.networkError), object: self)
            } else if let error = responseDictionary?[Constant.JSON.queryError] {
                let errMsg = error as! String
                print("Error : \(errMsg)")
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.networkError), object: self)
            } else if let responseDictionary = responseDictionary {
                print("Chat message read: \(String(describing: responseDictionary))")
            } else {
                print("ERROR: Incorrect response: \(String(describing: responseDictionary))")
            }
            parentResponseHandler(response, responseDictionary, error)
        })
    }
    
}
