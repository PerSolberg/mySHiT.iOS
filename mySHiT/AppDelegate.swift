//
//  AppDelegate.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-09.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import UIKit
import Firebase
import FirebaseInstanceID
import FirebaseMessaging
import AVFoundation
import UserNotifications
import os

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"
    var appSettings = Dictionary<AnyHashable, Any>()
    var avPlayer:AVAudioPlayer?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // First save current app settings, so we can avoid refreshing when Firebase settings change
        let defaults = UserDefaults.standard
        appSettings[Constant.Settings.tripLeadTime] = Int(defaults.float(forKey: Constant.Settings.tripLeadTime))
        appSettings[Constant.Settings.deptLeadTime] = Int(defaults.float(forKey: Constant.Settings.deptLeadTime))
        appSettings[Constant.Settings.legLeadTime] = Int(defaults.float(forKey: Constant.Settings.legLeadTime))
        appSettings[Constant.Settings.eventLeadTime] = Int(defaults.float(forKey: Constant.Settings.eventLeadTime))
        
        // Override point for customization after application launch.
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { (success : Bool, err : Error?) -> Void in } )
        self.registerDefaultsFromSettingsBundle();
        NotificationCenter.default.addObserver(self, selector: #selector(defaultsChanged(_:)), name: UserDefaults.didChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tokenRefreshNotification), name: NSNotification.Name.InstanceIDTokenRefresh, object: nil)

        //
        // Set up notification categories
        //
        let chatIgnoreAction = UNNotificationAction(identifier: Constant.ntfAction.ignoreChatMessage,
                                              title: String(format: NSLocalizedString(Constant.msg.chatNtfIgnoreAction, comment:Constant.dummyLocalisationComment), locale: NSLocale.current),
                                              options: .foreground)

        let chatReplyAction = UNTextInputNotificationAction(identifier: Constant.ntfAction.replyToChatMessage, title: String(format: NSLocalizedString(Constant.msg.chatNtfReplyAction, comment:Constant.dummyLocalisationComment), locale: NSLocale.current), options: .foreground, textInputButtonTitle: String(format: NSLocalizedString(Constant.msg.chatNtfReplySend, comment:Constant.dummyLocalisationComment), locale: NSLocale.current), textInputPlaceholder: Constant.emptyString)
        
        let newChatMsgCategory = UNNotificationCategory(identifier: Constant.ntfCategory.newChatMessage,
                                                     actions: [chatReplyAction, chatIgnoreAction],
                                                     intentIdentifiers: [],
                                                     options: UNNotificationCategoryOptions(rawValue: 0))
        
        UNUserNotificationCenter.current().setNotificationCategories([newChatMsgCategory])
        UNUserNotificationCenter.current().delegate = self
       
        // Register with APNs
        UIApplication.shared.registerForRemoteNotifications()
        
        // Initialise Firebase
        FirebaseApp.configure();

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {_, _ in} )
        Messaging.messaging().delegate = self as? MessagingDelegate

        application.registerForRemoteNotifications()
        
        configureShortCuts(application)

        NotificationCenter.default.addObserver(self, selector: #selector(refreshShortcuts), name: Constant.notification.dataRefreshed, object: nil)
        
        return true
    }

    @objc func refreshShortcuts() {
        DispatchQueue.main.async {
            self.configureShortCuts(UIApplication.shared)
        }
    }
    
    func configureShortCuts(_ application: UIApplication) {
        let chatIcon = UIApplicationShortcutIcon(templateImageName: Constant.icon.chat)
        var shortcuts:[UIApplicationShortcutItem] = []

        var nextTrip:AnnotatedTrip?
        var currentTrip:AnnotatedTrip?
        var lastTrip:AnnotatedTrip?
        TripList.sharedList.forEach { (aTrip) in
            switch (aTrip.trip.tense!) {
            case .future:
                nextTrip = aTrip
                
            case .present:
                currentTrip = aTrip
                
            case .past:
                lastTrip = lastTrip ?? aTrip
            }
        }
        
        if let trip = lastTrip, let tripName = trip.trip.name {
            let shortcut = UIMutableApplicationShortcutItem(type: Constant.shortcut.chat,
                localizedTitle: tripName,
                localizedSubtitle: Constant.msg.shortcutSendMessageSubtitle,
                icon: chatIcon,
                userInfo: [ Constant.ntfUserInfo.changeType: Constant.changeType.chatMessage as NSSecureCoding,
                            Constant.ntfUserInfo.changeOp: Constant.changeOperation.insert as NSSecureCoding,
                            Constant.ntfUserInfo.tripId: String(trip.trip.id) as NSSecureCoding ]
            )
            shortcuts.append(shortcut)
        }
        if let trip = currentTrip, let tripName = trip.trip.name {
            let shortcut = UIMutableApplicationShortcutItem(type: Constant.shortcut.chat,
                localizedTitle: tripName,
                localizedSubtitle: Constant.msg.shortcutSendMessageSubtitle,
                icon: chatIcon,
                userInfo: [ Constant.ntfUserInfo.changeType: Constant.changeType.chatMessage as NSSecureCoding,
                            Constant.ntfUserInfo.changeOp: Constant.changeOperation.insert as NSSecureCoding,
                            Constant.ntfUserInfo.tripId: String(trip.trip.id) as NSSecureCoding ]
            )
            shortcuts.append(shortcut)
        }
        if let trip = nextTrip, let tripName = trip.trip.name {
            let shortcut = UIMutableApplicationShortcutItem(type: Constant.shortcut.chat,
                localizedTitle: tripName,
                localizedSubtitle: Constant.msg.shortcutSendMessageSubtitle,
                icon: chatIcon,
                userInfo: [ Constant.ntfUserInfo.changeType: Constant.changeType.chatMessage as NSSecureCoding,
                            Constant.ntfUserInfo.changeOp: Constant.changeOperation.insert as NSSecureCoding,
                            Constant.ntfUserInfo.tripId: String(trip.trip.id) as NSSecureCoding ]
            )
            shortcuts.append(shortcut)
        }

        application.shortcutItems = shortcuts
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        
        switch (shortcutItem.type) {
        case Constant.shortcut.chat:
            let ntfLink = NotificationLink(userInfo: shortcutItem.userInfo ?? [:])
            DeepLinkManager.current().set(linkHandler: ntfLink)
            DeepLinkManager.current().checkAndHandle()

        default:
            os_log("Don't know how to handle shortcut type '%s'", type: .error, shortcutItem.type)
        }

        completionHandler(true)
    }

    // Handle remote notification registration.
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data){
        // No need to do anything? (was needed in earlier versions)
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // The token is not currently available.
        os_log("Remote notification support is unavailable due to error: %s", type: .error, error.localizedDescription)
    }

    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // appState is:
        //  - active if application is active,
        //  - inactive if application is being opened from notification
        //  - background if application is in the background
        // let appState = application.applicationState
        guard let _ = userInfo[Constant.ntfUserInfo.changeType] as? String, let _ = userInfo[Constant.ntfUserInfo.changeOp] as? String else {
            fatalError("Invalid remote notification, no changeType or changeOperation element")
        }

        handleRemoteNotification(userInfo: userInfo) {_ in
            completionHandler(UIBackgroundFetchResult.newData);
        }
    }
    
    func handleRemoteNotification(userInfo: [AnyHashable : Any], parentCompletionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        guard let changeType = userInfo[Constant.ntfUserInfo.changeType] as? String, let changeOperation = userInfo[Constant.ntfUserInfo.changeOp] as? String else {
            fatalError("Invalid remote notification, no changeType or changeOperation element")
        }

        switch (changeType, changeOperation) {
        case (Constant.changeType.chatMessage, Constant.changeOperation.insert):
            guard let apsInfo = userInfo["aps"] as? NSDictionary, let ntfFromUserId = userInfo[Constant.ntfUserInfo.fromUserId] as? String, let fromUserId = Int(ntfFromUserId), let ntfTripId = userInfo[Constant.ntfUserInfo.tripId] as? String, let tripId = Int(ntfTripId) else {
                fatalError("Invalid remote notification, chat message without aps data, trip ID or sending user ID.")
            }
            guard let currentUserId = User.sharedUser.userId else {
                fatalError("Unable to get logged on user ID.")
            }
            if let rootVC = UIApplication.shared.keyWindow?.rootViewController, let navVC = rootVC as? UINavigationController, let chatVC = navVC.visibleViewController as? ChatViewController, let trip = chatVC.trip?.trip, let ntfTripId = userInfo[Constant.ntfUserInfo.tripId] as? String, let tripId = Int(ntfTripId), trip.id == tripId {
                trip.chatThread.refresh(mode: .incremental)
            }
            var handlerOptions:UNNotificationPresentationOptions = [.alert, .sound]

            if fromUserId == currentUserId {
                handlerOptions = []
            } else if let rootVC = UIApplication.shared.keyWindow?.rootViewController, let navVC = rootVC as? UINavigationController, let chatVC = navVC.visibleViewController as? ChatViewController, let trip = chatVC.trip?.trip, trip.id == tripId {
                // Message for current chat - refresh but don't notify
                trip.chatThread.refresh(mode: .incremental)
                let soundName:String? = apsInfo["sound"] as? String
                playSound(name: soundName, type: nil)
                handlerOptions = []
            }
            parentCompletionHandler(handlerOptions)

        case (Constant.changeType.chatMessage, Constant.changeOperation.update):
            handleReadChatMessage(userInfo: userInfo, parentCompletionHandler: {
                parentCompletionHandler([.alert, .sound])
            })
            
        case (Constant.changeType.chatMessage, _):
            fatalError("Unknown change type/operation: \(changeType), \(changeOperation)")
            
        default:
            // Update from server (should take place in background)
            TripList.sharedList.getFromServer(parentCompletionHandler: {
                parentCompletionHandler([.alert, .sound]);
            } )
        }
    }
    

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        if let _ = notification.request.trigger as? UNPushNotificationTrigger {
            let userInfo = notification.request.content.userInfo
            handleRemoteNotification(userInfo: userInfo) {handlerOptions in
                completionHandler(handlerOptions)
            }
        } else if let _ = notification.request.trigger as? UNCalendarNotificationTrigger {
            // No need to do anything
            completionHandler([.alert, .sound])
        }
    }

    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let category = response.notification.request.content.categoryIdentifier
        let action = response.actionIdentifier
        let userInfo = response.notification.request.content.userInfo
        
        switch (category, action) {
        case (_, UNNotificationDismissActionIdentifier):
            //User dismissed notification, no need to do anything - or maybe flag it as read"
            break
            
        case (_, UNNotificationDefaultActionIdentifier):
            if let _ = response.notification.request.trigger as? UNPushNotificationTrigger, let changeType = userInfo[Constant.ntfUserInfo.changeType] as? String, let changeOperation = userInfo[Constant.ntfUserInfo.changeOp] as? String {
                switch (changeType, changeOperation) {
                case (Constant.changeType.chatMessage, Constant.changeOperation.update):
                    // This shouldn't happen because these notifications aren't presented to the user
                    break;
                    
                case (Constant.changeType.chatMessage, Constant.changeOperation.insert):
                    // User opened app from notification, open chat screen
                    let ntfLink = NotificationLink(userInfo: userInfo)
                    DeepLinkManager.current().set(linkHandler: ntfLink)
                    DeepLinkManager.current().checkAndHandle()
                    
                case (_, Constant.changeOperation.insert):
                    fallthrough
                case (_, Constant.changeOperation.update):
                    // Trip or itinerary updated
                    let ntfLink = NotificationLink(userInfo: userInfo)
                    DeepLinkManager.current().set(linkHandler: ntfLink)
                    DeepLinkManager.current().checkAndHandle()
                    
                default:
                    break
                }
            } else if let _ = response.notification.request.trigger as? UNCalendarNotificationTrigger {
                // User opened app from alert
                let alertLink = AlertLink(userInfo: userInfo)
                DeepLinkManager.current().set(linkHandler: alertLink)
                DeepLinkManager.current().checkAndHandle()
            }
            
        case (Constant.ntfCategory.newChatMessage, Constant.ntfAction.replyToChatMessage):
            // Handle reply to chat message
            guard let textResponse = response as? UNTextInputNotificationResponse else {
                fatalError("Response to chat message is not UNTextInputNotificationResponse")
            }
            guard let ntfTripId = userInfo[Constant.ntfUserInfo.tripId] as? String, let tripId = Int(ntfTripId), let trip = TripList.sharedList.trip(byId: tripId) else {
                fatalError("Invalid remote notification, no aps element, alert info, message key, message arguments or trip ID.")
            }
            ChatMessage.read(fromUserInfo: userInfo, responseHandler: {_,_,_ in })
            let newMsg = ChatMessage(message: textResponse.userText)
            trip.trip.chatThread.append(newMsg)
            
        case (Constant.ntfCategory.newChatMessage, Constant.ntfAction.ignoreChatMessage):
            ChatMessage.read(fromUserInfo: userInfo, responseHandler: {_,_,_ in })
            
        default:
            os_log("Invalid action for new chat message: %s", type: .error, response.actionIdentifier)
            
        }
        
        completionHandler()
    }

    
    func handleReadChatMessage(userInfo: [AnyHashable : Any], parentCompletionHandler: @escaping () -> Void) {
        guard let ntfTripId = userInfo[Constant.ntfUserInfo.tripId] as? String, let tripId = Int(ntfTripId), let strLastSeenInfo = userInfo["lastSeenInfo"] as? String else {
            os_log("Invalid remote notification, no/invalid trip ID or no last seen info: %s", type: .error, String(describing: userInfo))
            parentCompletionHandler()
            return
        }
        var jsonLastSeenInfo:Any?
        do {
            jsonLastSeenInfo = try JSONSerialization.jsonObject(with: strLastSeenInfo.data(using: .utf8)!, options: JSONSerialization.ReadingOptions.allowFragments)
        } catch {
            os_log("Invalid remote notification, invalid JSON: %s", type: .error, strLastSeenInfo)
            parentCompletionHandler()
            return
        }
        guard let lastSeenInfo = jsonLastSeenInfo as? NSDictionary, let lastSeenByUsers = lastSeenInfo[ Constant.JSON.messageLastSeenByOthers] as? NSDictionary, let lastSeenVersion = lastSeenInfo[Constant.JSON.lastSeenVersion] as? Int else {
            os_log("Invalid remote notification, invalid last seen info: %s", type: .error, String(describing: jsonLastSeenInfo))
            parentCompletionHandler()
            return
        }
        
        guard let aTrip = TripList.sharedList.trip(byId: tripId) else {
            // Chat update for unknown trip, ignore
            parentCompletionHandler()
            return
        }
        
        aTrip.trip.chatThread.updateReadStatus(lastSeenByUsers: lastSeenByUsers, lastSeenVersion: lastSeenVersion)
        parentCompletionHandler()
    }

    private func application(_ application: UIApplication, didRegister notificationSettings: UNNotificationRequest) {
        os_log("Registered with Firebase", type: .debug)
        Messaging.messaging().subscribe(toTopic: Constant.Firebase.topicGlobal)
        User.sharedUser.registerForPushNotifications()
        TripList.sharedList.registerForPushNotifications()
    }
    

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Release shared resources, save user data, invalidate timers, and store enough
        // application state information to restore your application to its current state
        // in case it is terminated later.
        // If the application supports background execution, this method is called instead
        // of applicationWillTerminate: when the user quits.
        TripList.sharedList.saveToArchive(TripListViewController.ArchiveTripsURL.path)
    }

    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application
        // was inactive. If the application was previously in the background, optionally
        // refresh the user interface.
        if (RSUtilities.isNetworkAvailable("www.shitt.no")) {
            // Network available, refreshing information from server
            TripList.sharedList.getFromServer()
        }
        
        NotificationCenter.default.post(name: Constant.notification.refreshTripList, object: self)
        NotificationCenter.default.post(name: Constant.notification.refreshTripElements, object: self)
        
        DeepLinkManager.current().checkAndHandle()
    }
    

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate.
        // See also applicationDidEnterBackground:.
        TripList.sharedList.saveToArchive(TripListViewController.ArchiveTripsURL.path)
    }

    
    func registerDefaultsFromSettingsBundle() {
        guard let settingsBundle = Bundle.main.url(forResource: "Settings", withExtension:"bundle") else {
            os_log("Could not find Settings.bundle", type: .error)
            return;
        }
        
        guard let settings = NSDictionary(contentsOf: settingsBundle.appendingPathComponent("Root.plist")) else {
            os_log("Could not find Root.plist in settings bundle", type: .error)
            return
        }
        
        guard let preferences = settings.object(forKey: "PreferenceSpecifiers") as? [[String: AnyObject]] else {
            os_log("Root.plist has invalid format", type: .error)
            return
        }
        
        var defaultsToRegister = [String: AnyObject]()
        for var p in preferences {
            if let k = p["Key"] as? String, let v = p["DefaultValue"] {
                defaultsToRegister[k] = v
            }
        }
        
        UserDefaults.standard.register(defaults: defaultsToRegister)
    }

    
    @objc func defaultsChanged(_ notification:Notification){
        if let defaults = notification.object as? UserDefaults {
            let newTripLeadTime = Int(defaults.float(forKey: Constant.Settings.tripLeadTime))
            let newDeptLeadTime = Int(defaults.float(forKey: Constant.Settings.deptLeadTime))
            let newLegLeadTime = Int(defaults.float(forKey: Constant.Settings.legLeadTime))
            let newEventLeadTime = Int(defaults.float(forKey: Constant.Settings.eventLeadTime))

            let oldTripLeadTime = appSettings[Constant.Settings.tripLeadTime] as? Int
            let oldDeptLeadTime = appSettings[Constant.Settings.deptLeadTime] as? Int
            let oldLegLeadTime = appSettings[Constant.Settings.legLeadTime] as? Int
            let oldEventLeadTime = appSettings[Constant.Settings.eventLeadTime] as? Int

            if oldTripLeadTime != newTripLeadTime ||
                oldDeptLeadTime != newDeptLeadTime ||
                oldLegLeadTime != newLegLeadTime ||
                oldEventLeadTime != newEventLeadTime {
                TripList.sharedList.refreshNotifications()
                
                appSettings[Constant.Settings.tripLeadTime] = newTripLeadTime
                appSettings[Constant.Settings.deptLeadTime] = newDeptLeadTime
                appSettings[Constant.Settings.legLeadTime] = newLegLeadTime
                appSettings[Constant.Settings.eventLeadTime] = newEventLeadTime
            }
        } else {
            os_log("Defaults changed, but user defaults not available", type: .info)
        }
    }
    
    
    @objc func tokenRefreshNotification( _ notification: Notification) {
        connectToFirebase()
    }
    
    
    func connectToFirebase() {
        Messaging.messaging().subscribe(toTopic: Constant.Firebase.topicGlobal)
        User.sharedUser.registerForPushNotifications()
    }

    
    func playSound(name: String?, type: String?) {
        guard let name = name else {
            return
        }
        guard let path = Bundle.main.path(forResource: name, ofType:type) else {
            os_log("Sound file '%s' not found.", type: .error, name)
            return
        }
        let url = URL(fileURLWithPath: path)
        do {
            avPlayer = try AVAudioPlayer(contentsOf: url)
            avPlayer?.play()
        } catch {
            os_log("Playing sound file '%s' failed", type: .error, name)
        }
    }

}

