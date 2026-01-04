//
//  TerminalSprite.swift
//  Claudachi
//

import SpriteKit

/// A mini terminal window that appears when Claudachi is "coding"
class TerminalSprite: SKNode {

    // MARK: - Constants

    private let terminalWidth: CGFloat = 20
    private let terminalHeight: CGFloat = 14
    private let textLines = 4

    // MARK: - Nodes

    private var frameNode: SKSpriteNode!
    private var textNodes: [SKSpriteNode] = []
    private var cursorNode: SKSpriteNode!

    // MARK: - Textures

    private var frameTexture: SKTexture!
    private var textLineTextures: [SKTexture] = []
    private var cursorTexture: SKTexture!

    // MARK: - State

    private var isTyping = false

    // MARK: - Initialization

    override init() {
        super.init()
        generateTextures()
        setupNodes()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Texture Generation

    private func generateTextures() {
        frameTexture = generateFrameTexture()
        cursorTexture = generateCursorTexture()

        // Generate varied text line textures
        for _ in 0..<6 {
            textLineTextures.append(generateTextLineTexture())
        }
    }

    private func generateFrameTexture() -> SKTexture {
        let width = Int(terminalWidth)
        let height = Int(terminalHeight)

        var pixels = Array(repeating: Array(repeating: PixelColor.clear, count: width), count: height)

        let frame = PixelColor(r: 60, g: 60, b: 60)       // Dark gray frame
        let bg = PixelColor(r: 30, g: 30, b: 35)          // Near-black background
        let titleBar = PixelColor(r: 80, g: 80, b: 85)    // Slightly lighter title bar
        let closeBtn = PixelColor(r: 255, g: 95, b: 86)   // Red close button
        let minimizeBtn = PixelColor(r: 255, g: 189, b: 46) // Yellow minimize
        let maximizeBtn = PixelColor(r: 39, g: 201, b: 63)  // Green maximize

        // Fill background
        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                pixels[y][x] = bg
            }
        }

        // Frame border
        for x in 0..<width {
            pixels[0][x] = frame
            pixels[height - 1][x] = frame
        }
        for y in 0..<height {
            pixels[y][0] = frame
            pixels[y][width - 1] = frame
        }

        // Title bar (top 3 rows inside frame)
        for y in (height - 4)..<(height - 1) {
            for x in 1..<(width - 1) {
                pixels[y][x] = titleBar
            }
        }

        // Window buttons (in title bar)
        pixels[height - 3][2] = closeBtn
        pixels[height - 3][4] = minimizeBtn
        pixels[height - 3][6] = maximizeBtn

