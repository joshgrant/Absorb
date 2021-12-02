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
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = ["18d2b257aecc483f0c335507b14fa727"]
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        Purchases.logLevel = .error
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
