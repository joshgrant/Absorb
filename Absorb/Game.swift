//
// Created by Joshua Grant on 10/23/21
// Copyright © 2021 Joshua Grant. All rights reserved.
//

import Foundation
import GameKit

final class Game
{
    static var localPlayer: GKLocalPlayer? {
        
        let player = GKLocalPlayer.local
        
        if player.isAuthenticated
        {
            return player
        }
        else
        {
            player.authenticateHandler = { viewController, error in
                if let error = error
                {
                    fatalError(error.localizedDescription)
                }
            }
            
            return nil
        }
        
        // FROM RayWenderlich:
        /*
         GKLocalPlayer.local.authenticateHandler = { gcAuthVC, error in
         if GKLocalPlayer.local.isAuthenticated {
         print("Authenticated to Game Center!")
         } else if let vc = gcAuthVC {
         self.viewController?.present(vc, animated: true)
         }
         else {
         print("Error authentication to GameCenter: " +
         "\(error?.localizedDescription ?? "none")")
         }
         */
    }
    
//    static var leaderboard: GKLeaderboard = {
//        let leaderboard = GKLeaderboard()
//        return leaderboard
//    }()
    
    static func loadTopTenEntries()
    {
        GKLeaderboard().loadEntries(for: .global, timeScope: .today, range: .init(location: 1, length: 10)) { entry, entries, totalPlayerCount, error in
            print(entry)
            print(entries)
            print(totalPlayerCount)
            print(error)
        }
    }
    
    static func submit(score: Int)
    {
        guard let player = localPlayer else { return }
        
        GKLeaderboard.submitScore(score, context: 0, player: player, leaderboardIDs: ["com.joshgrant.topscores"]) { error in
            if let error = error {
                fatalError(error.localizedDescription)
            }
        }
    }
    
    static func save()
    {
        let data = makeSaveData()
        save(data: data)
    }
    
    private static func makeSaveData() -> Data
    {
        return Data()
    }
    
    private static func save(data: Data)
    {
        guard let player = localPlayer else { return }
        
        player.saveGameData(data, withName: "current_game") { savedGame, error in
            if let error = error
            {
                fatalError(error.localizedDescription)
            }
            else if let savedGame = savedGame
            {
                print("Saved Game: \(savedGame)")
            }
        }
    }
}
