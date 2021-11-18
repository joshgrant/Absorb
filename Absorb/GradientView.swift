//
//  GradientView.swift
//  Absorb
//
//  Created by Josh Grant on 11/18/21.
//

import Foundation
import UIKit

class GradientView: UIView {
    
    override open class var layerClass: AnyClass {
       return CAGradientLayer.classForCoder()
    }

    init(colors: [CGColor]) {
        super.init(frame: .zero)
        let gradientLayer = layer as! CAGradientLayer
        gradientLayer.colors = colors
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
