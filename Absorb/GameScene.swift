//
//  GameScene.swift
//  Absorb
//
//  Created by Josh Grant on 10/12/21.
//

import SpriteKit
import GameplayKit
import GameKit

// TODO: Highlight score in scoreboard

public class GameScene: SKScene
{
    let generator = UIImpactFeedbackGenerator(style: .light)
    let avPlayer: AVAudioPlayer = {
        let url = Bundle.main.url(forResource: "ping_audio", withExtension: "caf")!
        return try! AVAudioPlayer(contentsOf: url)
    }()
    
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
        static let playerMovement: CGFloat = 900
        static let frameDuration: CGFloat = 1.0 / 60.0
        static let addEnemyWaitDuration: TimeInterval = 0.35
        static let minimumExpulsionRadius: CGFloat = 2
        static let expulsionAmountRatio: CGFloat = 0.2
        static let expulsionForceModifier: CGFloat = 0
        static let npcMovementModifier: CGFloat = 6000
        static let maxVelocity: CGVector = .init(dx: 100, dy: 100)
        static let startingNodes: Int = 12
        static let startingEnemiesOutsideSafeArea: Int = 30
        
        static let playerFrictionalCoefficient: CGFloat = 0.958
        static let enemyFrictionalCoefficient: CGFloat = 0.97
        
        static let minimumNPCSize: CGFloat = Constants.referenceRadius * 0.2
        static let maximumNPCSize: CGFloat = Constants.referenceRadius * 2.2
        
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
    
    internal var score: Int = 0
    private var pScore: Int = 0
    
    public let player: Ball = {
        let ball = Ball(radius: Constants.referenceRadius,
                        position: CGPoint(x: 0, y: 30))
        ball.kind = .player
        ball.fillColor = .systemBlue
        return ball
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
    
    /// Perform one-time setup
    public override func sceneDidLoad()
    {
        super.sceneDidLoad()
        physicsWorld.gravity = .zero
        addCamera()
        addPlayer()
        
        if configuration.addsNPCs {
            addNPCs()
            addStartingEnemies()
        }
    }
    
    func addStartingEnemies() {
        for _ in 0 ..< Constants.startingNodes {
            addStarterNPC()
        }
    }
    
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        super.touchesBegan(touches, with: event)
        if UserDefaults.standard.bool(forKey: "haptics")
        {
            generator.impactOccurred()
        }
        
        avPlayer.prepareToPlay()
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        super.touchesEnded(touches, with: event)
        
        guard let touch = touches.first else { return }
        let direction = player.direction(to: touch.location(in: self))
        
        let force: CGVector = direction * Constants.playerMovement
        player.run(.applyForce(force, duration: Constants.frameDuration))
        
        makeProjectile(force: force * Constants.expulsionForceModifier)
        
        if UserDefaults.standard.bool(forKey: "sound") {
            DispatchQueue.global(qos: .default).async { [unowned self] in
                if avPlayer.isPlaying {
                    avPlayer.currentTime = 0
                } else {
                    avPlayer.play()
                }
            }
        }
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
            if Ball.overlappingArea(ball, player) > 0
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
        let overlappingArea = Ball.overlappingArea(smaller, larger)
        guard overlappingArea > 0 else { return }
        
        if smaller == player
        {
            larger.updateArea(delta: overlappingArea)
            modifyRadiusScale(
                deltaArea: -overlappingArea,
                radius: &temporaryRadius)
            // Doesn't actually update the player's radius so...
            // Need to set the temporary radius directly!!!
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
            
            if smaller.radius < 1 {
                smaller.removeFromParent()
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
        
        if npcScale.isInfinite || npcScale.isNaN {
            showGameOverScreen()
        }
        
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
        
        if score != pScore {
            gameSceneDelegate?.scoreUpdate(to: score)
            pScore = score
        }
        
        checkGameOver()
    }
    
    /// Each overlap between the player and an npc causes the world to shrink
    /// This function calculates how that ratio is modified for a single overlap
    internal
    func modifyRadiusScale(deltaArea: CGFloat, radius: inout CGFloat)
    {
        let currentArea = radius.radiusToArea
        let newArea = currentArea + deltaArea
        radius = newArea.areaToRadius
        
        // Side effect... changes the customPlayerRadius so when we calculate
        // overlapping circles, it takes into account the smaller player size
        player.customPlayerRadius = radius
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
            showGameOverScreen()
        }
    }
    
    private func showGameOverScreen()
    {
        if showing { return }
        
        // Game Over
        showing = true
        
        Game.submit(score: score, completion: { })
        
        gameSceneDelegate?.gameOver(score: score)
    }
}

// MARK: - Iterating utility

extension GameScene
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
    
    func makeNPCSpawnPosition(playerPosition: CGPoint, cameraPosition: CGPoint) -> CGPoint
    {
        let distance = CGFloat.random(
            in: Constants.safeAreaRadius ..< Constants.killZoneRadius * 0.5)
        
        let radians: CGFloat
        
        let direction = playerPosition - cameraPosition
        
        if abs(direction.x) < 1 || abs(direction.y) < 1 {
            // Anywhere works
            radians = CGFloat.random(in: 0 ..< 360).radians
        } else {
            let angle = atan2(direction.y, direction.x).degrees
            // Random cone in a 30° area
            radians = (360 + round(angle) + .random(in: -15 ... 15))
                .truncatingRemainder(dividingBy: 360)
                .radians
        }
        
        let x = distance * cos(radians)
        let y = distance * sin(radians)
        
        return CGPoint(x: player.position.x + x,
                       y: player.position.y + y)
    }
}

// MARK: - Adding objects

extension GameScene
{
    func loopAddEnemies() -> SKAction
    {
        .repeatForever(.sequence([
            .run(addNPC),
            .wait(forDuration: Constants.addEnemyWaitDuration)
        ]))
    }
    
    func addStarterNPC() {
        let radius = CGFloat.random(in: playerRadius * 0.25 ..< playerRadius * 0.75)
        
        let distance = CGFloat.random(in: 30 ..< Constants.safeAreaRadius)
        
        let radians = CGFloat.random(in: 0 ..< 360).radians
        
        let x = distance * cos(radians)
        let y = distance * sin(radians)
        
        let position = CGPoint(x: player.position.x + x,
                               y: player.position.y + y)
        
        let npc = Ball(radius: radius, position: position)
        npc.fillColor = .init(hue: .random(in: 0 ... 1), saturation: 0.6, brightness: 1.0, alpha: 1.0)
        
        addChild(npc)
    }
    
    func addNPC()
    {
        let radius = makeNPCRadius()
        // We can get the angle by the camera position and the player position
        
        let position = makeNPCSpawnPosition(
            playerPosition: player.position,
            cameraPosition: camera!.position)
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
        
        if configuration.zoomedOutCamera {
            camera.setScale(10)
        } else {
            camera.setScale(Constants.cameraScale)
        }
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
        for _ in 0 ..< Constants.startingEnemiesOutsideSafeArea {
            addNPC()
        }
        
        run(loopAddEnemies())
    }
}
