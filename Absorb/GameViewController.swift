//
//  GameViewController.swift
//  Absorb
//
//  Created by Josh Grant on 10/12/21.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController
{
    override func loadView()
    {
        view = SKView()
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        guard let view = view as? SKView else { return }
        
        let scene = GameScene()
        
        view.ignoresSiblingOrder = true
        view.showsFPS = true
        view.showsNodeCount = true
        
        view.presentScene(scene)
    }

    override var shouldAutorotate: Bool { true }
    override var prefersStatusBarHidden: Bool { true }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask
    {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
}
