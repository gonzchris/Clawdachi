//
//  ChatBubbleManager.swift
//  Clawdachi
//
//  Manages a queue of stacking chat bubbles (RPG-style)
//

import AppKit

/// Manages multiple stacking chat bubbles with RPG-style scrolling
class ChatBubbleManager {

    private typealias C = ChatBubbleConstants

    // MARK: - Singleton

    static let shared = ChatBubbleManager()
    private init() {}

    // MARK: - Properties

    /// Maximum number of visible bubbles
    private let maxBubbles = 4

    /// Spacing between stacked bubbles
    private let bubbleSpacing: CGFloat = 2

    /// Active bubble windows (oldest first, newest last)
    private var bubbles: [ChatBubbleWindow] = []

    /// Pool of reusable bubble windows (reduces allocation overhead)
    private var windowPool: [ChatBubbleWindow] = []

    /// Maximum pool size
    private let maxPoolSize = 6

    /// Reference to sprite window for positioning
    private weak var spriteWindow: NSWindow?

    /// Current vertical offset override (nil = use default)
    private var currentVerticalOffset: CGFloat?

    /// Current horizontal offset override (nil = use default)
    private var currentHorizontalOffset: CGFloat?

    // MARK: - Public API

    /// Show a new chat message
    /// - Parameters:
    ///   - message: Text to display
    ///   - spriteWindow: The sprite window to position relative to
    ///   - duration: Auto-dismiss duration (nil = no auto-dismiss)
    ///   - verticalOffset: Custom vertical offset (nil = use default)
    ///   - horizontalOffset: Custom horizontal offset (nil = use default, positive = right)
    func showMessage(_ message: String, relativeTo spriteWindow: NSWindow, duration: TimeInterval? = C.defaultAutoDismiss, verticalOffset: CGFloat? = nil, horizontalOffset: CGFloat? = nil) {
        self.spriteWindow = spriteWindow
        self.currentVerticalOffset = verticalOffset
        self.currentHorizontalOffset = horizontalOffset

        // Remove oldest if at max capacity
        if bubbles.count >= maxBubbles {
            dismissOldest(animated: true)
        }

        // Update existing bubbles: remove tail from current newest
        if let currentNewest = bubbles.last {
            currentNewest.removeTail()
        }

        // Slide existing bubbles up
        slideExistingBubblesUp()

        // Get bubble from pool or create new one
        let newBubble = acquireBubble(message: message, spriteWindow: spriteWindow, hasTail: true)

        bubbles.append(newBubble)
        positionBubble(newBubble, at: 0)
        newBubble.showWithAnimation()

        // Schedule auto-dismiss
        if let duration = duration {
            newBubble.scheduleAutoDismiss(after: duration)
        }
    }

    // MARK: - Window Pool

    /// Acquire a bubble window from the pool or create a new one
    private func acquireBubble(message: String, spriteWindow: NSWindow, hasTail: Bool) -> ChatBubbleWindow {
        if let pooledWindow = windowPool.popLast() {
            // Reconfigure the pooled window
            pooledWindow.reconfigure(message: message, spriteWindow: spriteWindow, hasTail: hasTail, manager: self)
            return pooledWindow
        }
        // Create new window if pool is empty
        return ChatBubbleWindow(
            message: message,
            spriteWindow: spriteWindow,
            hasTail: hasTail,
            manager: self
        )
    }

    /// Return a bubble window to the pool for reuse
    func returnToPool(_ bubble: ChatBubbleWindow) {
        if windowPool.count < maxPoolSize {
            windowPool.append(bubble)
        }
        // Otherwise, let the window be deallocated
    }

    /// Dismiss all bubbles
    func dismissAll(animated: Bool = true) {
        let bubblesToDismiss = bubbles
        bubbles.removeAll()

        for bubble in bubblesToDismiss {
            if animated {
                bubble.dismissWithAnimation()
            } else {
                bubble.cleanup()
            }
        }
    }

