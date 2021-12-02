//
//  AbsorbTests.swift
//  AbsorbTests
//
//  Created by Josh Grant on 10/12/21.
//

import XCTest
@testable import absOrby
import SpriteKit

class AbsorbTests: XCTestCase
{
    func test_newPosition()
    {
        let a = Ball(radius: 10, position: .zero)
        XCTAssertEqual(a.newPosition(relativeTo: .init(x: 10, y: 10), scaledBy: 0.5), .init(x: 5, y: 5))
        
        let b = Ball(radius: 10, position: .zero)
        XCTAssertEqual(b.newPosition(relativeTo: .init(x: 10, y: 10), scaledBy: 2), .init(x: -10, y: -10))
    }
    
    func test_playerShrinks_growsAndMovesNPCAway()
    {
        let playerScale = 0.8
        let npcScale = 1 / playerScale
        let ball = Ball(radius: 10, position: CGPoint(x: 10, y: 15))
        ball.applyCameraZoom(scale: npcScale, cameraPosition: .zero)
        
        XCTAssertEqual(ball.radius, 12.5)
    }
    
    func test_playerGrows_shrinksAndMovesNPCCloser()
    {
        let playerScale = 1.2
        let npcScale = 1 / playerScale
        let ball = Ball(radius: 10, position: CGPoint(x: 10, y: 15))
        ball.applyCameraZoom(scale: npcScale, cameraPosition: .zero)
        
        XCTAssertEqual(ball.radius, 8.3333, accuracy: 0.0001)
    }
    
    func test_cgPoint_equalToAllowedDelta()
    {
        var first = CGPoint(x: 0, y: 0)
        var second = CGPoint(x: 1, y: 1)
        
        XCTAssertTrue(first.equalTo(second, allowedDelta: 1.0))
        
        first = CGPoint(x: 0.05, y: -0.05)
        second = CGPoint(x: -1, y: 0.0)
        
        XCTAssertTrue(first.equalTo(second, allowedDelta: 1.05))
        
        first = CGPoint(x: 10, y: 15)
        second = CGPoint(x: 0, y: -5)
        
        XCTAssertFalse(first.equalTo(second, allowedDelta: 15))
    }
    
    func test_balls_overlap()
    {
        let first = Ball(radius: 10, position: .zero)
        let second = Ball(radius: 15, position: CGPoint(x: 24, y: 0))
        
        XCTAssertTrue(Ball.overlappingArea(first, second) > 0)
        
        let a = Ball(radius: 1, position: .zero)
        let b = Ball(radius: 1, position: .init(x: 1.9, y: 0))
        
        XCTAssertTrue(Ball.overlappingArea(a, b) > 0)
    }
    
    func test_balls_doNotOverlap()
    {
        let first = Ball(radius: 10, position: .zero)
        let second = Ball(radius: 15, position: CGPoint(x: 25, y: 0))
        
        XCTAssertFalse(Ball.overlappingArea(first, second) > 0)
        
        let a = Ball(radius: 1, position: .zero)
        let b = Ball(radius: 1, position: .init(x: 2, y: 0))
        
        XCTAssertFalse(Ball.overlappingArea(a, b) > 0)
    }
    
    func test_distanceFormula()
    {
        let pointA = CGPoint(x: 0, y: 0)
        let pointB = CGPoint(x: 5, y: 12)
        
        let distance = CGPoint.distance(pointA, pointB)
        XCTAssertEqual(distance, 13)
    }
    
    func test_overlappingArea_identicalCircles()
    {
        let ballA = Ball(radius: 10, position: .zero)
        let ballB = Ball(radius: 10, position: .zero)
        
        let overlappingArea = Ball.overlappingArea(ballA, ballB)
        XCTAssertEqual(overlappingArea, CGFloat.pi * 100)
    }
    
