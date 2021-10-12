//
//  AppDelegate.swift
//  Absorb
//
//  Created by Josh Grant on 10/12/21.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        window = UIWindow()
        window?.rootViewController = GameViewController()
        window?.makeKeyAndVisible()
        
        return true
    }
}

