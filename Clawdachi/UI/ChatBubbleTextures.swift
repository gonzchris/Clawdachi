//
//  ChatBubbleTextures.swift
//  Clawdachi
//
//  Generates pixel-art chat bubble images dynamically based on content size
//

import AppKit

/// Generates pixel-art chat bubble backgrounds
class ChatBubbleTextures {

    private typealias C = ChatBubbleConstants

    // MARK: - Image Cache

    /// LRU cache for generated bubble images
    private static var imageCache: [String: NSImage] = [:]
    private static let maxCacheSize = 12

    /// Generate cache key from content size and tail flag
    private static func cacheKey(contentSize: CGSize, hasTail: Bool) -> String {
        "\(Int(contentSize.width))x\(Int(contentSize.height))-\(hasTail)"
    }

    // MARK: - Public API

    /// Generate a pixel-art chat bubble image for the given content size
    /// - Parameters:
    ///   - contentSize: Size of the text content area (without padding)
    ///   - hasTail: Whether to include the pointing tail (default true)
    /// - Returns: NSImage of the complete bubble with optional tail and shadow
    static func generateBubble(contentSize: CGSize, hasTail: Bool = true) -> NSImage {
        // Check cache first
        let key = cacheKey(contentSize: contentSize, hasTail: hasTail)
        if let cached = imageCache[key] {
            return cached
        }

        let px = C.pixelSize
        let outline = C.outlinePixels
        let shadow = C.shadowPixels
        let cornerRadius = CGFloat(C.cornerPixels) * px

        // Calculate bubble body dimensions (content + padding)
        let bodyWidth = ceil(contentSize.width) + C.paddingHorizontal * 2
        let bodyHeight = ceil(contentSize.height) + C.paddingVertical * 2

        // Calculate tail dimensions
        let tailHeight = hasTail ? C.tailHeight : 0

        // Total image dimensions including outline and shadow
        let outlineSize = CGFloat(outline) * px
        let shadowSize = CGFloat(shadow) * px
        let totalWidth = bodyWidth + outlineSize * 2 + shadowSize
        let totalHeight = bodyHeight + tailHeight + outlineSize * 2 + shadowSize

        let imageSize = CGSize(width: totalWidth, height: totalHeight)

        let image = NSImage(size: imageSize, flipped: true) { rect in
            NSColor.clear.setFill()
            rect.fill()

            // Draw shadow layer (offset left and down)
            let shadowRect = CGRect(
                x: 0,
                y: shadowSize,
                width: bodyWidth,
                height: bodyHeight
            )
            Self.drawBubbleWithPath(
                rect: shadowRect,
                cornerRadius: cornerRadius,
                tailWidth: C.tailWidth,
                tailHeight: tailHeight,
                color: C.shadowColor,
                includeTail: hasTail
            )

            // Draw outline (slightly larger)
            let outlineRect = CGRect(
                x: shadowSize,
                y: 0,
                width: bodyWidth + outlineSize * 2,
                height: bodyHeight + outlineSize * 2
            )
            Self.drawBubbleWithPath(
                rect: outlineRect,
                cornerRadius: cornerRadius + outlineSize,
                tailWidth: C.tailWidth + outlineSize * 2,
                tailHeight: hasTail ? tailHeight + outlineSize : 0,
                color: C.outlineColor,
                includeTail: hasTail
            )

            // Draw white fill
            let fillRect = CGRect(
                x: shadowSize + outlineSize,
                y: outlineSize,
                width: bodyWidth,
                height: bodyHeight
            )
            Self.drawBubbleWithPath(
                rect: fillRect,
                cornerRadius: cornerRadius,
                tailWidth: C.tailWidth,
                tailHeight: tailHeight,
                color: C.fillColor,
                includeTail: hasTail
            )

            return true
        }

        // Add to cache (evict oldest if full)
        if imageCache.count >= maxCacheSize {
            imageCache.removeValue(forKey: imageCache.keys.first!)
        }
        imageCache[key] = image

        return image
    }

    // MARK: - Optimized Path Drawing

    /// Draw bubble using NSBezierPath (much faster than pixel-by-pixel)
    private static func drawBubbleWithPath(
        rect: CGRect,
        cornerRadius: CGFloat,
        tailWidth: CGFloat,
        tailHeight: CGFloat,
        color: NSColor,
        includeTail: Bool
    ) {
        let path = NSBezierPath()

        // Start at top-left after corner
        path.move(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY))

        // Top edge
        path.line(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))

        // Top-right corner
        path.appendArc(
            withCenter: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY + cornerRadius),
            radius: cornerRadius,
            startAngle: 270,
            endAngle: 0,
            clockwise: false
        )

        // Right edge
        path.line(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))

        // Bottom-right corner
        path.appendArc(
            withCenter: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: 0,
            endAngle: 90,
            clockwise: false
        )

        // Bottom edge (with tail if included)
        if includeTail && tailHeight > 0 {
            // Bottom edge to tail start
            let tailStartX = rect.minX + cornerRadius + tailWidth
            path.line(to: CGPoint(x: tailStartX + tailWidth / 2, y: rect.maxY))

            // Tail point
            path.line(to: CGPoint(x: tailStartX, y: rect.maxY + tailHeight))

            // Tail back up
            path.line(to: CGPoint(x: tailStartX - tailWidth / 2, y: rect.maxY))

            // Continue to bottom-left corner
            path.line(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))
        } else {
            // Just bottom edge
            path.line(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))
        }

        // Bottom-left corner
        path.appendArc(
            withCenter: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: 90,
            endAngle: 180,
            clockwise: false
        )

        // Left edge
        path.line(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))

        // Top-left corner
        path.appendArc(
            withCenter: CGPoint(x: rect.minX + cornerRadius, y: rect.minY + cornerRadius),
            radius: cornerRadius,
            startAngle: 180,
            endAngle: 270,
            clockwise: false
        )

        path.close()

        color.setFill()
        path.fill()
    }
}
