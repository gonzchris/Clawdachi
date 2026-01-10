//
//  OnboardingContentView.swift
//  Clawdachi
//
//  Main content view for the Onboarding window with step navigation
//

import AppKit
import SpriteKit

/// Main content view for the Onboarding window
class OnboardingContentView: NSView {

    private typealias C = OnboardingConstants

    // MARK: - Properties

    weak var onboardingWindow: OnboardingWindow?

    // Step views
    private var bootSequenceView: BootSequenceView!
    private var claudeHooksView: ClaudeHooksView!
    private var customizeStepView: CustomizeStepView!

    private var contentContainer: NSView!
    private var stepViews: [OnboardingConstants.Step: NSView] = [:]

    // Tracking
    private var trackingArea: NSTrackingArea?
    private var isDragging = false
    private var dragStartPoint: NSPoint = .zero

    // CRT effect overlay
    private var crtEffect: CRTEffectView!

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
        setupManagerCallbacks()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        setupManagerCallbacks()
    }

    private func setupViews() {
        wantsLayer = true
        layer?.backgroundColor = C.backgroundColor.cgColor
        layer?.cornerRadius = 8
        layer?.masksToBounds = true
        layer?.borderWidth = 2
        layer?.borderColor = C.frameColor.cgColor

        setupContentContainer()
        setupStepViews()
        setupCRTEffect()

        // Show initial step
        showStep(.boot)
    }

    private func setupManagerCallbacks() {
        OnboardingManager.shared.onStepChange = { [weak self] step in
            self?.showStep(step)
        }
    }

    // MARK: - CRT Effect

    private func setupCRTEffect() {
        crtEffect = CRTEffectView(frame: bounds)
        crtEffect.autoresizingMask = [.width, .height]
        addSubview(crtEffect)
    }

    // MARK: - Content Container

    private func setupContentContainer() {
        let containerFrame = NSRect(
            x: 0,
            y: C.bottomBarHeight,
            width: C.windowWidth,
            height: C.contentHeight
        )
        contentContainer = NSView(frame: containerFrame)
        contentContainer.wantsLayer = true
        addSubview(contentContainer)
    }

    // MARK: - Step Views

    private func setupStepViews() {
        let stepFrame = NSRect(x: 0, y: 0, width: C.windowWidth, height: C.contentHeight)

        // Boot sequence
        bootSequenceView = BootSequenceView(frame: stepFrame)
        bootSequenceView.isHidden = true
        bootSequenceView.delegate = self
        contentContainer.addSubview(bootSequenceView)
        stepViews[.boot] = bootSequenceView

        // Claude hooks
        claudeHooksView = ClaudeHooksView(frame: stepFrame)
        claudeHooksView.isHidden = true
        claudeHooksView.delegate = self
        contentContainer.addSubview(claudeHooksView)
        stepViews[.hooks] = claudeHooksView

        // Customize
        customizeStepView = CustomizeStepView(frame: stepFrame)
        customizeStepView.isHidden = true
        customizeStepView.delegate = self
        contentContainer.addSubview(customizeStepView)
        stepViews[.customize] = customizeStepView
    }

    // MARK: - Step Switching

    private func showStep(_ step: OnboardingConstants.Step) {
        // Hide all step views
        for (_, view) in stepViews {
            view.isHidden = true
        }

        // Show current step
        stepViews[step]?.isHidden = false

        // Trigger step-specific actions
        switch step {
        case .boot:
            // Boot sequence handles its own animation
            break
        case .hooks:
            claudeHooksView.startProgressAnimation()
        case .customize:
            customizeStepView.startPreview()
        }

        needsDisplay = true
    }

    // MARK: - Drawing

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let context = NSGraphicsContext.current else { return }
        context.saveGraphicsState()

        // Fill background with rounded corners
        let bgPath = NSBezierPath(roundedRect: bounds, xRadius: 8, yRadius: 8)
        C.backgroundColor.setFill()
        bgPath.fill()

        // Draw pixel-art style border (3D effect)
        drawPixelBorder()

        // Draw title bar
        drawTitleBar()

        // Draw bottom bar divider
        drawBottomDivider()

        context.restoreGraphicsState()
    }

    private func drawPixelBorder() {
        let inset: CGFloat = 1

        // Outer highlight (top & left)
        C.frameHighlight.setStroke()
        let highlightPath = NSBezierPath()
        highlightPath.move(to: NSPoint(x: inset, y: bounds.height - inset))
        highlightPath.line(to: NSPoint(x: inset, y: inset))
        highlightPath.line(to: NSPoint(x: bounds.width - inset, y: inset))
        highlightPath.lineWidth = 2
        highlightPath.stroke()

        // Outer shadow (bottom & right)
        C.frameShadow.setStroke()
        let shadowPath = NSBezierPath()
        shadowPath.move(to: NSPoint(x: bounds.width - inset, y: inset))
        shadowPath.line(to: NSPoint(x: bounds.width - inset, y: bounds.height - inset))
        shadowPath.line(to: NSPoint(x: inset, y: bounds.height - inset))
        shadowPath.lineWidth = 2
        shadowPath.stroke()
    }

    private func drawTitleBar() {
        // Title bar background
        let titleRect = NSRect(x: 2, y: 2, width: bounds.width - 4, height: C.titleBarHeight - 2)
        let titlePath = NSBezierPath(roundedRect: titleRect, xRadius: 6, yRadius: 6)
        C.panelColor.setFill()
        titlePath.fill()

        // Title text (changes based on step)
        let step = OnboardingManager.shared.currentStep
        let title = step.title
        let font = NSFont.monospacedSystemFont(ofSize: C.titleFontSize, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: C.accentColor
        ]
        let titleStr = NSAttributedString(string: title, attributes: attrs)
        let titleSize = titleStr.size()
        let titlePoint = NSPoint(
            x: 16,
            y: (C.titleBarHeight - titleSize.height) / 2 + 1
        )
        titleStr.draw(at: titlePoint)
    }

    private func drawBottomDivider() {
        let dividerY = bounds.height - C.bottomBarHeight

        C.frameColor.setStroke()
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 8, y: dividerY))
        path.line(to: NSPoint(x: bounds.width - 8, y: dividerY))
        path.lineWidth = 1
        path.stroke()
    }

    // MARK: - Drag Handling

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        if let event = event {
            let location = convert(event.locationInWindow, from: nil)
            if location.y < C.titleBarHeight {
                return true
            }
        }
        return true
    }

    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)

        // Check if in title bar area (for dragging)
        if location.y < C.titleBarHeight {
            isDragging = true
            dragStartPoint = event.locationInWindow
            return
        }

        super.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        if isDragging {
            guard let window = window else { return }
            let currentPoint = event.locationInWindow
            let deltaX = currentPoint.x - dragStartPoint.x
            let deltaY = currentPoint.y - dragStartPoint.y

            var newOrigin = window.frame.origin
            newOrigin.x += deltaX
            newOrigin.y += deltaY
            window.setFrameOrigin(newOrigin)
            return
        }

        super.mouseDragged(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        isDragging = false
        super.mouseUp(with: event)
    }

    // MARK: - Public Methods

    /// Start the boot sequence animation with CRT power-on effect
    func startBootSequence() {
        // Play power-on animation, then start boot sequence
        crtEffect.playPowerOnAnimation { [weak self] in
            self?.bootSequenceView.startAnimation()
        }
    }

    /// Get the sprite's screen position for jump animation
    func getSpriteScreenPosition() -> CGPoint {
        guard let window = window else { return .zero }

        // Get the position from the customize step's preview
        let localPosition = customizeStepView.getSpritePosition()

        // Convert to screen coordinates
        let windowPosition = window.frame.origin
        return CGPoint(
            x: windowPosition.x + localPosition.x - 144,  // Center sprite (288/2)
            y: windowPosition.y + localPosition.y - 192   // Center sprite (384/2)
        )
    }

}

// MARK: - Boot Sequence Delegate

extension OnboardingContentView: BootSequenceViewDelegate {
    func bootSequenceDidComplete() {
        // Boot sequence shows its own continue button
    }

    func bootSequenceNextClicked() {
        OnboardingManager.shared.nextStep()
    }
}

// MARK: - Claude Hooks View Delegate

extension OnboardingContentView: ClaudeHooksViewDelegate {
    func claudeHooksNextClicked() {
        OnboardingManager.shared.nextStep()
    }
}

// MARK: - Customize Step View Delegate

extension OnboardingContentView: CustomizeStepViewDelegate {
    func customizeStepLaunchClicked() {
        let launchPosition = OnboardingWindow.bottomLeftPosition()
        OnboardingManager.shared.completeOnboarding(launchPosition: launchPosition)
    }
}
