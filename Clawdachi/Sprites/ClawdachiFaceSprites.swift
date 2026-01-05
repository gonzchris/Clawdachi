//
//  ClawdachiFaceSprites.swift
//  Clawdachi
//

import SpriteKit

/// Generates face element textures (eyes, mouth) with animation frames
class ClawdachiFaceSprites {

    private typealias P = ClawdachiPalette

    // MARK: - Eye States

    enum EyeState {
        case open
        case halfClosed
        case closed
        case squint  // ">" shape for peeking while sleeping
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

        case .squint:
            // ">" shape for annoyed peeking (pointing right)
            pixels[3][0] = P.eyePupil  // Top left
            pixels[2][1] = P.eyePupil  // Upper middle
            pixels[1][1] = P.eyePupil  // Lower middle
            pixels[0][0] = P.eyePupil  // Bottom left
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

    /// Generates a whistle "o" mouth texture (lowercase o style)
    /// Mouth size: 2x2 pixels
    static func generateWhistleMouthTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 2), count: 2)

        // Simple 2x2 filled block - minimal lowercase 'o'
        for row in 0..<2 {
            for col in 0..<2 {
                pixels[row][col] = P.mouthColor
            }
        }

        return PixelArtGenerator.textureFromPixels(pixels, width: 2, height: 2)
    }

    /// Generates a musical note texture for whistle effect
    /// Note size: 5x7 pixels - white with black stroke
    static func generateMusicNoteTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 5), count: 7)

        let fill = P.eyeWhite
        let stroke = P.eyePupil

        // Note head - outline
        pixels[0][0] = stroke
        pixels[0][1] = stroke
        pixels[0][2] = stroke
        pixels[1][0] = stroke
        pixels[1][3] = stroke
        pixels[2][1] = stroke
        pixels[2][2] = stroke
        pixels[2][3] = stroke

        // Note head - fill
        pixels[1][1] = fill
        pixels[1][2] = fill

        // Stem - outline and fill
        pixels[2][4] = stroke
        pixels[3][3] = stroke
        pixels[3][4] = fill
        pixels[4][3] = stroke
        pixels[4][4] = fill
        pixels[5][3] = stroke
        pixels[5][4] = fill
        pixels[6][3] = stroke
        pixels[6][4] = stroke

        // Flag - outline and fill
        pixels[6][2] = stroke
        pixels[5][2] = fill
        pixels[5][1] = stroke

        return PixelArtGenerator.textureFromPixels(pixels, width: 5, height: 7)
    }

    // MARK: - Effect Textures

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

    /// Generates a yawn mouth texture (filled oval)
    /// Size: 5x4 pixels
    static func generateYawnMouthTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 5), count: 4)

        // Filled oval for yawning mouth
        // Top row (narrower)
        pixels[3][1] = P.mouthColor
        pixels[3][2] = P.mouthColor
        pixels[3][3] = P.mouthColor
        // Middle rows (full width)
        for col in 0..<5 {
            pixels[2][col] = P.mouthColor
            pixels[1][col] = P.mouthColor
        }
        // Bottom row (narrower)
        pixels[0][1] = P.mouthColor
        pixels[0][2] = P.mouthColor
        pixels[0][3] = P.mouthColor

        return PixelArtGenerator.textureFromPixels(pixels, width: 5, height: 4)
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
}
