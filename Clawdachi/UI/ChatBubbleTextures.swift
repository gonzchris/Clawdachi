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

    /// Thread-safe LRU cache using NSCache (automatic memory management)
    private static let imageCache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 12
        return cache
    }()

    /// Generate cache key from content size and tail flag
    private static func cacheKey(contentSize: CGSize, hasTail: Bool) -> NSString {
        "\(Int(contentSize.width))x\(Int(contentSize.height))-\(hasTail)" as NSString
    }

    // MARK: - Public API

    /// Generate a pixel-art chat bubble image for the given content size
    /// - Parameters:
    ///   - contentSize: Size of the text content area (without padding)
    ///   - hasTail: Whether to include the pointing tail (default true)
    /// - Returns: NSImage of the complete bubble with optional tail and shadow
    static func generateBubble(contentSize: CGSize, hasTail: Bool = true) -> NSImage {
        // Check cache first (NSCache handles LRU automatically)
        let key = cacheKey(contentSize: contentSize, hasTail: hasTail)
        if let cached = imageCache.object(forKey: key) {
            return cached
        }

        let px = C.pixelSize
        let outline = C.outlinePixels
        let shadow = C.shadowPixels
        let cornerRadius = CGFloat(C.cornerPixels) * px

        // Calculate bubble body dimensions (content + padding)
        let bodyWidth = ceil(contentSize.width) + C.paddingHorizontal * 2
        let bodyHeight = ceil(contentSize.height) + C.paddingVertical * 2

        // Tail extends to the LEFT of the bubble
        let tailWidth = hasTail ? C.tailWidth : 0

        // Total image dimensions including outline, shadow, and left tail
        let outlineSize = CGFloat(outline) * px
        let shadowSize = CGFloat(shadow) * px
        let totalWidth = tailWidth + bodyWidth + outlineSize * 2 + shadowSize
        let totalHeight = bodyHeight + outlineSize * 2 + shadowSize

        let imageSize = CGSize(width: totalWidth, height: totalHeight)

        let image = NSImage(size: imageSize, flipped: true) { rect in
            NSColor.clear.setFill()
            rect.fill()

            // Body starts after the tail area
            let bodyX = tailWidth

            // Draw shadow layer (offset right and down)
            let shadowRect = CGRect(
                x: bodyX,
                y: shadowSize,
                width: bodyWidth,
                height: bodyHeight
            )
            Self.drawRoundedRect(rect: shadowRect, cornerRadius: cornerRadius, color: C.shadowColor)
            if hasTail {
                Self.drawLeftTail(
                    bodyX: bodyX,
                    bodyY: shadowSize,
                    bodyHeight: bodyHeight,
                    tailWidth: tailWidth,
                    tailHeight: C.tailHeight,
                    color: C.shadowColor
                )
            }

            // Draw outline (slightly larger)
            let outlineRect = CGRect(
                x: bodyX + shadowSize - outlineSize,
                y: 0,
                width: bodyWidth + outlineSize * 2,
                height: bodyHeight + outlineSize * 2
            )
            Self.drawRoundedRect(rect: outlineRect, cornerRadius: cornerRadius + outlineSize, color: C.outlineColor)
            if hasTail {
                Self.drawLeftTail(
                    bodyX: bodyX + shadowSize - outlineSize,
                    bodyY: 0,
                    bodyHeight: bodyHeight + outlineSize * 2,
                    tailWidth: tailWidth + outlineSize,
                    tailHeight: C.tailHeight + outlineSize * 2,
                    color: C.outlineColor
                )
            }

            // Draw white fill
            let fillRect = CGRect(
                x: bodyX + shadowSize,
                y: outlineSize,
                width: bodyWidth,
                height: bodyHeight
            )
            Self.drawRoundedRect(rect: fillRect, cornerRadius: cornerRadius, color: C.fillColor)
            if hasTail {
                Self.drawLeftTail(
                    bodyX: bodyX + shadowSize,
                    bodyY: outlineSize,
                    bodyHeight: bodyHeight,
                    tailWidth: tailWidth,
                    tailHeight: C.tailHeight,
                    color: C.fillColor
                )
            }

            // Draw inner shadow (bottom edge for 3D effect)
            let innerShadowRect = CGRect(
                x: bodyX + shadowSize + px,
                y: outlineSize + bodyHeight - px * 3,
                width: bodyWidth - px * 2,
                height: px * 3
            )
            Self.drawRoundedRect(rect: innerShadowRect, cornerRadius: cornerRadius / 2, color: C.innerShadowColor)

            // Draw inner highlight (top edge for 3D effect)
            let highlightRect = CGRect(
                x: bodyX + shadowSize + px,
                y: outlineSize + px,
                width: bodyWidth - px * 2,
                height: px * 2
            )
            Self.drawRoundedRect(rect: highlightRect, cornerRadius: cornerRadius / 2, color: C.highlightColor)

            return true
        }

        // Add to cache (NSCache handles eviction automatically)
        imageCache.setObject(image, forKey: key)

        return image
    }

    // MARK: - Drawing Helpers

    /// Draw a simple rounded rectangle
    private static func drawRoundedRect(rect: CGRect, cornerRadius: CGFloat, color: NSColor) {
        let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
        color.setFill()
        path.fill()
    }

    /// Draw a triangular tail pointing LEFT from the left edge of the bubble body
    private static func drawLeftTail(
        bodyX: CGFloat,
        bodyY: CGFloat,
        bodyHeight: CGFloat,
        tailWidth: CGFloat,
        tailHeight: CGFloat,
        color: NSColor
    ) {
        // Position tail vertically centered on the left edge, slightly toward bottom
        let tailY = bodyY + bodyHeight - tailHeight - 8

        let path = NSBezierPath()
        // Start at body edge (top of tail attachment)
        path.move(to: CGPoint(x: bodyX, y: tailY))
        // Point to the left
        path.line(to: CGPoint(x: bodyX - tailWidth, y: tailY + tailHeight / 2))
        // Back to body edge (bottom of tail attachment)
        path.line(to: CGPoint(x: bodyX, y: tailY + tailHeight))
        path.close()

        color.setFill()
        path.fill()
    }
}
