//
//  ClawdachiFaceSprites.swift
//  Clawdachi
//

import SpriteKit

/// Generates face element textures (eyes, mouth) with animation frames
class ClawdachiFaceSprites {

    private typealias P = ClawdachiPalette

    // MARK: - Pixel Pattern Renderer

    /// Renders a pixel pattern to an SKTexture
    /// - Parameters:
    ///   - pattern: 2D array where each value maps to a color (0 = transparent)
    ///   - colorMap: Dictionary mapping pattern values to colors
    ///   - pixelSize: Size of each pixel in points
    ///   - filtering: Texture filtering mode (.nearest for crisp, .linear for smooth)
    /// - Returns: Generated SKTexture
    static func renderPixelPattern(
        _ pattern: [[Int]],
        colorMap: [Int: NSColor],
        pixelSize: CGFloat,
        filtering: SKTextureFilteringMode = .nearest
    ) -> SKTexture {
        let height = pattern.count
        let width = pattern.first?.count ?? 0
        let size = CGSize(width: CGFloat(width) * pixelSize, height: CGFloat(height) * pixelSize)

        let image = NSImage(size: size, flipped: true) { rect in
            NSColor.clear.setFill()
            rect.fill()

            for row in 0..<height {
                for col in 0..<width {
                    let value = pattern[row][col]
                    guard value > 0, let color = colorMap[value] else { continue }

                    color.setFill()
                    CGRect(
                        x: CGFloat(col) * pixelSize,
                        y: CGFloat(row) * pixelSize,
                        width: pixelSize,
                        height: pixelSize
                    ).fill()
                }
            }

            return true
        }

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            fatalError("Failed to create pixel pattern image")
        }

