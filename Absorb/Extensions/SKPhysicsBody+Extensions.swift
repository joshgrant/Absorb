//
// Created by Joshua Grant on 10/12/21
// Copyright © 2021 Joshua Grant. All rights reserved.
//

import SpriteKit

extension SKPhysicsBody
{
    convenience init(physicsBody: SKPhysicsBody, radius: CGFloat)
    {
        self.init(circleOfRadius: radius)
        
        // The only settable property that we _don't_ set is the `mass`
        // because it should update with a larger radius
        
        isDynamic = physicsBody.isDynamic
        usesPreciseCollisionDetection = physicsBody.usesPreciseCollisionDetection
        allowsRotation = physicsBody.allowsRotation
        pinned = physicsBody.pinned
        isResting = physicsBody.isResting
        friction = physicsBody.friction
        charge = physicsBody.charge
        restitution = physicsBody.restitution
        linearDamping = physicsBody.linearDamping
        angularDamping = physicsBody.angularDamping
        density = physicsBody.density
        affectedByGravity = physicsBody.affectedByGravity
        fieldBitMask = physicsBody.fieldBitMask
        categoryBitMask = physicsBody.categoryBitMask
        collisionBitMask = physicsBody.collisionBitMask
        contactTestBitMask = physicsBody.contactTestBitMask
        velocity = physicsBody.velocity
        angularVelocity = physicsBody.angularVelocity
    }
}
