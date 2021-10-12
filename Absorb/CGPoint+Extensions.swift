//
//  CGPoint+Extensions.swift
//  Absorb
//
//  Created by Josh Grant on 10/12/21.
//

import SpriteKit

func +(_ a: CGPoint, _ b: CGPoint) -> CGPoint
{
    .init(x: a.x + b.x, y: a.y + b.y)
}

func -(_ a: CGPoint, _ b: CGPoint) -> CGPoint
{
    .init(x: a.x - b.x, y: a.y - b.y)
}

func *(_ a: CGPoint, _ b: CGFloat) -> CGPoint
{
    .init(x: a.x * b, y: a.y * b)
}

public extension CGPoint
{
    func equalTo(_ point: CGPoint, allowedDelta: CGFloat) -> Bool
    {
        let dx = abs(point.x - x)
        let dy = abs(point.y - y)
        
        return dx <= allowedDelta && dy <= allowedDelta
    }
}
