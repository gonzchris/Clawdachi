//
//  ASCIIFrameRenderer.swift
//  Clawdachi
//
//  Renders ASCII box-drawing characters for the terminal-inspired Settings UI
//

import AppKit

/// Renders ASCII box-drawing frames with a terminal aesthetic
enum ASCIIFrameRenderer {

    private typealias C = SettingsConstants

    // MARK: - Frame Drawing

    /// Draws a complete ASCII frame in the given rect
    /// - Parameters:
    ///   - rect: The rectangle to draw the frame in
    ///   - context: The graphics context to draw in
    ///   - color: The color for the frame lines
    static func drawFrame(in rect: NSRect, color: NSColor = C.frameColor) {
        let charW = C.ASCII.charWidth
        let charH = C.ASCII.charHeight

        // Draw corners
        drawChar(C.ASCII.topLeft, at: NSPoint(x: rect.minX, y: rect.maxY - charH), color: color)
        drawChar(C.ASCII.topRight, at: NSPoint(x: rect.maxX - charW, y: rect.maxY - charH), color: color)
        drawChar(C.ASCII.bottomLeft, at: NSPoint(x: rect.minX, y: rect.minY), color: color)
        drawChar(C.ASCII.bottomRight, at: NSPoint(x: rect.maxX - charW, y: rect.minY), color: color)

        // Draw horizontal lines (top and bottom)
        let hCount = Int((rect.width - 2 * charW) / charW)
        for i in 0..<hCount {
            let x = rect.minX + charW + CGFloat(i) * charW
            drawChar(C.ASCII.horizontal, at: NSPoint(x: x, y: rect.maxY - charH), color: color)
            drawChar(C.ASCII.horizontal, at: NSPoint(x: x, y: rect.minY), color: color)
        }

        // Draw vertical lines (left and right)
        let vCount = Int((rect.height - 2 * charH) / charH)
        for i in 0..<vCount {
            let y = rect.minY + charH + CGFloat(i) * charH
            drawChar(C.ASCII.vertical, at: NSPoint(x: rect.minX, y: y), color: color)
            drawChar(C.ASCII.vertical, at: NSPoint(x: rect.maxX - charW, y: y), color: color)
        }
    }

    /// Draws a horizontal divider line with tee connectors
    static func drawHorizontalDivider(at y: CGFloat, in rect: NSRect, color: NSColor = C.frameColor) {
        let charW = C.ASCII.charWidth

        // Left tee
        drawChar(C.ASCII.teeRight, at: NSPoint(x: rect.minX, y: y), color: color)

        // Horizontal line
        let hCount = Int((rect.width - 2 * charW) / charW)
        for i in 0..<hCount {
            let x = rect.minX + charW + CGFloat(i) * charW
            drawChar(C.ASCII.horizontal, at: NSPoint(x: x, y: y), color: color)
        }

        // Right tee
        drawChar(C.ASCII.teeLeft, at: NSPoint(x: rect.maxX - charW, y: y), color: color)
    }

    /// Draws a vertical divider line with tee connectors
    static func drawVerticalDivider(at x: CGFloat, in rect: NSRect, color: NSColor = C.frameColor) {
        let charH = C.ASCII.charHeight

        // Top tee
        drawChar(C.ASCII.teeDown, at: NSPoint(x: x, y: rect.maxY - charH), color: color)

        // Vertical line
        let vCount = Int((rect.height - 2 * charH) / charH)
        for i in 0..<vCount {
            let y = rect.minY + charH + CGFloat(i) * charH
            drawChar(C.ASCII.vertical, at: NSPoint(x: x, y: y), color: color)
        }

        // Bottom tee
        drawChar(C.ASCII.teeUp, at: NSPoint(x: x, y: rect.minY), color: color)
    }

    /// Draws a single box-drawing character at the specified position
    static func drawChar(_ char: String, at point: NSPoint, color: NSColor) {
        let font = NSFont.monospacedSystemFont(ofSize: C.ASCII.charHeight - 2, weight: .regular)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]

