//
// Created by Joshua Grant on 10/31/21
// Copyright © 2021 Joshua Grant. All rights reserved.
//

import Foundation
import UIKit

class PauseViewController: UIViewController {
    
    override func loadView() {
        
        var containerView = UIView()
        
        let logoView = UIImageView(image: .init(named: "logo"))
        let gameCenterButton = UIButton()
        gameCenterButton.configuration = .tinted()
        gameCenterButton.configuration?.cornerStyle = .medium
        gameCenterButton.tintColor = .secondarySystemBackground
        // TODO: Resize the asset in the asset folder (currently HUGE)
        gameCenterButton.setImage(UIImage(named: "game_center"), for: .normal)
        gameCenterButton.configuration?.imagePlacement = .all
        gameCenterButton.configuration?.imagePadding = 10
        
        NSLayoutConstraint.activate([
            gameCenterButton.widthAnchor.constraint(equalToConstant: 44),
            gameCenterButton.heightAnchor.constraint(equalToConstant: 44),
        ])
        
        let titleStackView = UIStackView(arrangedSubviews: [logoView, UIView.spacer(), gameCenterButton])
        titleStackView.axis = .horizontal
        let stackView = UIStackView(arrangedSubviews: [titleStackView])
        
        containerView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: stackView.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
        ])
        
        view = containerView
    }
    
}
