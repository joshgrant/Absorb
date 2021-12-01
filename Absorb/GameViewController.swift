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
import Firebase

// 2. When the user enters their name, it should update the score...
// 3. Game center view's bottom has a weird spacing...

protocol GameSceneDelegate: AnyObject
{
    func gamePaused()
    func resumeGame()
    func gameOver(score: Int)
    func gameRestarted()
    func showLeaderboard()
    func openPauseMenuFromGameOver()
    func scoreUpdate(to score: Int)
//    func disableAds()
    func authenticatePlayer()
}

class GameViewController: UIViewController
{
    enum Constants {
        static let screenshotMode = false
        static let alwaysShowTutorial = false
    }
    
    var fakeWindow: UIWindow?
    var tutorialView: UIStackView?
    var updating: Bool = false // Whether or not the score label is updating
    
    private var interstitial: GADInterstitialAd?
    
    var score: Int?
    
    var hackPaused: Bool {
        get {
            gameView.scene?.speed == 0
        }
        set {
            if tutorialView != nil { return }
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
    
//    var _bannerView: GADBannerView?
//    var bannerView: GADBannerView {
//        get {
//            if _bannerView == nil {
//                _bannerView = GADBannerView(adSize: GADAdSizeBanner)
////#if DEBUG
////                _bannerView!.adUnitID = "ca-app-pub-3940256099942544/2934735716"
////#else
//                _bannerView!.adUnitID = "ca-app-pub-7759050985948144/2574435753"
////#endif
//
//                _bannerView!.rootViewController = self
//                _bannerView!.delegate = self
//            }
//
//            return _bannerView!
//        }
//        set {
//            _bannerView = newValue
//        }
//    }
    
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
        
        view = contentView
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        preloadAd()
        
        presentScene(paused: shouldPauseForTutorial())
        authenticatePlayer()
        
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
        
//        guard let view = view as? UIStackView else { assertionFailure(); return }
//        if UserDefaults.standard.bool(forKey: "premium") { return }
//        if Constants.screenshotMode { return }
        
//        view.addArrangedSubview(bannerView)
//        bannerView.load(GADRequest())
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        if tutorialView != nil {
            tutorialView?.removeFromSuperview()
            tutorialView = nil
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
    func resumeGame() {
        hackPaused = false
    }
    
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
        self.score = score
        
        let gameOverCount = UserDefaults.standard.integer(forKey: "gameOverCount")
        UserDefaults.standard.set(gameOverCount + 1, forKey: "gameOverCount")
        
        if gameOverCount > 10 || UserDefaults.standard.bool(forKey: "premium") {
            UserDefaults.standard.set(0, forKey: "gameOverCount")
            showGameOvewScreen()
        } else {
            showAd()
        }
    }
    
    private func showGameOvewScreen() {
        presentScene(paused: true)
        
        guard let score = self.score else { assertionFailure(); return }
        
        let gameOver = GameOverViewController(score: score)
        gameOver.presentationController?.delegate = self
        gameOver.gameSceneDelegate = self
        show(gameOver, sender: self)
        
        (gameView.scene as? GameScene)?.showing = false
    }
    
    func gameRestarted()
    {
        score = nil
        presentScene(paused: shouldPauseForTutorial())
        presentedViewController?.dismiss(animated: true, completion: nil)
        preloadAd()
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
        
        print("Update!")
        
        scoreLabel.text = "\(score)"
        
        if updating { return }
        updating = true
        
        UIView.animateKeyframes(withDuration: 0.3, delay: 0.0, options: [.beginFromCurrentState], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5) {
                self.scoreLabel.transform = .init(scaleX: 2.0, y: 2.0)
            }
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                self.scoreLabel.transform = .init(scaleX: 1.0, y: 1.0)
            }
        }, completion: { [weak self] _ in
            self?.updating = false
        })
        
    }
    
    func shouldPauseForTutorial() -> Bool {
        return UserDefaults.standard.bool(forKey: "tutorial") == false || Constants.alwaysShowTutorial
    }
    
    func authenticatePlayer()
    {
        // Note: authenticate player doesn't get called all the time, but this
        // authenticate handler is stored and called on each launch
        GKLocalPlayer.local.authenticateHandler = { [unowned self] controller, error in
            
            let previouslyPaused = hackPaused
            hackPaused = true
            
            if GKLocalPlayer.local.isAuthenticated
            {
                if !shouldPauseForTutorial() {
                    hackPaused = previouslyPaused
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
                    hackPaused = previouslyPaused
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

extension GameViewController: GADFullScreenContentDelegate {
    
    func showAd() {
        if let interstitial = interstitial {
            interstitial.present(fromRootViewController: self)
          } else {
            print("Ad wasn't ready")
          showGameOvewScreen()
          }
    }
    
    func preloadAd() {
        if interstitial != nil { return }
        
        let adUnitId = "ca-app-pub-7759050985948144/2429065718"
        
        let request = GADRequest()
        GADInterstitialAd.load(withAdUnitID:adUnitId, request: request) { [weak self] ad, error in
            if let error = error {
                print("Failed to load interstital ad: \(error)")
                return
            }
            self?.interstitial = ad
            ad?.fullScreenContentDelegate = self
        }
    }
    
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        showGameOvewScreen()
        interstitial = nil
        preloadAd()
    }
    
    /// Tells the delegate that the ad failed to present full screen content.
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
      print("Ad did fail to present full screen content.")
    }

    /// Tells the delegate that the ad presented full screen content.
    func adDidPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
      print("Ad did present full screen content.")
    }
}
