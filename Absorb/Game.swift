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
            print(entries)
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
}
