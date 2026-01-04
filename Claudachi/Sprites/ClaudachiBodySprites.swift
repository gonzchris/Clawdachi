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

    /// Generates a body texture for a specific breathing phase
    static func generateBodyTexture(breathPhase: BreathPhase) -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 32), count: 32)

        // Vertical offset based on breath phase
        let yOffset: Int
        switch breathPhase {
        case .contracted: yOffset = 0
        case .neutral: yOffset = 0
        case .expanded: yOffset = 1
        }

        // Draw the friendly blob body
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

        // Draw from bottom to top (array index 0 = bottom of sprite)
        // Rectangular body ~18px tall (rows 5-22)

        // Feet (rows 5-6) - two small bumps at bottom
        // Left foot
        setPixels(&pixels, row: 5, from: 9, to: 11, color: s)
        setPixels(&pixels, row: 6, from: 9, to: 11, color: c)

        // Right foot
        setPixels(&pixels, row: 6, from: 20, to: 22, color: c)
        setPixels(&pixels, row: 5, from: 20, to: 22, color: s)

        // Main body (rows 7-22) - 16px tall, rectangular shape
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

        // Left arm (small block sticking out) - rows 11-13
        for row in 11...13 {
            let adjustedRow = row + yOffset
            if adjustedRow < 0 || adjustedRow >= 32 { continue }

            let armLeft = 16 - bodyWidth - 2  // 2 pixels out from body
            let armRight = 16 - bodyWidth

            for x in armLeft...armRight {
                if row == 11 {
                    pixels[adjustedRow][x] = s  // Bottom shadow
                } else if x == armLeft {
                    pixels[adjustedRow][x] = s  // Left shadow
                } else {
                    pixels[adjustedRow][x] = c
                }
            }
        }

        // Right arm (small block sticking out) - rows 11-13
        for row in 11...13 {
            let adjustedRow = row + yOffset
            if adjustedRow < 0 || adjustedRow >= 32 { continue }

            let armLeft = 16 + bodyWidth - 1
            let armRight = 16 + bodyWidth + 1  // 2 pixels out from body

            for x in armLeft...armRight {
                if row == 11 {
                    pixels[adjustedRow][x] = s  // Bottom shadow
                } else if x == armRight {
                    pixels[adjustedRow][x] = h  // Right highlight
                } else {
                    pixels[adjustedRow][x] = c
                }
            }
        }
    }

    private static func setPixels(_ pixels: inout [[PixelColor]], row: Int, from startX: Int, to endX: Int, color: PixelColor) {
        guard row >= 0 && row < 32 else { return }
        for x in max(0, startX)...min(31, endX) {
            pixels[row][x] = color
        }
    }
}
