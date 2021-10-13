//
//  GameScene.swift
//  Absorb
//
//  Created by Josh Grant on 10/12/21.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene
{
    let ball = Ball(radius: 10, position: CGPoint(x: 200, y: 400))
    let player = Ball(radius: 10, position: CGPoint(x: 150, y: 390))
    
    /// Perform one-time setup
    override func sceneDidLoad()
    {
        super.sceneDidLoad()
        
        physicsWorld.gravity = .zero
        
        addChild(ball)
        addChild(player)
        
        addCamera()
    }
    
    /// Called once per frame before any actions are evaluated or any
    /// physics are simulated
    override func update(_ currentTime: TimeInterval)
    {
        player.physicsBody?.velocity.dx = 10
        
        if Ball.overlapping(player, ball)
        {
            let overlappingArea = Ball.overlappingArea(player, ball)
            player.updateArea(delta: overlappingArea)
            ball.updateArea(delta: -overlappingArea)
            
        }
        
        moveCameraToPlayer()
    }

    // TODO: - Utility
    
    func addCamera()
    {
        let camera = SKCameraNode()
        addChild(camera)
        scene?.camera = camera
    }
    
    func moveCameraToPlayer()
    {
        guard let camera = camera else { return }
        
        if !camera.position.equalTo(player.position, allowedDelta: 1.0)
        {
            camera.run(.move(to: player.position, duration: 0.3))
        }
    }
}
