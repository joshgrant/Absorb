//
//  CGColor+Extensions.swift
//  Absorb
//
//  Created by Josh Grant on 11/18/21.
//

import Foundation
import UIKit

extension UIColor {
    
    convenience init(rawRed: Int, rawGreen: Int, rawBlue: Int, alpha: CGFloat) {
        
        precondition(alpha <= 1, "Alpha must not exceed 1")
        precondition(alpha >= 0, "Alpha must not be less than 0")
        
        let red = CGFloat(rawRed) / 255.0
        let green = CGFloat(rawGreen) / 255.0
        let blue = CGFloat(rawBlue) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
