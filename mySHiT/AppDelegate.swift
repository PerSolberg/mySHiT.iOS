//
//  AppDelegate.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-09.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import UIKit
import Firebase
//import FirebaseInstanceID
import FirebaseInstallations
import FirebaseMessaging
import AVFoundation
import UserNotifications
import os


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    var appSettings = Dictionary<AnyHashable, Any>()
    var avPlayer:AVAudioPlayer?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {        
        os_log("application didFinishLaunchingWithOptions", log: OSLog.general, type: .debug)
        
        // First save current app settings, so we can avoid refreshing when Firebase settings change
        let defaults = UserDefaults.standard
        appSettings[Constant.Settings.tripLeadTime] = Int(defaults.float(forKey: Constant.Settings.tripLeadTime))
        appSettings[Constant.Settings.deptLeadTime] = Int(defaults.float(forKey: Constant.Settings.deptLeadTime))
        appSettings[Constant.Settings.legLeadTime] = Int(defaults.float(forKey: Constant.Settings.legLeadTime))
        appSettings[Constant.Settings.eventLeadTime] = Int(defaults.float(forKey: Constant.Settings.eventLeadTime))

        // Override point for customization after application launch.
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { (success : Bool, err : Error?) -> Void in } )
        self.registerDefaultsFromSettingsBundle();
        NotificationCenter.default.addObserver(self, selector: #selector(defaultsChanged(_:)), name: UserDefaults.didChangeNotification, object: UserDefaults.standard)
        //xNotificationCenter.default.addObserver(self, selector: #selector(tokenRefreshNotification), name: /*NSNotification.Name.InstanceIDTokenRefresh*/InstallationIDDidChange, object: nil)

        //
        // Set up notification categories
        //
        let chatIgnoreAction = UNNotificationAction(identifier: Constant.NotificationAction.ignoreChatMessage,
                                              title: Constant.Message.chatNtfIgnoreAction,
                                              options: .foreground)

        let chatReplyAction = UNTextInputNotificationAction(identifier: Constant.NotificationAction.replyToChatMessage, title:  Constant.Message.chatNtfReplyAction, options: .foreground, textInputButtonTitle: Constant.Message.chatNtfReplySend, textInputPlaceholder: Constant.emptyString)
        
        let newChatMsgCategory = UNNotificationCategory(identifier: Constant.NotificationCategory.newChatMessage,
                                                     actions: [chatReplyAction, chatIgnoreAction],
                                                     intentIdentifiers: [],
                                                     options: UNNotificationCategoryOptions(rawValue: 0))

        UNUserNotificationCenter.current().setNotificationCategories([newChatMsgCategory])
        UNUserNotificationCenter.current().delegate = self
       
        // Register with APNs
        application.registerForRemoteNotifications()
        
        // Initialise Firebase
        FirebaseApp.configure();

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {_, _ in} )
        Messaging.messaging().delegate = self as? MessagingDelegate

        application.registerForRemoteNotifications()
        
        configureShortCuts(application)

        NotificationCenter.default.addObserver(self, selector: #selector(refreshShortcuts), name: Constant.Notification.dataRefreshed, object: nil)
        
        return true
    }


    //
    // MARK: Shortcuts
    //
    @objc func refreshShortcuts() {
        DispatchQueue.main.async {
            self.configureShortCuts(UIApplication.shared)
        }
    }
    
    
    func configureShortCuts(_ application: UIApplication) {
        let chatIcon = UIApplicationShortcutIcon(templateImageName: Constant.Icon.chat)
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
            let userInfo:UserInfo = [ .tripId: String(trip.trip.id) ]
            let shortcut = UIMutableApplicationShortcutItem(type: Constant.Shortcut.chat,
                localizedTitle: tripName,
                localizedSubtitle: Constant.Message.shortcutSendMessageSubtitle,
                icon: chatIcon,
                userInfo: userInfo.securePropertyList()
            )
            shortcuts.append(shortcut)
        }
        if let trip = currentTrip, let tripName = trip.trip.name {
            let userInfo:UserInfo = [ .tripId: String(trip.trip.id) ]
            let shortcut = UIMutableApplicationShortcutItem(type: Constant.Shortcut.chat,
                localizedTitle: tripName,
                localizedSubtitle: Constant.Message.shortcutSendMessageSubtitle,
                icon: chatIcon,
                userInfo: userInfo.securePropertyList()
            )
            shortcuts.append(shortcut)
        }
        if let trip = nextTrip, let tripName = trip.trip.name {
            let userInfo:UserInfo = [ .tripId: String(trip.trip.id) ]
            let shortcut = UIMutableApplicationShortcutItem(type: Constant.Shortcut.chat,
                localizedTitle: tripName,
                localizedSubtitle: Constant.Message.shortcutSendMessageSubtitle,
                icon: chatIcon,
                userInfo: userInfo.securePropertyList()
            )
            shortcuts.append(shortcut)
        }

        application.shortcutItems = shortcuts
    }
    
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        
        switch (shortcutItem.type) {
        case Constant.Shortcut.chat:
            let userInfo = UserInfo(shortcutItem.userInfo)
            guard let tripIdStr = userInfo[.tripId] as? String, let tripId = Int(tripIdStr) else {
                os_log("Invalid shortcut, no tripId", log: OSLog.general, type: .error)
                return
            }
            ChatViewController.pushDeepLinked(for: tripId)

        default:
            os_log("Don't know how to handle shortcut type '%{public}s'", log: OSLog.general, type: .error, shortcutItem.type)
        }

        completionHandler(true)
    }

    
    //
    // MARK: Remote Notifications
    //
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        os_log("Remote notification support is unavailable due to error: %{public}s", log: OSLog.notification, type: .error, error.localizedDescription)
    }

    
    func application(_ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
      var readableToken: String = ""
      for i in 0..<deviceToken.count {
        readableToken += String(format: "%02.2hhx", deviceToken[i] as CVarArg)
      }
      os_log("Received an APNs device token: %{public}s", log: OSLog.notification, type: .debug, readableToken)
    }


    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        os_log("application didReceiveRemoteNotification", log: OSLog.general, type: .debug)

        guard let remoteNotification = RemoteNotification(from: userInfo) else {
            completionHandler(.failed)
            return
        }
        handleRemoteNotification(notification: remoteNotification, completionHandler: completionHandler)
    }
    
    
    func handleRemoteNotification(notification: RemoteNotification, completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        switch (notification.changeType, notification.changeOperation) {
        case (Constant.ChangeType.chatMessage, Constant.ChangeOperation.insert):
            if let trip = notification.trip {
                trip.chatThread.refresh(mode: .incremental)
            }
            completionHandler(.newData)

        case (Constant.ChangeType.chatMessage, Constant.ChangeOperation.update):
            if let trip = notification.trip {
                trip.chatThread.updateReadStatus(lastSeenByUsers: notification.lastSeenByUsers!, lastSeenVersion: notification.lastSeenVersion!)
                completionHandler(.newData)
            } else {
                os_log("Updating trip list", log: OSLog.general, type: .debug)
                TripList.sharedList.getFromServer(parentCompletionHandler: {
                    completionHandler(.newData);
                } )
            }

        case (Constant.ChangeType.chatMessage, _):
            completionHandler(.failed)
            os_log("Unknown change type/operation: %{public}s, %{public}s", log: OSLog.notification, type: .error, notification.changeType, notification.changeOperation)
            
        default:
            // Update from server in background
            if let trip = notification.trip {
                os_log("Updating trip ID %d", log: OSLog.general, type: .debug, notification.tripId)
                trip.loadDetails(parentCompletionHandler: {
                    completionHandler(.newData);
                } )
            } else {
                os_log("Updating trip list", log: OSLog.general, type: .debug)
                TripList.sharedList.getFromServer(parentCompletionHandler: {
                    completionHandler(.newData);
                } )
            }
        }
    }
    

    //
    // MARK: UNUserNotificationCenter delegate
    //
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        os_log("AppDelegate userNotificationCenter willPresent", log: OSLog.general, type: .debug)
        completionHandler([/*.alert, */.badge, .banner, .sound])
    }
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        os_log("userNotificationCenter didReceive", log: OSLog.general, type: .debug)

        let category = response.notification.request.content.categoryIdentifier
        let action = response.actionIdentifier
        let userInfo = UserInfo(response.notification.request.content.userInfo)
        
        switch (category, action) {
        case (_, UNNotificationDismissActionIdentifier):
            // User dismissed notification, no need to do anything
            break
            
        case (_, UNNotificationDefaultActionIdentifier):
            if let _ = response.notification.request.trigger as? UNPushNotificationTrigger, let remoteNotification = RemoteNotification(from: userInfo) {
                switch (remoteNotification.changeType, remoteNotification.changeOperation) {
                case (Constant.ChangeType.chatMessage, Constant.ChangeOperation.update):
                    // This shouldn't happen because these notifications aren't presented to the user
                    break;
                    
                case (Constant.ChangeType.chatMessage, Constant.ChangeOperation.insert):
                    // User opened app from notification, open chat screen
                    let ntfLink = NotificationLink(userInfo: userInfo)
                    DeepLinkManager.current().set(linkHandler: ntfLink)
                    DeepLinkManager.current().checkAndHandle()
                    
                case (_, Constant.ChangeOperation.insert):
                    fallthrough
                case (_, Constant.ChangeOperation.update):
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
            
        case (Constant.NotificationCategory.newChatMessage, Constant.NotificationAction.replyToChatMessage):
            // Handle reply to chat message
            guard let textResponse = response as? UNTextInputNotificationResponse else {
                fatalError("Response to chat message is not UNTextInputNotificationResponse")
            }
            guard let ntfTripId = userInfo[.tripId] as? String, let tripId = Int(ntfTripId), let trip = TripList.sharedList.trip(byId: tripId) else {
                fatalError("Invalid remote notification, no aps element, alert info, message key, message arguments or trip ID.")
            }
            ChatMessage.read(fromUserInfo: userInfo, responseHandler: {_,_,_ in })
            let newMsg = ChatMessage(message: textResponse.userText)
            trip.trip.chatThread.append(newMsg)
            
        case (Constant.NotificationCategory.newChatMessage, Constant.NotificationAction.ignoreChatMessage):
            ChatMessage.read(fromUserInfo: userInfo, responseHandler: {_,_,_ in })
            
        default:
            os_log("Invalid action for new chat message: %s", log: OSLog.webService, type: .error, response.actionIdentifier)
            
        }
        
        completionHandler()
    }

    
    private func application(_ application: UIApplication, didRegister notificationSettings: UNNotificationRequest) {
        os_log("Registered with Firebase", log: OSLog.notification, type: .debug)
        Messaging.messaging().subscribe(toTopic: Constant.Firebase.topicGlobal)
        User.sharedUser.registerForPushNotifications()
        TripList.sharedList.registerForPushNotifications()
    }
    
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        if RSUtilities.isNetworkAvailable( SHiTResource.host ) {
            if User.sharedUser.hasCredentials() {
                TripList.sharedList.getFromServer()
            }
        } else {
            os_log("Network unavailable", log: OSLog.general, type: .debug)
        }

        DeepLinkManager.current().checkAndHandle()
    }
    

    func applicationWillTerminate(_ application: UIApplication) {
        TripList.sharedList.saveToArchive()
    }

    
    func registerDefaultsFromSettingsBundle() {
        guard let settingsURL = Constant.Settings.url, let settingsRootDict = NSDictionary(contentsOf: settingsURL),
            let prefSpecifiers = settingsRootDict[Constant.Settings.preferencesDictionaryKey] as? [NSDictionary] else {
            os_log("Could not get preference specifiers from Settings.bundle", log: OSLog.general, type: .error)
            return;
        }
        
        let filteredSpecifiers = prefSpecifiers.filter { $0[Constant.Settings.preferenceIdentifier] != nil && $0[Constant.Settings.preferenceDefaultValue] != nil }
        if let keysAndValues = filteredSpecifiers.map({ ($0[Constant.Settings.preferenceIdentifier], $0[Constant.Settings.preferenceDefaultValue]) }) as? [(String, Any)] {
            UserDefaults.standard.register(defaults: Dictionary(uniqueKeysWithValues: keysAndValues))
        } else {
            os_log("Unable to get default values from Settings.bundle", log: OSLog.general, type: .error)
        }
        
        syncDefaults()
    }

    func syncDefaults() {
        if let sharedDefaults = UserDefaults(suiteName: Constant.Group.defaults) {
            let muteSetting = UserDefaults.standard.string(forKey: Constant.Settings.notificationMute)
            sharedDefaults.set(muteSetting, forKey: Constant.Settings.notificationMute)
        } else {
            os_log("Unable to sync defaults - couldn't access shared defaults", log: OSLog.general, type: .error)
        }
    }
    
    @objc func defaultsChanged(_ notification:Notification) {
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

            syncDefaults()
        } else {
            os_log("Defaults changed, but user defaults not available", log: OSLog.general, type: .info)
        }
    }
    
    
    @objc func tokenRefreshNotification( _ notification: Notification) {
        connectToFirebase()
    }
    
    
    func connectToFirebase() {
        Messaging.messaging().subscribe(toTopic: Constant.Firebase.topicGlobal)
        User.sharedUser.registerForPushNotifications()
    }

}

