//
// Created by Joshua Grant on 10/31/21
// Copyright © 2021 Joshua Grant. All rights reserved.
//

import Foundation
import UIKit
import GameKit

enum GameOverType: String {
    case won = "High Score! 🥳"
    case lost = "Game Over 😥"
}

class GameOverViewController: UIViewController {
    
    override var prefersStatusBarHidden: Bool { UserDefaults.standard.bool(forKey: "status") }
    
    // MARK: - Variables
    
    var gameOverType: GameOverType?
    var score: Int
    
    var gameCenterButton: UIButton!
    var alert: UIAlertController?
    
    weak var gameSceneDelegate: GameSceneDelegate?
    
    // MARK: - Initialization
    
    init(score: Int) {
        self.score = score
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UserDefaults.standard.string(forKey: "name") != nil {
            addNewScore()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if UserDefaults.standard.string(forKey: "name") == nil {
            let askNameAlert = UIAlertController(title: "Enter your name:", message: nil, preferredStyle: .alert)
            askNameAlert.addTextField { textField in
                textField.delegate = self
                textField.autocapitalizationType = .words
                textField.autocorrectionType = .no
            }
            show(askNameAlert, sender: self)
            self.alert = askNameAlert
        }
    }
    
    func addNewScore() {
        let newScore = Score(context: Database.context)
        newScore.name = UserDefaults.standard.string(forKey: "name") ?? "Easter Egg"
        newScore.date = Date()
        newScore.score = Int64(score)
        
        try? Database.context.save()
        
        let topScore = Database.topScore
        
        self.gameOverType = (newScore.score == topScore?.score) ? .won : .lost
        view = makeContainerView()
    }
    
    // MARK: - View lifecycle
    
    override func loadView() {
        view = makeContainerView()
    }
}

extension GameOverViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Save the user name
        UserDefaults.standard.set(textField.text, forKey: "name")
        // Reload the view...
        self.alert?.dismiss(animated: true, completion: { [weak self] in
            self?.addNewScore()
        })
        
    }
}

// MARK: - Factory

extension GameOverViewController {
    
