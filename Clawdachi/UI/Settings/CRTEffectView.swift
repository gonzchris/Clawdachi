//
//  CRTEffectView.swift
//  Clawdachi
//
//  CRT monitor effect overlay with scanlines, vignette, and flicker
//

import AppKit

/// Overlay view that adds CRT monitor effects
class CRTEffectView: NSView {

    // MARK: - Properties

    /// Scanline opacity (0.0 - 1.0)
    var scanlineOpacity: CGFloat = 0.08

    /// Scanline spacing in points
    var scanlineSpacing: CGFloat = 2.0

    /// Vignette intensity (0.0 - 1.0)
    var vignetteIntensity: CGFloat = 0.3

    /// Enable subtle flicker animation
    var flickerEnabled: Bool = false

    private var flickerTimer: Timer?
    private var currentFlickerAlpha: CGFloat = 0.0

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor

        // Don't intercept mouse events
        // This view is just for visual effects
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let bounds = self.bounds

        // Draw scanlines
        drawScanlines(in: bounds, context: context)

        // Draw vignette
        drawVignette(in: bounds, context: context)

        // Draw flicker overlay
        if flickerEnabled && currentFlickerAlpha > 0 {
            drawFlicker(in: bounds, context: context)
        }
    }

    // MARK: - Scanlines

    private func drawScanlines(in rect: NSRect, context: CGContext) {
        context.saveGState()

        // Semi-transparent black lines
        context.setFillColor(NSColor(white: 0, alpha: scanlineOpacity).cgColor)

        var y: CGFloat = 0
        while y < rect.height {
            let lineRect = CGRect(x: 0, y: y, width: rect.width, height: 1)
            context.fill(lineRect)
            y += scanlineSpacing
        }

        context.restoreGState()
    }

    // MARK: - Vignette

    private func drawVignette(in rect: NSRect, context: CGContext) {
        context.saveGState()

        let centerX = rect.midX
        let centerY = rect.midY
        let radius = max(rect.width, rect.height) * 0.8

        // Create radial gradient from center (clear) to edges (dark)
        let colors = [
            NSColor(white: 0, alpha: 0).cgColor,
            NSColor(white: 0, alpha: 0).cgColor,
            NSColor(white: 0, alpha: vignetteIntensity * 0.5).cgColor,
            NSColor(white: 0, alpha: vignetteIntensity).cgColor
        ]
        let locations: [CGFloat] = [0.0, 0.5, 0.8, 1.0]

        if let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors as CFArray,
            locations: locations
        ) {
            context.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: centerX, y: centerY),
                startRadius: 0,
                endCenter: CGPoint(x: centerX, y: centerY),
                endRadius: radius,
                options: .drawsAfterEndLocation
            )
        }

        context.restoreGState()
    }

    // MARK: - Flicker

    private func drawFlicker(in rect: NSRect, context: CGContext) {
        context.saveGState()
        context.setFillColor(NSColor(white: 1, alpha: currentFlickerAlpha).cgColor)
        context.fill(rect)
        context.restoreGState()
    }

    // MARK: - Animation

    func startFlicker() {
        guard flickerEnabled else { return }

        flickerTimer?.invalidate()
        flickerTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateFlicker()
        }
    }

    func stopFlicker() {
        flickerTimer?.invalidate()
        flickerTimer = nil
        currentFlickerAlpha = 0
        needsDisplay = true
    }

    private func updateFlicker() {
        // Random subtle brightness fluctuation
        let shouldFlicker = Int.random(in: 0...20) == 0
        if shouldFlicker {
            currentFlickerAlpha = CGFloat.random(in: 0.01...0.03)
        } else {
            currentFlickerAlpha = 0
        }
        needsDisplay = true
    }

    // MARK: - Hit Testing

    override func hitTest(_ point: NSPoint) -> NSView? {
        // Pass through all mouse events to views below
        return nil
    }

    override var acceptsFirstResponder: Bool { false }
}
