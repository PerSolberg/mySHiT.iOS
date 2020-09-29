//
//  ChatThread.swift
//  mySHiT
//
//  Created by Per Solberg on 2017-04-13.
//  Copyright © 2017 &More AS. All rights reserved.
//

import Foundation
import UIKit
import os

class ChatThread:NSObject, NSCoding {
    enum RefreshMode:String {
        case full           = "F"
        case incremental    = "I"
    }
    
    private var messages = [ChatMessage]()
    private var messageVersion:Int?
    private var lastSeenByOthers = NSDictionary()
    private var lastDisplayedId:ChatMessage.LocalId?
    private var lastDisplayedPosition:UITableView.ScrollPosition?
    private var lastSeenByUserLocal:Int?
    private var lastSeenByUserServer:Int?
    private var lastSeenVersion:Int?
    private var tripId:Int
    var messageBeingEntered:String?
    private var savedExactPosition:CGPoint?
    
    private var savedPosition:(ChatMessage.LocalId, UITableView.ScrollPosition)?
    private var retryCount:Int = 0
    
    static let dqServerComm = DispatchQueue(label: "no.andmore.mySHiT.chat.server", target: .global())
    static let dqAccess = DispatchQueue(label: "no.andmore.mySHiT.chat.access", attributes: .concurrent, target: .global())
    
    static let retryDelays = [ 1: 5.0, 10: 30.0, 20: 300.0, 30: 1800.0 ]


    struct PropertyKey {
        static let messagesKey = "messages"
        static let tripIdKey = "tripId"
        static let lastSeenByOthersKey = "lastSeenByOthers"
        static let lastDisplayedId_deviceTypeKey = "lastDisplayedId.deviceType"
        static let lastDisplayedId_deviceIdKey = "lastDisplayedId.deviceId"
        static let lastDisplayedId_localIdKey = "lastDisplayedId.localId"
        static let lastSeenByUserLocalKey = "lastSeenByUserLocal"
        static let lastSeenByUserServerKey = "lastSeenByUserServer"
        static let messageVersionKey = "messageVersion"
        static let lastDisplayedPositionKey = "lastDisplayedPosition"
        static let lastSeenVersionKey = "lastSeenVersion"
    }


    //
    // MARK: Properties
    //
    var count:Int! {
        var count = 0
        
        ChatThread.dqAccess.sync {
            count = messages.count
        }

        return count
    }


    private var retryDelay:Double {
        if retryCount == 0 {
            return 0
        } else {
            var delayFound = 0.0
            for (lowerBound, delay) in ChatThread.retryDelays {
                if lowerBound <= retryCount && delay > delayFound {
                    delayFound = delay
                }
            }
            return delayFound
        }
    }


    var unreadCount:Int! {
        var count = 0
        
        ChatThread.dqAccess.sync {
            let unreadMessages = messages.filter( { (m:ChatMessage) -> Bool in
                return m.isStored && m.id! > (lastSeenByUserLocal ?? 0)
            })
            count = unreadMessages.count
        }
        
        return count
    }


