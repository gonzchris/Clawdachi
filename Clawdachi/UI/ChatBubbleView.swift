//
//  ChatBubbleView.swift
//  Clawdachi
//
//  Custom NSView that draws a pixel-art chat bubble with text
//

import AppKit

/// Custom view that renders a pixel-art chat bubble with text
class ChatBubbleView: NSView {

    private typealias C = ChatBubbleConstants

    // MARK: - Properties

    private var message: String = ""
    private var hasTail: Bool = true
    private var bubbleImage: NSImage?
    private var textAttributes: [NSAttributedString.Key: Any] = [:]
    private var calculatedTextRect: CGRect = .zero
    private var cachedAttributedString: NSAttributedString?

    // View is flipped (0,0 at top-left) for easier text layout
    override var isFlipped: Bool { true }

    // MARK: - Configuration

    /// Configure the view with a message
    /// - Parameters:
    ///   - message: The text to display in the bubble
    ///   - hasTail: Whether to show the pointing tail (default true)
    func configure(message: String, hasTail: Bool = true) {
        self.message = message
        self.hasTail = hasTail
        setupTextAttributes()
        calculateSizeAndGenerateBubble()
        needsDisplay = true
    }

    // MARK: - Text Setup

    private func setupTextAttributes() {
        // Use Press Start 2P pixel font for authentic retro look
        let font = PixelFontLoader.pixelFont(size: C.fontSize)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = C.lineSpacing
        paragraphStyle.alignment = .center

        textAttributes = [
            .font: font,
            .foregroundColor: C.textColor,
            .paragraphStyle: paragraphStyle
        ]
    }

    // MARK: - Size Calculation

    private func calculateSizeAndGenerateBubble() {
        // Calculate text size with max width constraint
        let maxTextWidth = C.maxWidth - C.paddingHorizontal * 2

        // Create and cache attributed string
        let attributedString = NSAttributedString(string: message, attributes: textAttributes)
        cachedAttributedString = attributedString

        let textRect = attributedString.boundingRect(
            with: CGSize(width: maxTextWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        )

        // Ensure minimum width
        let textWidth = max(textRect.width, C.minWidth - C.paddingHorizontal * 2)
        let textHeight = textRect.height

        let contentSize = CGSize(width: ceil(textWidth), height: ceil(textHeight))

        // Generate bubble image
        bubbleImage = ChatBubbleTextures.generateBubble(contentSize: contentSize, hasTail: hasTail)

        // Calculate text rect for drawing
        // Text is drawn inside the bubble, accounting for shadow offset and padding
        let shadowOffset = CGFloat(C.shadowPixels) * C.pixelSize
        let outlineOffset = CGFloat(C.outlinePixels) * C.pixelSize

        calculatedTextRect = CGRect(
            x: shadowOffset + outlineOffset + C.paddingHorizontal,
            y: outlineOffset + C.paddingVertical - 1,  // Raised 1px
            width: ceil(textWidth),
            height: ceil(textHeight)
        )

        // Update view frame
        if let image = bubbleImage {
            setFrameSize(image.size)
        }
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Draw bubble background
        bubbleImage?.draw(in: bounds)

        // Draw cached text (avoids recreating attributed string)
        cachedAttributedString?.draw(in: calculatedTextRect)
    }
}
