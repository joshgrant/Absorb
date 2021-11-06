//
// Created by Joshua Grant on 10/23/21
// Copyright © 2021 Joshua Grant. All rights reserved.
//

import Foundation
import GameKit

final class Game
{
    static func loadTopTenEntries()
    {
        GKLeaderboard().loadEntries(for: [GKLocalPlayer.local], timeScope: .allTime) { entry, entries, error in
//            print(entry)
//            print(entries)
//            print(error)
        }
    }
    
    static func submit(score: Int, completion: @escaping () -> Void)
    {
        guard GKLocalPlayer.local.isAuthenticated else { completion(); return }
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: ["com.joshgrant.topscores"]) { error in
            if let error = error {
                print(error.localizedDescription)
                completion()
            } else {
                completion()
            }
        }
    }
    
//    static func save()
//    {
//        let data = makeSaveData()
//        save(data: data)
//    }
//    
//    private static func makeSaveData() -> Data
//    {
//        return Data()
//    }
//    
//    private static func save(data: Data)
//    {
//        GKLocalPlayer.local.saveGameData(data, withName: "current_game") { savedGame, error in
//            if let error = error
//            {
//                fatalError(error.localizedDescription)
//            }
//            else if let savedGame = savedGame
//            {
//                print("Saved Game: \(savedGame)")
//            }
//        }
//    }
}
