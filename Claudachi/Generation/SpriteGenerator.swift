//
//  SpriteGenerator.swift
//  Claudachi
//

import Foundation
import SpriteKit

/// A generated sprite with its metadata
struct GeneratedSprite {
    let texture: SKTexture
    let pixelData: [[PixelColor]]
    let item: String
    let category: ItemCategory
    let width: Int
    let height: Int
    let style: SpriteStyle
}

/// Error types for sprite generation
enum SpriteGenerationError: Error, LocalizedError {
    case jsonParsingFailed(String)
    case invalidPixelData(String)
    case dimensionMismatch(expected: Int, got: Int)

    var errorDescription: String? {
        switch self {
        case .jsonParsingFailed(let message):
            return "Failed to parse sprite JSON: \(message)"
        case .invalidPixelData(let message):
            return "Invalid pixel data: \(message)"
        case .dimensionMismatch(let expected, let got):
            return "Dimension mismatch: expected \(expected) pixels, got \(got)"
        }
    }
}

/// Generates pixel art sprites using Claude Code CLI
class SpriteGenerator {

    // MARK: - Configuration

    /// Default sprite size
    static let defaultSize: SpriteSize = .medium

    /// Default style
    static let defaultStyle: SpriteStyle = .claudachi

    // MARK: - Generation

    /// Generate a sprite for the given item and category
    /// - Parameters:
    ///   - item: The item name (e.g., "cowboy hat", "pizza slice")
    ///   - category: The item category
    ///   - size: Sprite size (default: .medium / 16x16)
    ///   - style: Visual style preset (default: .claudachi)
    ///   - enforceStyle: Whether to post-process colors to match palette (default: true)
    /// - Returns: A GeneratedSprite with texture and metadata
    /// - Throws: ClaudeCodeError or SpriteGenerationError
    static func generate(
        item: String,
        category: ItemCategory,
        size: SpriteSize = .medium,
        style: SpriteStyle = .claudachi,
        enforceStyle: Bool = true
    ) async throws -> GeneratedSprite {
        let prompt = buildPrompt(for: item, category: category, size: size, style: style)

        // Call Claude Code CLI
        print("[SpriteGenerator] Generating \(size.dimension)x\(size.dimension) \(style.rawValue) sprite: \(item)")
        let response = try await ClaudeCodeClient.generate(prompt: prompt)
        print("[SpriteGenerator] Got response, parsing JSON...")

        // Parse the JSON response
        let pixelData: [[PixelColor]]
        do {
            pixelData = try parsePixelData(from: response, expectedSize: size.dimension)
            print("[SpriteGenerator] Parsed \(pixelData.count) pixel rows")
        } catch {
            print("[SpriteGenerator] Parse error: \(error)")
            print("[SpriteGenerator] Response preview: \(String(response.prefix(500)))")
            throw error
        }

        // Handle dimension mismatches gracefully
        let expectedPixels = size.pixelCount
        var flatPixels = pixelData.flatMap { $0 }

        if flatPixels.count != expectedPixels {
            print("[SpriteGenerator] Warning: Got \(flatPixels.count) pixels, expected \(expectedPixels)")

            if flatPixels.count > expectedPixels {
                // Truncate extra pixels
                flatPixels = Array(flatPixels.prefix(expectedPixels))
                print("[SpriteGenerator] Truncated to \(expectedPixels) pixels")
            } else {
                // Pad with transparent pixels
                let padding = Array(repeating: PixelColor.clear, count: expectedPixels - flatPixels.count)
                flatPixels.append(contentsOf: padding)
                print("[SpriteGenerator] Padded with \(padding.count) transparent pixels")
            }
        }

        // Convert to 2D array for PixelArtGenerator
        var pixels2D: [[PixelColor]] = []
        for row in 0..<size.dimension {
            var rowPixels: [PixelColor] = []
            for col in 0..<size.dimension {
                let index = row * size.dimension + col
                rowPixels.append(flatPixels[index])
            }
            pixels2D.append(rowPixels)
        }

        // Optionally enforce style palette
        if enforceStyle {
            pixels2D = PaletteEnforcer.enforceStyle(pixels: pixels2D, style: style)
            print("[SpriteGenerator] Applied \(style.rawValue) palette enforcement")
        }

        // Generate texture
        let texture = PixelArtGenerator.textureFromPixels(
            pixels2D,
            width: size.dimension,
            height: size.dimension
        )

        return GeneratedSprite(
            texture: texture,
            pixelData: pixels2D,
            item: item,
            category: category,
            width: size.dimension,
            height: size.dimension,
            style: style
        )
    }

    /// Backwards-compatible generation with default size and style
    static func generate(item: String, category: ItemCategory) async throws -> GeneratedSprite {
        return try await generate(item: item, category: category, size: defaultSize, style: defaultStyle)
    }

    // MARK: - Prompt Building

    private static func buildPrompt(
        for item: String,
        category: ItemCategory,
        size: SpriteSize,
        style: SpriteStyle
    ) -> String {
        let dim = size.dimension
        let totalPixels = size.pixelCount

        return """
        Generate a \(dim)x\(dim) pixel art sprite of a \(item).

        ITEM TYPE: \(category.promptDescription)

        \(style.paletteDescription)

        STYLE GUIDELINES:
        \(style.styleGuidelines)
        - Maximum \(style.maxColors) colors (plus transparent)
        - Transparent background: [0,0,0,0]

        \(category.compositionRules)

        TECHNICAL REQUIREMENTS:
        - Exactly \(totalPixels) pixels as [r,g,b,a] arrays
        - Row by row, top to bottom (row 0 is TOP of sprite)
        - Each color value 0-255
        - Center the sprite with 1-2 pixel margins

        Return ONLY valid JSON in this exact format, no other text:
        {"pixels": [[r,g,b,a], [r,g,b,a], ...], "width": \(dim), "height": \(dim)}
        """
    }

    // MARK: - JSON Parsing

    private static func parsePixelData(from response: String, expectedSize: Int = 16) throws -> [[PixelColor]] {
        // Try to extract JSON from the response (in case there's extra text)
        guard let jsonString = extractJSON(from: response) else {
            throw SpriteGenerationError.jsonParsingFailed("No JSON object found in response")
        }

        guard let data = jsonString.data(using: .utf8) else {
            throw SpriteGenerationError.jsonParsingFailed("Failed to convert to data")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SpriteGenerationError.jsonParsingFailed("Invalid JSON structure")
        }

        guard let pixelsArray = json["pixels"] as? [[Any]] else {
            throw SpriteGenerationError.jsonParsingFailed("Missing or invalid 'pixels' array")
        }

        var pixels: [[PixelColor]] = []

        for (index, pixelArray) in pixelsArray.enumerated() {
            guard let rgba = pixelArray as? [Int],
                  rgba.count == 4 else {
                throw SpriteGenerationError.invalidPixelData("Invalid pixel at index \(index)")
            }

            let r = UInt8(clamping: rgba[0])
            let g = UInt8(clamping: rgba[1])
            let b = UInt8(clamping: rgba[2])
            let a = UInt8(clamping: rgba[3])

            pixels.append([PixelColor(r: r, g: g, b: b, a: a)])
        }

        return pixels
    }

    /// Extract JSON object from a string that might contain other text
    private static func extractJSON(from text: String) -> String? {
        // Find the first { and last }
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}") else {
            return nil
        }

        let jsonSubstring = text[start...end]
        return String(jsonSubstring)
    }
}
