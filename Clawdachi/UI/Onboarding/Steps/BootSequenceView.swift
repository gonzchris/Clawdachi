//
//  BootSequenceView.swift
//  Clawdachi
//
//  Boot sequence animation - ASCII logo reveal
//

import AppKit
import SpriteKit

/// Delegate for boot sequence completion
protocol BootSequenceViewDelegate: AnyObject {
    func bootSequenceDidComplete()
    func bootSequenceNextClicked()
}

/// Boot sequence view with ASCII logo reveal
class BootSequenceView: NSView {

    private typealias C = OnboardingConstants

    // MARK: - Properties

    weak var delegate: BootSequenceViewDelegate?

    private var logoLabel: NSTextField!
    private var spriteContainer: NSView!
    private var skView: SKView!
    private var spriteScene: SKScene!
    private var miniSprite: ClawdachiSprite!
    private var versionLabel: NSTextField!
    private var readyButton: NSButton!

    private var isAnimating = false
    private var currentLogoLine = 0

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        wantsLayer = true

        setupLogo()
        setupMiniSprite()
        setupVersion()
        setupReadyButton()
    }

    override var isFlipped: Bool { true }

    // MARK: - UI Setup

    private func setupLogo() {
        logoLabel = NSTextField(labelWithString: "")
        // Larger font, centered in the view
        let logoFontSize: CGFloat = 12  // Bigger logo
        let logoHeight: CGFloat = 180
        let logoY = (bounds.height - logoHeight) / 2 - 20  // Centered

        logoLabel.frame = NSRect(
            x: 0,
            y: logoY,
            width: bounds.width,
            height: logoHeight
        )
        logoLabel.font = NSFont.monospacedSystemFont(ofSize: logoFontSize, weight: .regular)
        logoLabel.textColor = C.accentColor
        logoLabel.alignment = .center
        logoLabel.maximumNumberOfLines = 6
        logoLabel.lineBreakMode = .byClipping
        logoLabel.alphaValue = 0

        // Add phosphor glow effect
        logoLabel.wantsLayer = true
        logoLabel.layer?.shadowColor = C.accentColor.cgColor
        logoLabel.layer?.shadowOffset = .zero
        logoLabel.layer?.shadowRadius = 8
        logoLabel.layer?.shadowOpacity = 0.6

        addSubview(logoLabel)
    }

    private func setupMiniSprite() {
        let containerSize: CGFloat = 64  // Container size for the sprite
        let spriteY = (bounds.height - 180) / 2 + 138  // Below logo

        // Container view
        spriteContainer = NSView(frame: NSRect(
            x: (bounds.width - containerSize) / 2,
            y: spriteY,
            width: containerSize,
            height: containerSize
        ))
        spriteContainer.wantsLayer = true
        spriteContainer.alphaValue = 0
        addSubview(spriteContainer)

        // SpriteKit view
        skView = SKView(frame: NSRect(x: 0, y: 0, width: containerSize, height: containerSize))
        skView.allowsTransparency = true
        spriteContainer.addSubview(skView)

        // Create scene
        let sceneSize: CGFloat = 40
        spriteScene = SKScene(size: CGSize(width: sceneSize, height: sceneSize))
        spriteScene.backgroundColor = .clear
        spriteScene.scaleMode = .aspectFit

        // Create the actual sprite
        miniSprite = ClawdachiSprite()
        miniSprite.position = CGPoint(x: sceneSize / 2, y: sceneSize / 2 - 2)
        spriteScene.addChild(miniSprite)

        skView.presentScene(spriteScene)
    }

    private func setupVersion() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        versionLabel = NSTextField(labelWithString: "v\(version)")
        versionLabel.frame = NSRect(
            x: 0,
            y: (bounds.height - 180) / 2 + 190,  // Below the mini sprite
            width: bounds.width,
            height: 20
        )
        versionLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        versionLabel.textColor = C.textDimColor
        versionLabel.alignment = .center
        versionLabel.alphaValue = 0

        // Subtle phosphor glow
        versionLabel.wantsLayer = true
        versionLabel.layer?.shadowColor = C.textDimColor.cgColor
        versionLabel.layer?.shadowOffset = .zero
        versionLabel.layer?.shadowRadius = 4
        versionLabel.layer?.shadowOpacity = 0.4

        addSubview(versionLabel)
    }

    private func setupReadyButton() {
        readyButton = NSButton(frame: NSRect(
            x: (bounds.width - 250) / 2,
            y: bounds.height - 80,
            width: 250,
            height: 24
        ))
        readyButton.title = "> CLICK HERE TO CONTINUE"
        readyButton.bezelStyle = .inline
        readyButton.isBordered = false
        readyButton.font = NSFont.monospacedSystemFont(ofSize: C.terminalFontSize, weight: .bold)
        readyButton.contentTintColor = C.accentColor
        readyButton.target = self
        readyButton.action = #selector(readyButtonClicked)
        readyButton.alphaValue = 0

        // Phosphor glow effect
        readyButton.wantsLayer = true
        readyButton.layer?.shadowColor = C.accentColor.cgColor
        readyButton.layer?.shadowOffset = .zero
        readyButton.layer?.shadowRadius = 6
        readyButton.layer?.shadowOpacity = 0.5

        // Add hover effect via tracking area
        let trackingArea = NSTrackingArea(
            rect: readyButton.bounds,
            options: [.activeAlways, .mouseEnteredAndExited],
            owner: self,
            userInfo: ["button": "ready"]
        )
        readyButton.addTrackingArea(trackingArea)

        addSubview(readyButton)
    }

    // MARK: - Mouse Handling

    override func mouseEntered(with event: NSEvent) {
        if let userInfo = event.trackingArea?.userInfo as? [String: String],
           userInfo["button"] == "ready" {
            NSCursor.pointingHand.set()
            readyButton.contentTintColor = NSColor.white
        }
    }

    override func mouseExited(with event: NSEvent) {
        if let userInfo = event.trackingArea?.userInfo as? [String: String],
           userInfo["button"] == "ready" {
            NSCursor.arrow.set()
            readyButton.contentTintColor = C.accentColor
        }
    }

    // MARK: - Actions

    @objc private func readyButtonClicked() {
        delegate?.bootSequenceNextClicked()
    }

    // MARK: - Animation

    /// Start the boot sequence animation
    func startAnimation() {
        guard !isAnimating else { return }
        isAnimating = true

        // Play startup sound (slight delay to avoid audio clip)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            SoundManager.shared.playStartupSound()
        }

        // Reset state
        currentLogoLine = 0
        logoLabel.stringValue = ""
        logoLabel.alphaValue = 0
        miniSpriteView.alphaValue = 0
        versionLabel.alphaValue = 0
        readyButton.alphaValue = 0

        // Start showing logo
        showNextLogoLine()
    }

    /// Stop animation
    func stopAnimation() {
        isAnimating = false
    }

    private func showNextLogoLine() {
        guard isAnimating else { return }

        let logoLines = C.asciiLogo.components(separatedBy: "\n")

        if currentLogoLine < logoLines.count {
            // Build logo text progressively
            let visibleLines = logoLines.prefix(currentLogoLine + 1).joined(separator: "\n")
            logoLabel.stringValue = visibleLines

            // Fade in logo if first line
            if currentLogoLine == 0 {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.1
                    logoLabel.animator().alphaValue = 1.0
                }
            }

            currentLogoLine += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + C.BootAnimation.logoLineDelay) { [weak self] in
                self?.showNextLogoLine()
            }
        } else {
            // Logo complete, show version then ready message
            finishAnimation()
        }
    }

    private func finishAnimation() {
        // Fade in mini sprite
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            miniSpriteView.animator().alphaValue = 1.0
        }

        // Fade in version after sprite
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                self?.versionLabel.animator().alphaValue = 1.0
            }
        }

        // Show ready button after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.showReadyButton()
        }
    }

    private func showReadyButton() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            readyButton.animator().alphaValue = 1.0
        } completionHandler: { [weak self] in
            self?.isAnimating = false
            self?.delegate?.bootSequenceDidComplete()
        }
    }

    // MARK: - Mini Sprite Generation

    /// Generates a mini static sprite image for the boot sequence
    private func generateMiniSpriteImage(size: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            NSColor.clear.setFill()
            rect.fill()

            // Pixel scale (size / sprite logical size of ~24 pixels)
            let pixelSize = size / 24

            // Colors matching ClawdachiPalette (hardcoded for boot sequence)
            let primaryOrange = NSColor(red: 255/255, green: 153/255, blue: 51/255, alpha: 1.0)
            let shadowOrange = NSColor(red: 204/255, green: 102/255, blue: 0/255, alpha: 1.0)
            let highlightOrange = NSColor(red: 255/255, green: 187/255, blue: 119/255, alpha: 1.0)
            let eyeColor = NSColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0)

            // Helper to draw a pixel
            func drawPixel(x: Int, y: Int, color: NSColor) {
                color.setFill()
                CGRect(
                    x: CGFloat(x) * pixelSize,
                    y: CGFloat(y) * pixelSize,
                    width: pixelSize,
                    height: pixelSize
                ).fill()
            }

            // Body (centered blob, rows 4-16, centered around x=12)
            let bodyWidth = 9  // Half-width
            for row in 4...16 {
                var width = bodyWidth
                // Round corners at top and bottom
                if row == 4 || row == 16 {
                    width = bodyWidth - 1
                }

                let left = 12 - width
                let right = 12 + width - 1

                for x in left...right {
                    // Left edge shadow
                    if x < left + 2 {
                        drawPixel(x: x, y: row, color: shadowOrange)
                    }
                    // Right edge highlight
                    else if x > right - 2 {
                        drawPixel(x: x, y: row, color: highlightOrange)
                    }
                    // Top highlight
                    else if row >= 15 {
                        drawPixel(x: x, y: row, color: highlightOrange)
                    }
                    // Bottom shadow
                    else if row == 4 {
                        drawPixel(x: x, y: row, color: shadowOrange)
                    }
                    // Main body
                    else {
                        drawPixel(x: x, y: row, color: primaryOrange)
                    }
                }
            }

            // Left arm (3x2, attached at left side)
            for row in 9...10 {
                drawPixel(x: 1, y: row, color: shadowOrange)
                drawPixel(x: 2, y: row, color: primaryOrange)
                drawPixel(x: 3, y: row, color: primaryOrange)
            }

            // Right arm (3x2, attached at right side)
            for row in 9...10 {
                drawPixel(x: 20, y: row, color: primaryOrange)
                drawPixel(x: 21, y: row, color: primaryOrange)
                drawPixel(x: 22, y: row, color: highlightOrange)
            }

            // Left leg (2x4)
            for row in 0...3 {
                if row == 0 {
                    drawPixel(x: 7, y: row, color: shadowOrange)
                    drawPixel(x: 8, y: row, color: shadowOrange)
                } else {
                    drawPixel(x: 7, y: row, color: shadowOrange)
                    drawPixel(x: 8, y: row, color: primaryOrange)
                }
            }

            // Right leg (2x4)
            for row in 0...3 {
                if row == 0 {
                    drawPixel(x: 15, y: row, color: shadowOrange)
                    drawPixel(x: 16, y: row, color: shadowOrange)
                } else {
                    drawPixel(x: 15, y: row, color: primaryOrange)
                    drawPixel(x: 16, y: row, color: highlightOrange)
                }
            }

            // Eyes (3x3 each, positioned in upper body)
            // Left eye
            for row in 11...13 {
                for x in 8...10 {
                    drawPixel(x: x, y: row, color: eyeColor)
                }
            }
            // Right eye
            for row in 11...13 {
                for x in 13...15 {
                    drawPixel(x: x, y: row, color: eyeColor)
                }
            }

            return true
        }

        return image
    }
}
