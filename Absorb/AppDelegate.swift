//
//  AppDelegate.swift
//  Absorb
//
//  Created by Josh Grant on 10/12/21.
//

import UIKit
import GameKit
import GoogleMobileAds
import Purchases
import Firebase

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
        
        /*
         Warning: Ads may be preloaded by the Mobile Ads SDK or mediation partner SDKs upon calling startWithCompletionHandler:. If you need to obtain consent from users in the European Economic Area (EEA), set any request-specific flags (such as tagForChildDirectedTreatment or tag_for_under_age_of_consent), or otherwise take action before loading ads, ensure you do so before initializing the Mobile Ads SDK.
         */
        
        // How can I obtain consent from the EEA?
        
        // Check the in-app purchases to see if they've bought ad-free
        if !UserDefaults.standard.bool(forKey: "premium") {
            GADMobileAds.sharedInstance().start(completionHandler: nil)
        }
        
        #if DEBUG
            Purchases.logLevel = .debug
        #endif
        
        Purchases.configure(withAPIKey: "skJjROkPtlcnwqeMdaxjxtuKQubDCyGy")
        FirebaseApp.configure()
        
        return true
    }
    
//    func applicationDidEnterBackground(_ application: UIApplication)
//    {
//        guard let controller = window?.rootViewController as? GameViewController else { return }
//     
//        if !controller.gameView.isPaused {
//            controller.gamePaused()
//        }
//    }
}