        let texture = SKTexture(cgImage: cgImage)
        texture.filteringMode = filtering
        return texture
    }

    // MARK: - Common Colors

    private enum Colors {
        static let outline = NSColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0)  // #222222
        static let orangeHighlight = NSColor(red: 255/255, green: 200/255, blue: 140/255, alpha: 1.0)
        static let orangeMain = NSColor(red: 255/255, green: 153/255, blue: 51/255, alpha: 1.0)  // #FF9933
        static let orangeShadow = NSColor(red: 180/255, green: 80/255, blue: 0/255, alpha: 1.0)
    }

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

        return renderPixelPattern(pattern, colorMap: [
            1: Colors.outline,
            2: Colors.orangeHighlight,
            3: Colors.orangeMain,
            4: Colors.orangeShadow
        ], pixelSize: 4)
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

    // MARK: - Smoking Textures

    /// Generates a pixel-art cigarette texture
    /// Size: 2x8 pixels - vertical cigarette with paper, tobacco, and ash
    static func generateCigaretteTexture() -> SKTexture {
        let pixelSize: CGFloat = 3
        let width = 2
        let height = 8
        let size = CGSize(width: CGFloat(width) * pixelSize, height: CGFloat(height) * pixelSize)

        // Cigarette colors
        let outlineColor = NSColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0)       // #222222
        let paperColor = NSColor(red: 245/255, green: 240/255, blue: 230/255, alpha: 1.0)     // Off-white paper
        let paperShadow = NSColor(red: 220/255, green: 215/255, blue: 205/255, alpha: 1.0)    // Slightly darker
        let tobaccoColor = NSColor(red: 180/255, green: 100/255, blue: 40/255, alpha: 1.0)    // Brown tobacco
        let ashColor = NSColor(red: 180/255, green: 180/255, blue: 175/255, alpha: 1.0)       // Gray ash
        let emberColor = NSColor(red: 255/255, green: 120/255, blue: 50/255, alpha: 1.0)      // Orange ember glow

        // Cigarette pattern (1=outline, 2=paper, 3=paperShadow, 4=tobacco, 5=ash, 6=ember)
        let pattern: [[Int]] = [
            [5, 5],  // ash tip (top)
            [6, 5],  // ember glow
            [4, 4],  // tobacco
            [2, 3],  // paper body
            [2, 3],  // paper body
            [2, 3],  // paper body
            [2, 3],  // paper body
            [2, 3],  // paper body (bottom, held here)
        ]

        let image = NSImage(size: size, flipped: true) { rect in
            NSColor.clear.setFill()
            rect.fill()

            // Draw outline first (expand by 1 pixel)
            outlineColor.setFill()
            for row in 0..<height {
                for col in 0..<width {
                    let value = pattern[row][col]
                    guard value > 0 else { continue }
                    // Draw outline pixels around this pixel
                    let offsets: [(Int, Int)] = [(-1, 0), (1, 0), (0, -1), (0, 1)]
                    for offset in offsets {
                        let pixelRect = CGRect(
                            x: CGFloat(col + offset.0) * pixelSize,
                            y: CGFloat(row + offset.1) * pixelSize,
                            width: pixelSize,
                            height: pixelSize
                        )
                        pixelRect.fill()
                    }
                }
            }

            // Draw main colors
            for row in 0..<height {
                for col in 0..<width {
                    let value = pattern[row][col]
                    guard value > 0 else { continue }

                    let color: NSColor
                    switch value {
                    case 1: color = outlineColor
                    case 2: color = paperColor
                    case 3: color = paperShadow
                    case 4: color = tobaccoColor
                    case 5: color = ashColor
                    case 6: color = emberColor
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
            fatalError("Failed to create cigarette image")
        }

        let texture = SKTexture(cgImage: cgImage)
        texture.filteringMode = .nearest
        return texture
    }

    /// Generates a smoke particle texture - wispy cloud shape
    /// Size: 6x6 pixels - irregular cloud with gradient
    static func generateSmokeParticleTexture() -> SKTexture {
        let pixelSize: CGFloat = 3
        let width = 6
        let height = 6
        let size = CGSize(width: CGFloat(width) * pixelSize, height: CGFloat(height) * pixelSize)

        // Smoke colors - light gray gradient
        let outlineColor = NSColor(red: 80/255, green: 80/255, blue: 80/255, alpha: 0.6)      // Dark gray outline
        let lightSmoke = NSColor(red: 220/255, green: 220/255, blue: 220/255, alpha: 0.8)    // Light gray
        let midSmoke = NSColor(red: 180/255, green: 180/255, blue: 180/255, alpha: 0.7)      // Medium gray
        let darkSmoke = NSColor(red: 140/255, green: 140/255, blue: 140/255, alpha: 0.5)     // Darker gray

        // Wispy cloud pattern (1=outline, 2=light, 3=mid, 4=dark)
        let pattern: [[Int]] = [
            [0, 0, 1, 1, 0, 0],
            [0, 1, 2, 2, 1, 0],
            [1, 2, 3, 2, 2, 1],
            [1, 3, 3, 3, 2, 1],
            [0, 1, 2, 3, 1, 0],
            [0, 0, 1, 1, 0, 0],
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
                    case 2: color = lightSmoke
                    case 3: color = midSmoke
                    case 4: color = darkSmoke
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
            fatalError("Failed to create smoke image")
        }

        let texture = SKTexture(cgImage: cgImage)
        texture.filteringMode = .nearest
        return texture
    }

    // MARK: - Party Celebration Textures

    /// Generates a pixel-art party hat texture - striped triangular hat
    /// Size: 7x9 pixels - festive party hat with stripes
    static func generatePartyHatTexture() -> SKTexture {
        let pixelSize: CGFloat = 4
        let width = 7
        let height = 9
        let size = CGSize(width: CGFloat(width) * pixelSize, height: CGFloat(height) * pixelSize)

        // Party hat colors - festive purple and gold stripes
        let outlineColor = NSColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0)        // #222222
        let purpleMain = NSColor(red: 150/255, green: 80/255, blue: 180/255, alpha: 1.0)       // Purple
        let purpleShadow = NSColor(red: 110/255, green: 50/255, blue: 140/255, alpha: 1.0)     // Dark purple
        let goldMain = NSColor(red: 255/255, green: 215/255, blue: 80/255, alpha: 1.0)         // Gold
        let goldShadow = NSColor(red: 220/255, green: 170/255, blue: 40/255, alpha: 1.0)       // Dark gold
        let pompomColor = NSColor(red: 255/255, green: 230/255, blue: 100/255, alpha: 1.0)     // Bright yellow pompom

        // Party hat pattern (1=outline, 2=purple, 3=purpleShadow, 4=gold, 5=goldShadow, 6=pompom)
        let pattern: [[Int]] = [
            [0, 0, 0, 6, 0, 0, 0],  // pompom top
            [0, 0, 0, 1, 0, 0, 0],  // tip
            [0, 0, 1, 2, 1, 0, 0],  // purple stripe
            [0, 0, 1, 4, 1, 0, 0],  // gold stripe
            [0, 1, 2, 2, 3, 1, 0],  // purple stripe wider
            [0, 1, 4, 4, 5, 1, 0],  // gold stripe wider
            [1, 2, 2, 2, 3, 3, 1],  // purple stripe
            [1, 4, 4, 4, 5, 5, 1],  // gold stripe
            [1, 1, 1, 1, 1, 1, 1],  // brim outline
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
                    case 2: color = purpleMain
                    case 3: color = purpleShadow
                    case 4: color = goldMain
                    case 5: color = goldShadow
                    case 6: color = pompomColor
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
            fatalError("Failed to create party hat image")
        }

        let texture = SKTexture(cgImage: cgImage)
        texture.filteringMode = .nearest
        return texture
    }

    /// Generates a party blower texture in retracted state - coiled at mouth
    /// Size: 4x3 pixels - compact coiled blower
    static func generatePartyBlowerRetractedTexture() -> SKTexture {
        let pixelSize: CGFloat = 4
        let width = 4
        let height = 3
        let size = CGSize(width: CGFloat(width) * pixelSize, height: CGFloat(height) * pixelSize)

        // Party blower colors
        let outlineColor = NSColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0)       // #222222
        let redMain = NSColor(red: 230/255, green: 70/255, blue: 70/255, alpha: 1.0)           // Red
        let redShadow = NSColor(red: 180/255, green: 40/255, blue: 40/255, alpha: 1.0)         // Dark red
        let mouthpiece = NSColor(red: 200/255, green: 180/255, blue: 140/255, alpha: 1.0)      // Tan mouthpiece

        // Retracted blower pattern (1=outline, 2=red, 3=redShadow, 4=mouthpiece)
        let pattern: [[Int]] = [
            [0, 1, 2, 1],  // coil top
            [1, 2, 3, 1],  // coil body
            [4, 1, 1, 0],  // mouthpiece
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
                    case 2: color = redMain
                    case 3: color = redShadow
                    case 4: color = mouthpiece
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
            fatalError("Failed to create party blower retracted image")
        }

        let texture = SKTexture(cgImage: cgImage)
        texture.filteringMode = .nearest
        return texture
    }

    /// Generates a party blower texture in extended state - unrolled
    /// Size: 10x3 pixels - extended blower with stripes
    static func generatePartyBlowerExtendedTexture() -> SKTexture {
        let pixelSize: CGFloat = 4
        let width = 10
        let height = 3
        let size = CGSize(width: CGFloat(width) * pixelSize, height: CGFloat(height) * pixelSize)

        // Party blower colors
        let outlineColor = NSColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0)       // #222222
        let redMain = NSColor(red: 230/255, green: 70/255, blue: 70/255, alpha: 1.0)           // Red
        let redShadow = NSColor(red: 180/255, green: 40/255, blue: 40/255, alpha: 1.0)         // Dark red
        let yellowMain = NSColor(red: 255/255, green: 220/255, blue: 80/255, alpha: 1.0)       // Yellow
        let yellowShadow = NSColor(red: 220/255, green: 180/255, blue: 40/255, alpha: 1.0)     // Dark yellow
        let mouthpiece = NSColor(red: 200/255, green: 180/255, blue: 140/255, alpha: 1.0)      // Tan mouthpiece

        // Extended blower pattern (1=outline, 2=red, 3=redShadow, 4=yellow, 5=yellowShadow, 6=mouthpiece)
        let pattern: [[Int]] = [
            [0, 1, 2, 1, 4, 1, 2, 1, 4, 1],  // top with stripes
            [1, 2, 3, 4, 5, 2, 3, 4, 5, 1],  // body with stripes
            [6, 1, 1, 1, 1, 1, 1, 1, 1, 0],  // mouthpiece and bottom
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
                    case 2: color = redMain
                    case 3: color = redShadow
                    case 4: color = yellowMain
                    case 5: color = yellowShadow
                    case 6: color = mouthpiece
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
            fatalError("Failed to create party blower extended image")
        }

        let texture = SKTexture(cgImage: cgImage)
        texture.filteringMode = .nearest
        return texture
    }

    // MARK: - Speaking Mouth Textures

    /// Generate open mouth texture for speaking (hollow O shape)
    static func generateSpeakingOpenMouthTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 3), count: 3)

        // Hollow O shape - only outline, no center
        pixels[2][1] = P.mouthColor  // Top
        pixels[1][0] = P.mouthColor  // Left
        pixels[1][2] = P.mouthColor  // Right
        pixels[0][1] = P.mouthColor  // Bottom

        return PixelArtGenerator.textureFromPixels(pixels, width: 3, height: 3)
    }

    /// Generate closed mouth texture for speaking (horizontal line)
    static func generateSpeakingClosedMouthTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 3), count: 1)

        pixels[0][0] = P.mouthColor
        pixels[0][1] = P.mouthColor
        pixels[0][2] = P.mouthColor

        return PixelArtGenerator.textureFromPixels(pixels, width: 3, height: 1)
    }

    // MARK: - Lightbulb Spark Textures (Yellow/White)

    /// Yellow/white color palette for lightbulb sparks
    private static let sparkWhite = PixelColor(r: 255, g: 255, b: 255)
    private static let sparkYellow = PixelColor(r: 255, g: 245, b: 150)
    private static let sparkYellowBright = PixelColor(r: 255, g: 255, b: 200)
    private static let sparkYellowDark = PixelColor(r: 255, g: 220, b: 80)

    /// Generates a small yellow/white spark (2x2 pixels)
    static func generateSparkSmall() -> SKTexture {
        let pixels: [[PixelColor]] = [
            [sparkYellow, sparkWhite],
            [sparkYellowDark, sparkYellow],
        ]
        return PixelArtGenerator.textureFromPixels(pixels, width: 2, height: 2)
    }

    /// Generates a medium yellow/white spark (3x3 pixels)
    static func generateSparkMedium() -> SKTexture {
        let pixels: [[PixelColor]] = [
            [P.clear, sparkWhite, P.clear],
            [sparkYellowBright, sparkYellow, sparkYellowDark],
            [P.clear, sparkYellowDark, P.clear],
        ]
        return PixelArtGenerator.textureFromPixels(pixels, width: 3, height: 3)
    }

    /// Generates a large yellow/white spark (4x4 pixels)
    static func generateSparkLarge() -> SKTexture {
        let pixels: [[PixelColor]] = [
            [P.clear, sparkWhite, sparkYellowBright, P.clear],
            [sparkWhite, sparkYellow, sparkYellow, sparkYellowDark],
            [sparkYellowBright, sparkYellow, sparkYellow, sparkYellowDark],
            [P.clear, sparkYellowDark, sparkYellowDark, P.clear],
        ]
        return PixelArtGenerator.textureFromPixels(pixels, width: 4, height: 4)
    }
}
