//
//  ChatBubbleConstants.swift
//  Clawdachi
//
//  Constants for the chat bubble system
//

import Foundation
import AppKit

/// Chat bubble constants for sizing, colors, and timing
enum ChatBubbleConstants {

    // MARK: - Sizing

    /// Minimum bubble width
    static let minWidth: CGFloat = 60

    /// Maximum bubble width
    static let maxWidth: CGFloat = 200

    /// Horizontal padding inside bubble
    static let paddingHorizontal: CGFloat = 12

    /// Vertical padding inside bubble (slightly taller)
    static let paddingVertical: CGFloat = 10

    /// Height of the pointing tail
    static let tailHeight: CGFloat = 8

    /// Width of the tail at its base
    static let tailWidth: CGFloat = 12

    /// Pixel size for drawing (controls pixelation level)
    static let pixelSize: CGFloat = 2

    /// Corner radius in pixel units
    static let cornerPixels: Int = 3

    /// Outline thickness in pixel units
    static let outlinePixels: Int = 1

    /// Shadow offset in pixel units (left and bottom)
    static let shadowPixels: Int = 2

    // MARK: - Colors

    /// White fill for bubble interior
    static let fillColor = NSColor.white

    /// Black outline
    static let outlineColor = NSColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0)

    /// Gray shadow (left/bottom edges)
    static let shadowColor = NSColor(red: 140/255, green: 140/255, blue: 140/255, alpha: 1.0)

    // MARK: - Text

    /// Font size for bubble text
    static let fontSize: CGFloat = 14

    /// Text color
    static let textColor = NSColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0)

    /// Line spacing for multi-line text
    static let lineSpacing: CGFloat = 2

    // MARK: - Animation Timings

    /// Pop-in animation duration
    static let popInDuration: TimeInterval = 0.15

    /// Settle animation duration (after overshoot)
    static let settleDuration: TimeInterval = 0.075

    /// Fade-out animation duration
    static let fadeOutDuration: TimeInterval = 0.2

    /// Default auto-dismiss duration
    static let defaultAutoDismiss: TimeInterval = 5.0

    /// Scale overshoot during pop-in
    static let popInOvershoot: CGFloat = 1.1

    /// Initial scale for pop-in
    static let popInInitialScale: CGFloat = 0.3

    // MARK: - Positioning

    /// Vertical offset from sprite center (in screen points)
    /// Sprite is at (24, 24) in scene coords * 6x scale = (144, 144) in window
    /// Bubble appears above sprite's head
    static let verticalOffsetFromSpriteCenter: CGFloat = 70

    /// Horizontal offset (0 = centered)
    static let horizontalOffset: CGFloat = 0
}
