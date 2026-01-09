//
//  ClawdachiPalette.swift
//  Clawdachi
//

import Foundation

/// Color palette for Clawdachi, matching Clawd's warm orange/amber aesthetic
struct ClawdachiPalette {
    // Dynamic body colors from current theme
    static var primaryOrange: PixelColor {
        ClosetManager.shared.currentTheme.colors.primary
    }
    static var primary: PixelColor { primaryOrange }

    // Darker variant for shading (from theme)
    static var shadowOrange: PixelColor {
        ClosetManager.shared.currentTheme.colors.shadow
    }

    // Lighter variant for highlights (from theme)
    static var highlightOrange: PixelColor {
        ClosetManager.shared.currentTheme.colors.highlight
    }

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

    // Brain colors (for thinking animation)
    static let brainPink = PixelColor(r: 255, g: 153, b: 179)       // #FF99B3 - main
    static let brainPinkLight = PixelColor(r: 255, g: 191, b: 209)  // #FFBFD1 - highlight
    static let brainPinkDark = PixelColor(r: 217, g: 115, b: 140)   // #D9738C - shadow
    static let brainPinkDeep = PixelColor(r: 179, g: 89, b: 115)    // #B35973 - deep folds

    // Transparent
    static let clear = PixelColor.clear
}
