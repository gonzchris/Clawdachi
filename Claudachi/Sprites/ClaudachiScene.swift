//
//  ClaudachiScene.swift
//  Claudachi
//

import SpriteKit

class ClaudachiScene: SKScene {

    private var claudachi: ClaudachiSprite!

    override init() {
        super.init(size: CGSize(width: 32, height: 32))
        scaleMode = .aspectFill
        backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        setupCharacter()
    }

    private func setupCharacter() {
        claudachi = ClaudachiSprite()
        claudachi.position = CGPoint(x: 16, y: 16) // Center of 32x32 scene
        addChild(claudachi)
    }

    // MARK: - Interaction

    override func mouseDown(with event: NSEvent) {
        claudachi.triggerBlink()
    }
}
