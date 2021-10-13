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
            addChild(Ball(radius: 5,
                          position: .init(x: .random(in: -1000 ... 1000),
                                          y: .random(in: -1000 ... 1000))))
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
        
        // 1. If a node is a projectile and not overlapping the player, convert it to an npc
        // 2. Calculate total impluse between enemies and prey
        // 3. Remove nodes outside of the kill zone
        // 4. Bounce nodes that are far away
        
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
    
    /// This is a less-naive approach than I was currently taking, I previously iterated through
    /// the entire children array twice, but here we avoid that by making sure the sibling hasn't
    /// been iterated through already
    public func permuteAllBallsAndSiblings(handler: (_ ball: Ball, _ sibling: Ball) -> Void)
    {
        for i in 0 ..< children.count
        {
            for j in i + 1 ..< children.count
            {
                guard let first = children[i] as? Ball else { continue }
                guard let second = children[j] as? Ball else { continue }
                handler(first, second)
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
        if playerRadius < 1 {
            // Game Over
            assertionFailure()
        }
    }
}
