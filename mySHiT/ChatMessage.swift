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
                 "createdTS": ServerDate.convertServerDate(createdTimestamp, timeZone: Constant.timezoneUTC)
               ]
    }


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
    
    
    //
    // MARK: NSCoding
    //
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
    
    
    //
    // MARK: Equatable
    //
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        let equal = lhs.localId == rhs.localId
        return equal
    }
    
    
    //
    // MARK: Initialisers
    //
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
        storedTimestamp = ServerDate.convertServerDate(elementData[Constant.JSON.msgStoredTS] as? String ?? "", timeZone: Constant.timezoneUTC)
        createdTimestamp = ServerDate.convertServerDate(elementData[Constant.JSON.msgCreatedTS] as? String, timeZone: Constant.timezoneUTC)
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
    
    
    //
    // MARK: Functions
    //
    func save(tripId: Int!, responseHandler parentResponseHandler: @escaping ((SHiTStatus, SHiTRetry?)?, URLResponse?, NSDictionary?, Error?) -> Void) {
        //Set the parameters for the RSTransaction object
        let threadResource = SHiTResource.thread(key: String(tripId), parameters: [])
        
        //Send request
        RESTRequest.put(threadResource, payload: savePayload) {(response : URLResponse?, responseDictionary: NSDictionary?, error: Error?) -> Void in
            let status = SHiTResource.checkStatus(response: response, responseDictionary: responseDictionary, error: error)
            if status.status == .ok {
                //Set the tableData NSArray to the results returned from www.shitt.no
                if let returnedMessage = responseDictionary?[Constant.JSON.queryMessage] as? NSDictionary {
                    //TODO: CHeck error (status = ERROR, errorCode = xxx, errorMsg = xxxx, retryMode = STOP)
                    self.id = returnedMessage["id"] as? Int
                    self.storedTimestamp = ServerDate.convertServerDate(returnedMessage["storedTS"] as? String ?? "", timeZone: Constant.timezoneUTC)
                    NotificationCenter.default.post(name: Constant.notification.chatRefreshed, object: self)
                } else {
                    os_log("Incorrect response: %{public}s", log: OSLog.webService, type: .error, String(describing: responseDictionary))
                }
            }
            parentResponseHandler(status, response, responseDictionary, error)
        }
    }

    
    func read(tripId: Int!, responseHandler parentResponseHandler: @escaping (URLResponse?, NSDictionary?, Error?)  -> Void ) {
        guard let id = id else {
            fatalError("Cannot update read status on message without ID")
        }
        type(of:self).read(msgId: id, tripId: tripId, responseHandler: parentResponseHandler)
    }
    
    
    static func read(msgId: Int!, tripId: Int!, responseHandler parentResponseHandler: @escaping (URLResponse?, NSDictionary?, Error?)  -> Void ) {
        let msgResource = SHiTResource.message(keys: [String(tripId), SHiTResource.Verb.read, String(msgId)], parameters: [])

        RESTRequest.post(msgResource, parameters: nil, payload: nil) {(response : URLResponse?, responseDictionary: NSDictionary?, error: Error?) -> Void in
            let status = SHiTResource.checkStatus(response: response, responseDictionary: responseDictionary, error: error)
            if status.status == .ok {
                // No need to do anything, already handled
            } else if let _ = responseDictionary {
                // No need to do anything, no useful information in success response
            } else {
                os_log("Incorrect response: %{public}s", log: OSLog.webService, type: .error, String(describing: responseDictionary))
            }
            parentResponseHandler(response, responseDictionary, error)
        }
    }
    
    
    static func read(fromUserInfo userInfo: UserInfo, responseHandler parentResponseHandler: @escaping (URLResponse?, NSDictionary?, Error?)  -> Void) {
        guard let changeType = userInfo[.changeType] as? String, let changeOp = userInfo[.changeOperation] as? String, changeType == "CHATMESSAGE" && changeOp == "INSERT" else {
            fatalError("Invalid usage, can only be used to initialise message from notification")
        }
        guard let ntfMsgId = userInfo[.id] as? String, let msgId = Int(ntfMsgId), let ntfTripId = userInfo[.tripId] as? String, let tripId = Int(ntfTripId) else {
            fatalError("Invalid chat message notification, no message ID or trip ID.")
        }
        read(msgId: msgId, tripId: tripId, responseHandler: parentResponseHandler)
    }

}
