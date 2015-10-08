//
//  AppDelegate.swift
//  Jenkins Shake
//
//  Created by Zach Waterson on 12/17/14.
//  Copyright (c) 2014 Zach Waterson. All rights reserved.
//

import UIKit
import Parse
import Bolts

public enum UserDefaults: String {
    case RandomJenkins
    case SendUsageData
}

enum ShortcutItems: String {
    case Selfie = "com.zachwaterson.Jenkins-Shake.selfie"
    case Photo = "com.zachwaterson.Jenkins-Shake.photo"
    case Existing = "com.zachwaterson.Jenkins-Shake.existing"
}

protocol ShortcutDelegate {
    func receiveSelfieShortcut()
    func receivePhotoShortcut()
    func receiveExistingShortcut()
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var outsideImageURL: NSURL?
    
    var shortcutDelegate: ShortcutDelegate?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // register default preferences
        let appDefaults = [UserDefaults.RandomJenkins.rawValue : false, UserDefaults.SendUsageData.rawValue : true]
        NSUserDefaults.standardUserDefaults().registerDefaults(appDefaults)
        
        // color the bar
        UINavigationBar.appearance().barTintColor = UIColor.JSBackgroundColor
        
        // Parse setup
        Parse.setApplicationId("n7K1JnvwuHBLaw3dDnXSmg9thycR75jz4XNmIyd2", clientKey: "8m6kIVjRECzIJ2ssHdRwFmntbn1o0etG0gFHiY5i")
        PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
        
        // Override point for customization after application launch.
        return true
    }
    
    @available(iOS 9, *)
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
        let type = ShortcutItems(rawValue: shortcutItem.type)!

        switch type {
        case ShortcutItems.Selfie:
            shortcutDelegate?.receiveSelfieShortcut()
        case ShortcutItems.Photo:
            shortcutDelegate?.receivePhotoShortcut()
        case ShortcutItems.Existing:
            shortcutDelegate?.receiveExistingShortcut()
        }
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
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

