//
//  MenuBarIconGenerator.swift
//  Clawdachi
//
//  Generates icons for the menu bar status item
//

import AppKit

/// Generates icons for the menu bar
enum MenuBarIconGenerator {

    // MARK: - Icon Size

    /// Menu bar icon size (standard is 18x18 for retina)
    private static let iconSize: CGFloat = 18

    // MARK: - Cache

    private static var cachedIcon: NSImage?

    // MARK: - Public API

    /// Get the menu bar icon (same icon for all states, uses template rendering)
    static func icon(for status: String) -> NSImage {
        if let cached = cachedIcon {
            return cached
        }

        let image = generateIcon()
        cachedIcon = image
        return image
    }

    // MARK: - Icon Generation

    private static func generateIcon() -> NSImage {
        let size = NSSize(width: iconSize, height: iconSize)
        let image = NSImage(size: size)

        image.lockFocus()
        drawBlobIcon()
        image.unlockFocus()

        // Template image adapts to system appearance (light/dark mode)
        image.isTemplate = true
        return image
    }

    // MARK: - Icon Drawing

    /// Full sprite silhouette with body, arms, and legs
    private static func drawBlobIcon() {
        let color = NSColor.black

        // Scaled down to fit limbs in 18x18
        let scale: CGFloat = 1.5
        let offsetX: CGFloat = 1.5
        let offsetY: CGFloat = 0

        // --- Legs (4 legs below body) ---
        // Far left leg
        drawPixelRect(x: 1, y: 0, w: 1, h: 2, color: color, scale: scale, offsetX: offsetX, offsetY: offsetY)
        // Inner left leg
        drawPixelRect(x: 3, y: 0, w: 1, h: 2, color: color, scale: scale, offsetX: offsetX, offsetY: offsetY)
        // Inner right leg
        drawPixelRect(x: 5, y: 0, w: 1, h: 2, color: color, scale: scale, offsetX: offsetX, offsetY: offsetY)
        // Far right leg
        drawPixelRect(x: 7, y: 0, w: 1, h: 2, color: color, scale: scale, offsetX: offsetX, offsetY: offsetY)

        // --- Body (rectangular, no arms) ---
        // Bottom row of body
        drawPixelRect(x: 1, y: 2, w: 7, h: 1, color: color, scale: scale, offsetX: offsetX, offsetY: offsetY)

        // Main body rows (below eyes)
        drawPixelRect(x: 1, y: 3, w: 7, h: 2, color: color, scale: scale, offsetX: offsetX, offsetY: offsetY)

        // Eye row (y=5) - leave gaps for eyes at x=2 and x=6
        drawPixelRect(x: 1, y: 5, w: 1, h: 1, color: color, scale: scale, offsetX: offsetX, offsetY: offsetY)  // left of left eye
        drawPixelRect(x: 3, y: 5, w: 3, h: 1, color: color, scale: scale, offsetX: offsetX, offsetY: offsetY)  // between eyes
        drawPixelRect(x: 7, y: 5, w: 1, h: 1, color: color, scale: scale, offsetX: offsetX, offsetY: offsetY)  // right of right eye

        // Row above eyes
        drawPixelRect(x: 1, y: 6, w: 7, h: 1, color: color, scale: scale, offsetX: offsetX, offsetY: offsetY)

        // Top row (full width - rectangular)
        drawPixelRect(x: 1, y: 7, w: 7, h: 1, color: color, scale: scale, offsetX: offsetX, offsetY: offsetY)
    }

    // MARK: - Drawing Helpers

    private static func drawPixelRect(x: Int, y: Int, w: Int, h: Int, color: NSColor, scale: CGFloat, offsetX: CGFloat, offsetY: CGFloat) {
        let rect = NSRect(
            x: offsetX + CGFloat(x) * scale,
            y: offsetY + CGFloat(y) * scale,
            width: CGFloat(w) * scale,
            height: CGFloat(h) * scale
        )
        color.setFill()
        rect.fill()
    }
}
