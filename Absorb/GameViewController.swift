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
    lazy var gameView = SKView()
    
    override func loadView()
    {
        view = gameView
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
    
    func presentScene(paused: Bool = false)
    {
        let scene = GameScene()
        scene.gameSceneDelegate = self
        
        gameView.ignoresSiblingOrder = true
        gameView.showsFPS = true
        gameView.showsNodeCount = true
        
        gameView.presentScene(scene)
        
        scene.isPaused = paused
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
    
    func gamePaused() {
        let pauseViewController = PauseViewController()
        pauseViewController.presentationController?.delegate = self
        present(pauseViewController, animated: true, completion: nil)
    }
    
    func gameOver(score: Int, type: GameOverType) {
        
        presentScene(paused: true)
        
        let gameOver = GameOverViewController(score: score, type: type)
        gameOver.presentationController?.delegate = self
        present(gameOver, animated: true, completion: nil)
    }
}

extension GameViewController: UIPopoverPresentationControllerDelegate
{
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        gameView.scene?.isPaused = false
    }
}

