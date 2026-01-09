//
//  SettingsWindow.swift
//  Clawdachi
//
//  Settings window with sidebar navigation
//

import AppKit
import SpriteKit

/// Singleton window for the Clawdachi Settings UI
class SettingsWindow: NSWindow {

    private typealias C = SettingsConstants

    // MARK: - Singleton

    static let shared = SettingsWindow()

    // MARK: - Properties

    private var contentViewContainer: SettingsContentView!
    private weak var spriteWindow: NSWindow?
    private var isShowing = false

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
        setupDragging()
    }

    private func setupWindow() {
        isOpaque = false
        backgroundColor = .clear
        level = .floating
        hasShadow = true
        collectionBehavior = [.canJoinAllSpaces, .stationary]
        isMovableByWindowBackground = true
    }

    private func setupContentView() {
        contentViewContainer = SettingsContentView(frame: NSRect(
            x: 0,
            y: 0,
            width: C.windowWidth,
            height: C.windowHeight
        ))
        contentViewContainer.wantsLayer = true
        contentViewContainer.settingsWindow = self
        contentView = contentViewContainer
    }

    private func setupDragging() {
        // Window is movable by dragging the title bar area
        isMovableByWindowBackground = false  // We'll handle this ourselves

        // Register for tracking in the content view
        contentViewContainer.setupDragTracking()
    }

    // MARK: - Window Behavior

    override var canBecomeKey: Bool {
        return true  // Allow keyboard events
    }

    override var canBecomeMain: Bool {
        return false  // Don't become main window
    }

    // MARK: - Show/Hide

    func show(relativeTo spriteWindow: NSWindow) {
        guard !isShowing else { return }
        isShowing = true
        self.spriteWindow = spriteWindow

        // Position relative to sprite window
        positionRelativeToSprite()

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
        }

        // Start the preview sprite animation
        contentViewContainer.startPreviewAnimation()
    }

    func hide(animated: Bool = true) {
        guard isShowing else { return }

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = C.fadeInDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                animator().alphaValue = 0
            } completionHandler: { [weak self] in
                self?.orderOut(nil)
                self?.isShowing = false
                self?.contentViewContainer.stopPreviewAnimation()
            }
        } else {
            orderOut(nil)
            isShowing = false
            contentViewContainer.stopPreviewAnimation()
        }
    }

    func toggle(relativeTo spriteWindow: NSWindow) {
        if isShowing {
            hide()
        } else {
            show(relativeTo: spriteWindow)
        }
    }

    // MARK: - Positioning

    private func positionRelativeToSprite() {
        guard let spriteWindow = spriteWindow else { return }

        // Position to the right of the sprite, centered vertically
        let spriteFrame = spriteWindow.frame
        let settingsX = spriteFrame.maxX + 20
        let settingsY = spriteFrame.midY - C.windowHeight / 2

        // Ensure on screen
        if let screen = spriteWindow.screen ?? NSScreen.main {
            let screenFrame = screen.visibleFrame
            var finalX = settingsX
            var finalY = settingsY

            // Adjust if off right edge
            if finalX + C.windowWidth > screenFrame.maxX {
                finalX = spriteFrame.minX - C.windowWidth - 20
            }

            // Adjust if off left edge
            if finalX < screenFrame.minX {
                finalX = screenFrame.minX + 20
            }

            // Adjust if off top
            if finalY + C.windowHeight > screenFrame.maxY {
                finalY = screenFrame.maxY - C.windowHeight - 20
            }

            // Adjust if off bottom
            if finalY < screenFrame.minY {
                finalY = screenFrame.minY + 20
            }

            setFrameOrigin(NSPoint(x: finalX, y: finalY))
        } else {
            setFrameOrigin(NSPoint(x: settingsX, y: settingsY))
        }
    }

    // MARK: - Keyboard Handling

    override func keyDown(with event: NSEvent) {
        // Close on Escape
        if event.keyCode == 53 {  // Escape key
            hide()
            return
        }
        super.keyDown(with: event)
    }

    // MARK: - Close Button Handler

    func closeButtonClicked() {
        hide()
    }
}

// MARK: - Window Delegate Conformance

extension SettingsWindow: NSWindowDelegate {
    func windowDidResignKey(_ notification: Notification) {
        // Optionally hide when losing focus
        // hide()
    }
}
