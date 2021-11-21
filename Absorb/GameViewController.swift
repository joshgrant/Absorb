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

// 2. When the user enters their name, it should update the score...
// 3. Game center view's bottom has a weird spacing...

protocol GameSceneDelegate: AnyObject
{
    func gamePaused()
    func gameOver(score: Int)
    func gameRestarted()
    func showLeaderboard()
    func openPauseMenuFromGameOver()
    func scoreUpdate(to score: Int)
    func disableAds()
    func authenticatePlayer()
    
    func resume()
}

class GameViewController: UIViewController
{
    enum Constants {
        static let screenshotMode = false
        static let alwaysShowTutorial = false
    }
    
    var fakeWindow: UIWindow?
    var showingTutorial: Bool = false
    var tutorialView: UIStackView?
    
    var hackPaused: Bool {
        get {
            gameView.scene?.speed == 0
        }
        set {
            if showingTutorial { return }
            gameView.scene?.speed = newValue ? 0 : 1
            gameView.scene?.physicsWorld.speed = newValue ? 0 : 1
        }
    }
    
    lazy var gameView = SKView()
    var playPauseButton: UIButton?
    lazy var scoreLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .label
        label.font = .systemFont(ofSize: 34, weight: .light)
        return label
    }()
    
    lazy var bannerView: GADBannerView = {
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
#if DEBUG
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
#else
        bannerView.adUnitID = "ca-app-pub-7759050985948144/7040274891"
#endif
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
        gameView.addSubview(scoreLabel)
        
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44),
            button.trailingAnchor.constraint(equalTo: gameView.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            button.topAnchor.constraint(equalTo: gameView.safeAreaLayoutGuide.topAnchor, constant: 20),
            
            scoreLabel.leadingAnchor.constraint(equalTo: gameView.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            scoreLabel.topAnchor.constraint(equalTo: gameView.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
        
        playPauseButton = button
        
        contentView.addArrangedSubview(gameView)
        
        if !UserDefaults.standard.bool(forKey: "premium") {
            if !Constants.screenshotMode {
                contentView.addArrangedSubview(bannerView)
            }
        }
        
        view = contentView
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        presentScene(paused: shouldPauseForTutorial())
        authenticatePlayer()
        bannerView.load(GADRequest())
        
        if shouldPauseForTutorial() {
            tutorialView = makeTutorialView()
            
            view.addSubview(tutorialView!)
            print("Adding tutorial view")
            
            NSLayoutConstraint.activate([
                tutorialView!.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100),
                tutorialView!.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
            
            UIView.animate(withDuration: 1.5, delay: 0.0, options: [.repeat, .autoreverse], animations: { [weak self] in
                self?.tutorialView!.transform = .init(scaleX: 1.2, y: 1.2)
            }, completion: { done in
                print("Done animating")
            })
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        if tutorialView != nil {
            tutorialView?.removeFromSuperview()
            resume()
            UserDefaults.standard.set(true, forKey: "tutorial")
        }
    }
    
    func presentScene(paused: Bool = false)
    {
        scoreLabel.text = "0"
        
        let scene = GameScene()
        scene.gameSceneDelegate = self
        
        gameView.ignoresSiblingOrder = true
        
#if DEBUG
        if !Constants.screenshotMode {
            gameView.showsFPS = true
            gameView.showsNodeCount = true
        }
#endif
        
        gameView.presentScene(scene)
        
        hackPaused = paused
    }
    
    @objc func playPauseButtonDidTouchUpInside(_ sender: UIButton)
    {
        hackPaused.toggle()
        
        if hackPaused
        {
            gamePaused()
        }
    }
}

extension GameViewController: GameSceneDelegate
{
    func gamePaused()
    {
        hackPaused = true
        let pauseViewController = PauseViewController()
        pauseViewController.gameSceneDelegate = self
        pauseViewController.presentationController?.delegate = self
        show(pauseViewController, sender: self)
    }
    
    func gameOver(score: Int)
    {
        presentScene(paused: true)
        
        let gameOver = GameOverViewController(score: score)
        gameOver.presentationController?.delegate = self
        gameOver.gameSceneDelegate = self
        show(gameOver, sender: self)
    }
    
    func gameRestarted()
    {
        presentScene(paused: shouldPauseForTutorial())
        presentedViewController?.dismiss(animated: true, completion: nil)
    }
    
    func showLeaderboard()
    {
        hackPaused = true
        
        fakeWindow = UIWindow(frame: UIScreen.main.bounds)
        fakeWindow?.rootViewController = UIViewController()
        
        let leaderboard = GKGameCenterViewController(
            leaderboardID: "com.joshgrant.topscores",
            playerScope: .global,
            timeScope: .allTime)
        leaderboard.gameCenterDelegate = self
        leaderboard.view.translatesAutoresizingMaskIntoConstraints = true
        
        fakeWindow?.makeKeyAndVisible()
        fakeWindow?.rootViewController?.show(leaderboard, sender: self)
    }
    
    func openPauseMenuFromGameOver()
    {
        let pause = PauseViewController()
        pause.gameSceneDelegate = self
        pause.presentationController?.delegate = self
        show(pause, sender: self)
    }
    
    func scoreUpdate(to score: Int) {
        scoreLabel.text = "\(score)"
        
        UIView.animateKeyframes(withDuration: 0.3, delay: 0.0, options: [.beginFromCurrentState], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5) {
                self.scoreLabel.transform = .init(scaleX: 2.0, y: 2.0)
            }
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                self.scoreLabel.transform = .init(scaleX: 1.0, y: 1.0)
            }
        }, completion: nil)
        
    }
    
    func disableAds() {
        bannerView.removeFromSuperview()
    }
    
    func shouldPauseForTutorial() -> Bool {
        return UserDefaults.standard.bool(forKey: "tutorial") == false || Constants.alwaysShowTutorial
    }
    
    func authenticatePlayer()
    {
        hackPaused = true
        GKLocalPlayer.local.authenticateHandler = { [unowned self] controller, error in
            if GKLocalPlayer.local.isAuthenticated
            {
                if !shouldPauseForTutorial() {
                    hackPaused = false
                }
                print("Authenticated!")
            }
            else if let controller = controller
            {
                present(controller, animated: true, completion: nil)
            }
            else if let error = error
            {
                if !shouldPauseForTutorial() {
                    hackPaused = false
                }
                print(error.localizedDescription)
            }
        }
    }
    
    func resume() {
        hackPaused = false
    }
}

