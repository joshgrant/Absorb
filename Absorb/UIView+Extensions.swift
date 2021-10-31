//
// Created by Joshua Grant on 10/31/21
// Copyright © 2021 Joshua Grant. All rights reserved.
//

import UIKit

extension UIView
{
    static func spacer(width: CGFloat? = nil, height: CGFloat? = nil) -> UIView
    {
        let spacerView = UIView()
        spacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacerView.setContentHuggingPriority(.defaultLow, for: .vertical)
        spacerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        spacerView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        spacerView.translatesAutoresizingMaskIntoConstraints = false
        
        if let width = width
        {
            NSLayoutConstraint.activate([
                spacerView.widthAnchor.constraint(equalToConstant: width)
            ])
        }
        
        if let height = height
        {
            NSLayoutConstraint.activate([
                spacerView.heightAnchor.constraint(equalToConstant: height)
            ])
        }
        
        return spacerView
    }
}
