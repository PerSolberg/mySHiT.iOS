//
//  ChatThread.swift
//  mySHiT
//
//  Created by Per Solberg on 2017-04-13.
//  Copyright © 2017 &More AS. All rights reserved.
//

import Foundation
import UIKit

class ChatThread:NSObject, NSCoding {
    enum RefreshMode:String {
        case full           = "F"
        case incremental    = "I"
    }
    
    private var messages = [ChatMessage]()
    private var messageVersion:Int?
    private var lastSeenByOthers = NSDictionary()
    private var lastDisplayedId:ChatMessage.LocalId?
    private var lastDisplayedPosition:UITableViewScrollPosition?
    private var lastSeenByUserLocal:Int?
    private var lastSeenByUserServer:Int?
    private var lastSeenVersion:Int?
    private var tripId:Int!
    var messageBeingEntered:String?
    private var savedExactPosition:CGPoint?
    
    private var savedPosition:(ChatMessage.LocalId, UITableViewScrollPosition)?
    private var retryCount:Int = 0

    static let LastSeenByNone = "(NONE)"
    static let LastSeenByEveryone = "(ALL)"
    
    static let dqServerComm = DispatchQueue(label: "no.andmore.mySHiT.chat.server")
    static let dqAccess = DispatchQueue(label: "no.andmore.mySHiT.chat.access", attributes: .concurrent) // DispatchQueue(label: "no.andmore.mySHiT.chat.access")
    
    static let retryDelays = [ 1: 5.0, 10: 30.0, 20: 300.0, 30: 1800.0 ]

    //static let webServiceTripPath = "trip/code/"
    static let webServiceChatPath = "thread"
    var rsRequest: RSTransactionRequest = RSTransactionRequest()
    var rsTransGetChat: RSTransaction = RSTransaction(transactionType: RSTransactionType.get, baseURL: "https://www.shitt.no/mySHiT", path: webServiceChatPath, parameters: ["userName":"dummy@default.com","password":"******"])

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


    // MARK: Properties
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


    var lastDisplayedItem:Int? {
        var item:Int?
        
        ChatThread.dqAccess.sync {
            if let id = lastDisplayedId {
                item = self.messages.index(where: { (m) -> Bool in
                    return (m.localId ?? ChatMessage.missingLocalId) == id
                })
            } else if let id = lastSeenByUserLocal ?? lastSeenByUserServer {
                item = self.messages.index(where: { (m) -> Bool in
                    return (m.id ?? 0) == id
                })
            }
        }
        
        return item
    }
    
    
    var lastDisplayedItemPosition:UITableViewScrollPosition {
        var pos:UITableViewScrollPosition = .top
        
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
                lastDisplayedPosition = index > (lastDisplayedItem ?? -1) ? .bottom : .top
                lastDisplayedId = message.localId

                if let msgId = message.id, msgId > (lastSeenByUserLocal ?? 0) {
                    lastSeenByUserLocal = msgId
                    read(message: message)
                }
                
                guard let msgId = message.id else {
                    return
                }
                
                if lastSeenByOthers.count == 1, let _ = lastSeenByOthers[String(msgId)] {
                    message.lastSeenBy = [ ChatThread.LastSeenByEveryone ]
                } else if let lastSeenUsers = lastSeenByOthers[String(msgId)] as? NSArray {
                    message.lastSeenBy = []
                    for userInfo in lastSeenUsers {
                        if let userInfo = userInfo as? NSDictionary, let userName = userInfo["name"] as? String {
                            message.lastSeenBy.append( userName )
                        }
                    }
                } else {
                    message.lastSeenBy = [ ChatThread.LastSeenByNone ]
                }
            }
        
