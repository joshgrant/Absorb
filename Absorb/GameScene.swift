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
        static let referenceRadius: CGFloat = 100
        static let playerMovement: CGFloat = 10000
        static let frameDuration: CGFloat = 1.0 / 60.0
    }
    
    private var playerRadius: CGFloat = Constants.referenceRadius
    
    public let player: Ball = {
        let ball = Ball(radius: Constants.referenceRadius,
                        position: CGPoint(x: 300, y: 0))
        ball.kind = .player
        return ball
    }()
    
    /// Perform one-time setup
    override func sceneDidLoad()
    {
        super.sceneDidLoad()
        
        physicsWorld.gravity = .zero
        
        addChild(player)
        
        run(.repeatForever(.sequence([.wait(forDuration: 0.5),
                                      .run { [unowned self] in
            self.addChild(Ball(radius: Constants.referenceRadius - 10,
                               position: self.player.position + .init(x: .random(in: 100 ... 300),
                                                                      y: .random(in: 100 ... 400))))
        }])))
        
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
        var currentRadius: CGFloat = Constants.referenceRadius
        
        permuteAllBallsAndSiblings { ball, sibling in
            if Ball.overlapping(ball, sibling)
            {
                let (smaller, larger) = Ball.orderByRadius(ball, sibling)
                let overlappingArea = Ball.overlappingArea(smaller, larger)
                
                if smaller == player
                {
                    larger.updateArea(delta: overlappingArea)
                    modifyRadiusScale(with: -overlappingArea, radius: &currentRadius)
                }
                else if larger == player
                {
                    smaller.updateArea(delta: -overlappingArea)
                    modifyRadiusScale(with: overlappingArea, radius: &currentRadius)
                }
                else
                {
                    larger.updateArea(delta: overlappingArea)
                    smaller.updateArea(delta: -overlappingArea)
                }
            }
        }
        
        let npcScale = Constants.referenceRadius / currentRadius
        
        playerRadius += currentRadius - Constants.referenceRadius
        
        if playerRadius < 1 {
            // Game Over
            assertionFailure()
        }
        
        // 2 for loops is expensive... at least this isn't a nested loop
        iterateNPCs { ball in
            ball.applyCameraZoom(scale: npcScale, cameraPosition: player.position)
        }
        
        moveCameraToPlayer()
    }
    
    override func didFinishUpdate()
    {
        super.didFinishUpdate()
        checkGameOver()
    }
    
    // TODO: - Utility
    
    public func iterateNPCs(handler: (Ball) -> Void)
    {
        for child in children
        {
            guard let child = child as? Ball else { continue }
            guard child != player else { continue }
            handler(child)
        }
    }
    
    public func permuteAllBallsAndSiblings(handler: (_ ball: Ball, _ sibling: Ball) -> Void)
    {
        var encounteredPairs: Set<Int> = []
        
        for child in children
        {
            guard let child = child as? Ball else { continue }
            for sibling in children
            {
                guard let sibling = sibling as? Ball else { continue }
                guard child != sibling else { continue }
                
                // An additional step to reduce the number of comparisons
                let hash = Ball.hashTogether([child, sibling])
                if encounteredPairs.contains(hash) { continue }
                encounteredPairs.insert(hash)
                
                handler(child, sibling)
            }
        }
    }
    
    /// Each overlap between the player and an npc causes the world to shrink
    /// This function calculates how that ratio is modified for a single overlap
    private func modifyRadiusScale(with overlappingArea: CGFloat, radius: inout CGFloat)
    {
        let currentArea = radius.radiusToArea
        let newArea = currentArea + overlappingArea
        radius = newArea.areaToRadius
    }
    
    private func addCamera()
    {
        let camera = SKCameraNode()
        camera.setScale(6)
        addChild(camera)
        scene?.camera = camera
    }
    
    private func moveCameraToPlayer()
    {
        guard let camera = camera else { return }
        
        if !camera.position.equalTo(player.position, allowedDelta: 1.0)
        {
            camera.run(.move(to: player.position, duration: 0.5))
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