        return PixelArtGenerator.textureFromPixels(pixels, width: width, height: height)
    }

    private func generateTextLineTexture() -> SKTexture {
        // Random length text line (simulating code)
        let maxWidth = Int(terminalWidth) - 4
        let lineLength = Int.random(in: 3...maxWidth)

        var pixels = Array(repeating: Array(repeating: PixelColor.clear, count: maxWidth), count: 1)

        let green = PixelColor(r: 0, g: 255, b: 136)      // Terminal green
        let white = PixelColor(r: 200, g: 200, b: 200)    // Gray-white
        let keyword = PixelColor(r: 255, g: 120, b: 200)  // Pink for keywords

        // Randomly colored "code" pixels
        for x in 0..<lineLength {
            let colors = [green, green, green, white, white, keyword]
            pixels[0][x] = colors.randomElement()!
        }

        return PixelArtGenerator.textureFromPixels(pixels, width: maxWidth, height: 1)
    }

    private func generateCursorTexture() -> SKTexture {
        let pixels = [[PixelColor(r: 0, g: 255, b: 136)]]  // Green cursor
        return PixelArtGenerator.textureFromPixels(pixels, width: 1, height: 1)
    }

    // MARK: - Setup

    private func setupNodes() {
        // Terminal frame
        frameNode = SKSpriteNode(texture: frameTexture)
        frameNode.size = CGSize(width: terminalWidth, height: terminalHeight)
        frameNode.position = .zero
        frameNode.zPosition = 0
        addChild(frameNode)

        // Text lines (initially hidden)
        let textAreaTop = -2  // Below title bar
        for i in 0..<textLines {
            let textNode = SKSpriteNode(texture: textLineTextures[i % textLineTextures.count])
            textNode.anchorPoint = CGPoint(x: 0, y: 0.5)
            textNode.size = CGSize(width: terminalWidth - 4, height: 1)
            textNode.position = CGPoint(x: -terminalWidth/2 + 2, y: CGFloat(textAreaTop - i * 2))
            textNode.zPosition = 1
            textNode.alpha = 0
            addChild(textNode)
            textNodes.append(textNode)
        }

        // Cursor
        cursorNode = SKSpriteNode(texture: cursorTexture)
        cursorNode.size = CGSize(width: 1, height: 1)
        cursorNode.anchorPoint = CGPoint(x: 0, y: 0.5)
        cursorNode.position = CGPoint(x: -terminalWidth/2 + 2, y: CGFloat(textAreaTop))
        cursorNode.zPosition = 2
        cursorNode.alpha = 0
        addChild(cursorNode)

        // Start hidden
        alpha = 0
        setScale(0.5)
    }

    // MARK: - Animations

    /// Show the terminal with a pop-in animation
    func show(completion: (() -> Void)? = nil) {
        let popIn = SKAction.group([
            SKAction.fadeIn(withDuration: 0.15),
            SKAction.scale(to: 1.1, duration: 0.15)
        ])
        let settle = SKAction.scale(to: 1.0, duration: 0.08)

        run(SKAction.sequence([popIn, settle])) {
            completion?()
        }
    }

    /// Hide the terminal with a poof animation
    func hide(completion: (() -> Void)? = nil) {
        stopTyping()

        let poof = SKAction.group([
            SKAction.fadeOut(withDuration: 0.12),
            SKAction.scale(to: 1.3, duration: 0.12)
        ])

        run(poof) { [weak self] in
            self?.reset()
            completion?()
        }
    }

    /// Start the typing animation
    func startTyping() {
        guard !isTyping else { return }
        isTyping = true

        // Show cursor with blink
        cursorNode.alpha = 1
        let blink = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.fadeIn(withDuration: 0.3)
        ])
        cursorNode.run(SKAction.repeatForever(blink), withKey: "cursorBlink")

        // Start typing lines
        typeNextLine(index: 0)
    }

    private func typeNextLine(index: Int) {
        guard isTyping && index < textNodes.count else {
            // Loop back to simulate continuous coding
            if isTyping {
                run(SKAction.sequence([
                    SKAction.wait(forDuration: 0.5),
                    SKAction.run { [weak self] in
                        self?.clearLines()
                        self?.typeNextLine(index: 0)
                    }
                ]))
            }
            return
        }

        let textNode = textNodes[index]

        // Assign a new random texture
        textNode.texture = textLineTextures.randomElement()

        // Animate the line appearing (typing effect)
        let typeDuration = TimeInterval.random(in: 0.3...0.6)

        // Move cursor to this line
        cursorNode.position.y = textNode.position.y

        // Reveal text gradually by scaling X from 0
        textNode.xScale = 0
        textNode.alpha = 1

        let typeIn = SKAction.scaleX(to: 1.0, duration: typeDuration)
        typeIn.timingMode = .easeOut

        // Move cursor along as we type
        let cursorMove = SKAction.moveTo(
            x: textNode.position.x + textNode.size.width,
            duration: typeDuration
        )

        textNode.run(typeIn)
        cursorNode.run(cursorMove)

        // Schedule next line
        run(SKAction.sequence([
            SKAction.wait(forDuration: typeDuration + 0.1),
            SKAction.run { [weak self] in
                self?.typeNextLine(index: index + 1)
            }
        ]), withKey: "typeNextLine")
    }

    private func clearLines() {
        for textNode in textNodes {
            textNode.alpha = 0
            textNode.xScale = 1
        }
        cursorNode.position.x = -terminalWidth/2 + 2
    }

    /// Stop the typing animation
    func stopTyping() {
        isTyping = false
        removeAction(forKey: "typeNextLine")
        cursorNode.removeAction(forKey: "cursorBlink")
    }

    /// Reset to initial hidden state
    func reset() {
        stopTyping()
        alpha = 0
        setScale(0.5)
        clearLines()
        cursorNode.alpha = 0
    }
}
