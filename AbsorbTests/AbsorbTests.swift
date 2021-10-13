//
//  AbsorbTests.swift
//  AbsorbTests
//
//  Created by Josh Grant on 10/12/21.
//

import XCTest
@testable import Absorb
import SpriteKit

class AbsorbTests: XCTestCase
{
    func test_playerShrinks_growsAndMovesNPCAway()
    {
        let playerScale = 0.8
        let npcScale = 1 / playerScale
        let ball = Ball(radius: 10, position: CGPoint(x: 10, y: 15))
        ball.applyCameraZoom(scale: npcScale, cameraPosition: .zero)
        
        XCTAssertEqual(ball.radius, 12.5)
        XCTAssertEqual(ball.position, CGPoint(x: 12.5, y: 18.75))
    }
    
    func test_playerGrows_shrinksAndMovesNPCCloser()
    {
        let playerScale = 1.2
        let npcScale = 1 / playerScale
        let ball = Ball(radius: 10, position: CGPoint(x: 10, y: 15))
        ball.applyCameraZoom(scale: npcScale, cameraPosition: .zero)
        
        XCTAssertEqual(ball.radius, 8.3333, accuracy: 0.0001)
        XCTAssertEqual(ball.position, CGPoint(x: 8.333333015441895, y: 12.5))
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
        
        XCTAssertTrue(Ball.overlapping(first, second))
    }
    
    func test_balls_doNotOverlap()
    {
        let first = Ball(radius: 10, position: .zero)
        let second = Ball(radius: 15, position: CGPoint(x: 25, y: 0))
        
        XCTAssertFalse(Ball.overlapping(first, second))
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
        XCTAssertEqual(ball.physicsBody!.mass, 0.013962635770440102)
        
        ball.updateArea(to: 15)
        
        XCTAssertEqual(ball.radius, 2.1850968611841584)
        XCTAssertEqual(ball.physicsBody!.area * pow(150, 2), 15, accuracy: 0.00001)
        XCTAssertEqual(ball.physicsBody?.mass, 0.0006666667759418488)// TODO: Check later
    }
}
