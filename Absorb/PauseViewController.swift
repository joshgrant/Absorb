//
// Created by Joshua Grant on 10/31/21
// Copyright © 2021 Joshua Grant. All rights reserved.
//

import Foundation
import UIKit
import GameKit
import StoreKit

extension UIButton {
    
    static func makeGameCenterButton(action: UIAction) -> UIButton {
        let gameCenterButton = UIButton()
        gameCenterButton.configuration = .filled()
        gameCenterButton.configuration?.cornerStyle = .medium
        gameCenterButton.tintColor = .label
        gameCenterButton.configuration?.image = UIImage(named: "game_center")
        gameCenterButton.configuration?.imagePlacement = .all
        gameCenterButton.configuration?.imagePadding = 10
        gameCenterButton.translatesAutoresizingMaskIntoConstraints = false
        gameCenterButton.addAction(action, for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            gameCenterButton.widthAnchor.constraint(equalToConstant: 44),
            gameCenterButton.heightAnchor.constraint(equalToConstant: 44),
        ])
        return gameCenterButton
    }
}

extension UIStackView {
    static func makeTitleStackView(centerView: UIView, gameCenterAction: UIAction) -> UIStackView {
        centerView.translatesAutoresizingMaskIntoConstraints = false
        let titleStackView = UIStackView(arrangedSubviews: [
            UIView.spacer(),
            centerView,
            UIView.spacer(),
            UIButton.makeGameCenterButton(action: gameCenterAction),
            UIView.spacer(width: 10)])
        titleStackView.axis = .horizontal
        titleStackView.translatesAutoresizingMaskIntoConstraints = false
        titleStackView.alignment = .center
        
        NSLayoutConstraint.activate([
            centerView.centerXAnchor.constraint(equalTo: titleStackView.centerXAnchor)
        ])
        return titleStackView
    }
}

class PauseViewController: UIViewController {
    
    override var prefersStatusBarHidden: Bool { UserDefaults.standard.bool(forKey: "status") }
    
    weak var gameSceneDelegate: GameSceneDelegate?
    
    let store: Store
    let noAds: Product
    let onPurchase: (Product) -> Void
    
    func purchase() {
        do {
            if try await store.purchase(fuel) != nil {
                onPurchase(fuel)
            }
        } catch StoreError.failedVerification {
            errorTitle = "Your purchase could not be verified by the App Store."
            isShowingError = true
        } catch {
            print("Failed fuel purchase: \(error)")
        }
    }
    
    override func loadView() {
        
        let containerView = UIView()
        containerView.backgroundColor = .systemBackground
        
        let logoView = UIImageView(image: .init(named: "absorby_logo"))
        
        let titleStackView = UIStackView.makeTitleStackView(centerView: logoView, gameCenterAction: .init(handler: { [weak self] action in
            self?.gameSceneDelegate?.showLeaderboard()
        }))
        
        let stackView = UIStackView(arrangedSubviews: [
            UIView.spacer(height: 20),
            titleStackView,
            makeTextField(text: "Name",
                          placeholder: "Johnny",
                          content: UserDefaults.standard.string(forKey: "name")),
            UIView.spacer(),
            makeSwitch(text: "Sound",
                       isOn: UserDefaults.standard.bool(forKey: "sound"),
                       action: .init(handler: { action in
                guard let sender = action.sender as? UISwitch else { return }
                UserDefaults.standard.set(sender.isOn, forKey: "sound")
            })),
            makeSwitch(text: "Haptics",
                       isOn: UserDefaults.standard.bool(forKey: "haptics"),
                       action: .init(handler: { action in
                guard let sender = action.sender as? UISwitch else { return }
                UserDefaults.standard.set(sender.isOn, forKey: "haptics")
            })),
            makeSwitch(text: "Hide Status Bar",
                       isOn: UserDefaults.standard.bool(forKey: "status"),
                       action: .init(handler: { action in
                guard let sender = action.sender as? UISwitch else { return }
                UserDefaults.standard.set(sender.isOn, forKey: "status")
            })),
            UIView.spacer(),
            Self.makeButton(title: "Restart", tint: .systemBlue, action: .init(handler: { [weak self] action in
                self?.gameSceneDelegate?.gameRestarted()
            })),
            Self.makeButton(title: "Remove Ads", tint: .systemGreen, action: .init(handler: { action in
                
            })),
            Self.makeButton(title: "Delete Scores", tint: .systemRed, action: .init(handler: { action in
                let alert = UIAlertController(
                    title: "Delete Scores",
                    message: "Are you sure you want to delete local scores? This cannot be undone.",
                    preferredStyle: .alert)
                alert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
                alert.addAction(.init(title: "Delete", style: .destructive, handler: { [weak self] action in
                    Database.deleteAllScores()
                    self?.gameSceneDelegate?.gameRestarted()
                }))
                self.present(alert, animated: true, completion: nil)
            })),
            UIView.spacer()])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 20
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = .init(top: 0, leading: 20, bottom: 0, trailing: 20)
        containerView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
        ])
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        view = containerView
    }
    
    func makeTextField(text: String, placeholder: String, content: String? = nil) -> UIStackView {
        let textField = UITextField()
        textField.text = content
        textField.placeholder = placeholder
        textField.font = .systemFont(ofSize: 24, weight: .medium)
        textField.delegate = self
        textField.textAlignment = .right
        
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 24, weight: .regular) // TODO: Same as makeSwitch
        
        let stackView = UIStackView(arrangedSubviews: [label, UIView.spacer(), textField])
        stackView.axis = .horizontal
        return stackView
    }
    
    func makeSwitch(text: String, isOn: Bool, action: UIAction) -> UIStackView {
        let textLabel = UILabel()
        textLabel.text = text
        textLabel.font = .systemFont(ofSize: 24, weight: .regular)
        let toggle = UISwitch()
        toggle.isOn = isOn
        toggle.addAction(action, for: .valueChanged)
        let stackView = UIStackView(arrangedSubviews: [textLabel, UIView.spacer(), toggle])
        stackView.axis = .horizontal
        return stackView
    }
    
    static func makeButton(title: String, tint: UIColor, action: UIAction) -> UIButton {
        let button = UIButton()
        
        let rect = CGRect(x: 0, y: 0, width: 10, height: 10)
        let imageWithColor = UIGraphicsImageRenderer.init(size: rect.size).image { context in
            context.cgContext.setFillColor(tint.cgColor)
            context.fill(rect)
        }
        
        button.setBackgroundImage(imageWithColor, for: .normal)
        button.layer.cornerCurve = .continuous
        button.layer.cornerRadius = 10
        button.layer.masksToBounds = true
        button.addAction(action, for: .touchUpInside)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 22, weight: .medium)
        //        button.configuration?.attributedTitle = .init(title, attributes: .init([.font: UIFont.systemFont(ofSize: 22, weight: .medium), .foregroundColor: UIColor.systemBackground]))
        
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        return button
    }
}

extension PauseViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        UserDefaults.standard.set(textField.text, forKey: "name")
    }
}
