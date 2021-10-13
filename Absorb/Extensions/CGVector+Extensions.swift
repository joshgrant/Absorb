//
// Created by Joshua Grant on 10/12/21
// Copyright © 2021 Joshua Grant. All rights reserved.
//

import SpriteKit

func *(_ a: CGVector, _ b: CGFloat) -> CGVector
{
    return CGVector(dx: a.dx * b, dy: a.dy * b)
}
