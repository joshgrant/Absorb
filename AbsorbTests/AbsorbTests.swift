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
}
