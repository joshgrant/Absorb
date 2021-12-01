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
import AdSupport

@main
class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        FirebaseApp.configure()
        
        #if DEBUG
        Purchases.logLevel = .error
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = ["e5e26e1cf15032c6dea0674945c9d8a4", "GADSimulatorID"]
        #endif
        
        // Check the in-app purchases to see if they've bought ad-free
        if !UserDefaults.standard.bool(forKey: "premium") {
            GADMobileAds.sharedInstance().start { status in
                for thing in status.adapterStatusesByClassName {
                    print(thing.key, thing.value)
                }
            }
        }
        
        Purchases.configure(withAPIKey: "skJjROkPtlcnwqeMdaxjxtuKQubDCyGy")
        
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.ambient)
        } catch {
            assertionFailure(error.localizedDescription)
        }
        
        window = UIWindow()
        window?.rootViewController = GameViewController()
        window?.makeKeyAndVisible()
        
        if UserDefaults.standard.value(forKey: "status") == nil {
            UserDefaults.standard.set(true, forKey: "status")
        }
        
        return true
    }
}
