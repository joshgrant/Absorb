//
//  GameViewController.swift
//  Absorb
//
//  Created by Josh Grant on 10/12/21.
//

import UIKit
import SpriteKit
import GameKit

class GameViewController: UIViewController
{
    override func loadView()
    {
        view = SKView()
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()
        presentScene()
        authenticatePlayer()
    }

    override var shouldAutorotate: Bool { true }
    override var prefersStatusBarHidden: Bool { true }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask
    {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    func authenticatePlayer()
    {
        GKLocalPlayer.local.authenticateHandler = { [unowned self] controller, error in
            if GKLocalPlayer.local.isAuthenticated
            {
                print("Authenticated!")
            }
            else if let controller = controller
            {
                present(controller, animated: true, completion: nil)
            }
            else if let error = error
            {
                print(error.localizedDescription)
            }
        }
    }
    
    func presentScene()
    {
        guard let view = view as? SKView else { return }
        
        let scene = GameScene()
        scene.gameSceneDelegate = self
        
        view.ignoresSiblingOrder = true
        view.showsFPS = true
        view.showsNodeCount = true
        
        view.presentScene(scene)
    }
}

extension GameViewController: GKGameCenterControllerDelegate
{
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController)
    {
        gameCenterViewController.dismiss(animated: true, completion: nil)
        presentScene()
    }
}

extension GameViewController: GameSceneDelegate
{
    func showLeaderboard()
    {
        let leaderboard = GKGameCenterViewController(
            leaderboardID: "com.joshgrant.topscores",
            playerScope: .global, timeScope: .allTime)
        leaderboard.gameCenterDelegate = self
        present(leaderboard, animated: true, completion: nil)
    }
}
