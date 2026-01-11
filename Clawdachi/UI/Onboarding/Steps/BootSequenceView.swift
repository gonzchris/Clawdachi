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
    private var greetingLabel: NSTextField!
    private var readyButton: NSButton!

    // Bottom bar elements (only shown in boot view)
    private var versionLabel: NSTextField!
    private var disclaimerLabel: NSTextField!

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
        setupGreeting()
        setupReadyButton()
        setupBottomBarElements()
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
        let containerSize: CGFloat = 50  // Container size for the sprite
        let spriteY = (bounds.height - 180) / 2 + 105  // Below logo

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
        let sceneSize: CGFloat = 32
        spriteScene = SKScene(size: CGSize(width: sceneSize, height: sceneSize))
        spriteScene.backgroundColor = .clear
        spriteScene.scaleMode = .aspectFit

        // Create the actual sprite
        miniSprite = ClawdachiSprite()
        miniSprite.position = CGPoint(x: sceneSize / 2, y: sceneSize / 2 - 2)
        spriteScene.addChild(miniSprite)

        skView.presentScene(spriteScene)
    }

    private func setupGreeting() {
        let greeting = ClawdachiMessages.greetingForCurrentTime()
        greetingLabel = NSTextField(labelWithString: greeting)

        // Position above the sprite's head
        let spriteY = (bounds.height - 180) / 2 + 105
        greetingLabel.frame = NSRect(
            x: 0,
            y: spriteY - 18,  // Above the sprite
            width: bounds.width,
            height: 18
        )
        greetingLabel.font = NSFont.monospacedSystemFont(ofSize: C.terminalFontSize, weight: .bold)
        greetingLabel.textColor = C.accentColor
        greetingLabel.alignment = .center
        greetingLabel.alphaValue = 0

        // Phosphor glow effect
        greetingLabel.wantsLayer = true
        greetingLabel.layer?.shadowColor = C.accentColor.cgColor
        greetingLabel.layer?.shadowOffset = .zero
        greetingLabel.layer?.shadowRadius = 6
        greetingLabel.layer?.shadowOpacity = 0.5

        addSubview(greetingLabel)
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

    private func setupBottomBarElements() {
        // Version label - centered in bottom bar
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        versionLabel = NSTextField(labelWithString: "v\(version)")
        versionLabel.frame = NSRect(
            x: 0,
            y: bounds.height + 6,
            width: bounds.width,
            height: 16
        )
        versionLabel.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        versionLabel.textColor = C.textDimColor
        versionLabel.alignment = .center
        versionLabel.alphaValue = 0
        addSubview(versionLabel)

        // Disclaimer - small text below version
        disclaimerLabel = NSTextField(labelWithString: "Not affiliated with Anthropic")
        disclaimerLabel.frame = NSRect(
            x: 0,
            y: bounds.height + 22,
            width: bounds.width,
            height: 14
        )
        disclaimerLabel.font = NSFont.monospacedSystemFont(ofSize: 9, weight: .regular)
        disclaimerLabel.textColor = C.textDimColor.withAlphaComponent(0.6)
        disclaimerLabel.alignment = .center
        disclaimerLabel.alphaValue = 0
        addSubview(disclaimerLabel)
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
        spriteContainer.alphaValue = 0
        greetingLabel.alphaValue = 0
        readyButton.alphaValue = 0
        versionLabel.alphaValue = 0
        disclaimerLabel.alphaValue = 0

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
        // Start sprite animations and fade in sprite + greeting together
        miniSprite?.regenerateTextures()
        miniSprite?.startAnimations()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            spriteContainer.animator().alphaValue = 1.0
            greetingLabel.animator().alphaValue = 1.0
        }

        // Fade in bottom bar elements
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                self?.versionLabel.animator().alphaValue = 1.0
                self?.disclaimerLabel.animator().alphaValue = 1.0
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

}
