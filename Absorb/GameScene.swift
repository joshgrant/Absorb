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
    var lastTime: TimeInterval = 0
    
    let ball = Ball(radius: 10, position: CGPoint(x: 200, y: 400))
    let player = Ball(radius: 10, position: CGPoint(x: 150, y: 390))
    
    /// Perform one-time setup
    override func sceneDidLoad() {
        super.sceneDidLoad()
        
        physicsWorld.gravity = .zero
        
        addChild(ball)
        addChild(player)
        addCamera()
    }
    
    /// Called once per frame before any actions are evaluated or any
    /// physics are simulated
    override func update(_ currentTime: TimeInterval) {
        player.physicsBody?.velocity.dx = 10
        
        lastTime = currentTime
        
        moveCameraToPlayer()
    }
    
    override func didEvaluateActions() {
        super.didEvaluateActions()
    }
    
    override func didSimulatePhysics() {
        super.didSimulatePhysics()
    }
    
    // Any updates here are not applied until the next update
    override func didFinishUpdate() {
        super.didFinishUpdate()
    }
    
    // TODO: - Utility
    
    func addCamera() {
        let camera = SKCameraNode()
        addChild(camera)
        scene?.camera = camera
    }
    
    func moveCameraToPlayer() {
        guard let camera = camera else { return }
        
        if !camera.position.equalTo(player.position, allowedDelta: 1.0)
        {
            camera.run(.move(to: player.position, duration: 0.3))
            print("Moving the camera")
        }
    }
}
