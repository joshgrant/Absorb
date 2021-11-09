//
//  GameViewController.swift
//  Absorb
//
//  Created by Josh Grant on 10/12/21.
//

import UIKit
import SpriteKit
import GameKit
import GoogleMobileAds

class GameViewController: UIViewController
{
    lazy var gameView = SKView()
    var playPauseButton: UIButton?
    lazy var bannerView: GADBannerView = {
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
        // Change this to production?
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        bannerView.rootViewController = self
        return bannerView
    }()
    
    override var prefersStatusBarHidden: Bool { UserDefaults.standard.bool(forKey: "status") }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { [.portrait] }
    override var shouldAutorotate: Bool { false }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        gameView.scene?.backgroundColor = .systemBackground
    }
    
    override func loadView()
    {
        let contentView = UIStackView()
        contentView.axis = .vertical
        
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(.init(systemName: "pause.fill"), for: .normal)
        button.tintColor = .darkGray
        button.addTarget(self, action: #selector(playPauseButtonDidTouchUpInside(_:)), for: .touchUpInside)
        gameView.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44),
            button.trailingAnchor.constraint(equalTo: gameView.safeAreaLayoutGuide.trailingAnchor),
            button.topAnchor.constraint(equalTo: gameView.safeAreaLayoutGuide.topAnchor)
        ])
        
        // Check that the in-app purchase hasn't been made yet
        
        playPauseButton = button
        
        contentView.addArrangedSubview(gameView)
        contentView.addArrangedSubview(bannerView)

        view = contentView
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        presentScene()
        authenticatePlayer()
        bannerView.load(GADRequest())
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
    
    @objc func playPauseButtonDidTouchUpInside(_ sender: UIButton)
    {
        gameView.scene?.isPaused.toggle()
        
        if gameView.scene?.isPaused ?? false
        {
            gamePaused()
        }
    }
}

extension GameViewController: GameSceneDelegate
{
    func gamePaused()
    {
        let pauseViewController = PauseViewController()
        pauseViewController.gameSceneDelegate = self
        pauseViewController.presentationController?.delegate = self
        present(pauseViewController, animated: true, completion: nil)
    }
    
    func gameOver(score: Int, type: GameOverType)
    {
        presentScene(paused: true)
        
        let gameOver = GameOverViewController(score: score, type: type)
        gameOver.presentationController?.delegate = self
        gameOver.gameSceneDelegate = self
        present(gameOver, animated: true, completion: nil)
    }
    
    func gameRestarted()
    {
        presentScene(paused: false)
        presentedViewController?.dismiss(animated: true, completion: nil)
    }
    
    func showLeaderboard() {
        let leaderboard = GKGameCenterViewController(
            leaderboardID: "com.joshgrant.topscores",
            playerScope: .global,
            timeScope: .allTime)
        leaderboard.gameCenterDelegate = self
        
        show(leaderboard, sender: self)
    }
}

extension GameViewController: UIPopoverPresentationControllerDelegate
{
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController)
    {
        gameView.scene?.isPaused = false
        playPauseButton?.setImage(.init(systemName: "pause.fill"), for: .normal)
    }
}

extension GameViewController: GKGameCenterControllerDelegate
{
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController)
    {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
}
