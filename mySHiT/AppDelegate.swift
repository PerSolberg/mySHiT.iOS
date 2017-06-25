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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"
    var appSettings = Dictionary<AnyHashable, Any>()
    var avPlayer:AVAudioPlayer?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // First save current app settings, so we can avoid refreshing when Firebase settings change
        let defaults = UserDefaults.standard
        appSettings[Constant.Settings.tripLeadTime] = Int(defaults.float(forKey: Constant.Settings.tripLeadTime))
        appSettings[Constant.Settings.deptLeadTime] = Int(defaults.float(forKey: Constant.Settings.deptLeadTime))
        appSettings[Constant.Settings.legLeadTime] = Int(defaults.float(forKey: Constant.Settings.legLeadTime))
        appSettings[Constant.Settings.eventLeadTime] = Int(defaults.float(forKey: Constant.Settings.eventLeadTime))
        
        print("Application didFinishLaunchingWithOptions")
        // Override point for customization after application launch.
        application.registerUserNotificationSettings(UIUserNotificationSettings(types: [UIUserNotificationType.alert, UIUserNotificationType.badge, UIUserNotificationType.sound], categories: nil))
        self.registerDefaultsFromSettingsBundle();
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.defaultsChanged(_:)), name: UserDefaults.didChangeNotification, object: nil)
        
        //NotificationCenter.default.addObserver(self, selector: #selector(tokenRefreshNotification), name: kFIRInstanceIDTokenRefreshNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tokenRefreshNotification), name: NSNotification.Name.firInstanceIDTokenRefresh, object: nil)
        
        // Register with APNs
        UIApplication.shared.registerForRemoteNotifications()
        
        // Initialise Firebase
        FIRApp.configure();

        // Not supporting iOS 10 yet
        //if #available(iOS 10.0, *) {
        //    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        //    UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {_, _ in} )
        //    UNUserNotificationCenter.current().delegate = self
        //    FIRMessaging.messaging().remoteMessageDelegate = self
        //} else {
            let settings: UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        //}
        
        application.registerForRemoteNotifications()
        
        if let firebaseToken = FIRInstanceID.instanceID().token() {
            print("Firebase token = " + firebaseToken)
            //self.forwardTokenToServer(tokenString: firebaseToken)
        } else {
            print("Firebase token not assigned yet")
        }

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

    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