    /// Called by a bubble when it's dismissed
    func bubbleWasDismissed(_ bubble: ChatBubbleWindow) {
        guard let index = bubbles.firstIndex(where: { $0 === bubble }) else { return }
        bubbles.remove(at: index)

        // Reposition remaining bubbles and update tail
        repositionAllBubbles()
    }

    // MARK: - Positioning

    /// Standard height for stacking calculations (bubble without tail)
    private let standardBubbleHeight: CGFloat = 46

    /// Calculate X position for bubbles (centered above sprite, with optional offset)
    /// - Parameter bubble: The bubble window to position
    private func calculateBubbleX(for bubble: ChatBubbleWindow) -> CGFloat {
        guard let parent = spriteWindow else { return 0 }
        let spriteWindowCenter = parent.frame.origin.x + parent.frame.width / 2
        let horizontalOffset = currentHorizontalOffset ?? C.horizontalOffset
        // Center the bubble horizontally, then apply offset
        let bubbleWidth = bubble.frame.width
        return spriteWindowCenter + horizontalOffset - bubbleWidth / 2
    }

    /// Calculate Y position for a given stack index
    private func calculateBubbleY(stackIndex: Int) -> CGFloat {
        guard let parent = spriteWindow else { return 0 }
        let verticalOffset = currentVerticalOffset ?? C.verticalOffsetNoHat
        let baseY = parent.frame.origin.y + 144 + verticalOffset

        if stackIndex == 0 {
            // Bottom bubble sits at base
            return baseY
        } else {
            // Bubbles above stack with spacing (tail is on side, not bottom)
            let firstOffset = standardBubbleHeight + bubbleSpacing
            let additionalOffset = CGFloat(stackIndex - 1) * (standardBubbleHeight + bubbleSpacing)
            return baseY + firstOffset + additionalOffset
        }
    }

    /// Position a bubble at the given stack index (0 = bottom/newest)
    private func positionBubble(_ bubble: ChatBubbleWindow, at stackIndex: Int) {
        let bubbleX = calculateBubbleX(for: bubble)
        let bubbleY = calculateBubbleY(stackIndex: stackIndex)
        bubble.setFrameOrigin(CGPoint(x: bubbleX, y: bubbleY))
    }

    /// Slide existing bubbles up to make room for new one
    private func slideExistingBubblesUp() {
        // bubbles array is oldest-first, newest-last
        // When adding a new one, each existing bubble needs to move up one slot
        for (index, bubble) in bubbles.enumerated() {
            // Current position is (bubbles.count - 1 - index), new position is one higher
            let newStackIndex = bubbles.count - index  // One higher than current
            animateBubbleToPosition(bubble, stackIndex: newStackIndex)
        }
    }

    /// Reposition all bubbles after one is dismissed
    private func repositionAllBubbles() {
        // Update tail: only newest (last) bubble should have tail
        for (index, bubble) in bubbles.enumerated() {
            let isNewest = index == bubbles.count - 1
            if isNewest && !bubble.hasTail {
                bubble.addTail()
            } else if !isNewest && bubble.hasTail {
                bubble.removeTail()
            }

            // Animate to new position (newest at 0, oldest at count-1)
            let stackIndex = bubbles.count - 1 - index
            animateBubbleToPosition(bubble, stackIndex: stackIndex)
        }
    }

    /// Animate a bubble to a new stack position
    private func animateBubbleToPosition(_ bubble: ChatBubbleWindow, stackIndex: Int) {
        let bubbleX = calculateBubbleX(for: bubble)
        let targetY = calculateBubbleY(stackIndex: stackIndex)
        let targetOrigin = CGPoint(x: bubbleX, y: targetY)

        // Use setFrame with current size for reliable animation
        let targetFrame = NSRect(origin: targetOrigin, size: bubble.frame.size)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            context.allowsImplicitAnimation = true
            bubble.animator().setFrame(targetFrame, display: true)
        }
    }

    /// Dismiss the oldest bubble
    private func dismissOldest(animated: Bool) {
        guard let oldest = bubbles.first else { return }
        bubbles.removeFirst()

        if animated {
            oldest.dismissWithAnimation()
        } else {
            oldest.cleanup()
        }
    }
}
