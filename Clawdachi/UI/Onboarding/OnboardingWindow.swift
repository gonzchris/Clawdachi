//
//  OnboardingWindow.swift
//  Clawdachi
//
//  Main onboarding window - terminal-style first-launch experience
//

import AppKit
import SpriteKit

/// Singleton window for the Clawdachi Onboarding experience
class OnboardingWindow: NSWindow {

    private typealias C = OnboardingConstants

    // MARK: - Singleton

    static let shared = OnboardingWindow()

    // MARK: - Properties

    private var contentViewContainer: OnboardingContentView!
    private var isShowing = false
    private var isCompletingOnboarding = false  // Prevent multiple completion attempts

    /// Callback when onboarding completes - passes the launch position
    var onComplete: ((CGPoint) -> Void)?

    // MARK: - Initialization

    private init() {
        super.init(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: C.windowWidth,
                height: C.windowHeight
            ),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        setupWindow()
        setupContentView()
        setupManager()
    }

    private func setupWindow() {
        isOpaque = false
        backgroundColor = .clear
        level = .floating  // Stay on top during onboarding
        hasShadow = true
        collectionBehavior = [.canJoinAllSpaces]
        isMovableByWindowBackground = false  // Drag handled by content view
    }

    private func setupContentView() {
        contentViewContainer = OnboardingContentView(frame: NSRect(
            x: 0,
            y: 0,
            width: C.windowWidth,
            height: C.windowHeight
        ))
        contentViewContainer.wantsLayer = true
        contentViewContainer.onboardingWindow = self
        contentView = contentViewContainer
    }

    private func setupManager() {
        // Set up completion handler
        OnboardingManager.shared.onComplete = { [weak self] position in
            self?.completeOnboarding(launchPosition: position)
        }
    }

    // MARK: - Window Behavior

    override var canBecomeKey: Bool {
        return true  // Allow keyboard events
    }

    override var canBecomeMain: Bool {
        return true  // Become main during onboarding
    }

    // MARK: - Show/Hide

    func show() {
        guard !isShowing else { return }
        isShowing = true
        isCompletingOnboarding = false  // Reset completion flag

        // Reset to first step
        OnboardingManager.shared.resetSteps()

        // Center on screen
        centerOnScreen()

        // Start with hidden state for animation
        alphaValue = 0
        setFrame(
            NSRect(
                origin: frame.origin,
                size: NSSize(width: C.windowWidth * C.initialScale, height: C.windowHeight * C.initialScale)
            ),
            display: false
        )

        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Animate in
        NSAnimationContext.runAnimationGroup { context in
            context.duration = C.fadeInDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().alphaValue = 1.0
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = C.scaleInDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().setFrame(
                NSRect(
                    origin: frame.origin,
                    size: NSSize(width: C.windowWidth, height: C.windowHeight)
                ),
                display: true
            )
        } completionHandler: { [weak self] in
            // Start boot sequence after window appears
            self?.contentViewContainer.startBootSequence()
        }
    }

