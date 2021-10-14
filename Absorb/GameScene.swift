//
//  GameScene.swift
//  Absorb
//
//  Created by Josh Grant on 10/12/21.
//

import SpriteKit
import GameplayKit

public class GameScene: SKScene
{
    public struct Configuration
    {
        var addsNPCs = true
        var addsPlayer = true
    }
    
    struct Constants
    {
        static let referenceRadius: CGFloat = 22
        static let playerMovement: CGFloat = referenceRadius * 10
        static let frameDuration: CGFloat = 1.0 / 60.0
        static let addEnemyWaitDuration: TimeInterval = 0.2
        static let minimumExpulsionAmount: CGFloat = 2
        static let expulsionAmountRatio: CGFloat = 0.15
        static let expulsionForceModifier: CGFloat = -0.1
        static let npcMovementModifier: CGFloat = 0.001
        
        // TODO: Is this true when the user rotates the device?
        /// The area in which npcs are not allowed to spawn
        static let safeAreaRadius: CGFloat = UIScreen.main.bounds.height / 2
        /// The area in which npcs reverse their trajectory
        static let bounceBackRadius: CGFloat = safeAreaRadius * 2
        /// The area past which npcs despawn
        static let killZoneRadius: CGFloat = bounceBackRadius * 2
    }
    
    private var configuration: Configuration
    
    private var temporaryRadius: CGFloat = Constants.referenceRadius
    private var playerRadius: CGFloat = Constants.referenceRadius
    
    public let player: Ball = {
        let ball = Ball(radius: Constants.referenceRadius,
                        position: CGPoint(x: 300, y: 0))
        ball.kind = .player
        return ball
    }()
    
    // MARK: - Initialization
    
