//
//  ChatBubbleWindow.swift
//  Clawdachi
//
//  Floating window that displays pixel-art chat bubbles above the sprite
//

import AppKit

/// A single chat bubble window (managed by ChatBubbleManager)
class ChatBubbleWindow: NSWindow {

    private typealias C = ChatBubbleConstants

    // MARK: - Properties

    private var bubbleView: ChatBubbleView!
    private weak var spriteWindow: NSWindow?
    private weak var manager: ChatBubbleManager?
    private var dismissTimer: Timer?
    private(set) var hasTail: Bool
    private var message: String

    // MARK: - Convenience API (uses manager)

    /// Show a chat bubble with the given message (convenience for single messages)
    static func show(
        message: String,
        relativeTo spriteWindow: NSWindow,
        duration: TimeInterval? = C.defaultAutoDismiss,
        completion: (() -> Void)? = nil
    ) {
        ChatBubbleManager.shared.showMessage(message, relativeTo: spriteWindow, duration: duration)
    }

    /// Dismiss all chat bubbles
    static func dismiss(animated: Bool = true) {
        ChatBubbleManager.shared.dismissAll(animated: animated)
    }

    /// Check if any bubble is currently visible
    static var isVisible: Bool {
        // Could track this in manager if needed
        false
    }

    // MARK: - Initialization

    init(message: String, spriteWindow: NSWindow, hasTail: Bool, manager: ChatBubbleManager) {
        self.hasTail = hasTail
        self.message = message

        // Create with zero frame initially - will resize based on content
        super.init(
            contentRect: .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        self.spriteWindow = spriteWindow
        self.manager = manager

        // Configure window properties
        isOpaque = false
        backgroundColor = .clear
        level = .floating
        hasShadow = false  // We draw our own pixel shadow
        collectionBehavior = [.canJoinAllSpaces, .stationary]
        ignoresMouseEvents = false  // Allow click to dismiss

        // Create and configure bubble view
        bubbleView = ChatBubbleView()
        bubbleView.wantsLayer = true
        bubbleView.configure(message: message, hasTail: hasTail)

        // Get the size before setting as content view
        let bubbleSize = bubbleView.frame.size

        // Set window size first, then set content view
        setContentSize(bubbleSize)
        contentView = bubbleView
        bubbleView.frame = NSRect(origin: .zero, size: bubbleSize)
    }

    // MARK: - Tail Management

    /// Add tail to this bubble (when it becomes the newest)
    func addTail() {
        guard !hasTail else { return }
        hasTail = true
        regenerateBubble()
    }

    /// Remove tail from this bubble (when a newer one is added)
    func removeTail() {
        guard hasTail else { return }
        hasTail = false
        regenerateBubble()
    }

    private func regenerateBubble() {
        bubbleView.configure(message: message, hasTail: hasTail)
        let bubbleSize = bubbleView.frame.size
        setContentSize(bubbleSize)
        bubbleView.frame = NSRect(origin: .zero, size: bubbleSize)
    }

    // MARK: - Animation

    func showWithAnimation() {
        // Start small and transparent
        alphaValue = 0
        bubbleView.layer?.setAffineTransform(
            CGAffineTransform(scaleX: C.popInInitialScale, y: C.popInInitialScale)
        )

        makeKeyAndOrderFront(nil)

        // Animate alpha
        NSAnimationContext.runAnimationGroup { context in
            context.duration = C.popInDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().alphaValue = 1.0
        }

        // Animate scale with overshoot
        NSAnimationContext.runAnimationGroup { context in
            context.duration = C.popInDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            bubbleView.layer?.setAffineTransform(
                CGAffineTransform(scaleX: C.popInOvershoot, y: C.popInOvershoot)
            )
        } completionHandler: { [weak self] in
            guard let self = self else { return }
            // Settle to final size
            NSAnimationContext.runAnimationGroup { context in
                context.duration = C.settleDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                self.bubbleView.layer?.setAffineTransform(.identity)
            }
        }
    }

    func dismissWithAnimation() {
        dismissTimer?.invalidate()
        dismissTimer = nil

        NSAnimationContext.runAnimationGroup { context in
            context.duration = C.fadeOutDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            animator().alphaValue = 0
        } completionHandler: { [weak self] in
            self?.cleanup()
        }
    }

    // MARK: - Auto-dismiss

    func scheduleAutoDismiss(after duration: TimeInterval) {
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.dismissWithAnimation()
        }
    }

    // MARK: - Click to Dismiss

    override func mouseDown(with event: NSEvent) {
        dismissWithAnimation()
    }

    // MARK: - Cleanup

    func cleanup() {
        dismissTimer?.invalidate()
        dismissTimer = nil

        orderOut(nil)

        // Notify manager
        manager?.bubbleWasDismissed(self)
    }
}
