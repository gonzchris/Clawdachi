//
//  ClawdachiPalette.swift
//  Clawdachi
//

import Foundation

/// Color palette for Clawdachi, matching Clawd's warm orange/amber aesthetic
struct ClawdachiPalette {
    // Primary orange/amber (Clawd's main color)
    static let primaryOrange = PixelColor(r: 255, g: 153, b: 51)    // #FF9933
    static let primary = primaryOrange  // Alias for convenience

    // Darker orange for shading
    static let shadowOrange = PixelColor(r: 204, g: 102, b: 0)      // #CC6600

    // Lighter orange for highlights
    static let highlightOrange = PixelColor(r: 255, g: 187, b: 119) // #FFBB77

    // Eyes - white with dark pupils
    static let eyeWhite = PixelColor(r: 255, g: 255, b: 255)        // #FFFFFF
    static let eyePupil = PixelColor(r: 34, g: 34, b: 34)           // #222222

    // Mouth
    static let mouthColor = PixelColor(r: 68, g: 34, b: 0)          // #442200

    // Terminal green for effects
    static let terminalGreen = PixelColor(r: 0, g: 255, b: 136)     // #00FF88
    static let effectGreen = terminalGreen  // Alias for convenience

    // Ground shadow (semi-transparent)
    static let groundShadow = PixelColor(r: 0, g: 0, b: 0, a: 51)   // 20% opacity black

    // Transparent
    static let clear = PixelColor.clear
}
