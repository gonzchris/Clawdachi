//
//  ClaudachiBodySprites.swift
//  Claudachi
//

import SpriteKit

/// Generates body textures for Claudachi with breathing animation frames
class ClaudachiBodySprites {

    private typealias P = ClaudachiPalette

    /// Generates all breathing animation frames
    /// - Returns: Array of 4 textures: contracted, neutral (expanding), expanded, neutral (contracting)
    static func generateBreathingFrames() -> [SKTexture] {
        return [
            generateBodyTexture(breathPhase: .contracted),
            generateBodyTexture(breathPhase: .neutral),
            generateBodyTexture(breathPhase: .expanded),
            generateBodyTexture(breathPhase: .neutral)
        ]
    }

    enum BreathPhase {
        case contracted  // Slightly squashed
        case neutral     // Normal size
        case expanded    // Slightly stretched
    }

    /// Generates a body texture for a specific breathing phase (without arms/legs - those are separate)
    static func generateBodyTexture(breathPhase: BreathPhase) -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 32), count: 32)

        // Vertical offset based on breath phase
        let yOffset: Int
        switch breathPhase {
        case .contracted: yOffset = 0
        case .neutral: yOffset = 0
        case .expanded: yOffset = 1
        }

        // Draw the friendly blob body (without arms/legs)
        drawBody(into: &pixels, yOffset: yOffset, phase: breathPhase)

        return PixelArtGenerator.textureFromPixels(pixels, width: 32, height: 32)
    }

    private static func drawBody(into pixels: inout [[PixelColor]], yOffset: Int, phase: BreathPhase) {
        let c = P.primaryOrange
        let s = P.shadowOrange
        let h = P.highlightOrange

        // Body dimensions adjust slightly based on breath phase
        let extraWidth = (phase == .contracted) ? 1 : 0
        let bodyWidth = 10 + extraWidth  // Half-width of body

        // Main body only (rows 7-22) - arms and legs are separate nodes now
        for row in 7...22 {
            let adjustedRow = row + yOffset
            if adjustedRow < 0 || adjustedRow >= 32 { continue }

            // Slight corner rounding only at very top and bottom rows
            var width = bodyWidth
            if row == 7 || row == 22 {
                width = bodyWidth - 1  // Slight corner cut
            }

            let left = 16 - width
            let right = 16 + width - 1

            for x in left...right {
                // Left edge shadow (2 pixels)
                if x < left + 2 {
                    pixels[adjustedRow][x] = s
                }
                // Right edge highlight (2 pixels)
                else if x > right - 2 {
                    pixels[adjustedRow][x] = h
                }
                // Top highlight (top 2 rows)
                else if row >= 21 {
                    pixels[adjustedRow][x] = h
                }
                // Bottom shadow (bottom row of body)
                else if row == 7 {
                    pixels[adjustedRow][x] = s
                }
                // Main body color
                else {
                    pixels[adjustedRow][x] = c
                }
            }
        }
    }

    // MARK: - Limb Textures

    /// Generate left arm texture (3x3 pixels)
    static func generateLeftArmTexture() -> SKTexture {
        let c = P.primaryOrange
        let s = P.shadowOrange

        var pixels = Array(repeating: Array(repeating: P.clear, count: 3), count: 3)

        // 3x3 arm block
        for row in 0..<3 {
            for x in 0..<3 {
                if row == 0 {
                    pixels[row][x] = s  // Bottom shadow
                } else if x == 0 {
                    pixels[row][x] = s  // Left shadow
                } else {
                    pixels[row][x] = c
                }
            }
        }

        return PixelArtGenerator.textureFromPixels(pixels, width: 3, height: 3)
    }

    /// Generate right arm texture (3x3 pixels)
    static func generateRightArmTexture() -> SKTexture {
        let c = P.primaryOrange
        let s = P.shadowOrange
        let h = P.highlightOrange

        var pixels = Array(repeating: Array(repeating: P.clear, count: 3), count: 3)

        // 3x3 arm block
        for row in 0..<3 {
            for x in 0..<3 {
                if row == 0 {
                    pixels[row][x] = s  // Bottom shadow
                } else if x == 2 {
                    pixels[row][x] = h  // Right highlight
                } else {
                    pixels[row][x] = c
                }
            }
        }

        return PixelArtGenerator.textureFromPixels(pixels, width: 3, height: 3)
    }

    /// Generate left foot texture (3x2 pixels)
    static func generateLeftFootTexture() -> SKTexture {
        let c = P.primaryOrange
        let s = P.shadowOrange

        var pixels = Array(repeating: Array(repeating: P.clear, count: 3), count: 2)

        // Bottom row - shadow
        pixels[0][0] = s
        pixels[0][1] = s
        pixels[0][2] = s

        // Top row - main color
        pixels[1][0] = c
        pixels[1][1] = c
        pixels[1][2] = c

        return PixelArtGenerator.textureFromPixels(pixels, width: 3, height: 2)
    }

    /// Generate right foot texture (3x2 pixels)
    static func generateRightFootTexture() -> SKTexture {
        let c = P.primaryOrange
        let s = P.shadowOrange

        var pixels = Array(repeating: Array(repeating: P.clear, count: 3), count: 2)

        // Bottom row - shadow
        pixels[0][0] = s
        pixels[0][1] = s
        pixels[0][2] = s

        // Top row - main color
        pixels[1][0] = c
        pixels[1][1] = c
        pixels[1][2] = c

        return PixelArtGenerator.textureFromPixels(pixels, width: 3, height: 2)
    }

    private static func setPixels(_ pixels: inout [[PixelColor]], row: Int, from startX: Int, to endX: Int, color: PixelColor) {
        guard row >= 0 && row < 32 else { return }
        for x in max(0, startX)...min(31, endX) {
            pixels[row][x] = color
        }
    }
}
