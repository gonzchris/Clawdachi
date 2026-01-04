//
//  ClaudachiFaceSprites.swift
//  Claudachi
//

import SpriteKit

/// Generates face element textures (eyes, mouth) with animation frames
class ClaudachiFaceSprites {

    private typealias P = ClaudachiPalette

    // MARK: - Eye States

    enum EyeState {
        case open
        case halfClosed
        case closed
    }

    /// Generates an eye texture for the given state
    /// Eye size: 3x4 pixels
    static func generateEyeTexture(state: EyeState) -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 3), count: 4)

        switch state {
        case .open:
            // Simple 3x4 dark eye
            for row in 0..<4 {
                for col in 0..<3 {
                    pixels[row][col] = P.eyePupil
                }
            }

        case .halfClosed:
            // Bottom 2 rows only
            for row in 0..<2 {
                for col in 0..<3 {
                    pixels[row][col] = P.eyePupil
                }
            }

        case .closed:
            // Single row horizontal line
            for col in 0..<3 {
                pixels[1][col] = P.eyePupil
            }
        }

        return PixelArtGenerator.textureFromPixels(pixels, width: 3, height: 4)
    }

    /// Generates all blink animation frames
    /// - Returns: Array of 5 textures: open -> half -> closed -> half -> open
    static func generateBlinkFrames() -> [SKTexture] {
        return [
            generateEyeTexture(state: .open),
            generateEyeTexture(state: .halfClosed),
            generateEyeTexture(state: .closed),
            generateEyeTexture(state: .halfClosed),
            generateEyeTexture(state: .open)
        ]
    }

    // MARK: - Mouth

    /// Generates a whistle "o" mouth texture
    /// Mouth size: 3x3 pixels
    static func generateWhistleMouthTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 3), count: 3)

        // Small "o" shape for whistling
        pixels[0][1] = P.mouthColor  // Bottom
        pixels[1][0] = P.mouthColor  // Left
        pixels[1][2] = P.mouthColor  // Right
        pixels[2][1] = P.mouthColor  // Top

        return PixelArtGenerator.textureFromPixels(pixels, width: 3, height: 3)
    }

    /// Generates a musical note texture for whistle effect
    /// Note size: 3x5 pixels
    static func generateMusicNoteTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 3), count: 5)

        // Simple music note shape
        pixels[0][0] = P.eyePupil  // Note head
        pixels[0][1] = P.eyePupil
        pixels[1][0] = P.eyePupil
        pixels[1][2] = P.eyePupil  // Stem
        pixels[2][2] = P.eyePupil
        pixels[3][2] = P.eyePupil
        pixels[4][2] = P.eyePupil
        pixels[4][1] = P.eyePupil  // Flag

        return PixelArtGenerator.textureFromPixels(pixels, width: 3, height: 5)
    }

    // MARK: - Effect Textures

    /// Generates an exclamation mark texture for "getting idea" animation
    /// Size: 3x7 pixels
    static func generateExclamationTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 3), count: 7)

        // Exclamation mark "!"
        // Vertical line (top part)
        for row in 2..<7 {
            pixels[row][1] = P.effectGreen
        }
        // Dot at bottom
        pixels[0][1] = P.effectGreen

        return PixelArtGenerator.textureFromPixels(pixels, width: 3, height: 7)
    }

    /// Generates a thought bubble dot texture
    /// Size: 2x2 pixels
    static func generateThoughtDotTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 2), count: 2)

        pixels[0][0] = P.eyeWhite
        pixels[0][1] = P.eyeWhite
        pixels[1][0] = P.eyeWhite
        pixels[1][1] = P.eyeWhite

        return PixelArtGenerator.textureFromPixels(pixels, width: 2, height: 2)
    }

    /// Generates a heart texture for happy reactions
    /// Size: 5x5 pixels
    static func generateHeartTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 5), count: 5)

        let heart = P.primary  // Orange heart to match character

        // Heart shape
        pixels[4][1] = heart
        pixels[4][3] = heart
        pixels[3][0] = heart
        pixels[3][1] = heart
        pixels[3][2] = heart
        pixels[3][3] = heart
        pixels[3][4] = heart
        pixels[2][0] = heart
        pixels[2][1] = heart
        pixels[2][2] = heart
        pixels[2][3] = heart
        pixels[2][4] = heart
        pixels[1][1] = heart
        pixels[1][2] = heart
        pixels[1][3] = heart
        pixels[0][2] = heart

        return PixelArtGenerator.textureFromPixels(pixels, width: 5, height: 5)
    }

    /// Generates a star/sparkle texture for success celebrations
    /// Size: 5x5 pixels
    static func generateSparkleTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 5), count: 5)

        let spark = P.effectGreen

        // 4-point star shape
        pixels[2][2] = spark  // Center
        pixels[0][2] = spark  // Top
        pixels[4][2] = spark  // Bottom
        pixels[2][0] = spark  // Left
        pixels[2][4] = spark  // Right
        // Diagonal hints
        pixels[1][1] = spark
        pixels[1][3] = spark
        pixels[3][1] = spark
        pixels[3][3] = spark

        return PixelArtGenerator.textureFromPixels(pixels, width: 5, height: 5)
    }

    /// Generates a "Z" texture for sleeping animation
    /// Size: 4x5 pixels
    static func generateZzzTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 4), count: 5)

        let z = P.eyeWhite

        // Z shape
        pixels[4][0] = z
        pixels[4][1] = z
        pixels[4][2] = z
        pixels[4][3] = z
        pixels[3][2] = z
        pixels[2][1] = z
        pixels[1][0] = z
        pixels[0][0] = z
        pixels[0][1] = z
        pixels[0][2] = z
        pixels[0][3] = z

        return PixelArtGenerator.textureFromPixels(pixels, width: 4, height: 5)
    }

    /// Generates a small smile mouth texture
    /// Size: 5x2 pixels
    static func generateSmileMouthTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 5), count: 2)

        // Simple curved smile
        pixels[1][1] = P.mouthColor
        pixels[1][2] = P.mouthColor
        pixels[1][3] = P.mouthColor
        pixels[0][0] = P.mouthColor
        pixels[0][4] = P.mouthColor

        return PixelArtGenerator.textureFromPixels(pixels, width: 5, height: 2)
    }

    /// Generates a sweat drop texture for dragging animation
    /// Size: 3x6 pixels - classic teardrop shape
    static func generateSweatDropTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 3), count: 6)

        let dropMain = PixelColor(r: 100, g: 170, b: 255)      // Light blue
        let dropHighlight = PixelColor(r: 180, g: 220, b: 255) // Bright highlight

        // Teardrop shape - pointed tip at top, bulbous bottom
        pixels[5][1] = dropMain           // Top point (tip)
        pixels[4][1] = dropMain           // Upper stem
        pixels[3][0] = dropMain           // Widening left
        pixels[3][1] = dropHighlight      // Widening center (highlight)
        pixels[3][2] = dropMain           // Widening right
        pixels[2][0] = dropMain           // Bulb left
        pixels[2][1] = dropHighlight      // Bulb center (highlight)
        pixels[2][2] = dropMain           // Bulb right
        pixels[1][0] = dropMain           // Lower bulb left
        pixels[1][1] = dropMain           // Lower bulb center
        pixels[1][2] = dropMain           // Lower bulb right
        pixels[0][1] = dropMain           // Bottom rounded point

        return PixelArtGenerator.textureFromPixels(pixels, width: 3, height: 6)
    }

    // MARK: - Chef Mode

    /// Generates a chef hat (toque) texture
    /// Size: 13x12 pixels (classic puffy toque)
    static func generateChefHat() -> SKTexture {
        let width = 13
        let height = 12
        var pixels = Array(repeating: Array(repeating: P.clear, count: width), count: height)

        // Hat colors - crisp white chef toque
        let hatWhite = PixelColor(r: 252, g: 252, b: 250)      // Crisp white
        let hatShadow = PixelColor(r: 210, g: 210, b: 205)     // Shadow
        let hatMid = PixelColor(r: 235, g: 235, b: 230)        // Mid-tone for depth
        let hatHighlight = PixelColor(r: 255, g: 255, b: 255)  // Pure white highlight
        let band = PixelColor(r: 180, g: 180, b: 175)          // Dark band at bottom

        // Row 0 - band bottom edge
        for x in 3...9 {
            pixels[0][x] = band
        }

        // Row 1 - band with slight highlight
        for x in 3...9 {
            if x == 9 { pixels[1][x] = hatMid }
            else { pixels[1][x] = band }
        }

        // Row 2 - transition from band to puff
        for x in 2...10 {
            if x == 2 { pixels[2][x] = hatShadow }
            else if x == 10 { pixels[2][x] = hatHighlight }
            else { pixels[2][x] = hatWhite }
        }

        // Rows 3-4 - puff expands
        for row in 3...4 {
            for x in 1...11 {
                if x == 1 { pixels[row][x] = hatShadow }
                else if x == 11 { pixels[row][x] = hatHighlight }
                else if x == 2 { pixels[row][x] = hatMid }
                else { pixels[row][x] = hatWhite }
            }
        }

        // Rows 5-7 - full puff (widest part with pleats)
        for row in 5...7 {
            for x in 0...12 {
                if x == 0 { pixels[row][x] = hatShadow }
                else if x == 12 { pixels[row][x] = hatHighlight }
                else if x == 1 { pixels[row][x] = hatMid }
                else if x == 4 && row == 6 { pixels[row][x] = hatMid }  // Subtle pleat
                else if x == 8 && row == 6 { pixels[row][x] = hatMid }  // Subtle pleat
                else { pixels[row][x] = hatWhite }
            }
        }

        // Row 8 - start rounding top
        for x in 1...11 {
            if x == 1 { pixels[8][x] = hatShadow }
            else if x == 11 { pixels[8][x] = hatHighlight }
            else if x == 2 { pixels[8][x] = hatMid }
            else { pixels[8][x] = hatWhite }
        }

        // Row 9 - more rounding
        for x in 2...10 {
            if x == 2 { pixels[9][x] = hatShadow }
            else if x == 10 { pixels[9][x] = hatHighlight }
            else { pixels[9][x] = hatWhite }
        }

        // Row 10 - near top
        for x in 3...9 {
            if x == 3 { pixels[10][x] = hatMid }
            else if x == 9 { pixels[10][x] = hatHighlight }
            else { pixels[10][x] = hatWhite }
        }

        // Row 11 - rounded top
        for x in 4...8 {
            pixels[11][x] = hatHighlight
        }

        return PixelArtGenerator.textureFromPixels(pixels, width: width, height: height)
    }
}
