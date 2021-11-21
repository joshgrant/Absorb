//
// Created by Joshua Grant on 10/31/21
// Copyright © 2021 Joshua Grant. All rights reserved.
//

import Foundation
import UIKit
import GameKit
import StoreKit
import Purchases

extension UIButton {
    
    static func makeGameCenterButton(action: UIAction) -> UIButton {
        let gameCenterButton = UIButton()
        
        gameCenterButton.backgroundColor = .label
        gameCenterButton.layer.cornerCurve = .continuous
        gameCenterButton.layer.cornerRadius = 8
        gameCenterButton.setImage(UIImage(named: "game_center"), for: .normal)
        gameCenterButton.layoutMargins = .init(top: 10, left: 10, bottom: 10, right: 10)
        
        gameCenterButton.tintColor = .label
        
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
    static func makeTitleStackView(leftView: UIView? = nil, centerView: UIView, gameCenterAction: UIAction) -> UIStackView {
        leftView?.translatesAutoresizingMaskIntoConstraints = false
        centerView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleStackView = UIStackView()
        
        if let leftView = leftView {
            titleStackView.addArrangedSubview(.spacer())
            titleStackView.addArrangedSubview(leftView)
        }
        
        titleStackView.addArrangedSubview(UIView.spacer())
        titleStackView.addArrangedSubview(centerView)
        titleStackView.addArrangedSubview(UIView.spacer())
        
        if GKLocalPlayer.local.isAuthenticated {
            titleStackView.addArrangedSubview(UIButton.makeGameCenterButton(action: gameCenterAction))
            titleStackView.addArrangedSubview(UIView.spacer(width: 10))
        }
        
        titleStackView.axis = .horizontal
        titleStackView.translatesAutoresizingMaskIntoConstraints = false
        titleStackView.alignment = .center
        
        let centerAnchor = centerView.centerXAnchor.constraint(equalTo: titleStackView.centerXAnchor)
        centerAnchor.priority = .defaultHigh
        
        NSLayoutConstraint.activate([
            centerAnchor
        ])
        return titleStackView
    }
}

class PauseViewController: UIViewController {
    
    override var prefersStatusBarHidden: Bool { UserDefaults.standard.bool(forKey: "status") }
    
    weak var gameSceneDelegate: GameSceneDelegate?
    
    lazy var purchaseButton: UIButton = {
        Self.makeButton(title: Self.titleForRemoveAds(), tint: .systemGreen, action: .init(handler: { [weak self] action in
            self?.purchase()
        }))
    }()
    
    func purchase() {
        
        guard !UserDefaults.standard.bool(forKey: "premium") else {
            let alert = UIAlertController(title: "No Ads", message: "You've already removed ads. Thank you!", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default)
            alert.addAction(action)
            show(alert, sender: self)
            gameSceneDelegate?.disableAds()
            return
        }
        
        Purchases.shared.restoreTransactions { [weak self] (purchaserInfo, error) in
            //... check purchaserInfo to see if entitlement is now active
            if purchaserInfo?.entitlements.all["Pro"]?.isActive ?? false {
                // We have a purchase!
                UserDefaults.standard.set(true, forKey: "premium")
                self?.purchaseButton.setTitle(Self.titleForRemoveAds(), for: .normal)
                self?.gameSceneDelegate?.disableAds()
            } else {
                Purchases.shared.offerings { (offerings, error) in
                    if let offerings = offerings, let package = offerings.current?.availablePackages.first {
                        Purchases.shared.purchasePackage(package) { transaction, purchaserInfo, error, cancelled in
                            if transaction != nil && purchaserInfo != nil {
                                UserDefaults.standard.set(true, forKey: "premium")
                                self?.purchaseButton.setTitle(Self.titleForRemoveAds(), for: .normal)
                                let alert = UIAlertController(
                                    title: "Ads Removed",
                                    message: "Thank you for removing ads!",
                                    preferredStyle: .alert)
                                let action = UIAlertAction(title: "OK", style: .default)
                                alert.addAction(action)
                                self?.show(alert, sender: self)
                                self?.gameSceneDelegate?.disableAds()
                                return
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func loadView() {
        
        let containerView = UIView()
        containerView.backgroundColor = .systemBackground
        
        let logoView = UIImageView(image: .init(named: "absorby_logo"))
        
        let titleStackView = UIStackView.makeTitleStackView(centerView: logoView, gameCenterAction: .init(handler: { [weak self] action in
            if GKLocalPlayer.local.isAuthenticated {
                self?.gameSceneDelegate?.showLeaderboard()
            } else {
                self?.gameSceneDelegate?.authenticatePlayer()
            }
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
            purchaseButton,
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
            UIView.spacer(),
            makeLink(text: "Privacy Policy", url: URL(string: "https://gist.github.com/joshgrant/c3d8c640d2b3c9bd75c737ae90fa60d3")!),
            UIView.spacer()])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        if UIScreen.main.bounds.height > 600 {
            stackView.spacing = 20
        } else {
            stackView.spacing = 15
        }
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
    
    func makeLink(text: String, url: URL) -> UIButton {
        let button = UIButton()
        button.setTitle(text, for: .normal)
        button.setTitleColor(.tertiaryLabel, for: .normal)
        button.addAction(.init(handler: { action in
            UIApplication.shared.open(url)
        }), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        return button
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
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        return stackView
    }
    
    func makeSwitch(text: String, isOn: Bool, action: UIAction) -> UIStackView {
        let textLabel = UILabel()
        textLabel.text = text
        textLabel.font = .systemFont(ofSize: 24, weight: .regular)
        textLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        let toggle = UISwitch()
        toggle.isOn = isOn
        toggle.addAction(action, for: .valueChanged)
        toggle.setContentCompressionResistancePriority(.required, for: .vertical)
        let stackView = UIStackView(arrangedSubviews: [textLabel, UIView.spacer(), toggle])
        stackView.axis = .horizontal
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        return stackView
    }
    
    static func titleForRemoveAds() -> String {
        if UserDefaults.standard.bool(forKey: "premium") {
            return "Ads removed. Thank you!"
        } else {
            return "Remove Ads / Restore"
        }
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
        
        let height = button.heightAnchor.constraint(lessThanOrEqualToConstant: 54)
        height.priority = .defaultHigh
        
        NSLayoutConstraint.activate([
            height,
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 38),
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
