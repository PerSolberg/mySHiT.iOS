//
//  AppDelegate.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-09.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        print("Application didFinishLaunchingWithOptions")
        // Override point for customization after application launch.
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [UIUserNotificationType.Alert, UIUserNotificationType.Badge, UIUserNotificationType.Sound], categories: nil))
        self.registerDefaultsFromSettingsBundle();
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "defaultsChanged:", name: NSUserDefaultsDidChangeNotification, object: nil)
        return true
    }


    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        NSNotificationCenter.defaultCenter().postNotificationName("RefreshTripList", object: self)
        NSNotificationCenter.defaultCenter().postNotificationName("RefreshTripElements", object: self)
    }


    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        NSNotificationCenter.defaultCenter().postNotificationName("RefreshTripList", object: self)
        NSNotificationCenter.defaultCenter().postNotificationName("RefreshTripElements", object: self)
    }
    

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        print("Application applicationWillTerminate")
    }

    func registerDefaultsFromSettingsBundle() {
        guard let settingsBundle = NSBundle.mainBundle().URLForResource("Settings", withExtension:"bundle") else {
            NSLog("Could not find Settings.bundle")
            return;
        }
        
        guard let settings = NSDictionary(contentsOfURL: settingsBundle.URLByAppendingPathComponent("Root.plist")) else {
            NSLog("Could not find Root.plist in settings bundle")
            return
        }
        
        guard let preferences = settings.objectForKey("PreferenceSpecifiers") as? [[String: AnyObject]] else {
            NSLog("Root.plist has invalid format")
            return
        }
        
        var defaultsToRegister = [String: AnyObject]()
        for var p in preferences {
            if let k = p["Key"] as? String, v = p["DefaultValue"] {
                defaultsToRegister[k] = v
            }
        }
        
        NSUserDefaults.standardUserDefaults().registerDefaults(defaultsToRegister)
    }

    func defaultsChanged(notification:NSNotification){
        if let _ = notification.object as? NSUserDefaults {
            print("Defaults changed - updating alerts...")
            TripList.sharedList.refreshNotifications()
        }
    }
}

