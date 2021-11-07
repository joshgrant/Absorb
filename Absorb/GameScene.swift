//
//  GameScene.swift
//  Absorb
//
//  Created by Josh Grant on 10/12/21.
//

import SpriteKit
import GameplayKit
import GameKit

// TODO: Save game state when quitting the app
// TODO: When the user loses, they can enter their name and it'll save the score
// TODO: Highlight score in scoreboard

protocol GameSceneDelegate: AnyObject
{
    func gamePaused()
    func gameOver(score: Int, type: GameOverType)
    func gameRestarted()
}

public class GameScene: SKScene
{
    let generator = UIImpactFeedbackGenerator(style: .light)
    
    public struct Configuration
    {
        var addsNPCs = true
        var addsPlayer = true
        var npcsAreSmaller = false
        var zoomedOutCamera = false
    }
    
    struct Constants
    {
        static let cameraScale: CGFloat = 1
        
        static let referenceRadius: CGFloat = 20
        static let playerMovement: CGFloat = 1000
        static let frameDuration: CGFloat = 1.0 / 60.0
        static let addEnemyWaitDuration: TimeInterval = 0.3
        static let minimumExpulsionRadius: CGFloat = 2
        static let expulsionAmountRatio: CGFloat = 0.2
        static let expulsionForceModifier: CGFloat = 0
        static let npcMovementModifier: CGFloat = 6000
        static let maxVelocity: CGVector = .init(dx: 100, dy: 100)
        
        static let playerFrictionalCoefficient: CGFloat = 0.96
        static let enemyFrictionalCoefficient: CGFloat = 0.99
        
        static let minimumNPCSize: CGFloat = Constants.referenceRadius / 5
        static let maximumNPCSize: CGFloat = Constants.referenceRadius * 2
        
        /// The area in which npcs are not allowed to spawn
        static let safeAreaRadius: CGFloat = UIScreen.main.bounds.height / 2 + maximumNPCSize / 2
        
        /// The area past which npcs despawn
        /// The problem here is that for super large circles, they despawn because the player shrinks
        /// and the centers are too far apart. How do we solve this? Either increase the despawn radius (bad)
        /// or do an edge-edge distance calculation (distance - sum of radius)
        static let killZoneRadius: CGFloat = safeAreaRadius * 4
    }
    
    weak var gameSceneDelegate: GameSceneDelegate?
    
    private var configuration: Configuration
    
    private var temporaryRadius: CGFloat = Constants.referenceRadius
    private var playerRadius: CGFloat = Constants.referenceRadius
    
    private var score: Int = 0
    
    public let player: Ball = {
        let ball = Ball(radius: Constants.referenceRadius,
                        position: CGPoint(x: 0, y: 300))
        ball.kind = .player
        ball.fillColor = .systemBlue
        return ball
    }()
    
    public let total: SKLabelNode = {
        let node = SKLabelNode(text: "0")
        node.fontColor = .label
        node.fontSize = 34 // 68
        return node
    }()
    
    // MARK: - Initialization
    
    init(configuration: Configuration = .init())
    {
        self.configuration = configuration
        super.init(size: .zero)
        scaleMode = .resizeFill
        backgroundColor = .systemBackground
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - View lifecycle
    
    public override func didMove(to view: SKView)
    {
        super.didMove(to: view)
        
        DispatchQueue.main.async { [unowned self] in
            addTotalLabel(to: view)
        }
    }
    
    /// Perform one-time setup
    public override func sceneDidLoad()
    {
        super.sceneDidLoad()
        physicsWorld.gravity = .zero
        addCamera()
        addPlayer()
        addNPCs()
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        super.touchesBegan(touches, with: event)
        if UserDefaults.standard.bool(forKey: "haptics")
        {
            generator.impactOccurred()
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
            
            // I don't know why these are NaN but they are sometimes...
//            if smaller.position.x.isNaN || smaller.position.y.isNaN {
//                smaller.removeFromParent()
//                if smaller == player { checkGameOver() }
//                return
//            } else if larger.position.x.isNaN || larger.position.y.isNaN {
//                larger.removeFromParent()
//                if larger == player { checkGameOver() }
//                return
//            }
            
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
                
                if larger.radius < 1 {
                    larger.removeFromParent()
                }
            }
            else if larger == player
            {
                if smaller.addsPointsToScore
                {
                    score += Int(overlappingArea.areaToRadius)
                }
                
                smaller.updateArea(delta: -overlappingArea)
                modifyRadiusScale(
                    deltaArea: overlappingArea,
                    radius: &temporaryRadius)
                
                if smaller.radius < 1 {
                    smaller.removeFromParent()
                }
            }
            else
            {
                larger.updateArea(delta: overlappingArea)
                smaller.updateArea(delta: -overlappingArea)
                
                if larger.radius < 1 {
                    larger.removeFromParent()
                }
                if smaller.radius < 1 {
                    smaller.removeFromParent()
                }
            }
        }
    }
    