    // Unsynced method should only be used from tasks on dispatch queue dqAccess
    fileprivate var lastDisplayedItemUnsynced:Int? {
        var item:Int?
        
        if let id = lastDisplayedId {
            item = self.messages.firstIndex(where: { (m) -> Bool in
                return (m.localId ?? ChatMessage.missingLocalId) == id
            })
        } else if let id = lastSeenByUserLocal ?? lastSeenByUserServer {
            item = self.messages.firstIndex(where: { (m) -> Bool in
                return (m.id ?? 0) == id
            })
        }
        
        return item
    }
    var lastDisplayedItem:Int? {
        ChatThread.dqAccess.sync {
            return lastDisplayedItemUnsynced
        }
    }
    
    
    var lastDisplayedItemPosition:UITableView.ScrollPosition {
        var pos:UITableView.ScrollPosition = .top
        
        ChatThread.dqAccess.sync {
            pos = lastDisplayedPosition ?? .top
        }
        
        return pos
    }
    
    
    var exactPosition:CGPoint? {
        get {
            let returnValue = savedExactPosition
            savedExactPosition = nil
            return returnValue
        }
        set(newValue) {
            savedExactPosition = newValue
        }
    }
    
    
    subscript(index: Int) -> ChatMessage {
        get {
            var message:ChatMessage!
            ChatThread.dqAccess.sync {
                guard index < self.messages.count else {
                    fatalError("Trying to retrieve non-existing message [\(index)] of \(self.messages.count)")
                }
                message = self.messages[index]
                lastDisplayedPosition = index > (lastDisplayedItemUnsynced ?? -1) ? .bottom : .top
                lastDisplayedId = message.localId

                if let msgId = message.id, msgId > (lastSeenByUserLocal ?? 0) {
                    lastSeenByUserLocal = msgId
                    read(message: message)
                }
                
                guard let msgId = message.id else {
                    return
                }
                
                if lastSeenByOthers.count == 1, let _ = lastSeenByOthers[String(msgId)] {
                    message.lastSeenBy = .everyone
                } else if let lastSeenUsers = lastSeenByOthers[String(msgId)] as? NSArray {
                    var lastSeenByUsers:[String] = []

                    for userReadInfo in lastSeenUsers {
                        if let readInfo = MessageReadByInfo(userReadInfo as? [AnyHashable:Any]), let userName = readInfo[.name] as? String {
                            lastSeenByUsers.append(userName)
                        }
                    }
                    message.lastSeenBy = .some(lastSeenByUsers)
                } else {
                    message.lastSeenBy = .none
                }
            }
        
            return message
        }
        set(newValue) {
            ChatThread.dqAccess.sync(flags:.barrier) {
                guard index < self.messages.count else {
                    fatalError("Trying to update non-existing message [\(index)] of \(self.messages.count)")
                }
                self.messages[index] = newValue
            }
        }
    }


    //
    // MARK: NSCoding
    //
    required init?(coder aDecoder: NSCoder) {
        tripId = aDecoder.decodeObject(forKey: PropertyKey.tripIdKey) as? Int ?? aDecoder.decodeInteger(forKey: PropertyKey.tripIdKey)

        let savedDeviceType = aDecoder.decodeObject(forKey: PropertyKey.lastDisplayedId_deviceTypeKey) as? String
        let savedDeviceId = aDecoder.decodeObject(forKey: PropertyKey.lastDisplayedId_deviceIdKey) as? String
        let savedLocalId = aDecoder.decodeObject(forKey: PropertyKey.lastDisplayedId_localIdKey) as? String
        
        if let savedDeviceType = savedDeviceType, let savedDeviceId = savedDeviceId, let savedLocalId = savedLocalId {
            lastDisplayedId = (savedDeviceType, savedDeviceId, savedLocalId)
        }

        lastSeenByUserLocal = aDecoder.decodeObject(forKey: PropertyKey.lastSeenByUserLocalKey) as? Int //?? aDecoder.decodeInteger(forKey: PropertyKey.lastSeenByUserLocalKey)
        lastSeenByUserServer = aDecoder.decodeObject(forKey: PropertyKey.lastSeenByUserServerKey) as? Int //?? aDecoder.decodeInteger(forKey: PropertyKey.lastSeenByUserServerKey)
        lastSeenByOthers = (aDecoder.decodeObject(forKey: PropertyKey.lastSeenByOthersKey) as? NSDictionary) ?? NSDictionary()
        messages = (aDecoder.decodeObject(forKey: PropertyKey.messagesKey) as? [ChatMessage]) ?? [ChatMessage]()
        messageVersion = aDecoder.decodeObject(forKey: PropertyKey.messageVersionKey) as? Int
        if let rawLastDisplayedPosition = aDecoder.decodeObject(forKey: PropertyKey.lastDisplayedPositionKey) as? Int {
            lastDisplayedPosition = UITableView.ScrollPosition(rawValue: rawLastDisplayedPosition)
        }
        lastSeenVersion = aDecoder.decodeObject(forKey: PropertyKey.lastSeenVersionKey) as? Int
    }

    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(tripId, forKey: PropertyKey.tripIdKey)
        aCoder.encode(lastDisplayedId?.deviceType, forKey: PropertyKey.lastDisplayedId_deviceTypeKey)
        aCoder.encode(lastDisplayedId?.deviceId, forKey: PropertyKey.lastDisplayedId_deviceIdKey)
        aCoder.encode(lastDisplayedId?.localId, forKey: PropertyKey.lastDisplayedId_localIdKey)
        aCoder.encode(lastSeenByUserLocal, forKey: PropertyKey.lastSeenByUserLocalKey)
        aCoder.encode(lastSeenByUserServer, forKey: PropertyKey.lastSeenByUserServerKey)
        aCoder.encode(lastSeenByOthers, forKey: PropertyKey.lastSeenByOthersKey)

