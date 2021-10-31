//
// Created by Joshua Grant on 10/31/21
// Copyright © 2021 Joshua Grant. All rights reserved.
//

import Foundation
import UIKit

class PauseViewController: UIViewController {
    
    override func loadView() {
        
        let containerView = UIView()
        containerView.backgroundColor = .systemBackground
        containerView.alpha = 0.85
        
        let logoView = UIImageView(image: .init(named: "absorby_logo"))
        logoView.translatesAutoresizingMaskIntoConstraints = false
        
        let gameCenterButton = UIButton()
        gameCenterButton.configuration = .filled()
        gameCenterButton.configuration?.cornerStyle = .medium
        gameCenterButton.tintColor = .darkText
        gameCenterButton.configuration?.image = UIImage(named: "game_center")
        gameCenterButton.configuration?.imagePlacement = .all
        gameCenterButton.configuration?.imagePadding = 10
        gameCenterButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            gameCenterButton.widthAnchor.constraint(equalToConstant: 44),
            gameCenterButton.heightAnchor.constraint(equalToConstant: 44),
        ])
        
        let titleStackView = UIStackView(arrangedSubviews: [UIView.spacer(), logoView, UIView.spacer(), gameCenterButton, UIView.spacer(width: 10)])
        titleStackView.axis = .horizontal
        titleStackView.translatesAutoresizingMaskIntoConstraints = false
        titleStackView.alignment = .center
        
        NSLayoutConstraint.activate([
            logoView.centerXAnchor.constraint(equalTo: titleStackView.centerXAnchor)
        ])
        
        let stackView = UIStackView(arrangedSubviews: [
            UIView.spacer(height: 20),
            titleStackView,
            makeTextField(text: "Name", placeholder: "Johnny"),
            UIView.spacer(),
            makeSwitch(text: "Sound"),
            makeSwitch(text: "Haptics"),
            makeSwitch(text: "Show Menu Bar"),
            UIView.spacer(),
            makeButton(title: "Restart", tint: .systemBlue),
            makeButton(title: "Remove Ads", tint: .systemGreen),
            makeButton(title: "Delete Scores", tint: .systemRed),
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
    
    func makeTextField(text: String, placeholder: String) -> UIStackView {
        let textField = UITextField()
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
    
    func makeSwitch(text: String) -> UIStackView {
        let textLabel = UILabel()
        textLabel.text = text
        textLabel.font = .systemFont(ofSize: 24, weight: .regular)
        let toggle = UISwitch()
        let stackView = UIStackView(arrangedSubviews: [textLabel, UIView.spacer(), toggle])
        stackView.axis = .horizontal
        return stackView
    }
    
    func makeButton(title: String, tint: UIColor) -> UIButton {
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
        // TODO: Save the name...
    }
}