    func test_overlappingArea_concentricCircles()
    {
        let ballA = Ball(radius: 10, position: .zero)
        let ballB = Ball(radius: 4, position: .zero)
        
        let overlappingArea = Ball.overlappingArea(ballA, ballB)
        XCTAssertEqual(overlappingArea, CGFloat.pi * 16)
    }
    
    func test_overlappingArea_vennDiagramStyleCircles()
    {
        let ballA = Ball(radius: 10, position: .zero)
        let ballB = Ball(radius: 10, position: .init(x: -5, y: 0))
        
        let overlappingArea = Ball.overlappingArea(ballA, ballB)
        XCTAssertEqual(overlappingArea, 215.2109225029709)
    }
    
    func test_increaseRadius_withNewArea()
    {
        let ball = Ball(radius: 10, position: .zero)
        XCTAssertEqual(ball.radius, 10)
        XCTAssertEqual(ball.physicsBody!.area * pow(150, 2), .pi * 100, accuracy: 0.001)
        XCTAssertEqual(ball.physicsBody!.mass, 0.044999998062849045, accuracy: 0.01)
        
        ball.updateArea(to: 15)
        
        XCTAssertEqual(ball.radius, 2.1850968611841584)
        XCTAssertEqual(ball.physicsBody!.area * pow(150, 2), 15, accuracy: 0.00001)
        XCTAssertEqual(ball.physicsBody!.mass, 0.044999998062849045, accuracy: 0.01)
    }
    
    func test_increaseRadius_withDeltaArea()
    {
        let ball = Ball(radius: 5, position: .zero)
        ball.updateArea(delta: 5)
        XCTAssertEqual(ball.radius, 5.15, accuracy: 0.01)
    }
    
    func test_convertAreaToRadius()
    {
        let area: CGFloat = 314.15
        XCTAssertEqual(area.areaToRadius, 10, accuracy: 1.0)
    }
    
    func test_convertRadiusToArea()
    {
        let radius: CGFloat = 10
        XCTAssertEqual(radius.radiusToArea, 314.15, accuracy: 0.01)
    }
    
    func test_updatingRadiusPreservesVelocity()
    {
        let ball = Ball(radius: 10, position: .zero)
        ball.physicsBody?.velocity = .init(dx: 10, dy: 0)
        ball.updateArea(to: 20)
        XCTAssertEqual(ball.physicsBody?.velocity, .init(dx: 10.000001907348633, dy: 0))
    }
    
    func test_settingAreaToZero_removesNodeFromParent()
    {
        let parent = SKNode()
        let ball = Ball(radius: 10, position: .zero)
        
        parent.addChild(ball)
        
        ball.updateArea(to: 0)
        
        XCTAssertNil(ball.parent)
    }
    
    func test_directionToPoint_fromBall()
    {
        let ball = Ball(radius: 1.0, position: .zero)
        let point = CGPoint(x: 10, y: 0)
        
        XCTAssertEqual(ball.direction(to: point), CGVector(dx: 1.0, dy: 0.0))
    }
    
    func test_multipyVector()
    {
        let vector = CGVector(dx: 10, dy: 5)
        XCTAssertEqual(vector * 5, CGVector(dx: 50, dy: 25))
    }
    
    func test_dividePoint()
    {
        let point = CGPoint(x: 10, y: 5)
        XCTAssertEqual(point / 5, CGPoint(x: 2, y: 1))
    }
    
    func test_iterateNPCs()
    {
        let sut = GameScene()
        
        let first = Ball(radius: 1, position: .zero)
        let second = Ball(radius: 1, position: .zero)
        let third = Ball(radius: 2, position: .zero)
        
        sut.addChild(first)
        sut.addChild(second)
        sut.addChild(third)
        
        sut.iterateNPCs { ball in
            ball.radius = 10
        }
        
        XCTAssertEqual(first.radius, 10)
        XCTAssertEqual(second.radius, 10)
        XCTAssertEqual(third.radius, 10)
    }
    
