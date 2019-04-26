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
        
        print("Application didFinishLaunchingWithOptions")
        // Override point for customization after application launch.
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { (success : Bool, err : Error?) -> Void in } )
        self.registerDefaultsFromSettingsBundle();
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.defaultsChanged(_:)), name: UserDefaults.didChangeNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(tokenRefreshNotification), name: NSNotification.Name.InstanceIDTokenRefresh, object: nil)

        //
        // Set up notification categories
        //
        let chatIgnoreAction = UNNotificationAction(identifier: Constant.notificationAction.ignoreChatMessage,
                                              title: String(format: NSLocalizedString(Constant.msg.chatNtfIgnoreAction, comment:""), locale: NSLocale.current),
                                              options: .foreground)

        let chatReplyAction = UNTextInputNotificationAction(identifier: Constant.notificationAction.replyToChatMessage, title: String(format: NSLocalizedString(Constant.msg.chatNtfReplyAction, comment:""), locale: NSLocale.current), options: .foreground, textInputButtonTitle: String(format: NSLocalizedString(Constant.msg.chatNtfReplySend, comment:""), locale: NSLocale.current), textInputPlaceholder: "")
        
        let newChatMsgCategory = UNNotificationCategory(identifier: Constant.notificationCategory.newChatMessage,
                                                     actions: [chatReplyAction, chatIgnoreAction],
                                                     intentIdentifiers: [],
                                                     options: UNNotificationCategoryOptions(rawValue: 0))
        
        UNUserNotificationCenter.current().setNotificationCategories([newChatMsgCategory])
        UNUserNotificationCenter.current().delegate = self
       
        
        // Register with APNs
        UIApplication.shared.registerForRemoteNotifications()
        
        // Initialise Firebase
        FirebaseApp.configure();
        //FIRApp.configure();

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {_, _ in} )
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self as? MessagingDelegate

        application.registerForRemoteNotifications()
        
        print("Firebase instance ID = " + String(describing: InstanceID.instanceID()) )
//        if let firebaseInstanceID = InstanceID.instanceID() {
//            print("Firebase instance ID = " + firebaseInstanceID)
//        } else {
//            print("Firebase token not assigned yet")
//        }

        return true
    }

    // Handle remote notification registration.
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data){
        // Forward the token to your server.
        //self.enableRemoteNotificationFeatures()
        
        // Don't need this, handled by Firebase
        //self.forwardTokenToServer(token: deviceToken)
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // The token is not currently available.
        print("Remote notification support is unavailable due to error: \(error.localizedDescription)")
        //self.disableRemoteNotificationFeatures()
    }

    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//        print("Remote notification received: \(String(describing: userInfo))")
        // appState is:
        //  - active if application is active,
        //  - inactive if application is being opened from notification
        //  - background if application is in the background