    func makeContainerView() -> UIView {
        
        let colors: [CGColor]
        
        switch gameOverType {
        case .won:
            colors = [
                UIColor(rawRed: 224, rawGreen: 32, rawBlue: 32, alpha: 0.35).cgColor,
                UIColor(rawRed: 250, rawGreen: 100, rawBlue: 0, alpha: 0.35).cgColor,
                UIColor(rawRed: 247, rawGreen: 181, rawBlue: 0, alpha: 0.35).cgColor,
                UIColor(rawRed: 109, rawGreen: 212, rawBlue: 0, alpha: 0.35).cgColor,
                UIColor(rawRed: 0, rawGreen: 145, rawBlue: 255, alpha: 0.35).cgColor,
                UIColor(rawRed: 98, rawGreen: 54, rawBlue: 255, alpha: 0.35).cgColor,
                UIColor(rawRed: 182, rawGreen: 32, rawBlue: 224, alpha: 0.35).cgColor,
            ]
        default:
            colors = [UIColor.systemBackground.cgColor]
        }
        
        let containerView = GradientView(colors: colors)
        containerView.backgroundColor = .systemBackground
        
        let stackView = makeStackView()
        let gameOverLabel = makeGameOverLabel()
        
        let titleStackView = UIStackView.makeTitleStackView(
            leftView: nil,
            centerView: gameOverLabel,
            gameCenterAction: .init(handler: { [weak self] action in
                if GKLocalPlayer.local.isAuthenticated {
                    self?.gameSceneDelegate?.showLeaderboard()
                } else {
                    self?.gameSceneDelegate?.authenticatePlayer()
                }
            }))
        
        stackView.addArrangedSubview(.spacer(height: 40))
        stackView.addArrangedSubview(titleStackView)
        
        let firstSpacer = UIView.spacer()
        stackView.addArrangedSubview(firstSpacer)
        
        let yourScoreLabel = makeYourScoreLabel()
        stackView.addArrangedSubview(yourScoreLabel)
        stackView.addArrangedSubview(.spacer())
        
        let scoreLabel = makeScoreLabel()
        stackView.addArrangedSubview(scoreLabel)
        stackView.addArrangedSubview(.spacer())
        
        let highScoresHeader = makeHighScoresLabel()
        stackView.addArrangedSubview(highScoresHeader)
        stackView.addSubview(.spacer(height: 20))
        
        let topScoresStackView = makeHighScoresStackView()
        stackView.addArrangedSubview(topScoresStackView)
        let secondSpacer = UIView.spacer()
        stackView.addArrangedSubview(secondSpacer)
        
        let restartButton = PauseViewController.makeButton(title: "Restart", tint: UIColor.link, action: .init(handler: { [weak self] action in
            self?.gameSceneDelegate?.gameRestarted()
        }))
        
        let nested = UIStackView()
        nested.addArrangedSubview(restartButton)
        
        stackView.addArrangedSubview(nested)
        stackView.addArrangedSubview(.spacer(height: 20))
        containerView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            firstSpacer.heightAnchor.constraint(equalTo: secondSpacer.heightAnchor),
            
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
        ])
        
        return containerView
    }
    
    func makeStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = .init(top: 0, leading: 20, bottom: 0, trailing: 20)
        return stackView
    }
    
    func makeGameOverLabel() -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: 30, weight: .regular)
        label.textColor = .secondaryLabel
        label.text = (gameOverType ?? .won).rawValue
        return label
    }
    
    func makeYourScoreLabel() -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .light)
        label.textColor = .secondaryLabel
        label.text = "Your score:"
        label.textAlignment = .center
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }
    
    func makeScoreLabel() -> UILabel {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 60, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        label.text = "\(score)"
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }
    
    func makeHighScoresLabel() -> UILabel {
        let label = UILabel()
        label.text = "High scores:"
        label.font = .systemFont(ofSize: 18, weight: .light)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }
    
    func makeHighScoresStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let topScores = Database.topTenScores // TODO: Or fetch from game center?
        
        for i in 0 ... 9 {
            
            let horizontalStackView = UIStackView()
            horizontalStackView.axis = .horizontal
            horizontalStackView.translatesAutoresizingMaskIntoConstraints = false
            
            let numberLabel = UILabel()
            numberLabel.text = "\(i + 1). "
            numberLabel.textColor = .label
            numberLabel.font = .monospacedDigitSystemFont(ofSize: 20, weight: .light)
            numberLabel.textAlignment = .right
            
            NSLayoutConstraint.activate([
                numberLabel.widthAnchor.constraint(equalToConstant: numberLabel.font.pointSize * 2)
            ])
            
            horizontalStackView.addArrangedSubview(numberLabel)
            
            guard topScores.count > i else {
                horizontalStackView.addArrangedSubview(.spacer())
                stackView.addArrangedSubview(horizontalStackView)
                continue
            }
            
            horizontalStackView.addArrangedSubview(.spacer(width: 5))
            
            let score = topScores[i]
            
            let nameLabel = UILabel()
            nameLabel.text = score.name
            nameLabel.textColor = .label
            nameLabel.font = .systemFont(ofSize: 20, weight: .regular)
            horizontalStackView.addArrangedSubview(nameLabel)
            
            horizontalStackView.addArrangedSubview(.spacer())
            
            let scoreLabel = UILabel()
            scoreLabel.text = "\(score.score)"
            scoreLabel.textColor = .label
            scoreLabel.font = .monospacedDigitSystemFont(ofSize: 20, weight: .bold)
            horizontalStackView.addArrangedSubview(scoreLabel)
            
            stackView.addArrangedSubview(horizontalStackView)
        }
        
        return stackView
    }
    
}
