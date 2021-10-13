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
    
    var area: CGFloat { CGFloat.pi * radius * radius }
    
    init(radius: CGFloat, position: CGPoint)
    {
        self.radius = radius
        super.init()
        self.position = position
        fillColor = .orange
        radiusUpdated()
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError() }
    
    // MARK: - Public functions
    
    public func applyCameraZoom(scale: CGFloat, cameraPosition: CGPoint = .zero)
    {
        position = newPosition(relativeTo: cameraPosition, scaledBy: scale)
        radius = radius * scale
        radiusUpdated()
    }
    
    public func updateArea(to newArea: CGFloat)
    {
        radius = newArea.areaToRadius
        radiusUpdated()
    }
    
    public func updateArea(delta: CGFloat)
    {
        let newArea = area + delta
        updateArea(to: newArea)
    }
    
    // MARK: - Private functions
    
    private func configurePhysicsBody()
    {
        physicsBody = .init(circleOfRadius: radius)
        physicsBody?.isDynamic = true
        physicsBody?.contactTestBitMask = .zero
        physicsBody?.collisionBitMask = .zero
        physicsBody?.categoryBitMask = .zero
    }
    
    /// Returns the position this ball should be at when the viewport is scaled by the amount. The relative
    /// point should be the origin of the camera
    private func newPosition(
        relativeTo point: CGPoint,
        scaledBy scale: CGFloat) -> CGPoint
    {
        return (position - point) * scale + point
    }
    
    private func radiusUpdated()
    {
        path = UIBezierPath(circleOfRadius: radius).cgPath
        configurePhysicsBody()
    }
}

public extension Ball
{
    static func overlapping(_ a: Ball, _ b: Ball) -> Bool
    {
        let distance = CGPoint.distance(a.position, b.position)
        return distance < a.radius + b.radius
    }
    
    static func overlappingArea(_ a: Ball, _ b: Ball) -> CGFloat
    {
        let r = a.radius
        let R = b.radius
        
        let rr = r * r
        let RR = R * R
        
        let d = CGPoint.distance(a.position, b.position)
        let dd = d * d
        
        let area =
        rr * acos((dd + rr - RR) / (2 * d * r)) +
        RR * acos((dd + RR - rr) / (2 * d * R)) -
        0.5 * sqrt((-d + r + R) * (d + r - R) * (d - r + R) * (d + r + R))
        
        // If the area is NaN, the smaller circle is completely encircled
        // by the larger circle. In this case, we just return the smaller area
        return area.isNaN ? min(a.area, b.area) : area
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
