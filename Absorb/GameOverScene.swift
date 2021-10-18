//
//  GameOverScene.swift
//  Sorb
//
//  Created by Joshua Grant on 9/26/21.
//

import SpriteKit

enum GameOverType: String {
    case won = "New High Score! 🥳"
    case lost = "Game Over 😥"
}

class GameOverScene: SKScene {
    
    // MARK: - Variables
    
    var gameOverType: GameOverType
    var score: Int
    
    // MARK: - Initialization
    
    init(score: Int, type: GameOverType) {
        self.gameOverType = type
        self.score = score
        
        super.init(size: .zero)
        scaleMode = .resizeFill
        
        backgroundColor = .secondarySystemBackground
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        configure(view: view)
    }
    
    private func configure(view: SKView) {
        
        // 1. Create the parent stack view
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        
        // 2. Create the "You won!/Game Over!" Label
        
        let label = UILabel()
        label.font = .systemFont(ofSize: 30, weight: .regular)
        label.textColor = .secondaryLabel
        label.text = gameOverType.rawValue
        
        stackView.addArrangedSubview(makeSpacerView(height: 20))
        stackView.addArrangedSubview(label)
        
        let firstSpacer = makeSpacerView()
        
        stackView.addArrangedSubview(firstSpacer)
        
        // 3. Create the "Your score" label
        
        let yourScoreLabel = UILabel()
        yourScoreLabel.font = .systemFont(ofSize: 18, weight: .light)
        yourScoreLabel.textColor = .secondaryLabel
        yourScoreLabel.text = "Your score:"
        
        stackView.addArrangedSubview(yourScoreLabel)
        stackView.addArrangedSubview(makeSpacerView())
        
        // 4. Create the score label
        
        let scoreLabel = UILabel()
        scoreLabel.font = .monospacedDigitSystemFont(ofSize: 60, weight: .bold)
        scoreLabel.textColor = .label
        scoreLabel.text = "\(score)"
        
        stackView.addArrangedSubview(scoreLabel)
        
        stackView.addArrangedSubview(makeSpacerView())
        
        let highScoresHeader = UILabel()
        highScoresHeader.text = "High scores:"
        highScoresHeader.font = .systemFont(ofSize: 18, weight: .light)
        highScoresHeader.textColor = .secondaryLabel
        stackView.addArrangedSubview(highScoresHeader)
        stackView.addSubview(makeSpacerView())
        
        // 3. Create the top scores list
        
        let topScoresStackView = UIStackView()
        topScoresStackView.axis = .vertical
        topScoresStackView.translatesAutoresizingMaskIntoConstraints = false
        let topScores = Database.topTenScores
        
        for i in 0 ... 9 {
            
            let horizontalStackView = UIStackView()
            horizontalStackView.axis = .horizontal
            horizontalStackView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                horizontalStackView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width - 80) // TODO: Extract this as score padding
            ])
            
            let numberLabel = UILabel()
            numberLabel.text = "\(i + 1).  "
            numberLabel.textColor = .label
            numberLabel.font = .monospacedDigitSystemFont(ofSize: 20, weight: .light)
            numberLabel.textAlignment = .right
            
            NSLayoutConstraint.activate([
                numberLabel.widthAnchor.constraint(equalToConstant: numberLabel.font.pointSize * 2)
            ])
    
            horizontalStackView.addArrangedSubview(numberLabel)
            
            guard topScores.count > i else {
                horizontalStackView.addArrangedSubview(makeSpacerView())
                stackView.addArrangedSubview(horizontalStackView)
                topScoresStackView.addArrangedSubview(horizontalStackView)
                continue
            }
            
            horizontalStackView.addArrangedSubview(makeSpacerView())
            
            let score = topScores[i]
            
            let nameLabel = UILabel()
            nameLabel.text = score.name
            nameLabel.textColor = .label
            nameLabel.font = .systemFont(ofSize: 20, weight: .regular)
            horizontalStackView.addArrangedSubview(nameLabel)
            
            let spacerView = makeSpacerView()
            horizontalStackView.addArrangedSubview(spacerView)
            
            let scoreLabel = UILabel()
            scoreLabel.text = "\(score.score)"
            scoreLabel.textColor = .label
            scoreLabel.font = .monospacedDigitSystemFont(ofSize: 20, weight: .bold)
            horizontalStackView.addArrangedSubview(scoreLabel)
            
            topScoresStackView.addArrangedSubview(horizontalStackView)
        }
        
        stackView.addArrangedSubview(topScoresStackView)
        
        let secondSpacer = makeSpacerView()
        
        stackView.addArrangedSubview(secondSpacer)
        
        // 4. Create the "Restart"/"Replay" button
        
        let button = UIButton()
        button.setAttributedTitle(.init(string: "Restart", attributes: [
            .foregroundColor: UIColor.secondaryLabel,
            .font: UIFont.systemFont(ofSize: 20, weight: .light)
        ]), for: .normal)
        button.tintColor = .tertiarySystemFill
        button.addTarget(self, action: #selector(restartButtonDidTouchUpInside(_:)), for: .touchUpInside)
        button.configuration = .filled()
        button.configuration?.titlePadding = 20
        button.configuration?.cornerStyle = .capsule
        button.configuration?.imageColorTransformer = .preferredTint
        
        stackView.addArrangedSubview(button)
        
        stackView.addArrangedSubview(makeSpacerView(height: 20))
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            firstSpacer.heightAnchor.constraint(equalTo: secondSpacer.heightAnchor)
        ])
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        ])
    }
    
    func fadeOutViews(completion: @escaping () -> Void) {
        
        guard let view = view else { return }
        
        UIView.animate(withDuration: 0.3, animations: {
            for subview in view.subviews {
                subview.alpha = 0
            }
        }, completion: { _ in
            for subview in view.subviews {
                subview.removeFromSuperview()
            }
            completion()
        })
    }
    
    @objc func restartButtonDidTouchUpInside(_ sender: UIButton) {
        fadeOutViews { [unowned self] in
            let reveal = SKTransition.fade(with: .secondarySystemBackground, duration: 0.5)
            let scene = GameScene()
            view?.presentScene(scene, transition: reveal)
        }
    }
    
    func makeSpacerView(width: CGFloat? = nil, height: CGFloat? = nil) -> UIView {
        let spacerView = UIView()
        spacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacerView.setContentHuggingPriority(.defaultLow, for: .vertical)
        spacerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        spacerView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        spacerView.translatesAutoresizingMaskIntoConstraints = false
        
        if let width = width {
            NSLayoutConstraint.activate([
                spacerView.widthAnchor.constraint(equalToConstant: width)
            ])
        }
        
        if let height = height {
            NSLayoutConstraint.activate([
                spacerView.heightAnchor.constraint(equalToConstant: height)
            ])
        }
        
        return spacerView
    }
}