            return message
        }
        set(newValue) {
            ChatThread.dqAccess.async(flags:.barrier) {
                guard index < self.messages.count else {
                    fatalError("Trying to update non-existing message [\(index)] of \(self.messages.count)")
                }
                self.messages[index] = newValue
            }
        }
    }


    // MARK: NSCoding
    required init?(coder aDecoder: NSCoder) {
//        print("Decoding ChatThread")
        // NB: use conditional cast (as?) for any optional properties
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
            lastDisplayedPosition = UITableViewScrollPosition(rawValue: rawLastDisplayedPosition)
        }
        lastSeenVersion = aDecoder.decodeObject(forKey: PropertyKey.lastSeenVersionKey) as? Int

//        print("Decoded last displayed ID: \(String(describing: lastDisplayedId))")
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
        
//        print("Encoded thread \(tripId), last displayed ID: \(String(describing: lastDisplayedId))")
    }


    // MARK: Initialisers
    init(tripId:Int!) {
        super.init()
        self.tripId = tripId
    }


    // MARK: Functions
    
    // Appends a new message (no need to check for duplicates)
    func append(_ msg:ChatMessage) {
        ChatThread.dqAccess.async(flags:.barrier) {
            self.messages.append(msg)
            self.save()
        }
    }


    // Adds a message from the server that may or may not be a duplicate (but will always have an ID)
    func add(_ msg:ChatMessage) {
        guard let msgId = msg.id else {
            fatalError("Adding message with no ID")
        }

        // First check if message already exists and has been saved in non-blocking thread
        var matchedIdx:Int?
        ChatThread.dqAccess.sync {
            matchedIdx = self.messages.index(where: { (m) -> Bool in
                m.localId == msg.localId && m.isStored
            })
        }
        
        if matchedIdx == nil {
            // Message not found, updating array in thread safe manner
            ChatThread.dqAccess.async(flags:.barrier) {
                let insertBeforeIdx = self.messages.index(where: { (m) -> Bool in
                    (!m.isStored) || (m.id! >= msgId)
                })
                let removeIdx = self.messages.index(of: msg)

                if let insertBeforeIdx = insertBeforeIdx, let removeIdx = removeIdx {
                    if insertBeforeIdx == removeIdx {
                        self.messages[insertBeforeIdx] = msg
                    } else {
                        self.messages.remove(at: removeIdx)
                        self.messages.insert(msg, at: insertBeforeIdx)
                    }
                } else if let insertBeforeIdx = insertBeforeIdx {
                    self.messages.insert(msg, at: insertBeforeIdx)
                } else if let _ = removeIdx {
                    fatalError("Inconsistent array update!")
                } else {
                    self.messages.append(msg)
                }
            }
        }
    }
    
    
    // Resets thread; clears all messages save on server but keeps all messages only stored locally
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
            print("Saving message \(unsavedMessages[0].localId)")
            unsavedMessages[0].save(tripId: tripId, responseHandler: { (response: URLResponse?, responseDictionary: NSDictionary?, error: Error?) -> Void in
                if let _ = error {
                    self.retryCount += 1
                    print("Error when saving message, retrying in \(self.retryDelay) seconds")
                    ChatThread.dqServerComm.asyncAfter(deadline: .now() + self.retryDelay, execute: { () -> Void in self.performSave() })
                } else if let _ = responseDictionary?[Constant.JSON.queryError] {
                    self.retryCount += 1
                    print("Server error when saving message, retrying in \(self.retryDelay) seconds")
                    ChatThread.dqServerComm.asyncAfter(deadline: .now() + self.retryDelay, execute: { () -> Void in self.performSave() })
                } else {
                    print("Message saved successfully, saving next message")
                    self.retryCount = 0
                    self.save()
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
        print("Reading message \(msgId)")
        message.read(tripId: tripId, responseHandler: { (response: URLResponse?, responseDictionary: NSDictionary?, error: Error?) -> Void in
            if let _ = error {
                self.retryCount += 1
                print("Error when reading message, retrying in \(self.retryDelay) seconds")
                ChatThread.dqServerComm.asyncAfter(deadline: .now() + self.retryDelay, execute: { () -> Void in self.performRead(message: message) })
            } else if let _ = responseDictionary?[Constant.JSON.queryError] {
                self.retryCount += 1
                ChatThread.dqServerComm.asyncAfter(deadline: .now() + self.retryDelay, execute: { () -> Void in self.performRead(message: message) })
            } else {
                self.retryCount = 0
                if let responseDictionary = responseDictionary, let lastSeenByUser = responseDictionary[Constant.JSON.messageLastSeenByMe] as? Int, let lastSeenByOthers = responseDictionary[Constant.JSON.messageLastSeenByOthers] as? NSDictionary {
                    if lastSeenByUser > (self.lastSeenByUserServer ?? 0) {
                        self.lastSeenByUserServer = lastSeenByUser
                        self.lastSeenByOthers = lastSeenByOthers
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.chatRefreshed), object: self)
                    }
                }
            }
        })
    }


    func read(message: ChatMessage) {
        ChatThread.dqServerComm.async { self.performRead(message: message) }
    }
    

    func refresh(mode:RefreshMode) {
        let userCred = User.sharedUser.getCredentials()
        
        assert( userCred.name != nil );
        assert( userCred.password != nil );
        assert( userCred.urlsafePassword != nil );
        
        //Set the parameters for the RSTransaction object
        rsTransGetChat.path = type(of: self).webServiceChatPath + "/" + String(tripId)
        rsTransGetChat.parameters = [ "userName":userCred.name!
            , "password":userCred.urlsafePassword!
            ]

        if let lastMessageId = messageVersion, mode == .incremental {
            rsTransGetChat.parameters["lastMessageId"] = String(lastMessageId)
        }
        //Send request
        rsRequest.dictionaryFromRSTransaction(rsTransGetChat, completionHandler: {(response : URLResponse?, responseDictionary: NSDictionary?, error: Error?) -> Void in
            if let error = error {
                //If there was an error, log it
                print("Error : \(error.localizedDescription)")
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.networkError), object: self)
            } else if let error = responseDictionary?[Constant.JSON.queryError] {
                let errMsg = error as! String
                print("Error : \(errMsg)")
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.networkError), object: self)
            } else {
                print("Chat messages retrieved from server")

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
                            print("ChatThread refreshed incrementally, notifying screen")
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
                                print("ChatThread refreshed fully, notifying screen")
                            }
                        }
                    } else {
                        print("INFO: Didn't find any messages in dictionary: \(String(describing: responseDictionary))")
                    }
                    ChatThread.dqAccess.async {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.chatRefreshed), object: self)
                    }
                } else {
                    print("ERROR: Incorrect response: \(String(describing: responseDictionary))")
                }
            }
        })
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
                let otherUsers = userArray.filter({ (ui:Any) -> Bool in
                    guard let userInfo = ui as? NSDictionary, let userId = userInfo["id"] as? Int else {
                        fatalError("Invalid user info: \(String(describing:ui))")
                    }
                    return userId != User.sharedUser.userId ?? -1
                })
                let mySeenInfo = userArray.filter({ (ui:Any) -> Bool in
                    guard let userInfo = ui as? NSDictionary, let userId = userInfo["id"] as? Int else {
                        fatalError("Incorrect user info: \(String(describing:ui))")
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
//            print("Updated last seen by me: \(String(describing: self.lastSeenByUserServer)), other users: \(String(describing: self.lastSeenByOthers))")
        }
        ChatThread.dqAccess.async {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.chatRefreshed), object: self)
        }
    }
    
    func savePosition() {
        print("ChatThread: Saving position")
        if let lastItem = lastDisplayedItem {
            savedPosition = (messages[lastItem].localId, lastDisplayedItemPosition)
        }
    }
    
    func restorePosition() -> Bool {
        if let savedPosition = savedPosition {
            print("ChatThread: Restoring position")
            lastDisplayedId = savedPosition.0
            lastDisplayedPosition = savedPosition.1
            self.savedPosition = nil
            return true
        }
        return false
    }
}