    init(configuration: Configuration = .init())
    {
        self.configuration = configuration
        super.init(size: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View lifecycle
    
    /// Perform one-time setup
    public override func sceneDidLoad()
    {
        super.sceneDidLoad()
        
        physicsWorld.gravity = .zero
        addCamera()
        
        if configuration.addsPlayer
        {
            addChild(player)
        }
        
        if configuration.addsNPCs
        {
            run(loopAddEnemies())
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        super.touchesEnded(touches, with: event)
        
        guard let touch = touches.first else { return }
        let direction = player.direction(to: touch.location(in: self))
        
        let force: CGVector = direction * Constants.playerMovement
        player.run(.applyForce(force, duration: Constants.frameDuration))
        
        makeProjectile(force: force * Constants.expulsionForceModifier)
    }
    
    /// Called once per frame before any actions are evaluated or any
    /// physics are simulated
    public override func update(_ currentTime: TimeInterval)
    {
        // 2. Calculate total impluse between enemies and prey
        // 3. Remove nodes outside of the kill zone
        // 4. Bounce nodes that are far away
        
        permuteAllBallsAndSiblings { ball, sibling in
            
            let (smaller, larger) = Ball.orderByRadius(ball, sibling)
            
            updateProjectileToNPCIfNotOverlappingPlayer(ball: ball)
            handleOverlap(smaller: smaller, larger: larger)
            applyMovement(smaller: smaller, larger: larger)
        }
        
        moveCameraToPlayer()
    }
    
    public func updateProjectileToNPCIfNotOverlappingPlayer(ball: Ball)
    {
        if ball.kind == .projectile
        {
            if Ball.overlapping(ball, player)
            {
                return
            }
            else
            {
                ball.kind = .npc
            }
        }
    }
    
    private func handleOverlap(smaller: Ball, larger: Ball)
    {
        if Ball.overlapping(larger, smaller)
        {
            let overlappingArea = Ball.overlappingArea(smaller, larger)
            
            if smaller == player
            {
                larger.updateArea(delta: overlappingArea)
                modifyRadiusScale(
                    deltaArea: -overlappingArea,
                    radius: &temporaryRadius)
            }
            else if larger == player
            {
                smaller.updateArea(delta: -overlappingArea)
                modifyRadiusScale(
                    deltaArea: overlappingArea,
                    radius: &temporaryRadius)
            }
            else
            {
                larger.updateArea(delta: overlappingArea)
                smaller.updateArea(delta: -overlappingArea)
            }
        }
    }
    
    public func applyMovement(smaller: Ball, larger: Ball) {
        // This all seems really expensive to compute...
        
        let direction = (larger.position - smaller.position).normalized
        let distance = CGPoint.distance(smaller.position, larger.position)
        let squareRootDistance = sqrt(distance)
        
        let force = CGVector(dx: direction.x * squareRootDistance * Constants.npcMovementModifier,
                             dy: direction.y * squareRootDistance * Constants.npcMovementModifier)

        if smaller != player
        {
            smaller.physicsBody?.applyForce(force * -1)
        }
        
        if larger != player
        {
            larger.physicsBody?.applyForce(force)
        }
    }
    
    public override func didFinishUpdate()
    {
        super.didFinishUpdate()
        
        let npcScale = Constants.referenceRadius / temporaryRadius
        
        iterateNPCs { ball in
            ball.applyCameraZoom(scale: npcScale, cameraPosition: player.position)
        }
        
        playerRadius += temporaryRadius - Constants.referenceRadius
        temporaryRadius = Constants.referenceRadius
        
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
    
    /// This is a less-naive approach than I was previously taking, I previously iterated through
    /// the entire children array twice, but here we avoid that by making sure the sibling hasn't
    /// been iterated through already
    public func permuteAllBallsAndSiblings(handler: (_ ball: Ball, _ sibling: Ball) -> Void)
    {
        let children = children // The array was being modified mid loop; this ensures the array remains stable
        let count = children.count
        
        for i in 0 ..< count
        {
            for j in i + 1 ..< count
            {
                guard let first = children[i] as? Ball,
                      let second = children[j] as? Ball
                else { continue }
                handler(first, second)
            }
        }
    }
    
    /// Each overlap between the player and an npc causes the world to shrink
    /// This function calculates how that ratio is modified for a single overlap
    private func modifyRadiusScale(deltaArea: CGFloat, radius: inout CGFloat)
    {
        let currentArea = radius.radiusToArea
        let newArea = currentArea + deltaArea
        radius = newArea.areaToRadius
    }
    
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
            camera.run(.move(to: player.position, duration: 0.5))
        }
    }
    
    private func checkGameOver()
    {
        if playerRadius < 0.5 {
            // Game Over
            pause()
        }
    }
}

// MARK: - Expulsions

private extension GameScene
{
    func makeProjectile(force: CGVector)
    {
        let radius = Constants.referenceRadius * Constants.expulsionAmountRatio
        
        let npc = Ball(radius: radius, position: player.position)
        npc.kind = .projectile
        npc.addsPointsToScore = false
        npc.fillColor = .purple
        
        insertChild(npc, at: 0)
        
        // Side effect - modifies the temporary radius
        modifyRadiusScale(deltaArea: -radius.radiusToArea, radius: &temporaryRadius)
        
        npc.run(.applyForce(force, duration: Constants.frameDuration))
    }
}

// MARK: - NPC

private extension GameScene
{
    func loopAddEnemies() -> SKAction
    {
        .repeatForever(.sequence([
            .run(addNPC),
            .wait(forDuration: Constants.addEnemyWaitDuration)
        ]))
    }
    
    func addNPC()
    {
        let radius = makeNPCRadius()
        let position = makeNPCSpawnPosition(playerPosition: player.position)
        let npc = Ball(radius: radius, position: position)
        
        addChild(npc)
    }
    
    func makeNPCRadius() -> CGFloat
    {
        .random(in: Constants.referenceRadius / 6 ..< Constants.referenceRadius * 3)
    }
    
    func makeNPCSpawnPosition(playerPosition: CGPoint) -> CGPoint
    {
        let distance = CGFloat.random(
            in: Constants.safeAreaRadius ..< Constants.bounceBackRadius)
        
        let angle = CGFloat.random(in: 0 ..< 360).radians
        
        let x = distance * cos(angle)
        let y = distance * sin(angle)
        
        return CGPoint(x: player.position.x + x,
                       y: player.position.y + y)
    }
}
