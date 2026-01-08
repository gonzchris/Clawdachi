//
//  ChatBubbleView.swift
//  Clawdachi
//
//  Custom NSView that draws outlined text (no bubble background)
//

import AppKit

/// Custom view that renders outlined text for chat messages
class ChatBubbleView: NSView {

    private typealias C = ChatBubbleConstants

    // MARK: - Properties

    private var message: String = ""
    private var hasTail: Bool = true
    private var calculatedTextRect: CGRect = .zero
    private var renderedTextImage: NSImage?

    /// Render scale for crisp text (render larger, display smaller)
    private let renderScale: CGFloat = 2.0

    /// Font size at display scale
    private let displayFontSize: CGFloat = 18

    /// Stroke width for black outline
    private let strokeWidth: CGFloat = 4.0

    // View is flipped (0,0 at top-left) for easier text layout
    override var isFlipped: Bool { true }

    // MARK: - Configuration

    /// Configure the view with a message
    /// - Parameters:
    ///   - message: The text to display
    ///   - hasTail: Whether to show the pointing tail (ignored, kept for API compatibility)
    func configure(message: String, hasTail: Bool = true) {
        self.message = message
        self.hasTail = hasTail
        renderTextImage()
        needsDisplay = true
    }

    // MARK: - Text Rendering

    private func renderTextImage() {
        // Calculate sizes at render scale
        let renderFontSize = displayFontSize * renderScale
        let renderStrokeWidth = strokeWidth * renderScale

        // Use semibold monospace font
        let font = NSFont.monospacedSystemFont(ofSize: renderFontSize, weight: .bold)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = C.lineSpacing * renderScale
        paragraphStyle.alignment = .center

        // Calculate text size at render scale
        let maxTextWidth = (C.maxWidth - C.paddingHorizontal * 2) * renderScale
        let sizeAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]

        let sizeString = NSAttributedString(string: message, attributes: sizeAttributes)
        let textRect = sizeString.boundingRect(
            with: CGSize(width: maxTextWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        )

        // Add padding for stroke
        let strokePadding = renderStrokeWidth * 2
        let renderWidth = ceil(textRect.width) + strokePadding * 2
        let renderHeight = ceil(textRect.height) + strokePadding * 2

        // Create image at render scale
        let renderSize = CGSize(width: renderWidth, height: renderHeight)
        renderedTextImage = NSImage(size: renderSize, flipped: true) { rect in
            NSColor.clear.setFill()
            rect.fill()

            // Text drawing rect (centered with stroke padding)
            let drawRect = CGRect(
                x: strokePadding,
                y: strokePadding,
                width: ceil(textRect.width),
                height: ceil(textRect.height)
            )

            // Draw stroke first (black outline)
            let strokeAttributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.black,
                .strokeColor: NSColor.black,
                .strokeWidth: renderStrokeWidth,
                .paragraphStyle: paragraphStyle
            ]
            let strokeString = NSAttributedString(string: self.message, attributes: strokeAttributes)
            strokeString.draw(in: drawRect)

            // Draw fill on top (white text)
            let fillAttributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.white,
                .paragraphStyle: paragraphStyle
            ]
            let fillString = NSAttributedString(string: self.message, attributes: fillAttributes)
            fillString.draw(in: drawRect)

            return true
        }

        // Calculate display size (scaled down)
        let displayWidth = renderWidth / renderScale
        let displayHeight = renderHeight / renderScale

        // Position to match original bubble positioning
        // Keep horizontal offset from sprite, but text is now direct (no bubble body offset)
        calculatedTextRect = CGRect(
            x: 0,
            y: 0,
            width: displayWidth,
            height: displayHeight
        )

        setFrameSize(CGSize(width: displayWidth, height: displayHeight))
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let image = renderedTextImage else { return }

        // Enable high-quality interpolation for crisp downscaling
        NSGraphicsContext.current?.imageInterpolation = .high

        // Draw the pre-rendered text image scaled down
        image.draw(in: bounds)
    }
}