    func test_permuteAllBallsAndSiblings()
    {
        let sut = GameScene(configuration: .init(addsNPCs: false, addsPlayer: true, npcsAreSmaller: false))
        
        sut.player.name = "Player"
        
        let first = Ball(radius: 1, position: .zero)
        first.name = "First"
        
        let second = Ball(radius: 2, position: .zero)
        second.name = "Second"
        
        sut.addChild(first)
        sut.addChild(second)
        
        var iteratedBalls: [Ball] = []
        
        sut.permuteAllBallsAndSiblings { ball, sibling in
            iteratedBalls += [ball, sibling]
        }
        
        XCTAssertEqual(iteratedBalls, [
            sut.player, first,
            sut.player, second,
            first, second,
        ])
    }
    
    func test_hashTogether()
    {
        let first = Ball(radius: 1, position: .zero)
        let second = Ball(radius: 1, position: .zero)
        
        let firstHash = Ball.hashTogether([first, second])
        let secondHash = Ball.hashTogether([second, first])
        
        XCTAssertNotEqual(firstHash, 0)
        XCTAssertEqual(firstHash, secondHash)
    }
    
    func test_orderByRadius()
    {
        let first = Ball(radius: 10, position: .zero)
        let second = Ball(radius: 15, position: .zero)
        
        let (smaller, larger) = Ball.orderByRadius(second, first)
        XCTAssertEqual(smaller, first)
        XCTAssertEqual(larger, second)
        
        first.radius = 20
        
        let (s, l) = Ball.orderByRadius(second, first)
        XCTAssertEqual(s, second)
        XCTAssertEqual(l, first)
    }
    
    func test_speedOfPermutation()
    {
        let sut = makeGameSceneWithLotsOfChildren()
        
        measure
        {
            sut.permuteAllBallsAndSiblings { ball, sibling in
                doSomething(duration: 1)
            }
        }
    }
    
    func test_degreesToRadians()
    {
        XCTAssertEqual(CGFloat(180).radians, CGFloat.pi)
        XCTAssertEqual(CGFloat(360).radians, CGFloat.pi * 2)
        XCTAssertEqual(CGFloat(0).radians, 0)
    }
    
    func test_updateProjectileToNPC()
    {
        let sut = GameScene()
        let ball = Ball(radius: 1, position: .zero)
        ball.kind = .projectile
        
        sut.player.radius = 1
        sut.player.position = .zero
        
        _ = sut.updateProjectileToNPCIfNotOverlappingPlayer(ball: ball)
        
        XCTAssertEqual(ball.kind, .projectile)
        
        sut.player.position = .init(x: 2, y: 0)
        
        _ = sut.updateProjectileToNPCIfNotOverlappingPlayer(ball: ball)
        
        XCTAssertEqual(ball.kind, .npc)
    }
    