        aCoder.encode(messageVersion, forKey: PropertyKey.messageVersionKey)
        aCoder.encode(lastDisplayedPosition?.rawValue, forKey: PropertyKey.lastDisplayedPositionKey)
        aCoder.encode(lastSeenVersion, forKey: PropertyKey.lastSeenVersionKey)
        aCoder.encode(messages, forKey: PropertyKey.messagesKey)
    }


    //
    // MARK: Initialisers
    //
    init(tripId:Int) {
        self.tripId = tripId
        super.init()
    }


    //
    // MARK: Functions
    //
    
    // Appends a new message (no need to check for duplicates)
    func append(_ msg:ChatMessage) {
        ChatThread.dqAccess.async(flags:.barrier) {
            self.messages.append(msg)
            self.save()
        }
    }


    // Adds a message from the server that may or may not be a duplicate
    // (but will always have an ID)
    func add(_ msg:ChatMessage) {
        guard let msgId = msg.id else {
            fatalError("Adding message with no ID")
        }

        ChatThread.dqAccess.async(flags:.barrier) {
            // Check if message already exists
            // (may have been added by parallel thread)
//            Doesn't work for some reason
//            let matchedIdx2 = self.messages.firstIndex(of: msg)
            let matchedIdx = self.messages.firstIndex {
                $0.localId == msg.localId
            }

            if let matchedIdx = matchedIdx, self.messages[matchedIdx].isStored {
                // Already stored, so should be in correct order - no need to update
            } else {
                let insertBeforeIdx = self.messages.firstIndex(where: { (m) -> Bool in
                    (!m.isStored) || (m.id! >= msgId)
                })

                if let insertBeforeIdx = insertBeforeIdx, let removeIdx = matchedIdx {
                    if insertBeforeIdx == removeIdx {
                        self.messages[insertBeforeIdx] = msg
                    } else if insertBeforeIdx > removeIdx {
                        self.messages.insert(msg, at: insertBeforeIdx)
                        self.messages.remove(at: removeIdx)
                    } else {
                        self.messages.remove(at: removeIdx)
                        self.messages.insert(msg, at: insertBeforeIdx)
                    }
                } else if let insertBeforeIdx = insertBeforeIdx {
                    self.messages.insert(msg, at: insertBeforeIdx)
                } else if let _ = matchedIdx {
                    fatalError("Inconsistent array update!")
                } else {
                    self.messages.append(msg)
                }
            }
        }
    }
    
    
    // Resets thread; clears all messages saved on server but keeps
    // all messages only stored locally
    func reset() {
        ChatThread.dqAccess.async(flags:.barrier) {
            let unsavedMessages = self.messages.filter( { (m:ChatMessage) -> Bool in
                return !m.isStored
            })
            self.messages = unsavedMessages
        }
    }
    
    
    private func performSave() {
        let unsavedMessages = messages.filter( { (m:ChatMessage) -> Bool in
            return !m.isStored
        })
        if !unsavedMessages.isEmpty {
            unsavedMessages[0].save(tripId: tripId, responseHandler: { (handledStatus: SHiTHandledStatus?, response: URLResponse?, responseDictionary: NSDictionary?, error: Error?) -> Void in
                let status = handledStatus ?? SHiTResource.checkStatus(response: response, responseDictionary: responseDictionary, error: error)
                if status.status == .ok {
                    os_log("Message saved successfully, saving next message", log: OSLog.webService, type: .debug)
                    self.retryCount = 0
                    self.save()
                } else {
                    switch status.retry ?? .normal {
                    case .normal:
                        self.retryCount += 1
                        os_log("Error when saving message, retrying in %d seconds", log: OSLog.webService, type: .error, self.retryDelay)
                        ChatThread.dqServerComm.asyncAfter(deadline: .now() + self.retryDelay, execute: { () -> Void in self.performSave() })

                    case .stop:
                        os_log("Error when saving message, stopping", log: OSLog.webService, type: .error)
                        
                    case .skip:
                        os_log("Error when saving message, skipping", log: OSLog.webService, type: .info)
                    }
                }
            })
        }
    }


    func save() {
        ChatThread.dqServerComm.async { self.performSave() }
    }


    func performRead(message: ChatMessage) {
        guard let userId = User.sharedUser.userId else {
            fatalError("Cannot read messages when not logged in.")
        }
        guard let msgUserId = message.userId else {
            // Probably a newly created message, not yet saved on server (i.e., created by local user - no need to update server
            return
        }
        guard let msgId = message.id else {
            // Should have been caught by previous guard statement
            fatalError("ERROR: Inconsistent message ID and user ID")
        }
        if msgUserId == userId {
            // No point in telling server user has read his own messages.
            return
        }
        if msgId < (lastSeenByUserServer ?? 0) {
            // Already marked as seen on the server, no need to update
            return
        }
        message.read(tripId: tripId, responseHandler: { (response: URLResponse?, responseDictionary: NSDictionary?, error: Error?) -> Void in
            let status = SHiTResource.checkStatus(response: response, responseDictionary: responseDictionary, error: error)
            if status.status == .ok {
                self.retryCount = 0
                if let responseDictionary = responseDictionary, let lastSeenByUser = responseDictionary[Constant.JSON.messageLastSeenByMe] as? Int, let lastSeenByOthers = responseDictionary[Constant.JSON.messageLastSeenByOthers] as? NSDictionary {
                    if lastSeenByUser > (self.lastSeenByUserServer ?? 0) {
                        self.lastSeenByUserServer = lastSeenByUser
                        self.lastSeenByOthers = lastSeenByOthers
                        NotificationCenter.default.post(name: Constant.Notification.chatRefreshed, object: self)
                    }
                }
            } else {
                switch status.retry ?? .normal {
                case .normal:
                    self.retryCount += 1
                    os_log("Error when reading message, retrying in %d seconds", log: OSLog.webService, type: .error, self.retryDelay)
                    ChatThread.dqServerComm.asyncAfter(deadline: .now() + self.retryDelay, execute: { () -> Void in self.performRead(message: message) })

                case .stop:
                    os_log("Error when reading message, stopping", log: OSLog.webService, type: .error)
                    
                case .skip:
                    os_log("Error when reading message, skipping", log: OSLog.webService, type: .info)
                }
            }
        })
    }


    func read(message: ChatMessage) {
        ChatThread.dqServerComm.async { self.performRead(message: message) }
    }
    

    func refresh(mode:RefreshMode) {
        //Set the parameters for the RSTransaction object
        var extraParams:[URLQueryItem] = []
        if let lastMessageId = messageVersion, mode == .incremental {
            extraParams += [ URLQueryItem(name: SHiTResource.Param.lastMessageId, value: String(lastMessageId)) ]
        }
        let chatThreadResource = SHiTResource.thread(key: String(tripId), parameters: extraParams)

        RESTRequest.get(chatThreadResource) {(response : URLResponse?, responseDictionary: NSDictionary?, error: Error?) -> Void in
            let status = SHiTResource.checkStatus(response: response, responseDictionary: responseDictionary, error: error)
            if status.status == .ok {
                if let responseDictionary = responseDictionary, let messageArray = responseDictionary[Constant.JSON.messageList] as? NSArray, let lastSeenDict =  responseDictionary[Constant.JSON.messageLastSeenByOthers] as? NSDictionary, let messageVersion = responseDictionary[Constant.JSON.messageVersion] as? Int {
                    self.lastSeenByUserServer = (responseDictionary[Constant.JSON.messageLastSeenByMe] as? Int)
                    self.lastSeenByOthers = lastSeenDict
                    if messageArray.count > 0 {
                        if mode == .incremental {
                            if messageVersion > (self.messageVersion ?? 0) {
                                for msgJson in messageArray {
                                    if let msg = msgJson as? NSDictionary, let newMsg = ChatMessage(fromDictionary:msg) {
                                        self.add(newMsg)
                                    }
                                }
                            }
                        } else {
                            ChatThread.dqAccess.async(flags:.barrier) {
                                var newMessages = [ChatMessage]()
                                for msgJson in messageArray {
                                    if let msg = msgJson as? NSDictionary, let newMsg = ChatMessage(fromDictionary:msg) {
                                        newMessages.append(newMsg)
                                    }
                                }
                                let unsavedMessages = self.messages.filter( { (m:ChatMessage) -> Bool in
                                    return !m.isStored && !newMessages.contains(m)
                                })
                                newMessages.append(contentsOf: unsavedMessages)
                                self.messages = newMessages
                            }
                        }
                    } else {
                        os_log("INFO: Didn't find any messages in dictionary: %s", log: OSLog.webService, String(describing: responseDictionary))
                    }
                    ChatThread.dqAccess.async {
                        NotificationCenter.default.post(name: Constant.Notification.chatRefreshed, object: self)
                    }
                } else {
                    os_log("ERROR: Incorrect response: %s", log: OSLog.webService, type: .error, String(describing: responseDictionary))
                }
            }
        }
    }


    func updateReadStatus(lastSeenByUsers: NSDictionary, lastSeenVersion: Int) {
        ChatThread.dqAccess.async(flags:.barrier) {
            guard lastSeenVersion > (self.lastSeenVersion ?? 0) else {
                return
            }

            let newLastSeenInfo = NSMutableDictionary()
            for (msgId, msgInfo) in lastSeenByUsers {
                guard let userArray = msgInfo as? NSArray, let msgId = msgId as? String else {
                    fatalError("Last seen info is not array or message ID not string")
                }
                let otherUsers = userArray.filter({ (userReadInfo:Any) -> Bool in
                    guard let readBy = MessageReadByInfo(userReadInfo as? [AnyHashable:Any]), let userId = readBy[.id] as? Int else {
                        fatalError("Invalid user info: \(String(describing:userReadInfo))")
                    }
                    return userId != User.sharedUser.userId ?? -1
                })
                let mySeenInfo = userArray.filter({ (userReadInfo:Any) -> Bool in
                    guard let readBy = MessageReadByInfo(userReadInfo as? [AnyHashable:Any]), let userId = readBy[.id] as? Int else {
                        fatalError("Incorrect user info: \(String(describing:userReadInfo))")
                    }
                    return userId == User.sharedUser.userId ?? -1
                })

                if otherUsers.count > 0 {
                    newLastSeenInfo[msgId] = otherUsers
                }
                if mySeenInfo.count > 0 {
                    self.lastSeenByUserServer = Int(msgId)
                }
            }
            self.lastSeenByOthers = newLastSeenInfo
        }
        ChatThread.dqAccess.async {
            NotificationCenter.default.post(name: Constant.Notification.chatRefreshed, object: self)
        }
    }
    
    
    func savePosition() {
        if let lastItem = lastDisplayedItem {
            savedPosition = (messages[lastItem].localId, lastDisplayedItemPosition)
        }
    }
    
    
    func restorePosition() -> Bool {
        if let savedPosition = savedPosition {
            lastDisplayedId = savedPosition.0
            lastDisplayedPosition = savedPosition.1
            self.savedPosition = nil
            return true
        }
        return false
    }
}
