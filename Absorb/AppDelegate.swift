//
//  AppDelegate.swift
//  Absorb
//
//  Created by Josh Grant on 10/12/21.
//

import UIKit
import GameKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        window = UIWindow()
        window?.rootViewController = GameViewController()
        window?.makeKeyAndVisible()

        if UserDefaults.standard.value(forKey: "status") == nil {
            UserDefaults.standard.set(false, forKey: "status")
        }
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication)
    {
        Game.save()
    }
}