//        print("Received notification: " + notification.description)
        // if remote notification {
        /*
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.refreshTripList), object: self)
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.refreshTripElements), object: self)
        */
        // } else {
        //    Show alert if application is active
        // }
        if (application.applicationState == .active /* UIApplicationStateActive */ ) {
            let alertController = UIAlertController(title: notification.alertTitle, message: notification.alertBody, preferredStyle: UIAlertControllerStyle.alert)
            
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
            {
                (result : UIAlertAction) -> Void in
                print("You pressed OK")
            }
            alertController.addAction(okAction)
            
            AudioServicesPlaySystemSound(1005)
            self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
        }
    }
    

    /*
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        print("didReceiveRemoteNotification w/o completionHandler")
        // TO DO: Handle remote notication
        if let messageId = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageId)")
        }
        print(userInfo)
    }
    */
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//        print("Remote notification received: \(String(describing: userInfo))")

        guard let changeType = userInfo["changeType"] as? String else {
            fatalError("Invalid remote notification, no changeType element")
        }
        guard let changeOperation = userInfo["changeOperation"] as? String else {
            fatalError("Invalid remote notification, no changeOperation element")
        }

        print("Change type = \(changeType)")
        
        switch (changeType, changeOperation) {
        case (Constant.changeType.chatMessage, Constant.changeOperation.insert):
            handleNewChatMessage(userInfo: userInfo, parentCompletionHandler: {
                completionHandler(UIBackgroundFetchResult.newData);
            })

        case (Constant.changeType.chatMessage, Constant.changeOperation.update):
            handleReadChatMessage(userInfo: userInfo, parentCompletionHandler: {
                completionHandler(UIBackgroundFetchResult.newData)
            })
        
        case (Constant.changeType.chatMessage, _):
            fatalError("Unknown change type/operation: (changeType, changeOperation)")

        default:
            // Update from server (should take place in background)
            TripList.sharedList.getFromServer(parentCompletionHandler: {
                completionHandler(UIBackgroundFetchResult.newData);
            } )
        }
    }

    
    func handleNewChatMessage(userInfo: [AnyHashable : Any], parentCompletionHandler: @escaping () -> Void) {
        guard let apsInfo = userInfo["aps"] as? NSDictionary, let alertInfo = apsInfo["alert"] as? NSDictionary, let _ = alertInfo["loc-key"] as? String, let _ = alertInfo["loc-args"] as? NSArray, let ntfTripId = userInfo["tripId"] as? String, let tripId = Int(ntfTripId) else {
            fatalError("Invalid remote notification, no aps element, alert info, message key, message arguments or trip ID.")
        }
        let soundName:String? = apsInfo["sound"] as? String

//        print("Notification for trip \(tripId)")

        let rootVC = UIApplication.shared.keyWindow?.rootViewController
        if let navVC = rootVC as? UINavigationController, let chatVC = navVC.visibleViewController as? ChatViewController, let trip = chatVC.trip?.trip, trip.id == tripId {
//            print("Message for current chat - refresh but don't notify")
            trip.chatThread.refresh(mode: .incremental)

            // Notify user of chat message
            if let soundName = soundName {
                playSound(name: soundName, type: nil)
            }
        } else {
            // Notify user of chat message
            if let soundName = soundName {
                playSound(name: soundName, type: nil)
            }
            
            /* Notifications while app is active requires iOS 10 or bespoke GUI elements and code
             let message = String(format: NSLocalizedString(locKey, comment:""), locale: NSLocale.current, arguments: msgArgs as! [CVarArg])
             
            let alertController = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.alert)
            
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
            {
                (result : UIAlertAction) -> Void in
                print("You pressed OK")
            }
            alertController.addAction(okAction)
            
            //self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
            */

            /*
             @available(iOS 10.0, *)
             func userNotificationCenter(center: UNUserNotificationCenter, willPresentNotification notification: UNNotification, withCompletionHandler completionHandler: (UNNotificationPresentationOptions) -> Void)
             {
             //Handle the notification
             completionHandler(
             [UNNotificationPresentationOptions.Alert,
             UNNotificationPresentationOptions.Sound,
             UNNotificationPresentationOptions.Badge])
             }
             */
        }
        parentCompletionHandler()
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
    
    
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        print("Registered with Firebase")
        FIRMessaging.messaging().subscribe(toTopic: Constant.Firebase.topicGlobal)
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
        FIRMessaging.messaging().disconnect()
        TripList.sharedList.saveToArchive(TripListViewController.ArchiveTripsURL.path)
    }

    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        if (RSUtilities.isNetworkAvailable("www.shitt.no")) {
            print("Network available, refreshing information from server")
            TripList.sharedList.getFromServer()
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.refreshTripList), object: self)
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.refreshTripElements), object: self)
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

    
    func defaultsChanged(_ notification:Notification){
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
                print("SHiT Settings changed - updating alerts...")
                print("Trip lead time: \(String(describing: oldTripLeadTime)) -> \(newTripLeadTime)")
                print("Dept lead time: \(String(describing: oldDeptLeadTime)) -> \(newDeptLeadTime)")
                print("Leg lead time: \(String(describing: oldLegLeadTime)) -> \(newLegLeadTime)")
                print("Event lead time: \(String(describing: oldEventLeadTime)) -> \(newEventLeadTime)")
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
    
    
    func tokenRefreshNotification( _ notification: Notification) {
        /*
        if let refreshedToken = FIRInstanceID.instanceID().token() {
            print("New Firebase token = \(refreshedToken)")
            forwardTokenToServer(tokenString: refreshedToken)
        }
        */
        
        connectToFirebase()
    }
    
    
    func connectToFirebase() {
        guard FIRInstanceID.instanceID().token() != nil else {
            return
        }
        
        // Terminate previous connection (if any)
        FIRMessaging.messaging().disconnect()
        
        FIRMessaging.messaging().connect { (error) in
            if error != nil {
                print("Unable to connect to Firebase. \(String(describing: error))")
            } else {
                print("Connected to Firebase")
                FIRMessaging.messaging().subscribe(toTopic: Constant.Firebase.topicGlobal)

                User.sharedUser.registerForPushNotifications()
            }
        }
    }

    
    func playSound(name: String, type: String?) {
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

    
    // Probably won't need this...
    func forwardTokenToServer(token: Data) {
        print("Register token with server")
        let userCred = User.sharedUser.getCredentials()
        
        assert( userCred.name != nil );
        assert( userCred.password != nil );
        assert( userCred.urlsafePassword != nil );

        var tokenString = ""
        for i in 0..<token.count {
            tokenString += String(format: "%02.2hhx", token[i] as CVarArg)
        }
        
        //let tokenString = String(data: token, encoding: .utf8) ?? "Unable to print token"
        print("Token: " + tokenString)
        let webServiceRootPath = "device/"
        let rsRequest: RSTransactionRequest = RSTransactionRequest()
        //let tokenString = String(data:token, encoding: .utf8)
        let tokenPayload = [ "userName":userCred.name!,
                             "password":userCred.password!,
                             "platform": "IOS",
                             "env": "DEV",
                             "key1": tokenString
        ]
        let rsRegisterToken: RSTransaction = RSTransaction(transactionType: RSTransactionType.post, baseURL: "https://www.shitt.no/mySHiT", path: webServiceRootPath, parameters: ["userName":"dummy@default.com","password":"******"], payload: tokenPayload)
    
        //Set the parameters for the RSTransaction object
        rsRegisterToken.path = webServiceRootPath
        /*rsRegisterToken.parameters = [ "userName":userCred.name!,
                                       "password":userCred.password!,
                                       "platform": "IOS",
                                       "env": "DEV",
                                       "key1": token.base64EncodedString()
                                     ]
        */
        //Send request
        print("Send token registration request")
        rsRequest.dictionaryFromRSTransaction(rsRegisterToken, completionHandler: {(response : URLResponse?, responseDictionary: NSDictionary?, error: Error?) -> Void in
            if let error = error {
                //If there was an error, log it
                print("Token registration system error : \(error.localizedDescription)")
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.networkError), object: self)
            } else if let error = responseDictionary?[Constant.JSON.queryError] {
                let errMsg = error as! String
                print("Token registration server error : \(errMsg)")
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.networkError), object: self)
            } else {
                //Set the tableData NSArray to the results returned from www.shitt.no
                print("Token successfully registered with server")
            }
        })
        print("Token registration submitted")
    }

    func forwardTokenToServer(tokenString: String) {
        print("Register token with server")
        let userCred = User.sharedUser.getCredentials()
        
        assert( userCred.name != nil );
        assert( userCred.password != nil );
        assert( userCred.urlsafePassword != nil );
        
        //let tokenString = String(data: token, encoding: .utf8) ?? "Unable to print token"
        print("Token: " + tokenString)
        let webServiceRootPath = "device/"
        let rsRequest: RSTransactionRequest = RSTransactionRequest()
        //let tokenString = String(data:token, encoding: .utf8)
        let tokenPayload = [ "userName":userCred.name!,
                             "password":userCred.password!,
                             "platform": "IOS",
                             "env": "DEV",
                             "key1": tokenString
        ]
        let rsRegisterToken: RSTransaction = RSTransaction(transactionType: RSTransactionType.post, baseURL: "https://www.shitt.no/mySHiT", path: webServiceRootPath, parameters: ["userName":"dummy@default.com","password":"******"], payload: tokenPayload)
        
        //Set the parameters for the RSTransaction object
        rsRegisterToken.path = webServiceRootPath
        //Send request
        print("Send token registration request")
        rsRequest.dictionaryFromRSTransaction(rsRegisterToken, completionHandler: {(response : URLResponse?, responseDictionary: NSDictionary?, error: Error?) -> Void in
            if let error = error {
                //If there was an error, log it
                print("Token registration system error : \(error.localizedDescription)")
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.networkError), object: self)
            } else if let error = responseDictionary?[Constant.JSON.queryError] {
                let errMsg = error as! String
                print("Token registration server error : \(errMsg)")
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constant.notification.networkError), object: self)
            } else {
                //Set the tableData NSArray to the results returned from www.shitt.no
                print("Token successfully registered with server")
            }
        })
        print("Token registration submitted")
    }
}

