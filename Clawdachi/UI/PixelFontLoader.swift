//
//  PixelFontLoader.swift
//  Clawdachi
//
//  Loads custom pixel fonts for the chat bubble
//

import AppKit
import CoreText

/// Loads and registers custom pixel fonts (thread-safe)
enum PixelFontLoader {

    /// Serial queue for thread-safe access to font state
    private static let fontQueue = DispatchQueue(label: "com.clawdachi.fontloader")

    /// Size-keyed font cache (avoids repeated NSFont creation for multiple sizes)
    private static var fontCache: [CGFloat: NSFont] = [:]

    /// Get the terminal font at the specified size (thread-safe)
    /// - Parameter size: Font size in points
    /// - Returns: Clean monospace system font
    static func pixelFont(size: CGFloat) -> NSFont {
        fontQueue.sync {
            // Return cached font if available
            if let cached = fontCache[size] {
                return cached
            }

            // Use system monospace font (SF Mono on macOS)
            let font = NSFont.monospacedSystemFont(ofSize: size, weight: .semibold)

            // Cache for this size
            fontCache[size] = font
            return font
        }
    }
}