    /// Calculates the force between two balls
    public func applyMovement(smaller: Ball, larger: Ball)
    {
        // This is wrong if the player shrinks?...
        
        let distance = CGPoint.distance(smaller.position, larger.position)
        // This distance is messed up... like we shrink all the balls but we don't move them
        // further from the player, or something? It's around 121 at the start
        let inverseSquare = Constants.npcMovementModifier / (distance * distance)

        let direction = CGVector.direction(from: larger.position, to: smaller.position)
        let force = direction * inverseSquare

        // These are summed up here and applied at the end
        smaller.totalForce = smaller.totalForce + force
        larger.totalForce = larger.totalForce + force
    }
    
    public override func didFinishUpdate()
    {
        super.didFinishUpdate()
        
        let npcScale = Constants.referenceRadius / temporaryRadius
        
        iterateNPCs { ball in
            
            let distanceToPlayer = Ball.edgeDistance(ball, player)
            
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
                ball.physicsBody?.limitVelocity(to: Constants.maxVelocity)
                ball.totalForce = .zero
            }
        }
        
        if playerRadius <= 20
        {
            player.updateArea(to: playerRadius.radiusToArea)
        }
        
        player.physicsBody?.applyFriction(Constants.playerFrictionalCoefficient)
        
        playerRadius += temporaryRadius - Constants.referenceRadius
        temporaryRadius = Constants.referenceRadius
        
        updateScore(to: score)
        
        checkGameOver()
    }
    
    /// Each overlap between the player and an npc causes the world to shrink
    /// This function calculates how that ratio is modified for a single overlap
    private func modifyRadiusScale(deltaArea: CGFloat, radius: inout CGFloat)
    {
        let currentArea = radius.radiusToArea
        let newArea = currentArea + deltaArea
        radius = newArea.areaToRadius
    }
    
    private func moveCameraToPlayer()
    {
        guard let camera = camera else { return }
        
        if !camera.position.equalTo(player.position, allowedDelta: 1.0)
        {
            camera.run(.move(to: player.position, duration: 0.5))
        }
    }
    
    var showing: Bool = false
    
    private func checkGameOver()
    {
        guard !showing else { return }
        
        if playerRadius < 5 || playerRadius.isNaN || player.position.x.isNaN || player.position.y.isNaN
        {
            showing = true
            
            showGameOverScreen()
        }
    }
    
    private func showGameOverScreen()
    {
        // Game Over
        
        Game.submit(score: score, completion: { })
        
        let newScore = Score(context: Database.context)
        newScore.name = UserDefaults.standard.string(forKey: "name") ?? "Johnny"
        newScore.date = .now
        newScore.score = Int64(score)
        
        try? Database.context.save()
        
        let topScore = Database.topScore
        
        let type: GameOverType = (newScore.score == topScore?.score) ? .won : .lost
        
        gameSceneDelegate?.gameOver(score: score, type: type)
    }
}

// MARK: - Iterating utility

private extension GameScene
{
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
}

// MARK: - Expulsions

private extension GameScene
{
    func makeProjectile(force: CGVector)
    {
        let radius = max(Constants.minimumExpulsionRadius, Constants.referenceRadius * Constants.expulsionAmountRatio)
        
        let npc = Ball(radius: radius, position: player.position)
        npc.kind = .projectile
        npc.addsPointsToScore = false
        npc.fillColor = .systemBlue.withAlphaComponent(0.8)
        
        insertChild(npc, at: 0)
        
        // Side effect - modifies the temporary radius
        modifyRadiusScale(deltaArea: -radius.radiusToArea, radius: &temporaryRadius)
        npc.run(.applyForce(force, duration: Constants.frameDuration))
    }
    
    func updateScore(to newScore: Int)
    {
        total.text = "\(newScore)"
    }
}

// MARK: - NPC

private extension GameScene
{
    func makeNPCRadius() -> CGFloat
    {
        if configuration.npcsAreSmaller
        {
            return Constants.referenceRadius / 2
        }
        else
        {
            return .random(in: Constants.minimumNPCSize ... Constants.maximumNPCSize)
        }
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

// MARK: - Adding objects

extension GameScene
{
    private func addTotalLabel(to view: SKView)
    {
        camera?.addChild(total)
        
        let padding = CGSize(width: 20, height: 40)
        // Sa
        
        let topLeft = CGPoint(x: view.frame.size.width * -0.5 + view.safeAreaInsets.left + padding.width,
                              y: view.frame.size.height * 0.5 - view.safeAreaInsets.top - padding.height)
        
        total.horizontalAlignmentMode = .left
        total.position = topLeft
        
        if configuration.zoomedOutCamera {
            camera?.setScale(10)
        }
    }
    
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
        npc.fillColor = .init(hue: .random(in: 0 ... 1), saturation: 0.6, brightness: 1.0, alpha: 1.0)
        
        addChild(npc)
    }
    
    private func addCamera()
    {
        guard let scene = scene else { return }
        let camera = SKCameraNode()
        addChild(camera)
        scene.camera = camera
        scene.camera?.setScale(Constants.cameraScale)
    }
    
    func addPlayer()
    {
        if configuration.addsPlayer
        {
            addChild(player)
        }
    }
    
    func addNPCs()
    {
        if configuration.addsNPCs
        {
            for _ in 0 ..< 50 {
                addNPC()
            }
            
            run(loopAddEnemies())
        }
    }
}
