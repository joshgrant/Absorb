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
    enum Constants
    {
        static let playerMovement: CGFloat = 10
        static let frameDuration: CGFloat = 1.0 / 60.0
    }
    
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
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        super.touchesEnded(touches, with: event)
        
        guard let touch = touches.first else { return }
        let direction = player.direction(to: touch.location(in: self))
        let force: CGVector = direction * Constants.playerMovement
        player.run(.applyForce(force, duration: Constants.frameDuration))
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
    
    override func didFinishUpdate()
    {
        super.didFinishUpdate()
        checkGameOver()
    }

    // TODO: - Utility
    
    private func addCamera()
    {
        let camera = SKCameraNode()
        addChild(camera)
        scene?.camera = camera
    }
    
    private func moveCameraToPlayer()
    {
        guard let camera = camera else { return }
        
        if !camera.position.equalTo(player.position, allowedDelta: 1.0)
        {
            camera.run(.move(to: player.position, duration: 0.3))
        }
    }
    
    private func checkGameOver()
    {
        if player.parent == nil
        {
            // Show the game over screen
        }
    }
}
