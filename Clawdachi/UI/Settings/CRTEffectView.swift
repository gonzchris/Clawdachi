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

    // Power-on animation state
    private var isPoweringOn: Bool = false
    private var powerOnProgress: CGFloat = 0.0
    private var powerOnPhase: PowerOnPhase = .idle
    private var powerOnCompletion: (() -> Void)?

    private enum PowerOnPhase {
        case idle
        case flash       // Brief bright flash
        case scanline    // Horizontal line expands
        case brighten    // Screen fades in
        case complete
    }

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

        // Draw power-on animation (takes over entire screen during animation)
        if isPoweringOn {
            drawPowerOn(in: bounds, context: context)
            return  // Don't draw other effects during power-on
        }

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

    // MARK: - Power On Animation

    /// Play CRT power-on animation (call before showing content)
    func playPowerOnAnimation(completion: (() -> Void)? = nil) {
        guard !isPoweringOn else { return }

        isPoweringOn = true
        powerOnPhase = .scanline  // Skip flash, go straight to scanline
        powerOnProgress = 0.0
        powerOnCompletion = completion

        // Start animation loop
        animatePowerOn()
    }

    private func animatePowerOn() {
        switch powerOnPhase {
        case .idle, .complete:
            return

        case .flash:
            // Quick bright flash (0.05s)
            powerOnProgress = 1.0
            needsDisplay = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.powerOnPhase = .scanline
                self?.powerOnProgress = 0.0
                self?.animatePowerOn()
            }

        case .scanline:
            // Horizontal line expands from center (0.15s)
            let duration: TimeInterval = 0.15
            let steps = 15
            let stepTime = duration / Double(steps)
            var currentStep = 0

            func animateStep() {
                currentStep += 1
                self.powerOnProgress = CGFloat(currentStep) / CGFloat(steps)
                self.needsDisplay = true

                if currentStep < steps {
                    DispatchQueue.main.asyncAfter(deadline: .now() + stepTime) {
                        animateStep()
                    }
                } else {
                    self.powerOnPhase = .brighten
                    self.powerOnProgress = 0.0
                    self.animatePowerOn()
                }
            }
            animateStep()

        case .brighten:
            // Screen fades in (0.2s)
            let duration: TimeInterval = 0.2
            let steps = 20
            let stepTime = duration / Double(steps)
            var currentStep = 0

            func animateStep() {
                currentStep += 1
                self.powerOnProgress = CGFloat(currentStep) / CGFloat(steps)
                self.needsDisplay = true

                if currentStep < steps {
                    DispatchQueue.main.asyncAfter(deadline: .now() + stepTime) {
                        animateStep()
                    }
                } else {
                    self.powerOnPhase = .complete
                    self.isPoweringOn = false
                    self.powerOnCompletion?()
                }
            }
            animateStep()
        }
    }

    private func drawPowerOn(in rect: NSRect, context: CGContext) {
        context.saveGState()

        switch powerOnPhase {
        case .idle, .complete:
            break

        case .flash:
            // Bright white flash
            context.setFillColor(NSColor(white: 1, alpha: 0.8 * powerOnProgress).cgColor)
            context.fill(rect)

        case .scanline:
            // Black screen with expanding horizontal line from center
            // First fill with black
            context.setFillColor(NSColor.black.cgColor)
            context.fill(rect)

            // Draw expanding bright line
            let centerY = rect.midY
            let lineHeight: CGFloat = 2 + (20 * powerOnProgress)  // Grows from 2 to 22
            let lineWidth = rect.width * powerOnProgress

            let lineRect = CGRect(
                x: (rect.width - lineWidth) / 2,
                y: centerY - lineHeight / 2,
                width: lineWidth,
                height: lineHeight
            )

            // Bright phosphor color (slight orange tint)
            let phosphorColor = NSColor(red: 1.0, green: 0.95, blue: 0.9, alpha: 0.9)
            context.setFillColor(phosphorColor.cgColor)
            context.fill(lineRect)

            // Add glow around the line
            let glowColor = NSColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.3)
            context.setFillColor(glowColor.cgColor)
            let glowRect = lineRect.insetBy(dx: -8, dy: -8)
            context.fill(glowRect)

        case .brighten:
            // Black overlay fading out to reveal content
            let alpha = 1.0 - powerOnProgress
            context.setFillColor(NSColor(white: 0, alpha: alpha).cgColor)
            context.fill(rect)
        }

        context.restoreGState()
    }

    // MARK: - Hit Testing

    override func hitTest(_ point: NSPoint) -> NSView? {
        // Pass through all mouse events to views below
        return nil
    }

    override var acceptsFirstResponder: Bool { false }
}
