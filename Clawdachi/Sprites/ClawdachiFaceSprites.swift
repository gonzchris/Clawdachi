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

    /// Helper to generate any music symbol texture with theme-colored gradient and black outline
    private static func generateMusicSymbolTexture(symbol: String) -> SKTexture {
        let size = CGSize(width: 32, height: 32)

        // Use dynamic theme colors
        let theme = ClosetManager.shared.currentTheme.colors
        let outlineColor = NSColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0)      // Dark outline
        let highlightColor = NSColor(red: CGFloat(theme.highlight.r)/255, green: CGFloat(theme.highlight.g)/255, blue: CGFloat(theme.highlight.b)/255, alpha: 1.0)
        let mainColor = NSColor(red: CGFloat(theme.primary.r)/255, green: CGFloat(theme.primary.g)/255, blue: CGFloat(theme.primary.b)/255, alpha: 1.0)
        let shadowColor = NSColor(red: CGFloat(theme.shadow.r)/255, green: CGFloat(theme.shadow.g)/255, blue: CGFloat(theme.shadow.b)/255, alpha: 1.0)

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

    /// Generates a pixel-art heart texture with theme-colored gradient and black outline
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

        // Use dynamic theme colors
        let theme = ClosetManager.shared.currentTheme.colors
        let highlightColor = NSColor(red: CGFloat(theme.highlight.r)/255, green: CGFloat(theme.highlight.g)/255, blue: CGFloat(theme.highlight.b)/255, alpha: 1.0)
        let mainColor = NSColor(red: CGFloat(theme.primary.r)/255, green: CGFloat(theme.primary.g)/255, blue: CGFloat(theme.primary.b)/255, alpha: 1.0)
        let shadowColor = NSColor(red: CGFloat(theme.shadow.r)/255, green: CGFloat(theme.shadow.g)/255, blue: CGFloat(theme.shadow.b)/255, alpha: 1.0)

        return renderPixelPattern(pattern, colorMap: [
            1: Colors.outline,
            2: highlightColor,
            3: mainColor,
            4: shadowColor
        ], pixelSize: 4)
    }

    /// Generates a "Z" texture for sleeping animation with theme-colored gradient and black outline
    static func generateZzzTexture() -> SKTexture {
        let size = CGSize(width: 28, height: 28)

        // Use dynamic theme colors
        let theme = ClosetManager.shared.currentTheme.colors
        let outlineColor = NSColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0)      // Dark outline
        let highlightColor = NSColor(red: CGFloat(theme.highlight.r)/255, green: CGFloat(theme.highlight.g)/255, blue: CGFloat(theme.highlight.b)/255, alpha: 1.0)
        let mainColor = NSColor(red: CGFloat(theme.primary.r)/255, green: CGFloat(theme.primary.g)/255, blue: CGFloat(theme.primary.b)/255, alpha: 1.0)
        let shadowColor = NSColor(red: CGFloat(theme.shadow.r)/255, green: CGFloat(theme.shadow.g)/255, blue: CGFloat(theme.shadow.b)/255, alpha: 1.0)

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

    /// Lightbulb color palette
    private enum LightbulbColors {
        static let outline = NSColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0)        // #222222
        static let glow = NSColor(red: 255/255, green: 255/255, blue: 220/255, alpha: 1.0)       // #FFFFDC
        static let highlight = NSColor(red: 255/255, green: 250/255, blue: 180/255, alpha: 1.0)  // #FFFAB4
        static let main = NSColor(red: 255/255, green: 230/255, blue: 100/255, alpha: 1.0)       // #FFE664
        static let shadow = NSColor(red: 220/255, green: 180/255, blue: 50/255, alpha: 1.0)      // #DCB432
        static let filament = NSColor(red: 255/255, green: 200/255, blue: 50/255, alpha: 1.0)    // #FFC832
        static let base = NSColor(red: 140/255, green: 140/255, blue: 140/255, alpha: 1.0)       // #8C8C8C
        static let baseDark = NSColor(red: 100/255, green: 100/255, blue: 100/255, alpha: 1.0)   // #646464
    }

    /// Generates a pixel-art lightbulb texture with yellow glow, filament, and screw base
    /// Size: 7x10 pixels - detailed bulb shape for "eureka" moment
    static func generateLightbulbTexture() -> SKTexture {
        // 1=outline, 2=glow, 3=highlight, 4=main, 5=shadow, 6=filament, 7=base, 8=baseDark
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

        return renderPixelPattern(pattern, colorMap: [
            1: LightbulbColors.outline,
            2: LightbulbColors.glow,
            3: LightbulbColors.highlight,
            4: LightbulbColors.main,
            5: LightbulbColors.shadow,
            6: LightbulbColors.filament,
            7: LightbulbColors.base,
            8: LightbulbColors.baseDark
        ], pixelSize: 4)
    }

    // MARK: - Question Mark Texture

    /// Question mark color palette
    private enum QuestionMarkColors {
        static let outline = NSColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0)   // #222222
        static let white = NSColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0)  // #FFFFFF
        static let gray = NSColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1.0)   // #C8C8C8
    }

    /// Generates a pixel-art question mark texture for "waiting for input" state
    /// Size: 5x8 pixels - white with dark outline
    static func generateQuestionMarkTexture() -> SKTexture {
        // 1=outline, 2=white, 3=gray shadow
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

        return renderPixelPattern(pattern, colorMap: [
            1: QuestionMarkColors.outline,
            2: QuestionMarkColors.white,
            3: QuestionMarkColors.gray
        ], pixelSize: 4)
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

    /// Smoke particle color palette
    private enum SmokeColors {
        static let outline = NSColor(red: 80/255, green: 80/255, blue: 80/255, alpha: 0.6)    // Dark gray
        static let light = NSColor(red: 220/255, green: 220/255, blue: 220/255, alpha: 0.8)   // Light gray
        static let mid = NSColor(red: 180/255, green: 180/255, blue: 180/255, alpha: 0.7)     // Medium gray
        static let dark = NSColor(red: 140/255, green: 140/255, blue: 140/255, alpha: 0.5)    // Darker gray
    }

    /// Generates a smoke particle texture - wispy cloud shape
    /// Size: 6x6 pixels - irregular cloud with gradient
    static func generateSmokeParticleTexture() -> SKTexture {
        // 1=outline, 2=light, 3=mid, 4=dark
        let pattern: [[Int]] = [
            [0, 0, 1, 1, 0, 0],
            [0, 1, 2, 2, 1, 0],
            [1, 2, 3, 2, 2, 1],
            [1, 3, 3, 3, 2, 1],
            [0, 1, 2, 3, 1, 0],
            [0, 0, 1, 1, 0, 0],
        ]

        return renderPixelPattern(pattern, colorMap: [
            1: SmokeColors.outline,
            2: SmokeColors.light,
            3: SmokeColors.mid,
            4: SmokeColors.dark
        ], pixelSize: 3)
    }

    // MARK: - Party Celebration Textures

    /// Party hat color palette
    private enum PartyHatColors {
        static let outline = NSColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0)       // #222222
        static let purple = NSColor(red: 150/255, green: 80/255, blue: 180/255, alpha: 1.0)     // Purple
        static let purpleShadow = NSColor(red: 110/255, green: 50/255, blue: 140/255, alpha: 1.0)
        static let gold = NSColor(red: 255/255, green: 215/255, blue: 80/255, alpha: 1.0)       // Gold
        static let goldShadow = NSColor(red: 220/255, green: 170/255, blue: 40/255, alpha: 1.0)
        static let pompom = NSColor(red: 255/255, green: 230/255, blue: 100/255, alpha: 1.0)    // Yellow pompom
    }

    /// Generates a pixel-art party hat texture - striped triangular hat
    /// Size: 7x9 pixels - festive party hat with stripes
    static func generatePartyHatTexture() -> SKTexture {
        // 1=outline, 2=purple, 3=purpleShadow, 4=gold, 5=goldShadow, 6=pompom
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

        return renderPixelPattern(pattern, colorMap: [
            1: PartyHatColors.outline,
            2: PartyHatColors.purple,
            3: PartyHatColors.purpleShadow,
            4: PartyHatColors.gold,
            5: PartyHatColors.goldShadow,
            6: PartyHatColors.pompom
        ], pixelSize: 4)
    }

    /// Party blower color palette
    private enum PartyBlowerColors {
        static let outline = NSColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0)     // #222222
        static let red = NSColor(red: 230/255, green: 70/255, blue: 70/255, alpha: 1.0)        // Red
        static let redShadow = NSColor(red: 180/255, green: 40/255, blue: 40/255, alpha: 1.0)  // Dark red
        static let yellow = NSColor(red: 255/255, green: 220/255, blue: 80/255, alpha: 1.0)    // Yellow
        static let yellowShadow = NSColor(red: 220/255, green: 180/255, blue: 40/255, alpha: 1.0)
        static let mouthpiece = NSColor(red: 200/255, green: 180/255, blue: 140/255, alpha: 1.0)
    }

    /// Generates a party blower texture in retracted state - coiled at mouth
    /// Size: 4x3 pixels - compact coiled blower
    static func generatePartyBlowerRetractedTexture() -> SKTexture {
        // 1=outline, 2=red, 3=redShadow, 4=mouthpiece
        let pattern: [[Int]] = [
            [0, 1, 2, 1],  // coil top
            [1, 2, 3, 1],  // coil body
            [4, 1, 1, 0],  // mouthpiece
        ]

        return renderPixelPattern(pattern, colorMap: [
            1: PartyBlowerColors.outline,
            2: PartyBlowerColors.red,
            3: PartyBlowerColors.redShadow,
            4: PartyBlowerColors.mouthpiece
        ], pixelSize: 4)
    }

    /// Generates a party blower texture in extended state - unrolled
    /// Size: 10x3 pixels - extended blower with stripes
    static func generatePartyBlowerExtendedTexture() -> SKTexture {
        // 1=outline, 2=red, 3=redShadow, 4=yellow, 5=yellowShadow, 6=mouthpiece
        let pattern: [[Int]] = [
            [0, 1, 2, 1, 4, 1, 2, 1, 4, 1],  // top with stripes
            [1, 2, 3, 4, 5, 2, 3, 4, 5, 1],  // body with stripes
            [6, 1, 1, 1, 1, 1, 1, 1, 1, 0],  // mouthpiece and bottom
        ]

        return renderPixelPattern(pattern, colorMap: [
            1: PartyBlowerColors.outline,
            2: PartyBlowerColors.red,
            3: PartyBlowerColors.redShadow,
            4: PartyBlowerColors.yellow,
            5: PartyBlowerColors.yellowShadow,
            6: PartyBlowerColors.mouthpiece
        ], pixelSize: 4)
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

    // MARK: - Thinking Orb Textures (Theme-colored floating dots)

    /// Generates a tiny thinking orb (2x2 pixels) using theme colors
    static func generateThinkingOrbTiny() -> SKTexture {
        let P = ClawdachiPalette.self
        let pixels: [[PixelColor]] = [
            [P.highlightOrange, P.primaryOrange],
            [P.primaryOrange, P.shadowOrange],
        ]
        return PixelArtGenerator.textureFromPixels(pixels, width: 2, height: 2)
    }

    // MARK: - Cloud Textures (Thinking Animation)

    /// Cloud color palette
    private enum CloudColors {
        static let outline = NSColor(red: 50/255, green: 55/255, blue: 70/255, alpha: 1.0)
        static let highlight = NSColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0)
        static let main = NSColor(red: 240/255, green: 242/255, blue: 248/255, alpha: 1.0)
        static let shadow = NSColor(red: 180/255, green: 185/255, blue: 200/255, alpha: 1.0)

        static let colorMap: [Int: NSColor] = [
            1: outline,
            2: highlight,
            3: main,
            4: shadow
        ]
    }

    /// Large main thought cloud (15x10) - fluffy with bumps
    static func generateMainCloudTexture() -> SKTexture {
        // 1=outline, 2=highlight, 3=main, 4=shadow
        let pattern: [[Int]] = [
            [0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0],  // top bump
            [0, 0, 0, 0, 1, 2, 2, 2, 2, 2, 1, 0, 0, 0, 0],
            [0, 0, 1, 1, 1, 2, 2, 3, 2, 2, 1, 1, 1, 0, 0],  // side bumps
            [0, 1, 2, 2, 2, 2, 3, 3, 3, 2, 2, 2, 2, 1, 0],
            [1, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 2, 2, 2, 1],
            [1, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 1],
            [1, 3, 3, 3, 4, 3, 3, 3, 3, 3, 4, 3, 4, 4, 1],
            [1, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 1],
            [0, 1, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 1, 0],
            [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],  // bottom
        ]

        return renderPixelPattern(pattern, colorMap: CloudColors.colorMap, pixelSize: 2.0)
    }

    /// Mini cloud variation 1 - bumpy puff (7x5)
    static func generateMiniCloud1() -> SKTexture {
        let pattern: [[Int]] = [
            [0, 1, 1, 1, 1, 1, 0],
            [1, 2, 2, 2, 2, 2, 1],
            [1, 2, 3, 3, 3, 4, 1],
            [1, 3, 4, 4, 4, 4, 1],
            [0, 1, 1, 1, 1, 1, 0],
        ]

        return renderPixelPattern(pattern, colorMap: CloudColors.colorMap, pixelSize: 2.0)
    }

    /// Mini cloud variation 2 - two bumps (9x5)
    static func generateMiniCloud2() -> SKTexture {
        let pattern: [[Int]] = [
            [0, 1, 1, 1, 0, 1, 1, 1, 0],  // two bumps on top
            [1, 2, 2, 2, 1, 2, 2, 2, 1],
            [1, 2, 3, 3, 3, 3, 3, 4, 1],
            [1, 3, 4, 4, 4, 4, 4, 4, 1],
            [0, 1, 1, 1, 1, 1, 1, 1, 0],
        ]

        return renderPixelPattern(pattern, colorMap: CloudColors.colorMap, pixelSize: 2.0)
    }

    /// Mini cloud variation 3 - small bumpy puff (6x4)
    static func generateMiniCloud3() -> SKTexture {
        let pattern: [[Int]] = [
            [0, 1, 1, 1, 1, 0],
            [1, 2, 2, 2, 2, 1],
            [1, 3, 3, 3, 4, 1],
            [0, 1, 1, 1, 1, 0],
        ]

        return renderPixelPattern(pattern, colorMap: CloudColors.colorMap, pixelSize: 2.0)
    }

    /// Thought circle color palette
    private enum ThoughtCircleColors {
        static let outline = NSColor(red: 60/255, green: 60/255, blue: 70/255, alpha: 1.0)
        static let fill = NSColor.white

        static let colorMap: [Int: NSColor] = [
            1: outline,
            2: fill
        ]
    }

    /// Generates a small trailing circle for thought bubble
    /// Size: 4x4 pixels
    static func generateThoughtCircleSmall() -> SKTexture {
        let pattern: [[Int]] = [
            [0, 1, 1, 0],
            [1, 2, 2, 1],
            [1, 2, 2, 1],
            [0, 1, 1, 0],
        ]

        return renderPixelPattern(pattern, colorMap: ThoughtCircleColors.colorMap, pixelSize: 2.5)
    }

    /// Generates a tiny trailing circle for thought bubble
    /// Size: 3x3 pixels
    static func generateThoughtCircleTiny() -> SKTexture {
        let pattern: [[Int]] = [
            [0, 1, 0],
            [1, 2, 1],
            [0, 1, 0],
        ]

        return renderPixelPattern(pattern, colorMap: ThoughtCircleColors.colorMap, pixelSize: 2.5)
    }

    // MARK: - Lightning Bolt Textures (Thinking Animation)

    /// Generates a small lightning bolt (3x4 pixels)
    static func generateLightningBoltSmall() -> SKTexture {
        let pixels: [[PixelColor]] = [
            [sparkWhite, sparkYellow, P.clear],
            [P.clear, sparkYellow, sparkYellowDark],
            [sparkYellowBright, sparkYellow, P.clear],
            [P.clear, sparkYellowDark, P.clear],
        ]
        return PixelArtGenerator.textureFromPixels(pixels, width: 3, height: 4)
    }

    /// Generates a medium lightning bolt (4x5 pixels)
    static func generateLightningBoltMedium() -> SKTexture {
        let pixels: [[PixelColor]] = [
            [P.clear, sparkWhite, sparkYellow, P.clear],
            [P.clear, sparkYellowBright, sparkYellow, sparkYellowDark],
            [sparkWhite, sparkYellow, sparkYellowDark, P.clear],
            [P.clear, sparkYellow, sparkYellowDark, P.clear],
            [P.clear, P.clear, sparkYellowDark, P.clear],
        ]
        return PixelArtGenerator.textureFromPixels(pixels, width: 4, height: 5)
    }

    /// Generates a large lightning bolt (5x6 pixels)
    static func generateLightningBoltLarge() -> SKTexture {
        let pixels: [[PixelColor]] = [
            [P.clear, P.clear, sparkWhite, sparkYellowBright, P.clear],
            [P.clear, sparkWhite, sparkYellow, sparkYellow, sparkYellowDark],
            [sparkYellowBright, sparkYellow, sparkYellow, sparkYellowDark, P.clear],
            [P.clear, sparkYellow, sparkYellowDark, P.clear, P.clear],
            [P.clear, sparkYellowBright, sparkYellow, sparkYellowDark, P.clear],
            [P.clear, P.clear, sparkYellowDark, P.clear, P.clear],
        ]
        return PixelArtGenerator.textureFromPixels(pixels, width: 5, height: 6)
    }

    // MARK: - Confetti Textures

    /// Confetti color palette - festive party colors
    private enum ConfettiColors {
        static let red = NSColor(red: 230/255, green: 70/255, blue: 70/255, alpha: 1.0)
        static let blue = NSColor(red: 70/255, green: 130/255, blue: 230/255, alpha: 1.0)
        static let green = NSColor(red: 70/255, green: 200/255, blue: 100/255, alpha: 1.0)
        static let yellow = NSColor(red: 255/255, green: 220/255, blue: 80/255, alpha: 1.0)
        static let purple = NSColor(red: 180/255, green: 100/255, blue: 220/255, alpha: 1.0)
        static let pink = NSColor(red: 255/255, green: 150/255, blue: 180/255, alpha: 1.0)
        static let orange = NSColor(red: 255/255, green: 160/255, blue: 60/255, alpha: 1.0)
        static let cyan = NSColor(red: 80/255, green: 220/255, blue: 230/255, alpha: 1.0)

        static let allColors: [NSColor] = [red, blue, green, yellow, purple, pink, orange, cyan]
    }

    /// Generates a small square confetti piece (2x2 pixels)
    /// - Parameter colorIndex: Index into the confetti color array (0-7)
    static func generateConfettiSquare(colorIndex: Int) -> SKTexture {
        let color = ConfettiColors.allColors[colorIndex % ConfettiColors.allColors.count]
        let size = CGSize(width: 8, height: 8)  // 2x2 at 4px per pixel

        let image = NSImage(size: size, flipped: false) { rect in
            color.setFill()
            rect.fill()
            return true
        }

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            fatalError("Failed to create confetti square image")
        }

        let texture = SKTexture(cgImage: cgImage)
        texture.filteringMode = .nearest
        return texture
    }

    /// Generates a rectangular confetti piece (3x2 pixels)
    /// - Parameter colorIndex: Index into the confetti color array (0-7)
    static func generateConfettiRect(colorIndex: Int) -> SKTexture {
        let color = ConfettiColors.allColors[colorIndex % ConfettiColors.allColors.count]
        let size = CGSize(width: 12, height: 8)  // 3x2 at 4px per pixel

        let image = NSImage(size: size, flipped: false) { rect in
            color.setFill()
            rect.fill()
            return true
        }

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            fatalError("Failed to create confetti rect image")
        }

        let texture = SKTexture(cgImage: cgImage)
        texture.filteringMode = .nearest
        return texture
    }

    /// Pre-generates all confetti textures for performance
    /// Returns array of (texture, size) tuples for both squares and rectangles
    static func generateAllConfettiTextures() -> [(texture: SKTexture, size: CGSize)] {
        var textures: [(texture: SKTexture, size: CGSize)] = []

        // Generate squares (2x2 visual size)
        for i in 0..<ConfettiColors.allColors.count {
            textures.append((generateConfettiSquare(colorIndex: i), CGSize(width: 2, height: 2)))
        }

        // Generate rectangles (3x2 visual size)
        for i in 0..<ConfettiColors.allColors.count {
            textures.append((generateConfettiRect(colorIndex: i), CGSize(width: 3, height: 2)))
        }

        return textures
    }

    // MARK: - Gear Texture (Thinking indicator)

    /// Generates a pixel-art gear/cog for thinking animation
    /// Size: 9x9 pixels
    static func generateGearTexture() -> SKTexture {
        typealias P = PixelColor
        let gearMain = PixelColor(r: 0x88, g: 0x99, b: 0xAA)    // Blue-gray gear body
        let gearDark = PixelColor(r: 0x55, g: 0x66, b: 0x77)    // Darker edge
        let gearLight = PixelColor(r: 0xAA, g: 0xBB, b: 0xCC)   // Highlight
        let center = PixelColor(r: 0x33, g: 0x44, b: 0x55)      // Dark center hole

        // 9x9 gear with 8 teeth
        let pixels: [[PixelColor]] = [
            [P.clear,   P.clear,   gearDark,  gearMain,  gearMain,  gearMain,  gearDark,  P.clear,   P.clear],
            [P.clear,   gearDark,  gearLight, gearMain,  gearMain,  gearMain,  gearLight, gearDark,  P.clear],
            [gearDark,  gearLight, gearMain,  gearMain,  gearMain,  gearMain,  gearMain,  gearLight, gearDark],
            [gearMain,  gearMain,  gearMain,  gearDark,  center,    gearDark,  gearMain,  gearMain,  gearMain],
            [gearMain,  gearMain,  gearMain,  center,    center,    center,    gearMain,  gearMain,  gearMain],
            [gearMain,  gearMain,  gearMain,  gearDark,  center,    gearDark,  gearMain,  gearMain,  gearMain],
            [gearDark,  gearLight, gearMain,  gearMain,  gearMain,  gearMain,  gearMain,  gearLight, gearDark],
            [P.clear,   gearDark,  gearLight, gearMain,  gearMain,  gearMain,  gearLight, gearDark,  P.clear],
            [P.clear,   P.clear,   gearDark,  gearMain,  gearMain,  gearMain,  gearDark,  P.clear,   P.clear],
        ]

        return PixelArtGenerator.textureFromPixels(pixels, width: 9, height: 9)
    }
}