    func hide(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard isShowing else {
            completion?()
            return
        }

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = C.fadeInDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                animator().alphaValue = 0
            } completionHandler: { [weak self] in
                self?.orderOut(nil)
                self?.isShowing = false
                completion?()
            }
        } else {
            orderOut(nil)
            isShowing = false
            completion?()
        }
    }

    // MARK: - Positioning

    private func centerOnScreen() {
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let centerX = screenFrame.midX - C.windowWidth / 2
            let centerY = screenFrame.midY - C.windowHeight / 2
            setFrameOrigin(NSPoint(x: centerX, y: centerY))
        } else {
            center()
        }
    }

    // MARK: - Launch Animation

    /// Complete onboarding with jump animation
    private func completeOnboarding(launchPosition: CGPoint) {
        // Prevent multiple calls
        guard !isCompletingOnboarding else { return }
        isCompletingOnboarding = true

        // Create the main window FIRST (prevents app from quitting when onboarding hides)
        onComplete?(launchPosition)

        // Get the sprite's current screen position from the preview
        let spriteScreenPosition = contentViewContainer.getSpriteScreenPosition()

        // Perform the jump animation
        animateJumpToPosition(
            from: spriteScreenPosition,
            to: launchPosition
        )
    }

    /// Animate the sprite jumping from the onboarding window to the desktop
    private func animateJumpToPosition(
        from startPosition: CGPoint,
        to endPosition: CGPoint
    ) {
        // Create a temporary window for the jumping sprite
        let jumpWindow = createJumpWindow(at: startPosition)
        jumpWindow.orderFront(nil)

        // Calculate bezier control point for arc trajectory
        let midX = (startPosition.x + endPosition.x) / 2
        let peakY = max(startPosition.y, endPosition.y) + 150  // Arc height

        // Fade out the onboarding window during jump
        NSAnimationContext.runAnimationGroup { context in
            context.duration = C.JumpAnimation.launchDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            animator().alphaValue = 0.3
        }

        // Phase 1: Anticipation (squash)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = C.JumpAnimation.anticipationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
        } completionHandler: {
            // Phase 2: Launch (arc)
            self.animateArc(
                window: jumpWindow,
                from: startPosition,
                controlPoint: CGPoint(x: midX, y: peakY),
                to: endPosition
            ) {
                // Phase 3: Land (squash and remove)
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = C.JumpAnimation.landDuration
                    context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                } completionHandler: {
                    jumpWindow.orderOut(nil)
                    self.hide(animated: false)
                }
            }
        }
    }

    /// Create a temporary floating window with the sprite for the jump animation
    private func createJumpWindow(at position: CGPoint) -> NSWindow {
        let spriteSize = CGSize(width: 288, height: 384)
        let window = NSWindow(
            contentRect: NSRect(origin: position, size: spriteSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.hasShadow = true

        // Create SpriteKit view with the character
        let skView = SKView(frame: NSRect(origin: .zero, size: spriteSize))
        skView.allowsTransparency = true

        let scene = SKScene(size: spriteSize)
        scene.backgroundColor = .clear
        scene.scaleMode = .aspectFit

        // Create and add the sprite
        let sprite = ClawdachiSprite()
        sprite.position = CGPoint(x: spriteSize.width / 2, y: spriteSize.height / 2 - 40)
        scene.addChild(sprite)

        skView.presentScene(scene)
        window.contentView = skView

        return window
    }

    /// Animate window along a bezier arc using Timer for reliability
    private func animateArc(
        window: NSWindow,
        from start: CGPoint,
        controlPoint: CGPoint,
        to end: CGPoint,
        completion: @escaping () -> Void
    ) {
        let duration = C.JumpAnimation.launchDuration
        let totalSteps = 30
        let stepDuration = duration / Double(totalSteps)
        var currentStep = 0

        func bezierPoint(t: CGFloat) -> CGPoint {
            let t2 = t * t
            let mt = 1 - t
            let mt2 = mt * mt

            let x = mt2 * start.x + 2 * mt * t * controlPoint.x + t2 * end.x
            let y = mt2 * start.y + 2 * mt * t * controlPoint.y + t2 * end.y
            return CGPoint(x: x, y: y)
        }

        // Use Timer for more reliable frame-by-frame animation
        Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { timer in
            if currentStep > totalSteps {
                timer.invalidate()
                completion()
                return
            }

            let t = CGFloat(currentStep) / CGFloat(totalSteps)
            let point = bezierPoint(t: t)
            window.setFrameOrigin(point)
            currentStep += 1
        }
    }

    // MARK: - Keyboard Handling

    override func keyDown(with event: NSEvent) {
        // Don't allow escape to close during onboarding
        // User must complete the flow
        super.keyDown(with: event)
    }

    // MARK: - Target Position

    /// Calculate the bottom-left corner position for sprite landing
    static func bottomLeftPosition() -> CGPoint {
        guard let screen = NSScreen.main else {
            return CGPoint(x: 50, y: 50)
        }

        let visibleFrame = screen.visibleFrame
        let padding: CGFloat = 20

        return CGPoint(
            x: visibleFrame.minX + padding,
            y: visibleFrame.minY + padding
        )
    }
}
