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
        case squint       // ">" shape for peeking while sleeping
        case squintLeft   // "<" shape (mirrored squint)
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
            // ">" shape - thicker version
            pixels[3][0] = P.eyePupil
            pixels[3][1] = P.eyePupil
            pixels[2][1] = P.eyePupil
            pixels[2][2] = P.eyePupil
            pixels[1][1] = P.eyePupil
            pixels[1][2] = P.eyePupil
            pixels[0][0] = P.eyePupil
            pixels[0][1] = P.eyePupil

        case .squintLeft:
            // "<" shape - thicker version (mirrored)
            pixels[3][1] = P.eyePupil
            pixels[3][2] = P.eyePupil
            pixels[2][0] = P.eyePupil
            pixels[2][1] = P.eyePupil
            pixels[1][0] = P.eyePupil
            pixels[1][1] = P.eyePupil
            pixels[0][1] = P.eyePupil
            pixels[0][2] = P.eyePupil
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

    /// Generates a whistle "o" mouth texture - small hollow circle
    /// Mouth size: 3x3 pixels
    static func generateWhistleMouthTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 3), count: 3)

        // Small hollow "o" shape for side whistle
        pixels[2][1] = P.mouthColor  // Top
        pixels[1][0] = P.mouthColor  // Left
        pixels[1][2] = P.mouthColor  // Right
        pixels[0][1] = P.mouthColor  // Bottom

        return PixelArtGenerator.textureFromPixels(pixels, width: 3, height: 3)
    }

    /// Generates a musical note texture using actual music symbol
    /// Renders smooth anti-aliased note symbol
    static func generateMusicNoteTexture() -> SKTexture {
        return generateMusicSymbolTexture(symbol: "♪")
    }

    /// Generates a double note texture
    static func generateDoubleNoteTexture() -> SKTexture {
        return generateMusicSymbolTexture(symbol: "♫")
    }

    /// Helper to generate any music symbol texture with orange gradient and black outline
    private static func generateMusicSymbolTexture(symbol: String) -> SKTexture {
        let size = CGSize(width: 32, height: 32)

        // Colors
        let outlineColor = NSColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0)      // Dark outline
        let highlightColor = NSColor(red: 255/255, green: 200/255, blue: 140/255, alpha: 1.0) // Light orange
        let mainColor = NSColor(red: 255/255, green: 153/255, blue: 51/255, alpha: 1.0)       // #FF9933
        let shadowColor = NSColor(red: 180/255, green: 80/255, blue: 0/255, alpha: 1.0)       // Dark orange

        let image = NSImage(size: size, flipped: false) { rect in
            guard NSGraphicsContext.current != nil else { return false }

            NSColor.clear.setFill()
            rect.fill()

            let font = NSFont.systemFont(ofSize: 22, weight: .bold)

            let attrString = NSAttributedString(string: symbol, attributes: [.font: font])
            let stringSize = attrString.size()
            let drawPoint = CGPoint(
                x: (size.width - stringSize.width) / 2,
                y: (size.height - stringSize.height) / 2
            )

            // Draw black outline (multiple offsets for thickness)
            let outlineAttrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: outlineColor
            ]
            let offsets: [(CGFloat, CGFloat)] = [
                (-1, -1), (-1, 0), (-1, 1),
                (0, -1),          (0, 1),
                (1, -1),  (1, 0),  (1, 1),
                (-1.5, 0), (1.5, 0), (0, -1.5), (0, 1.5)
            ]
            for offset in offsets {
                NSAttributedString(string: symbol, attributes: outlineAttrs)
                    .draw(at: CGPoint(x: drawPoint.x + offset.0, y: drawPoint.y + offset.1))
            }

            // Draw shadow layer (offset down-right)
            let shadowAttrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: shadowColor
            ]
            NSAttributedString(string: symbol, attributes: shadowAttrs)
                .draw(at: CGPoint(x: drawPoint.x + 1, y: drawPoint.y - 1))

            // Draw main color layer
            let mainAttrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: mainColor
            ]
            NSAttributedString(string: symbol, attributes: mainAttrs)
                .draw(at: drawPoint)

            // Draw highlight layer (offset up-left, semi-transparent)
            let highlightAttrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: highlightColor.withAlphaComponent(0.5)
            ]
            NSAttributedString(string: symbol, attributes: highlightAttrs)
                .draw(at: CGPoint(x: drawPoint.x - 0.5, y: drawPoint.y + 0.5))

            return true
        }

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            fatalError("Failed to create music note image")
        }

        let texture = SKTexture(cgImage: cgImage)
        texture.filteringMode = .linear
        return texture
    }

    // MARK: - Effect Textures

    /// Generates a pixel-art heart texture with orange gradient and black outline
    static func generateHeartTexture() -> SKTexture {
        // 7x7 pixel heart with outline, scaled up for smooth rendering
        let pixelSize: CGFloat = 4
        let width = 7
        let height = 7
        let size = CGSize(width: CGFloat(width) * pixelSize, height: CGFloat(height) * pixelSize)

        // Colors
        let outlineColor = NSColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0)
        let highlightColor = NSColor(red: 255/255, green: 200/255, blue: 140/255, alpha: 1.0)
        let mainColor = NSColor(red: 255/255, green: 153/255, blue: 51/255, alpha: 1.0)
        let shadowColor = NSColor(red: 180/255, green: 80/255, blue: 0/255, alpha: 1.0)

        // Heart pattern (1 = outline, 2 = highlight, 3 = main, 4 = shadow)
        let pattern: [[Int]] = [
            [0, 1, 1, 0, 1, 1, 0],
            [1, 2, 3, 1, 2, 3, 1],
            [1, 3, 3, 3, 3, 4, 1],
            [1, 3, 3, 3, 3, 4, 1],
            [0, 1, 3, 3, 4, 1, 0],
            [0, 0, 1, 3, 1, 0, 0],
            [0, 0, 0, 1, 0, 0, 0],
        ]

        let image = NSImage(size: size, flipped: true) { rect in
            NSColor.clear.setFill()
            rect.fill()

            for row in 0..<height {
                for col in 0..<width {
                    let value = pattern[row][col]
                    guard value > 0 else { continue }

                    let color: NSColor
                    switch value {
                    case 1: color = outlineColor
                    case 2: color = highlightColor
                    case 3: color = mainColor
                    case 4: color = shadowColor
                    default: continue
                    }

                    color.setFill()
                    let pixelRect = CGRect(
                        x: CGFloat(col) * pixelSize,
                        y: CGFloat(row) * pixelSize,
                        width: pixelSize,
                        height: pixelSize
                    )
                    pixelRect.fill()
                }
            }

            return true
        }

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            fatalError("Failed to create heart image")
        }

        let texture = SKTexture(cgImage: cgImage)
        texture.filteringMode = .nearest  // Keep crisp pixels
        return texture
    }

    /// Generates a "Z" texture for sleeping animation with orange gradient and black outline
    static func generateZzzTexture() -> SKTexture {
        let size = CGSize(width: 28, height: 28)

        // Colors
        let outlineColor = NSColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0)      // Dark outline
        let highlightColor = NSColor(red: 255/255, green: 200/255, blue: 140/255, alpha: 1.0) // Light orange
        let mainColor = NSColor(red: 255/255, green: 153/255, blue: 51/255, alpha: 1.0)       // #FF9933
        let shadowColor = NSColor(red: 180/255, green: 80/255, blue: 0/255, alpha: 1.0)       // Dark orange

        let image = NSImage(size: size, flipped: false) { rect in
            NSColor.clear.setFill()
            rect.fill()

            let font = NSFont.systemFont(ofSize: 20, weight: .heavy)
            let symbol = "Z"

            let attrString = NSAttributedString(string: symbol, attributes: [.font: font])
            let stringSize = attrString.size()
            let drawPoint = CGPoint(
                x: (size.width - stringSize.width) / 2,
                y: (size.height - stringSize.height) / 2
            )

            // Draw black outline (multiple offsets for thickness)
            let outlineAttrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: outlineColor
            ]
            let offsets: [(CGFloat, CGFloat)] = [
                (-1, -1), (-1, 0), (-1, 1),
                (0, -1),          (0, 1),
                (1, -1),  (1, 0),  (1, 1),
                (-1.5, 0), (1.5, 0), (0, -1.5), (0, 1.5)
            ]
            for offset in offsets {
                NSAttributedString(string: symbol, attributes: outlineAttrs)
                    .draw(at: CGPoint(x: drawPoint.x + offset.0, y: drawPoint.y + offset.1))
            }

            // Draw shadow layer (offset down-right)
            let shadowAttrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: shadowColor
            ]
            NSAttributedString(string: symbol, attributes: shadowAttrs)
                .draw(at: CGPoint(x: drawPoint.x + 1, y: drawPoint.y - 1))

            // Draw main color layer
            let mainAttrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: mainColor
            ]
            NSAttributedString(string: symbol, attributes: mainAttrs)
                .draw(at: drawPoint)

            // Draw highlight layer (offset up-left, semi-transparent)
            let highlightAttrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: highlightColor.withAlphaComponent(0.5)
            ]
            NSAttributedString(string: symbol, attributes: highlightAttrs)
                .draw(at: CGPoint(x: drawPoint.x - 0.5, y: drawPoint.y + 0.5))

            return true
        }

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            fatalError("Failed to create Z image")
        }

        let texture = SKTexture(cgImage: cgImage)
        texture.filteringMode = .linear
        return texture
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

    // MARK: - Lightbulb Texture

    /// Generates a pixel-art lightbulb texture with yellow glow, filament, and screw base
    /// Size: 7x10 pixels - detailed bulb shape for "eureka" moment
    static func generateLightbulbTexture() -> SKTexture {
        let pixelSize: CGFloat = 4
        let width = 7
        let height = 10
        let size = CGSize(width: CGFloat(width) * pixelSize, height: CGFloat(height) * pixelSize)

        // Lightbulb colors
        let outlineColor = NSColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0)       // #222222
        let glowColor = NSColor(red: 255/255, green: 255/255, blue: 220/255, alpha: 1.0)      // #FFFFDC bright glow
        let highlightColor = NSColor(red: 255/255, green: 250/255, blue: 180/255, alpha: 1.0) // #FFFAB4
        let mainColor = NSColor(red: 255/255, green: 230/255, blue: 100/255, alpha: 1.0)      // #FFE664 yellow
        let shadowColor = NSColor(red: 220/255, green: 180/255, blue: 50/255, alpha: 1.0)     // #DCB432 golden
        let filamentColor = NSColor(red: 255/255, green: 200/255, blue: 50/255, alpha: 1.0)   // #FFC832 bright filament
        let baseColor = NSColor(red: 140/255, green: 140/255, blue: 140/255, alpha: 1.0)      // #8C8C8C gray base
        let baseDarkColor = NSColor(red: 100/255, green: 100/255, blue: 100/255, alpha: 1.0)  // #646464 dark base

        // Lightbulb pattern (1=outline, 2=glow, 3=highlight, 4=main, 5=shadow, 6=filament, 7=base, 8=baseDark)
        // Detailed bulb with visible filament and screw base
        let pattern: [[Int]] = [
            [0, 0, 1, 1, 1, 0, 0],  // top curve
            [0, 1, 2, 2, 3, 1, 0],  // upper bulb glow
            [1, 2, 3, 6, 3, 4, 1],  // filament visible
            [1, 3, 3, 6, 4, 4, 1],  // filament
            [1, 3, 4, 4, 4, 5, 1],  // lower bulb
            [0, 1, 4, 4, 5, 1, 0],  // bulb narrows
            [0, 0, 1, 4, 1, 0, 0],  // neck
            [0, 0, 1, 7, 1, 0, 0],  // screw base top
            [0, 0, 1, 8, 1, 0, 0],  // screw base bottom
            [0, 0, 0, 1, 0, 0, 0],  // contact point
        ]

        let image = NSImage(size: size, flipped: true) { rect in
            NSColor.clear.setFill()
            rect.fill()

            for row in 0..<height {
                for col in 0..<width {
                    let value = pattern[row][col]
                    guard value > 0 else { continue }

                    let color: NSColor
                    switch value {
                    case 1: color = outlineColor
                    case 2: color = glowColor
                    case 3: color = highlightColor
                    case 4: color = mainColor
                    case 5: color = shadowColor
                    case 6: color = filamentColor
                    case 7: color = baseColor
                    case 8: color = baseDarkColor
                    default: continue
                    }

                    color.setFill()
                    let pixelRect = CGRect(
                        x: CGFloat(col) * pixelSize,
                        y: CGFloat(row) * pixelSize,
                        width: pixelSize,
                        height: pixelSize
                    )
                    pixelRect.fill()
                }
            }

            return true
        }

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            fatalError("Failed to create lightbulb image")
        }

        let texture = SKTexture(cgImage: cgImage)
        texture.filteringMode = .nearest
        return texture
    }

    // MARK: - Question Mark Texture

    /// Generates a pixel-art question mark texture for "waiting for input" state
    /// Size: 5x8 pixels - white with dark outline
    static func generateQuestionMarkTexture() -> SKTexture {
        let pixelSize: CGFloat = 4
        let width = 5
        let height = 8
        let size = CGSize(width: CGFloat(width) * pixelSize, height: CGFloat(height) * pixelSize)

        // Question mark colors - white with dark outline
        let outlineColor = NSColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0)       // #222222
        let whiteColor = NSColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0)     // #FFFFFF
        let grayColor = NSColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1.0)      // #C8C8C8 light shadow

        // Question mark pattern (1=outline, 2=white, 3=gray shadow)
        let pattern: [[Int]] = [
            [0, 1, 1, 1, 0],  // top curve
            [1, 2, 2, 2, 1],  // upper bulb
            [1, 3, 1, 2, 1],  // curve with hole
            [0, 0, 1, 2, 1],  // right side going down
            [0, 1, 2, 3, 1],  // curving left
            [0, 1, 2, 1, 0],  // stem
            [0, 0, 0, 0, 0],  // gap
            [0, 1, 2, 1, 0],  // dot
        ]

        let image = NSImage(size: size, flipped: true) { rect in
            NSColor.clear.setFill()
            rect.fill()

            for row in 0..<height {
                for col in 0..<width {
                    let value = pattern[row][col]
                    guard value > 0 else { continue }

                    let color: NSColor
                    switch value {
                    case 1: color = outlineColor
                    case 2: color = whiteColor
                    case 3: color = grayColor
                    default: continue
                    }

                    color.setFill()
                    let pixelRect = CGRect(
                        x: CGFloat(col) * pixelSize,
                        y: CGFloat(row) * pixelSize,
                        width: pixelSize,
                        height: pixelSize
                    )
                    pixelRect.fill()
                }
            }

            return true
        }

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            fatalError("Failed to create question mark image")
        }

        let texture = SKTexture(cgImage: cgImage)
        texture.filteringMode = .nearest
        return texture
    }

    // MARK: - Thinking Dot Textures

    /// Generates a small orange thinking dot (2x2 pixels)
    static func generateThinkingDotSmall() -> SKTexture {
        let P = ClawdachiPalette.self
        let pixels: [[PixelColor]] = [
            [P.primaryOrange, P.highlightOrange],
            [P.shadowOrange, P.primaryOrange],
        ]
        return PixelArtGenerator.textureFromPixels(pixels, width: 2, height: 2)
    }

    /// Generates a medium orange thinking dot (3x3 pixels)
    static func generateThinkingDotMedium() -> SKTexture {
        let P = ClawdachiPalette.self
        let pixels: [[PixelColor]] = [
            [P.clear, P.highlightOrange, P.clear],
            [P.highlightOrange, P.primaryOrange, P.shadowOrange],
            [P.clear, P.shadowOrange, P.clear],
        ]
        return PixelArtGenerator.textureFromPixels(pixels, width: 3, height: 3)
    }

    /// Generates a large orange thinking dot (4x4 pixels)
    static func generateThinkingDotLarge() -> SKTexture {
        let P = ClawdachiPalette.self
        let pixels: [[PixelColor]] = [
            [P.clear, P.highlightOrange, P.highlightOrange, P.clear],
            [P.highlightOrange, P.primaryOrange, P.primaryOrange, P.shadowOrange],
            [P.highlightOrange, P.primaryOrange, P.primaryOrange, P.shadowOrange],
            [P.clear, P.shadowOrange, P.shadowOrange, P.clear],
        ]
        return PixelArtGenerator.textureFromPixels(pixels, width: 4, height: 4)
    }
}
