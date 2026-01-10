//
//  LaunchView.swift
//  Clawdachi
//
//  Final onboarding step - ready to launch with jump animation
//

import AppKit
import SpriteKit

/// Delegate for launch button events
protocol LaunchViewDelegate: AnyObject {
    func launchButtonClicked()
}

/// Final launch screen with animated preview and launch button
class LaunchView: NSView {

    private typealias C = OnboardingConstants
    private typealias SC = SettingsConstants

    // MARK: - Properties

    weak var delegate: LaunchViewDelegate?

    private var titleLabel: NSTextField!
    private var subtitleLabel: NSTextField!
    private var previewContainer: NSView!
    private var skView: SKView!
    private var previewScene: SKScene!
    private var previewSprite: ClawdachiSprite!
    private var launchButton: NSView!

    private var isButtonHovered = false
    private var hasLaunched = false  // Prevent multiple launch clicks

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

        setupTitle()
        setupPreview()
        setupSubtitle()
        setupLaunchButton()
    }

    override var isFlipped: Bool { true }

    // MARK: - UI Setup

    private func setupTitle() {
        titleLabel = NSTextField(labelWithString: "READY TO LAUNCH!")
        titleLabel.frame = NSRect(
            x: 0,
            y: C.panelPadding + 10,
            width: bounds.width,
            height: 30
        )
        titleLabel.font = NSFont.monospacedSystemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = C.accentColor
        titleLabel.alignment = .center
        addSubview(titleLabel)
    }

    private func setupPreview() {
        // Large centered preview
        let previewSize: CGFloat = 200
        let previewX = (bounds.width - previewSize) / 2
        let previewY: CGFloat = 60

        previewContainer = NSView(frame: NSRect(
            x: previewX,
            y: previewY,
            width: previewSize,
            height: previewSize
        ))
        previewContainer.wantsLayer = true
        previewContainer.layer?.backgroundColor = SC.cellBackgroundColor.cgColor
        previewContainer.layer?.cornerRadius = 8
        previewContainer.layer?.borderWidth = 2
        previewContainer.layer?.borderColor = SC.frameColor.cgColor
        addSubview(previewContainer)

        // SpriteKit view
        skView = SKView(frame: NSRect(x: 0, y: 0, width: previewSize, height: previewSize))
        skView.allowsTransparency = true
        previewContainer.addSubview(skView)

        // Create square scene to match container (avoids black letterboxing)
        let sceneSize: CGFloat = 45
        previewScene = SKScene(size: CGSize(width: sceneSize, height: sceneSize))
        previewScene.backgroundColor = .clear
        previewScene.scaleMode = .aspectFit

        // Create sprite centered in scene (slightly lower to show full body)
        previewSprite = ClawdachiSprite()
        previewSprite.position = CGPoint(x: sceneSize / 2, y: sceneSize / 2 - 2)
        previewScene.addChild(previewSprite)

        skView.presentScene(previewScene)
    }

    private func setupSubtitle() {
        let text = "Your Clawdachi is ready to join your desktop!"
        subtitleLabel = NSTextField(labelWithString: text)
        subtitleLabel.frame = NSRect(
            x: 0,
            y: 275,
            width: bounds.width,
            height: 24
        )
        subtitleLabel.font = NSFont.monospacedSystemFont(ofSize: C.terminalFontSize, weight: .regular)
        subtitleLabel.textColor = C.textColor
        subtitleLabel.alignment = .center
        addSubview(subtitleLabel)
    }

    private func setupLaunchButton() {
        // Large centered launch button
        let buttonWidth: CGFloat = 200
        let buttonHeight: CGFloat = 44
        let buttonX = (bounds.width - buttonWidth) / 2
        let buttonY: CGFloat = 320

        launchButton = NSView(frame: NSRect(
            x: buttonX,
            y: buttonY,
            width: buttonWidth,
            height: buttonHeight
        ))
        launchButton.wantsLayer = true
        launchButton.layer?.backgroundColor = SC.panelColor.cgColor
        launchButton.layer?.cornerRadius = 6
        launchButton.layer?.borderWidth = 2
        launchButton.layer?.borderColor = C.accentColor.cgColor
        addSubview(launchButton)

        // Button label
        let buttonLabel = NSTextField(labelWithString: "LAUNCH")
        buttonLabel.frame = NSRect(
            x: 0,
            y: (buttonHeight - 20) / 2,
            width: buttonWidth,
            height: 20
        )
        buttonLabel.font = NSFont.monospacedSystemFont(ofSize: 16, weight: .bold)
        buttonLabel.textColor = C.accentColor
        buttonLabel.alignment = .center
        buttonLabel.tag = 100
        launchButton.addSubview(buttonLabel)

        // Track mouse
        let trackingArea = NSTrackingArea(
            rect: launchButton.bounds,
            options: [.activeAlways, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        )
        launchButton.addTrackingArea(trackingArea)
    }

    // MARK: - Mouse Handling

    override func mouseEntered(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        if launchButton.frame.contains(location) {
            isButtonHovered = true
            animateButtonHover(hovered: true)
        }
    }

    override func mouseExited(with event: NSEvent) {
        isButtonHovered = false
        animateButtonHover(hovered: false)
    }

    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        if launchButton.frame.contains(location) {
            launchButton.alphaValue = 0.8
        }
    }

    override func mouseUp(with event: NSEvent) {
        launchButton.alphaValue = 1.0
        let location = convert(event.locationInWindow, from: nil)
        if launchButton.frame.contains(location) && !hasLaunched {
            hasLaunched = true  // Prevent double-clicks
            delegate?.launchButtonClicked()
        }
    }

    private func animateButtonHover(hovered: Bool) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.1
            if hovered {
                launchButton.animator().layer?.backgroundColor = C.accentColor.withAlphaComponent(0.2).cgColor
                if let label = launchButton.viewWithTag(100) as? NSTextField {
                    label.animator().textColor = NSColor.white
                }
            } else {
                launchButton.animator().layer?.backgroundColor = SC.panelColor.cgColor
                if let label = launchButton.viewWithTag(100) as? NSTextField {
                    label.animator().textColor = C.accentColor
                }
            }
        }
    }

    // MARK: - Animation

    func startPreview() {
        // Reset launch state when view becomes active again
        hasLaunched = false
        // Regenerate textures to pick up any color changes from customize step
        previewSprite?.regenerateTextures()
        // Start idle animation
        previewSprite?.startAnimations()
    }

    func stopPreview() {
        previewSprite?.removeAllActions()
    }

    // MARK: - Position

    /// Get the sprite's position within this view (for jump animation)
    func getSpritePosition() -> CGPoint {
        guard let container = previewContainer else { return .zero }
        return CGPoint(
            x: container.frame.midX,
            y: bounds.height - container.frame.midY  // Flip Y for screen coords
        )
    }
}