        let string = NSAttributedString(string: char, attributes: attributes)
        string.draw(at: point)
    }

    // MARK: - Styled Text Drawing

    /// Draws text with the terminal monospace style
    static func drawText(
        _ text: String,
        at point: NSPoint,
        fontSize: CGFloat,
        color: NSColor = C.textColor,
        weight: NSFont.Weight = .semibold
    ) {
        let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: weight)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]

        let string = NSAttributedString(string: text, attributes: attributes)
        string.draw(at: point)
    }

    /// Draws centered text within a rect
    static func drawCenteredText(
        _ text: String,
        in rect: NSRect,
        fontSize: CGFloat,
        color: NSColor = C.textColor,
        weight: NSFont.Weight = .semibold
    ) {
        let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: weight)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]

        let string = NSAttributedString(string: text, attributes: attributes)
        let size = string.size()

        let x = rect.midX - size.width / 2
        let y = rect.midY - size.height / 2

        string.draw(at: NSPoint(x: x, y: y))
    }

    // MARK: - Button Drawing

    /// Draws an ASCII-styled button
    static func drawButton(
        text: String,
        in rect: NSRect,
        isHovered: Bool = false,
        isAccent: Bool = false
    ) {
        let bgColor = isAccent ? C.accentColor : (isHovered ? C.buttonHoverColor : C.panelColor)
        let textColor = isAccent ? C.backgroundColor : C.textColor

        // Draw background
        bgColor.setFill()
        let path = NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4)
        path.fill()

        // Draw border
        C.frameColor.setStroke()
        path.lineWidth = 1
        path.stroke()

        // Draw text
        drawCenteredText(text, in: rect, fontSize: 10, color: textColor, weight: .bold)
    }

    // MARK: - Inner Frame (for preview box)

    /// Draws a smaller inner frame for content areas
    static func drawInnerFrame(in rect: NSRect, color: NSColor = C.frameColor) {
        let charW = C.ASCII.charWidth * 0.75
        let charH = C.ASCII.charHeight * 0.75
        let smallFont = NSFont.monospacedSystemFont(ofSize: charH - 2, weight: .regular)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: smallFont,
            .foregroundColor: color
        ]

        func draw(_ char: String, at point: NSPoint) {
            NSAttributedString(string: char, attributes: attributes).draw(at: point)
        }

        // Corners
        draw(C.ASCII.topLeft, at: NSPoint(x: rect.minX, y: rect.maxY - charH))
        draw(C.ASCII.topRight, at: NSPoint(x: rect.maxX - charW, y: rect.maxY - charH))
        draw(C.ASCII.bottomLeft, at: NSPoint(x: rect.minX, y: rect.minY))
        draw(C.ASCII.bottomRight, at: NSPoint(x: rect.maxX - charW, y: rect.minY))

        // Horizontals
        let hCount = Int((rect.width - 2 * charW) / charW)
        for i in 0..<hCount {
            let x = rect.minX + charW + CGFloat(i) * charW
            draw(C.ASCII.horizontal, at: NSPoint(x: x, y: rect.maxY - charH))
            draw(C.ASCII.horizontal, at: NSPoint(x: x, y: rect.minY))
        }

        // Verticals
        let vCount = Int((rect.height - 2 * charH) / charH)
        for i in 0..<vCount {
            let y = rect.minY + charH + CGFloat(i) * charH
            draw(C.ASCII.vertical, at: NSPoint(x: rect.minX, y: y))
            draw(C.ASCII.vertical, at: NSPoint(x: rect.maxX - charW, y: y))
        }
    }

    // MARK: - Cached Frame Images

    /// Creates a cached image of a frame for better performance
    static func createFrameImage(size: NSSize, color: NSColor = C.frameColor) -> NSImage {
        let image = NSImage(size: size, flipped: true) { rect in
            C.backgroundColor.setFill()
            rect.fill()
            self.drawFrame(in: rect, color: color)
            return true
        }
        return image
    }
}
