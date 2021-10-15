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
        static let cameraScale: CGFloat = 1
        
        static let referenceRadius: CGFloat = 20
        static let playerMovement: CGFloat = 1
        static let frameDuration: CGFloat = 1.0 / 60.0
        static let addEnemyWaitDuration: TimeInterval = 0.3
        static let minimumExpulsionAmount: CGFloat = 2
        static let expulsionAmountRatio: CGFloat = 0.15
        static let expulsionForceModifier: CGFloat = 0
        static let npcMovementModifier: CGFloat = 25
        static let maxVelocity: CGVector = .init(dx: 100, dy: 100)
        
        static let playerFrictionalCoefficient: CGFloat = 0.96
        static let enemyFrictionalCoefficient: CGFloat = 0.978
        
        static let minimumNPCSize: CGFloat = Constants.referenceRadius / 6
        static let maximumNPCSize: CGFloat = Constants.referenceRadius * 2.5
        
        // TODO: Is this true when the user rotates the device?
        /// The area in which npcs are not allowed to spawn
        static let safeAreaRadius: CGFloat = UIScreen.main.bounds.height / 2 + maximumNPCSize / 2
        /// The area past which npcs despawn
        static let killZoneRadius: CGFloat = safeAreaRadius * 4
    }
    
    private var configuration: Configuration
    
    private var temporaryRadius: CGFloat = Constants.referenceRadius
    private var playerRadius: CGFloat = Constants.referenceRadius
    
    public let player: Ball = {
        let ball = Ball(radius: Constants.referenceRadius,
                        position: CGPoint(x: 0, y: 300))
        ball.kind = .player
        ball.fillColor = .systemBlue
        return ball
    }()
    
    public let total: SKLabelNode = {
        let node = SKLabelNode(text: "0")
        node.fontColor = .darkText
        node.fontSize = 34 // 68
        return node
    }()
    
    // MARK: - Initialization
    
    init(configuration: Configuration = .init())
    {
        self.configuration = configuration
        super.init(size: .zero)
        backgroundColor = .systemBackground
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - View lifecycle
    
    public override func didMove(to view: SKView)
    {
        super.didMove(to: view)
        
        DispatchQueue.main.async { [unowned self] in
            // Add total
            
            camera?.addChild(total)
            total.horizontalAlignmentMode = .left
            let topLeft = scene!.convertPoint(fromView: .zero)
            let padding = CGSize(width: view.safeAreaInsets.left + 20,
                                 height: -view.safeAreaInsets.top - 40)
            let newPoint = CGPoint(x: topLeft.x + padding.width,
                                   y: topLeft.y + padding.height)
            total.position = newPoint
            
            // END: Add total
        }
    }
    
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
        update()
    }
    
    /// Making this a separate function for tests
    public func update()
    {
        permuteAllBallsAndSiblings { ball, sibling in
            
            let (smaller, larger) = Ball.orderByRadius(ball, sibling)
            
            let ballIsNPC = updateProjectileToNPCIfNotOverlappingPlayer(ball: ball)
            
            if ballIsNPC
            {
                handleOverlap(smaller: smaller, larger: larger)
                applyMovement(smaller: smaller, larger: larger)
            }
        }
        
        moveCameraToPlayer()
    }
    
    /// If true, this is not a projectile and we can handle overlap
    public func updateProjectileToNPCIfNotOverlappingPlayer(ball: Ball) -> Bool
    {
        if ball.kind == .projectile
        {
            if Ball.overlapping(ball, player)
            {
                return false
            }
            else
            {
                ball.kind = .npc
            }
        }
        
        return true
    }
    
    public func handleOverlap(smaller: Ball, larger: Ball)
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
    
    /// Calculates the force between two balls
    public func applyMovement(smaller: Ball, larger: Ball)
    {
        let distance = CGPoint.distance(smaller.position, larger.position)
        let inverseSquare = 1 / (distance * distance)
        
        let direction = CGVector.direction(from: larger.position, to: smaller.position)
        let force = direction * inverseSquare * Constants.npcMovementModifier
        
        // These are summed up here and applied at the end
        smaller.totalForce = smaller.totalForce + force
        larger.totalForce = larger.totalForce + force
    }
    
    public override func didFinishUpdate()
    {
        super.didFinishUpdate()
        
        let npcScale = Constants.referenceRadius / temporaryRadius
        
        iterateNPCs { ball in
            let distanceToPlayer = CGPoint.distance(ball.position, player.position)
            
            if distanceToPlayer > Constants.killZoneRadius
            {
                ball.removeFromParent()
                return
            }
            else
            {
                if npcScale != 1.0
                {
                    ball.applyCameraZoom(scale: npcScale, cameraPosition: player.position)
                }
                
                ball.physicsBody?.applyForce(ball.totalForce)
                ball.physicsBody?.applyFriction(Constants.enemyFrictionalCoefficient)
                ball.physicsBody?.limitVelocity(to: Constants.maxVelocity)
                ball.totalForce = .zero
            }
        }
        
        player.physicsBody?.applyFriction(Constants.playerFrictionalCoefficient)
        
        playerRadius += temporaryRadius - Constants.referenceRadius
        temporaryRadius = Constants.referenceRadius
        
        checkGameOver()
        
        updateScore(to: playerRadius)
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
        scene?.camera?.setScale(Constants.cameraScale)
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
        if playerRadius < 0.5 || playerRadius.isNaN {
            // Game Over
            let scene = GameScene(configuration: configuration)
            scene.scaleMode = .resizeFill
            view?.presentScene(scene)
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
    
    func updateScore(to newScore: CGFloat)
    {
        if newScore.isNaN || newScore.isInfinite
        {
            total.text = "0"
        }
        else
        {
            total.text = "\(Int(newScore))"
        }
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
        .random(in: Constants.minimumNPCSize ..< Constants.maximumNPCSize)
    }
    
    func makeNPCSpawnPosition(playerPosition: CGPoint) -> CGPoint
    {
        let distance = CGFloat.random(
            in: Constants.safeAreaRadius ..< Constants.safeAreaRadius * 2)
        
        let angle = CGFloat.random(in: 0 ..< 360).radians
        
        let x = distance * cos(angle)
        let y = distance * sin(angle)
        
        return CGPoint(x: player.position.x + x,
                       y: player.position.y + y)
    }
}
