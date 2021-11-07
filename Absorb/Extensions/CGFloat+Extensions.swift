//
// Created by Joshua Grant on 10/12/21
// Copyright © 2021 Joshua Grant. All rights reserved.
//

import SpriteKit

public extension CGFloat
{
    var areaToRadius: CGFloat {
        if sign == .minus {
            return 0 // Better than NaN
        } else {
            return sqrt(self / .pi)
        }
    }
    var radiusToArea: CGFloat { self * self * .pi }
    var radians: CGFloat { self * (.pi / 180) }
    var degrees: CGFloat { 180 * self / .pi }
    
    func limitMagnitude(to value: CGFloat) -> CGFloat
    {
        if self > value
        {
            return value
        }
        else if self < -value
        {
            return -value
        }
        else
        {
            return self
        }
    }
}
