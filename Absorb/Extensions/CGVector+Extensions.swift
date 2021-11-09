//
// Created by Joshua Grant on 10/12/21
// Copyright © 2021 Joshua Grant. All rights reserved.
//

import SpriteKit

func +(_ a: CGVector, _ b: CGVector) -> CGVector
{
    return CGVector(dx: a.dx + b.dx, dy: a.dy + b.dy)
}

func *(_ a: CGVector, _ b: CGFloat) -> CGVector
{
    return CGVector(dx: a.dx * b, dy: a.dy * b)
}

func /(_ a: CGVector, _ b: CGFloat) -> CGVector
{
    return CGVector(dx: a.dx / b, dy: a.dy / b)
}

public extension CGVector
{
    init(point: CGPoint) {
        self.init(dx: point.x, dy: point.y)
    }
    
    static func direction(from a: CGPoint, to b: CGPoint) -> CGVector
    {
        let normal = (b - a).normalized
        return CGVector(dx: normal.x, dy: normal.y)
    }
}
