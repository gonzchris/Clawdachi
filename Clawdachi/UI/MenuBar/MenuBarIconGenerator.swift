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

    /// Simple blob silhouette (wider rectangular shape with dot eyes as holes)
    private static func drawBlobIcon() {
        let color = NSColor.black

        // Wider rectangle blob shape
        let scale: CGFloat = 2.0
        let offsetX: CGFloat = 0
        let offsetY: CGFloat = 2

        // Top row (slightly narrower for rounded look)
        drawPixelRect(x: 1, y: 5, w: 7, h: 1, color: color, scale: scale, offsetX: offsetX, offsetY: offsetY)

        // Middle rows - draw around the eye positions to leave holes
        // Row y=4 (full width, no eyes)
        drawPixelRect(x: 0, y: 4, w: 9, h: 1, color: color, scale: scale, offsetX: offsetX, offsetY: offsetY)

        // Row y=3 (eyes at x=2 and x=6, leave gaps)
        drawPixelRect(x: 0, y: 3, w: 2, h: 1, color: color, scale: scale, offsetX: offsetX, offsetY: offsetY)  // left of left eye
        drawPixelRect(x: 3, y: 3, w: 3, h: 1, color: color, scale: scale, offsetX: offsetX, offsetY: offsetY)  // between eyes
        drawPixelRect(x: 7, y: 3, w: 2, h: 1, color: color, scale: scale, offsetX: offsetX, offsetY: offsetY)  // right of right eye

        // Rows y=1-2 (full width, below eyes)
        drawPixelRect(x: 0, y: 1, w: 9, h: 2, color: color, scale: scale, offsetX: offsetX, offsetY: offsetY)

        // Bottom row (slightly narrower for rounded look)
        drawPixelRect(x: 1, y: 0, w: 7, h: 1, color: color, scale: scale, offsetX: offsetX, offsetY: offsetY)
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