//        let appState = application.applicationState
        guard let changeType = userInfo["changeType"] as? String, let changeOperation = userInfo["changeOperation"] as? String else {
            fatalError("Invalid remote notification, no changeType or changeOperation element")
        }

        print("didReceiveRemoteNotification: Change type & operation = \(changeType), \(changeOperation)")
        
        switch (changeType, changeOperation) {
        case (Constant.changeType.chatMessage, Constant.changeOperation.insert):
            if let rootVC = UIApplication.shared.keyWindow?.rootViewController, let navVC = rootVC as? UINavigationController, let chatVC = navVC.visibleViewController as? ChatViewController, let trip = chatVC.trip?.trip, let ntfTripId = userInfo["tripId"] as? String, let tripId = Int(ntfTripId), trip.id == tripId {
                // print("Message for current chat - refresh but don't notify")
                trip.chatThread.refresh(mode: .incremental)
            }
            completionHandler(UIBackgroundFetchResult.newData)

        case (Constant.changeType.chatMessage, Constant.changeOperation.update):
            handleReadChatMessage(userInfo: userInfo, parentCompletionHandler: {
                completionHandler(UIBackgroundFetchResult.newData)
            })
        
        case (Constant.changeType.chatMessage, _):
            fatalError("Unknown change type/operation: \(changeType), \(changeOperation)")

        default:
            // Update from server (should take place in background)
            TripList.sharedList.getFromServer(parentCompletionHandler: {
                completionHandler(UIBackgroundFetchResult.newData);
            } )
        }
    }


    func handleReadChatMessage(userInfo: [AnyHashable : Any], parentCompletionHandler: @escaping () -> Void) {
        guard let ntfTripId = userInfo["tripId"] as? String, let tripId = Int(ntfTripId), let strLastSeenInfo = userInfo["lastSeenInfo"] as? String else {
            print("Invalid remote notification, no/invalid trip ID or no last seen info: \(String(describing: userInfo))")
            parentCompletionHandler()
            return
        }
        var jsonLastSeenInfo:Any?
        do {
            jsonLastSeenInfo = try JSONSerialization.jsonObject(with: strLastSeenInfo.data(using: .utf8)!, options: JSONSerialization.ReadingOptions.allowFragments)
        } catch {
            print("Invalid remote notification, invalid JSON: \(strLastSeenInfo)")
            parentCompletionHandler()
            return
        }
        guard let lastSeenInfo = jsonLastSeenInfo as? NSDictionary, let lastSeenByUsers = lastSeenInfo[ Constant.JSON.messageLastSeenByOthers] as? NSDictionary, let lastSeenVersion = lastSeenInfo[Constant.JSON.lastSeenVersion] as? Int else {
            print("Invalid remote notification, invalid last seen info: \(String(describing: jsonLastSeenInfo))")
            parentCompletionHandler()
            return
        }

//        print("Message read update for trip \(String(describing: tripId))")
        
        guard let aTrip = TripList.sharedList.trip(byId: tripId) else {
            print("Chat update for unknown trip")
            parentCompletionHandler()
            return
        }
        
        aTrip.trip.chatThread.updateReadStatus(lastSeenByUsers: lastSeenByUsers, lastSeenVersion: lastSeenVersion)
        parentCompletionHandler()
    }
    

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let category = response.notification.request.content.categoryIdentifier
        let action = response.actionIdentifier
        let userInfo = response.notification.request.content.userInfo
        
        print("userNotificationCenter.didReceiveResponse: Category & action = \(category), \(action)")
        switch (category, action) {
        case (_, UNNotificationDismissActionIdentifier):
            print("User dismissed notification, no need to do anything - or maybe flag it as read")

        case (_, UNNotificationDefaultActionIdentifier):
            if let _ = response.notification.request.trigger as? UNPushNotificationTrigger, let changeType = userInfo["changeType"] as? String, let changeOperation = userInfo["changeOperation"] as? String {
                switch (changeType, changeOperation) {
                case (Constant.changeType.chatMessage, Constant.changeOperation.update):
                    // This shouldn't happen because these notifications aren't presented to the user
                    break;
                    
                case (Constant.changeType.chatMessage, Constant.changeOperation.insert):
                    print("User opened app from notification, open chat screen")
                    let ntfLink = NotificationLink(userInfo: userInfo)
                    DeepLinkManager.current().set(linkHandler: ntfLink)
                    DeepLinkManager.current().checkAndHandle()

                case (_, Constant.changeOperation.insert):
                    fallthrough
                case (_, Constant.changeOperation.update):
                    print("Trip or itinerary updated")
                    let ntfLink = NotificationLink(userInfo: userInfo)
                    DeepLinkManager.current().set(linkHandler: ntfLink)
                    DeepLinkManager.current().checkAndHandle()
                    
                default:
                    break
                }
            } else if let _ = response.notification.request.trigger as? UNCalendarNotificationTrigger {
                print("User opened app from alert")
                let alertLink = AlertLink(userInfo: userInfo)
                DeepLinkManager.current().set(linkHandler: alertLink)
                DeepLinkManager.current().checkAndHandle()
            }
            
        case (Constant.notificationCategory.newChatMessage, Constant.notificationAction.replyToChatMessage):
            // Handle reply to chat message
            guard let textResponse = response as? UNTextInputNotificationResponse else {
                fatalError("Response to chat message is not UNTextInputNotificationResponse")
            }
            guard let ntfTripId = userInfo["tripId"] as? String, let tripId = Int(ntfTripId), let trip = TripList.sharedList.trip(byId: tripId) else {
                fatalError("Invalid remote notification, no aps element, alert info, message key, message arguments or trip ID.")
            }
            ChatMessage.read(fromUserInfo: userInfo, responseHandler: {_,_,_ in })
            let newMsg = ChatMessage(message: textResponse.userText)
            trip.trip.chatThread.append(newMsg)

        case (Constant.notificationCategory.newChatMessage, Constant.notificationAction.ignoreChatMessage):
            ChatMessage.read(fromUserInfo: userInfo, responseHandler: {_,_,_ in })
            
        default:
            print("Invalid action for new chat message: \(response.actionIdentifier)")
        }
        
        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        var handlerOption:UNNotificationPresentationOptions = [.alert, .sound]
        if let _ = notification.request.trigger as? UNPushNotificationTrigger {
            let userInfo = notification.request.content.userInfo
            guard let changeType = userInfo["changeType"] as? String, let changeOperation = userInfo["changeOperation"] as? String else {
                fatalError("Invalid remote notification, no changeType or changeOperation element")
            }
            print("userNotificationCenter.willPresent: Change type & operation = \(changeType), \(changeOperation)")
            
            switch (changeType, changeOperation) {
            case (Constant.changeType.chatMessage, Constant.changeOperation.insert):
                guard let apsInfo = userInfo["aps"] as? NSDictionary, let ntfFromUserId = userInfo["fromUserId"] as? String, let fromUserId = Int(ntfFromUserId), let ntfTripId = userInfo["tripId"] as? String, let tripId = Int(ntfTripId) else {
                    fatalError("Invalid remote notification, chat message without aps data, trip ID or sending user ID.")
                }
                guard let currentUserId = User.sharedUser.userId else {
                    fatalError("Unable to get logged on user ID.")
                }
                if fromUserId == currentUserId {
                    handlerOption = []
                } else if let rootVC = UIApplication.shared.keyWindow?.rootViewController, let navVC = rootVC as? UINavigationController, let chatVC = navVC.visibleViewController as? ChatViewController, let trip = chatVC.trip?.trip, trip.id == tripId {
                    // print("Message for current chat - refresh but don't notify")
                    trip.chatThread.refresh(mode: .incremental)
                    let soundName:String? = apsInfo["sound"] as? String
                    playSound(name: soundName, type: nil)
                    handlerOption = []
                }
                
            default:
                break;
            }
        } else if let _ = notification.request.trigger as? UNCalendarNotificationTrigger {
            
        }
        
        completionHandler(handlerOption)
    }

    private func application(_ application: UIApplication, didRegister notificationSettings: UNNotificationRequest) {
        print("Registered with Firebase")
        Messaging.messaging().subscribe(toTopic: Constant.Firebase.topicGlobal)
        User.sharedUser.registerForPushNotifications()
        TripList.sharedList.registerForPushNotifications()
    }
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("Application in background, disconnected from Firebase")
        //Removing disconnect at part of Swift 5 migration
        //Messaging.messaging().disconnect()
        TripList.sharedList.saveToArchive(TripListViewController.ArchiveTripsURL.path)
    }

    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        print("applicationWillEnterForeground")
    }

    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("applicationDidBecomeActive")
        if (RSUtilities.isNetworkAvailable("www.shitt.no")) {
            print("Network available, refreshing information from server")
            TripList.sharedList.getFromServer()
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.refreshTripList), object: self)
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.refreshTripElements), object: self)
        
        DeepLinkManager.current().checkAndHandle()
    }
    

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        print("Application applicationWillTerminate")
        TripList.sharedList.saveToArchive(TripListViewController.ArchiveTripsURL.path)
    }

    
    func registerDefaultsFromSettingsBundle() {
        guard let settingsBundle = Bundle.main.url(forResource: "Settings", withExtension:"bundle") else {
            NSLog("Could not find Settings.bundle")
            return;
        }
        
        guard let settings = NSDictionary(contentsOf: settingsBundle.appendingPathComponent("Root.plist")) else {
            NSLog("Could not find Root.plist in settings bundle")
            return
        }
        
        guard let preferences = settings.object(forKey: "PreferenceSpecifiers") as? [[String: AnyObject]] else {
            NSLog("Root.plist has invalid format")
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
            //let defaults = UserDefaults.standard
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
                //print("SHiT Settings changed - updating alerts...")
//                print("Trip lead time: \(String(describing: oldTripLeadTime)) -> \(newTripLeadTime)")
//                print("Dept lead time: \(String(describing: oldDeptLeadTime)) -> \(newDeptLeadTime)")
//                print("Leg lead time: \(String(describing: oldLegLeadTime)) -> \(newLegLeadTime)")
//                print("Event lead time: \(String(describing: oldEventLeadTime)) -> \(newEventLeadTime)")
                //print(defaults.dictionaryRepresentation())
                TripList.sharedList.refreshNotifications()
                
                appSettings[Constant.Settings.tripLeadTime] = newTripLeadTime
                appSettings[Constant.Settings.deptLeadTime] = newDeptLeadTime
                appSettings[Constant.Settings.legLeadTime] = newLegLeadTime
                appSettings[Constant.Settings.eventLeadTime] = newEventLeadTime
            }
        } else {
            print("Defaults changed, but user defaults not available")
        }
    }
    
    
    @objc func tokenRefreshNotification( _ notification: Notification) {
        connectToFirebase()
    }
    
    
    func connectToFirebase() {
        // Removing this as part of Swift 5 migration
        //guard InstanceID.instanceID().token() != nil else {
        //    return
        //}

        /* Trying without all the error handling logic */
        Messaging.messaging().subscribe(toTopic: Constant.Firebase.topicGlobal)
        User.sharedUser.registerForPushNotifications()

        // Terminate previous connection (if any)
        /*
        Messaging.messaging().disconnect()
        
        Messaging.messaging().connect { (error) in
            if error != nil {
                print("Unable to connect to Firebase. \(String(describing: error))")
            } else {
                print("Connected to Firebase")
                Messaging.messaging().subscribe(toTopic: Constant.Firebase.topicGlobal)

                User.sharedUser.registerForPushNotifications()
            }
        }
        */
    }

    
    func playSound(name: String?, type: String?) {
        guard let name = name else {
            return
        }
        guard let path = Bundle.main.path(forResource: name, ofType:type) else {
            print("ERROR: Sound file '\(name)' not found.")
            return
        }
        let url = URL(fileURLWithPath: path)
        do {
            avPlayer = try AVAudioPlayer(contentsOf: url)
            avPlayer?.play()
        } catch {
            print("ERROR: Playing sound file '\(name)' failed")
        }
    }

}

