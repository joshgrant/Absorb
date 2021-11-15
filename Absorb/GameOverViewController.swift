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
    //    var restartButton: UIButton!
    
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
        newScore.date = .now
        newScore.score = Int64(score)
        
        try? Database.context.save()
        
        let topScore = Database.topScore
        
        self.gameOverType = (newScore.score == topScore?.score) ? .won : .lost
        // Show the screen...
        self.view.setNeedsDisplay()
    }
    
    // MARK: - View lifecycle
    
    override func loadView() {
        let containerView = UIView()
        containerView.backgroundColor = .systemBackground
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = .init(top: 0, leading: 20, bottom: 0, trailing: 20)
        //        stackView.alignment = .center
        
        // 2. Create the "You won!/Game Over!" Label
        
        let label = UILabel()
        label.font = .systemFont(ofSize: 30, weight: .regular)
        label.textColor = .secondaryLabel
        label.text = (gameOverType ?? .won).rawValue
        
        //        let pauseMenuButton = UIButton()
        //        pauseMenuButton.setImage(.init(systemName: "gearshape.fill"), for: .normal)
        //        pauseMenuButton.addAction(.init(handler: { [weak self] action in
        //            self?.gameSceneDelegate?.openPauseMenuFromGameOver()
        //        }), for: .touchUpInside)
        
        let titleStackView = UIStackView.makeTitleStackView(leftView: nil, centerView: label, gameCenterAction: .init(handler: { [weak self] action in
            self?.gameSceneDelegate?.showLeaderboard()
        }))
        
        stackView.addArrangedSubview(.spacer(height: 40))
        stackView.addArrangedSubview(titleStackView)
        
        let firstSpacer = UIView.spacer()
        stackView.addArrangedSubview(firstSpacer)
        
        // 3. Create the "Your score" label
        
        let yourScoreLabel = UILabel()
        yourScoreLabel.font = .systemFont(ofSize: 18, weight: .light)
        yourScoreLabel.textColor = .secondaryLabel
        yourScoreLabel.text = "Your score:"
        yourScoreLabel.textAlignment = .center
        yourScoreLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        stackView.addArrangedSubview(yourScoreLabel)
        stackView.addArrangedSubview(.spacer())
        
        // 4. Create the score label
        
        let scoreLabel = UILabel()
        scoreLabel.font = .monospacedDigitSystemFont(ofSize: 60, weight: .bold)
        scoreLabel.textColor = .label
        scoreLabel.textAlignment = .center
        scoreLabel.text = "\(score)"
        scoreLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        stackView.addArrangedSubview(scoreLabel)
        
        stackView.addArrangedSubview(.spacer())
        
        let highScoresHeader = UILabel()
        highScoresHeader.text = "High scores:"
        highScoresHeader.font = .systemFont(ofSize: 18, weight: .light)
        highScoresHeader.textColor = .secondaryLabel
        highScoresHeader.textAlignment = .center
        highScoresHeader.setContentHuggingPriority(.defaultLow, for: .horizontal)
        stackView.addArrangedSubview(highScoresHeader)
        stackView.addSubview(.spacer(height: 20))
        
        // 3. Create the top scores list
        
        let topScoresStackView = UIStackView()
        topScoresStackView.axis = .vertical
        topScoresStackView.translatesAutoresizingMaskIntoConstraints = false
        let topScores = Database.topTenScores
        
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
                topScoresStackView.addArrangedSubview(horizontalStackView)
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
            
            topScoresStackView.addArrangedSubview(horizontalStackView)
        }
        
        stackView.addArrangedSubview(topScoresStackView)
        
        let secondSpacer = UIView.spacer()
        stackView.addArrangedSubview(secondSpacer)
        
        let restartButton = PauseViewController.makeButton(title: "Restart", tint: .tintColor, action: .init(handler: { [weak self] action in
            self?.gameSceneDelegate?.gameRestarted()
        }))
        
        let nested = UIStackView()
        nested.addArrangedSubview(restartButton)
        
        stackView.addArrangedSubview(nested)
        
        stackView.addArrangedSubview(.spacer(height: 20))
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            firstSpacer.heightAnchor.constraint(equalTo: secondSpacer.heightAnchor)
        ])
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
        ])
        
        view = containerView
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