    func test_applyMovement()
    {
        let sut = makeGameSceneInView(with: .init(addsNPCs: false, addsPlayer: false))
        
        // They can't be overlapping or they will absorb each other
        let smaller = Ball(radius: 10, position: .zero)
        let larger = Ball(radius: 15, position: .init(x: 50, y: 0))
        
        sut.addChild(smaller)
        sut.addChild(larger)
        
        sut.applyMovement(smaller: smaller, larger: larger)
        
        let exp = expectation(description: "Scene run loop update")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertLessThan(smaller.physicsBody!.velocity.dx, 0)
            XCTAssertLessThan(larger.physicsBody!.velocity.dx, 0)
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 0.3)
    }
    
    func test_gameSceneThatDoesNotAddNPCs()
    {
        let sut = makeGameSceneInView(with: .init(addsNPCs: false))
        
        let exp = expectation(description: "Loads the main thread")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(sut.children.count, 2) // 1 is the player, 2 is the camera, 12 for the starting npcs
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_applyFrictionalCoefficient()
    {
        let body = SKPhysicsBody()
        body.velocity = .init(dx: 10, dy: 10)
        body.applyFriction(0.95)
        
        XCTAssertEqual(body.velocity.dy, 9.5, accuracy: 0.01)
        XCTAssertEqual(body.velocity.dy, 9.5, accuracy: 0.01)
        
    }
    
    func test_limitVelocity()
    {
        let body = SKPhysicsBody()
        
        body.velocity = .init(dx: 100, dy: 100)
        body.limitVelocity(to: CGVector(dx: 10, dy: 10))
        XCTAssertEqual(body.velocity.dx, 10, accuracy: 0.01)
        XCTAssertEqual(body.velocity.dy, 10, accuracy: 0.01)
        
        body.velocity = .init(dx: -100, dy: -100)
        body.limitVelocity(to: CGVector(dx: 10, dy: 10))
        XCTAssertEqual(body.velocity.dx, -10, accuracy: 0.01)
        XCTAssertEqual(body.velocity.dy, -10, accuracy: 0.01)
    }
    
    func test_edgeDistance()
    {
        let a = Ball(radius: 10, position: .zero)
        let b = Ball(radius: 15, position: .init(x: 30, y: 0))
        
        XCTAssertEqual(Ball.edgeDistance(a, b), 5)
    }
    
    func test_durationOfOverlappingArea()
    {
        let sut = makeGameSceneWithLotsOfChildren()
        measure {
            sut.permuteAllBallsAndSiblings { ball, sibling in
                _ = Ball.overlappingArea(ball, sibling)
            }
        }
    }
    
    func test_durationOfApplyMovement()
    {
        let sut = makeGameSceneWithLotsOfChildren()
        measure
        {
            sut.permuteAllBallsAndSiblings { ball, sibling in
                sut.applyMovement(smaller: ball, larger: sibling)
            }
        }
    }
    
    func test_durationOfUpdateProjectileToNPC()
    {
        let sut = makeGameSceneWithLotsOfChildren()
        measure
        {
            sut.permuteAllBallsAndSiblings { ball, sibling in
                _ = sut.updateProjectileToNPCIfNotOverlappingPlayer(ball: ball)
            }
        }
    }
    
    func test_durationOfHandleOverlap()
    {
        let sut = makeGameSceneWithLotsOfChildren()
        measure
        {
            sut.permuteAllBallsAndSiblings { ball, sibling in
                sut.handleOverlap(smaller: ball, larger: sibling)
            }
        }
    }
    
    func test_durationOfUpdate()
    {
        let sut = makeGameSceneWithLotsOfChildren()
        measure
        {
            sut.update()
        }
    }
    
//    func test_durationOfModifyRadiusScale()
//    {
//        let sut = makeGameSceneWithLotsOfChildren()
//        let options = XCTMeasureOptions()
//        options.iterationCount = 1000
//        sut.player.radius = 3.2
//        measure(options: options) {
//            sut.player.updateArea(delta: 10)
//        }
//    }
    
    func test_durationDidFinishUpdate() {
        let sut = makeGameSceneWithLotsOfChildren()
        
        measure {
            sut.didFinishUpdate()
        }
    }
    
    func test_durationOfUpdateArea() {
        let circle = Ball(radius: 100, position: .zero)
        measure {
            circle.updateArea(delta: .random(in: -1 ..< 1))
        }
    }
    
    // MARK: - Test helpers
    
    func makeGameSceneInView(with configuration: GameScene.Configuration) -> GameScene
    {
        let controller = UIViewController()
        let window = UIWindow()
        window.rootViewController = controller
        let view = SKView()
        controller.view = view
        let sut = GameScene(configuration: configuration)
        window.makeKeyAndVisible()
        view.presentScene(sut)
        return sut
    }
    
    func makeGameSceneWithLotsOfChildren() -> GameScene
    {
        let sut = GameScene()
        
        for _ in 0 ..< 200
        {
            sut.addChild(Ball(radius: .random(in: 1 ..< 100), position: .zero))
        }
        
        return sut
    }
    
    func doSomething(duration: useconds_t)
    {
        usleep(duration)
    }
}