extension GameViewController: UIPopoverPresentationControllerDelegate
{
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController)
    {
        /// Check which controller dismisses... because if the game over dismisses, it... resumes the game?
        hackPaused = shouldPauseForTutorial()
        playPauseButton?.setImage(.init(systemName: "pause.fill"), for: .normal)
    }
}

extension GameViewController: GKGameCenterControllerDelegate
{
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController)
    {
        gameCenterViewController.dismiss(animated: true, completion: { [weak self] in
            self?.fakeWindow = nil
        })
    }
}

// MARK: - Tutorial

extension GameViewController {
    
    func makeTutorialView() -> UIStackView {
        let tapToMoveLabel = UILabel()
        tapToMoveLabel.text = "Tap to move"
        tapToMoveLabel.font = .systemFont(ofSize: 15)
        tapToMoveLabel.textColor = .secondaryLabel
        tapToMoveLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        tapToMoveLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        let tapNode = UIImageView(image: .init(systemName: "hand.tap")!)
        tapNode.tintColor = .label
        
        let view = UIStackView(arrangedSubviews: [
            tapToMoveLabel,
            tapNode
        ])
        
        view.axis = .vertical
        view.spacing = 5
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alignment = .center
        view.isUserInteractionEnabled = false
        
        return view
    }
}
