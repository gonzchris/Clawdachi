//
//  ChefModeSprite.swift
//  Claudachi
//
//  Frying pan held in hand during chef cooking mode

import SpriteKit

/// Frying pan that appears in hand during chef cooking mode
class ChefModeSprite: SKNode {

    // MARK: - Position Constants
    // Pan position - on top of right hand (arm is at x:11, y:-4, size 3x3)
    private let panPos = CGPoint(x: 20, y: -3)

    // MARK: - Nodes

    private var panNode: SKSpriteNode!
    private var steamNodes: [SKSpriteNode] = []

    // MARK: - State

    private var isActive = false

    // MARK: - Initialization

    override init() {
        super.init()
        setupNodes()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupNodes() {
        let panTexture = generateFryingPanTexture()

        panNode = SKSpriteNode(texture: panTexture)
        panNode.texture?.filteringMode = .nearest
        panNode.size = CGSize(width: 16, height: 8)
        panNode.position = panPos
        panNode.zPosition = 10  // In front of character
        panNode.alpha = 0
        addChild(panNode)

        // Create steam nodes
        for i in 0..<3 {
            let steam = SKSpriteNode(color: NSColor(white: 1.0, alpha: 0.7), size: CGSize(width: 2, height: 2))
            steam.position = CGPoint(x: panPos.x + CGFloat(i - 1) * 3, y: panPos.y + 6)
            steam.zPosition = 11
            steam.alpha = 0
            addChild(steam)
            steamNodes.append(steam)
        }
    }

    /// Generate pixel art frying pan texture (16x8 pixels)
    private func generateFryingPanTexture() -> SKTexture {
        let width = 16
        let height = 8
        var pixels = Array(repeating: Array(repeating: PixelColor.clear, count: width), count: height)

        // Pan colors - dark iron/steel
        let panDark = PixelColor(r: 60, g: 60, b: 65)         // Dark iron
        let panMid = PixelColor(r: 85, g: 85, b: 90)          // Mid gray
        let panLight = PixelColor(r: 110, g: 110, b: 115)     // Light edge
        let panInner = PixelColor(r: 45, g: 45, b: 50)        // Inner cooking surface
        let handleWood = PixelColor(r: 120, g: 80, b: 50)     // Wood handle
        let handleDark = PixelColor(r: 90, g: 60, b: 35)      // Handle shadow
        let handleLight = PixelColor(r: 150, g: 100, b: 65)   // Handle highlight

        // Handle (left side, rows 3-4, cols 0-4)
        for x in 0...4 {
            // Row 3 (bottom of handle)
            if x == 0 {
                pixels[3][x] = handleDark
            } else {
                pixels[3][x] = handleWood
            }
            // Row 4 (top of handle)
            if x == 0 {
                pixels[4][x] = handleWood
            } else {
                pixels[4][x] = handleLight
            }
        }

        // Pan body - circular from side view (cols 5-15)
        // Row 0 - bottom edge
        for x in 8...12 {
            pixels[0][x] = panDark
        }

        // Row 1
        for x in 6...14 {
            if x == 6 || x == 14 { pixels[1][x] = panDark }
            else { pixels[1][x] = panMid }
        }

        // Row 2
        for x in 5...15 {
            if x == 5 { pixels[2][x] = panDark }
            else if x == 15 { pixels[2][x] = panLight }
            else { pixels[2][x] = panMid }
        }

        // Rows 3-4 - widest part with inner surface
        for row in 3...4 {
            for x in 5...15 {
                if x == 5 { pixels[row][x] = panDark }
                else if x == 15 { pixels[row][x] = panLight }
                else if x >= 7 && x <= 13 { pixels[row][x] = panInner }
                else { pixels[row][x] = panMid }
            }
        }

        // Row 5
        for x in 5...15 {
            if x == 5 { pixels[5][x] = panDark }
            else if x == 15 { pixels[5][x] = panLight }
            else { pixels[5][x] = panMid }
        }

        // Row 6
        for x in 6...14 {
            if x == 6 { pixels[6][x] = panMid }
            else if x == 14 { pixels[6][x] = panLight }
            else { pixels[6][x] = panLight }
        }

        // Row 7 - top rim
        for x in 8...12 {
            pixels[7][x] = panLight
        }

        return PixelArtGenerator.textureFromPixels(pixels, width: width, height: height)
    }

    // MARK: - Animations

    /// Activate frying pan
    func activate(completion: (() -> Void)? = nil) {
        guard !isActive else {
            completion?()
            return
        }
        isActive = true

        // Fade in pan
        panNode.alpha = 0
        panNode.setScale(0.8)

        let scaleUp = SKAction.scale(to: 1.0, duration: 0.2)
        scaleUp.timingMode = .easeOut
        let fadeIn = SKAction.fadeIn(withDuration: 0.15)

        panNode.run(SKAction.group([scaleUp, fadeIn]))

        // Cooking shake animation
        let shakeUp = SKAction.moveBy(x: 0, y: 2, duration: 0.15)
        shakeUp.timingMode = .easeOut
        let shakeDown = SKAction.moveBy(x: 0, y: -2, duration: 0.15)
        shakeDown.timingMode = .easeIn
        let pause = SKAction.wait(forDuration: 0.4)

        panNode.run(SKAction.repeatForever(
            SKAction.sequence([shakeUp, shakeDown, pause])
        ), withKey: "panShake")

        // Start steam animations
        for (index, steam) in steamNodes.enumerated() {
            let delay = Double(index) * 0.4
            animateSteam(steam, delay: delay)
        }

        completion?()
    }

    private func animateSteam(_ steam: SKSpriteNode, delay: TimeInterval) {
        guard isActive else { return }

        let startX = panPos.x + CGFloat.random(in: -4...4)
        let startY = panPos.y + 5

        steam.position = CGPoint(x: startX, y: startY)
        steam.alpha = 0
        steam.setScale(0.5)

        let wait = SKAction.wait(forDuration: delay)
        let fadeIn = SKAction.fadeAlpha(to: 0.6, duration: 0.2)
        let rise = SKAction.moveBy(x: CGFloat.random(in: -2...2), y: 10, duration: 1.0)
        rise.timingMode = .easeOut
        let grow = SKAction.scale(to: 1.0, duration: 0.3)
        let shrink = SKAction.scale(to: 0.3, duration: 0.7)
        let fadeOut = SKAction.fadeOut(withDuration: 0.4)

        let sequence = SKAction.sequence([
            wait,
            SKAction.group([fadeIn, grow]),
            SKAction.group([rise, SKAction.sequence([shrink, fadeOut])]),
            SKAction.run { [weak self] in
                self?.animateSteam(steam, delay: 0.2)
            }
        ])

        steam.run(sequence, withKey: "steam")
    }

    /// Deactivate frying pan
    func deactivate(success: Bool, completion: (() -> Void)? = nil) {
        guard isActive else {
            completion?()
            return
        }
        isActive = false

        panNode.removeAction(forKey: "panShake")
        for steam in steamNodes {
            steam.removeAction(forKey: "steam")
        }

        if success {
            // Success flip animation
            let flipUp = SKAction.moveBy(x: 0, y: 6, duration: 0.15)
            flipUp.timingMode = .easeOut
            let flipDown = SKAction.moveBy(x: 0, y: -6, duration: 0.15)
            flipDown.timingMode = .easeIn

            panNode.run(SKAction.sequence([flipUp, flipDown]))
        }

        // Fade out
        let fadeOut = SKAction.fadeOut(withDuration: 0.25)
        panNode.run(fadeOut)
        for steam in steamNodes {
            steam.run(fadeOut)
        }

        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.run { [weak self] in
                self?.reset()
                completion?()
            }
        ]))
    }

    /// Reset to initial state
    func reset() {
        isActive = false
        panNode.alpha = 0
        panNode.setScale(1.0)
        panNode.position = panPos
        panNode.removeAction(forKey: "panShake")
        for steam in steamNodes {
            steam.alpha = 0
            steam.removeAction(forKey: "steam")
        }
    }
}
