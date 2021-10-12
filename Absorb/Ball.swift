//
//  Ball.swift
//  Absorb
//
//  Created by Josh Grant on 10/12/21.
//

import SpriteKit

public class Ball: SKShapeNode
{
    var radius: CGFloat
    
    init(radius: CGFloat, position: CGPoint)
    {
        self.radius = radius
        super.init()
        self.position = position
        fillColor = .orange
        radiusUpdated()
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError() }
    
    func applyCameraZoom(scale: CGFloat, cameraPosition: CGPoint = .zero)
    {
        position = newPosition(relativeTo: cameraPosition, scaledBy: scale)
        radius = radius * scale
        radiusUpdated()
    }
    
    private func configurePhysicsBody() {
        guard let body = physicsBody else { return }
        body.isDynamic = true
        body.contactTestBitMask = .zero
        body.collisionBitMask = .zero
        body.categoryBitMask = .zero
    }
    
    /// Returns the position this ball should be at when the viewport is scaled by the amount. The relative
    /// point should be the origin of the camera
    private func newPosition(relativeTo point: CGPoint, scaledBy scale: CGFloat) -> CGPoint
    {
        return (position - point) * scale + point
    }
    
    private func radiusUpdated()
    {
        path = UIBezierPath(circleOfRadius: radius).cgPath
        physicsBody = .init(circleOfRadius: radius)
        configurePhysicsBody()
    }
}

public extension UIBezierPath
{
    convenience init(circleOfRadius radius: CGFloat)
    {
        self.init(
            arcCenter: .zero,
            radius: radius,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true)
    }
}
