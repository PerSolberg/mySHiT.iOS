//
//  ChatMessage.swift
//  mySHiT
//
//  Created by Per Solberg on 2017-03-24.
//  Copyright © 2017 &More AS. All rights reserved.
//

import Foundation
import UIKit
import os

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
        id = aDecoder.decodeObject(forKey: PropertyKey.idKey) as? Int //?? aDecoder.decodeInteger(forKey: PropertyKey.idKey)
        userId = aDecoder.decodeObject(forKey: PropertyKey.userIdKey) as? Int ?? aDecoder.decodeInteger(forKey: PropertyKey.userIdKey)

        userName  = aDecoder.decodeObject(forKey: PropertyKey.userNameKey) as? String ?? "Unknown"
        userInitials = aDecoder.decodeObject(forKey: PropertyKey.userInitialsKey) as? String ?? "XXX"
        
        let savedDeviceType = aDecoder.decodeObject(forKey: PropertyKey.deviceTypeKey) as! String
        let savedDeviceId = aDecoder.decodeObject(forKey: PropertyKey.deviceIdKey) as! String
        let savedLocalId = aDecoder.decodeObject(forKey: PropertyKey.localIdKey) as! String
        
        localId = (savedDeviceType, savedDeviceId, savedLocalId)
        
        messageText = aDecoder.decodeObject(forKey: PropertyKey.messageTextKey) as? String
        storedTimestamp = aDecoder.decodeObject(forKey: PropertyKey.storedTimestampKey) as? Date
        createdTimestamp = aDecoder.decodeObject(forKey: PropertyKey.createdTimestampKey) as? Date
    }


    required init?(fromDictionary elementData: NSDictionary!) {
        id = elementData[Constant.JSON.msgId] as? Int
        userId = elementData[Constant.JSON.msgUserId] as? Int
        userName = elementData[Constant.JSON.msgUserName] as? String
        userInitials = elementData[Constant.JSON.msgUserInitials] as? String
        localId = ( elementData[Constant.JSON.msgDeviceType] as! String,
                    elementData[Constant.JSON.msgDeviceId] as! String,
                    elementData[Constant.JSON.msgLocalId] as! String )
        messageText = elementData[Constant.JSON.msgText] as? String
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
                os_log("Error : %s", type: .error, error.localizedDescription)
                NotificationCenter.default.post(name: Constant.notification.networkError, object: self)
            } else if let error = responseDictionary?[Constant.JSON.queryError] {
                let errMsg = error as! String
                os_log("Error : %s", type: .error, errMsg)
                NotificationCenter.default.post(name: Constant.notification.networkError, object: self)
            } else {
                //Set the tableData NSArray to the results returned from www.shitt.no
                if let returnedMessage = responseDictionary {
                    self.id = returnedMessage["id"] as? Int
                    self.storedTimestamp = ServerDate.convertServerDate(returnedMessage["storedTS"] as? String ?? "", timeZoneName: ChatMessage.Timezone)
                    NotificationCenter.default.post(name: Constant.notification.chatRefreshed, object: self)
                } else {
                    os_log("ERROR: Incorrect response: %s", type: .error, String(describing: responseDictionary))
                }
            }
            parentResponseHandler(response, responseDictionary, error)
        })
    }

    
    func read(tripId: Int!, responseHandler parentResponseHandler: @escaping (URLResponse?, NSDictionary?, Error?)  -> Void ) {
        guard let id = id else {
            fatalError("Cannot update read status on message without ID")
        }
        type(of:self).read(msgId: id, tripId: tripId, responseHandler: parentResponseHandler)
    }
    
    
    static func read(msgId: Int!, tripId: Int!, responseHandler parentResponseHandler: @escaping (URLResponse?, NSDictionary?, Error?)  -> Void ) {
        let userCred = User.sharedUser.getCredentials()
        assert( userCred.name != nil );
        assert( userCred.password != nil );
        assert( userCred.urlsafePassword != nil );

        let rsRequest: RSTransactionRequest = RSTransactionRequest()
        let rsTransReadMsg: RSTransaction = RSTransaction(transactionType: RSTransactionType.post, baseURL: "https://www.shitt.no/mySHiT", path: webServiceChatPath, parameters: ["userName":"dummy@default.com","password":"******"])
        
        //Set the parameters for the RSTransaction object
        rsTransReadMsg.path = webServiceChatPath + "/" + String(tripId) + "/" + webServiceReadMessageVerb + "/" + String(msgId)
        rsTransReadMsg.parameters = [ "userName":userCred.name!
            , "password":userCred.urlsafePassword!
        ]
        
        //Send request
        rsRequest.dictionaryFromRSTransaction(rsTransReadMsg, completionHandler: {(response : URLResponse?, responseDictionary: NSDictionary?, error: Error?) -> Void in
            if let error = error {
                os_log("Error : %s", type: .error, error.localizedDescription)
                NotificationCenter.default.post(name: Constant.notification.networkError, object: self)
            } else if let error = responseDictionary?[Constant.JSON.queryError] {
                let errMsg = error as! String
                os_log("Error : %s", type: .error, errMsg)
                NotificationCenter.default.post(name: Constant.notification.networkError, object: self)
            } else if let _ /*responseDictionary*/ = responseDictionary {
                //print("Chat message read: \(String(describing: responseDictionary))")
            } else {
                os_log("ERROR: Incorrect response: %s", type: .error, String(describing: responseDictionary))
            }
            parentResponseHandler(response, responseDictionary, error)
        })
    }
    
    static func read(fromUserInfo userInfo: UserInfo/*[AnyHashable:Any]*/, responseHandler parentResponseHandler: @escaping (URLResponse?, NSDictionary?, Error?)  -> Void) {
        //super.init(fromDictionary: elementData)
        guard let changeType = userInfo[.changeType] as? String, let changeOp = userInfo[.changeOperation] as? String, changeType == "CHATMESSAGE" && changeOp == "INSERT" else {
            fatalError("Invalid usage, can only be used to initialise message from notification")
        }
        guard let ntfMsgId = userInfo[.id] as? String, let msgId = Int(ntfMsgId), let ntfTripId = userInfo[.tripId] as? String, let tripId = Int(ntfTripId) else {
            fatalError("Invalid chat message notification, no message ID or trip ID.")
        }
        read(msgId: msgId, tripId: tripId, responseHandler: parentResponseHandler)
    }

}
