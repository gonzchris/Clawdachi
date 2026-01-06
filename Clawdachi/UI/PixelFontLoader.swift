//
//  PixelFontLoader.swift
//  Clawdachi
//
//  Loads custom pixel fonts for the chat bubble
//

import AppKit
import CoreText

/// Loads and registers custom pixel fonts
enum PixelFontLoader {

    /// The name of the pixel font after registration
    static let pixelFontName = "Press Start 2P"

    /// Whether the font has been loaded
    private static var isLoaded = false

    /// Cached font instance (avoids repeated NSFont creation)
    private static var cachedFont: NSFont?
    private static var cachedFontSize: CGFloat = 0

    /// Load the pixel font from the app bundle
    static func loadFonts() {
        guard !isLoaded else { return }

        // Load Press Start 2P (bold chunky pixel font)
        if let fontURL = Bundle.main.url(forResource: "PressStart2P-Regular", withExtension: "ttf") {
            var error: Unmanaged<CFError>?
            if CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) {
                print("[PixelFontLoader] Successfully loaded VT323 font")
            } else {
                print("[PixelFontLoader] Failed to load VT323: \(error?.takeRetainedValue().localizedDescription ?? "unknown error")")
            }
        } else {
            print("[PixelFontLoader] VT323 not found in bundle")
        }
        isLoaded = true
    }

    /// Get the pixel font at the specified size
    /// - Parameter size: Font size in points
    /// - Returns: The pixel font, or a fallback monospace font
    static func pixelFont(size: CGFloat) -> NSFont {
        // Return cached font if size matches
        if let cached = cachedFont, cachedFontSize == size {
            return cached
        }

        loadFonts()
        let font = NSFont(name: pixelFontName, size: size)
            ?? NSFont.monospacedSystemFont(ofSize: size, weight: .bold)

        // Cache for next call
        cachedFont = font
        cachedFontSize = size
        return font
    }
}
