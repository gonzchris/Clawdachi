//
//  SettingsContentView.swift
//  Clawdachi
//
//  Main content view for the Settings window with sidebar navigation
//

import AppKit
import SpriteKit

/// Main content view for the Settings window
class SettingsContentView: NSView {

    private typealias C = SettingsConstants

    // MARK: - Properties

    weak var settingsWindow: SettingsWindow?

    private var sidebar: SettingsSidebar!
    private var contentContainer: NSView!

    // Section views
    private var customizationView: CustomizationSectionView!
    private var claudeView: ClaudeSettingsView!
    private var generalView: GeneralSettingsView!
    private var soundView: SoundSettingsView!
    private var aboutView: AboutSettingsView!

    private var currentSection: C.Section = .customize
    private var closeButton: SettingsButton!

    private var trackingArea: NSTrackingArea?
    private var isDragging = false
    private var dragStartPoint: NSPoint = .zero

    // CRT effect overlay
    private var crtEffect: CRTEffectView!

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        wantsLayer = true
        layer?.backgroundColor = C.backgroundColor.cgColor
        layer?.cornerRadius = 8
        layer?.masksToBounds = true  // Clip content to rounded corners
        layer?.borderWidth = 2
        layer?.borderColor = C.frameColor.cgColor

        setupSidebar()
        setupContentContainer()
        setupSectionViews()
        setupButtons()
        setupCRTEffect()

        // Show initial section
        showSection(.customize)
    }

    // MARK: - CRT Effect

    private func setupCRTEffect() {
        crtEffect = CRTEffectView(frame: bounds)
        crtEffect.autoresizingMask = [.width, .height]
        addSubview(crtEffect)
    }

    // MARK: - Sidebar Setup

    private func setupSidebar() {
        let sidebarFrame = NSRect(
            x: 0,
            y: C.bottomBarHeight,
            width: C.sidebarWidth,
            height: C.contentHeight
        )
        sidebar = SettingsSidebar(frame: sidebarFrame)
        sidebar.delegate = self
        addSubview(sidebar)
    }

    // MARK: - Content Container

    private func setupContentContainer() {
        let containerFrame = NSRect(
            x: C.sidebarWidth,
            y: C.bottomBarHeight,
            width: C.contentAreaWidth,
            height: C.contentHeight
        )
        contentContainer = NSView(frame: containerFrame)
        contentContainer.wantsLayer = true
        addSubview(contentContainer)
    }

    // MARK: - Section Views

    private func setupSectionViews() {
        let sectionFrame = NSRect(x: 0, y: 0, width: C.contentAreaWidth, height: C.contentHeight)

        // Customization section (combines preview + grid)
        customizationView = CustomizationSectionView(frame: sectionFrame)
        customizationView.isHidden = true
        contentContainer.addSubview(customizationView)

        // Claude settings
        claudeView = ClaudeSettingsView(frame: sectionFrame)
        claudeView.isHidden = true
        contentContainer.addSubview(claudeView)

        // General settings
        generalView = GeneralSettingsView(frame: sectionFrame)
        generalView.isHidden = true
        contentContainer.addSubview(generalView)

        // Sound settings
        soundView = SoundSettingsView(frame: sectionFrame)
        soundView.isHidden = true
        contentContainer.addSubview(soundView)

        // About
        aboutView = AboutSettingsView(frame: sectionFrame)
        aboutView.isHidden = true
        contentContainer.addSubview(aboutView)
    }

    private func setupButtons() {
        // Close button (right side of bottom bar)
        let closeFrame = NSRect(
            x: C.windowWidth - 80 - C.panelPadding,
            y: 10,
            width: 80,
            height: 24
        )
        closeButton = SettingsButton(frame: closeFrame, title: "CLOSE")
        closeButton.target = self
        closeButton.action = #selector(closeButtonClicked)
        addSubview(closeButton)
    }

    // MARK: - Section Switching

    private func showSection(_ section: C.Section) {
        currentSection = section

        // Hide all sections and stop their animations
        customizationView.isHidden = true
        customizationView.stopAnimation()
        claudeView.isHidden = true
        generalView.isHidden = true
        soundView.isHidden = true
        aboutView.isHidden = true

        // Show selected section and start its animation
        switch section {
        case .customize:
            customizationView.isHidden = false
            customizationView.startAnimation()
        case .claude:
            claudeView.isHidden = false
            claudeView.refresh()
        case .general:
            generalView.isHidden = false
        case .sound:
            soundView.isHidden = false
        case .about:
            aboutView.isHidden = false
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

        // Draw sidebar background
        drawSidebarBackground()

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

        // Title text
        let title = "SETTINGS"
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

        // Close X button in top right
        let xFont = NSFont.monospacedSystemFont(ofSize: 14, weight: .medium)
        let xAttrs: [NSAttributedString.Key: Any] = [
            .font: xFont,
            .foregroundColor: C.textDimColor
        ]
        let xStr = NSAttributedString(string: "x", attributes: xAttrs)
        let xPoint = NSPoint(x: bounds.width - 20, y: 6)
        xStr.draw(at: xPoint)
    }

    private func drawSidebarBackground() {
        let sidebarRect = NSRect(
            x: 2,
            y: C.titleBarHeight,
            width: C.sidebarWidth - 2,
            height: bounds.height - C.titleBarHeight - C.bottomBarHeight
        )

        // Custom path with rounded bottom-left corner only
        let radius: CGFloat = 6
        let sidebarPath = NSBezierPath()

        // Start at top-left
        sidebarPath.move(to: NSPoint(x: sidebarRect.minX, y: sidebarRect.minY))
        // Line to top-right
        sidebarPath.line(to: NSPoint(x: sidebarRect.maxX, y: sidebarRect.minY))
        // Line down right side
        sidebarPath.line(to: NSPoint(x: sidebarRect.maxX, y: sidebarRect.maxY))
        // Line to bottom-left corner start
        sidebarPath.line(to: NSPoint(x: sidebarRect.minX + radius, y: sidebarRect.maxY))
        // Rounded bottom-left corner
        sidebarPath.appendArc(
            withCenter: NSPoint(x: sidebarRect.minX + radius, y: sidebarRect.maxY - radius),
            radius: radius,
            startAngle: 270,
            endAngle: 180,
            clockwise: true
        )
        // Line back up
        sidebarPath.line(to: NSPoint(x: sidebarRect.minX, y: sidebarRect.minY))
        sidebarPath.close()

        C.panelColor.setFill()
        sidebarPath.fill()

        // Sidebar divider
        C.frameColor.setStroke()
        let dividerPath = NSBezierPath()
        dividerPath.move(to: NSPoint(x: C.sidebarWidth, y: C.titleBarHeight))
        dividerPath.line(to: NSPoint(x: C.sidebarWidth, y: bounds.height - C.bottomBarHeight))
        dividerPath.lineWidth = 1
        dividerPath.stroke()
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
        // Allow dragging without requiring focus first
        if let event = event {
            let location = convert(event.locationInWindow, from: nil)
            // Accept first mouse in title bar area
            if location.y < C.titleBarHeight {
                return true
            }
        }
        return true
    }

    func setupDragTracking() {
        let options: NSTrackingArea.Options = [.activeAlways, .mouseMoved, .mouseEnteredAndExited]
        trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea!)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let options: NSTrackingArea.Options = [.activeAlways, .mouseMoved, .mouseEnteredAndExited]
        trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea!)
    }

    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)

        // Check if clicking the X button area
        if location.y < C.titleBarHeight && location.x > bounds.width - 28 {
            settingsWindow?.closeButtonClicked()
            return
        }

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

    // MARK: - Button Actions

    @objc private func closeButtonClicked() {
        settingsWindow?.closeButtonClicked()
    }

    // MARK: - Preview Animation Control

    func startPreviewAnimation() {
        if currentSection == .customize {
            customizationView.startAnimation()
        }
    }

    func stopPreviewAnimation() {
        customizationView.stopAnimation()
    }

    // MARK: - Refresh

    func refresh() {
        customizationView.refresh()
    }
}

// MARK: - Sidebar Delegate

extension SettingsContentView: SettingsSidebarDelegate {
    func sidebar(_ sidebar: SettingsSidebar, didSelectSection section: SettingsConstants.Section) {
        showSection(section)
    }
}

// MARK: - Settings Button

/// Custom button with pixel-art RPG styling
class SettingsButton: NSView {

    private typealias C = SettingsConstants

    var title: String
    var icon: NSImage?
    var isHovered: Bool = false

    weak var target: AnyObject?
    var action: Selector?

    private var trackingArea: NSTrackingArea?

    init(frame: NSRect, title: String, icon: NSImage? = nil) {
        self.title = title
        self.icon = icon
        super.init(frame: frame)
        setupTracking()
    }

    required init?(coder: NSCoder) {
        self.title = ""
        self.icon = nil
        super.init(coder: coder)
        setupTracking()
    }

    private func setupTracking() {
        let options: NSTrackingArea.Options = [.activeAlways, .mouseEnteredAndExited]
        trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea!)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let options: NSTrackingArea.Options = [.activeAlways, .mouseEnteredAndExited]
        trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea!)
    }

    override func draw(_ dirtyRect: NSRect) {
        // Background
        let bgColor = isHovered ? C.buttonHoverColor : C.panelColor
        let bgPath = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 4, yRadius: 4)
        bgColor.setFill()
        bgPath.fill()

        // Border
        C.frameColor.setStroke()
        bgPath.lineWidth = 1
        bgPath.stroke()

        // Text
        let font = NSFont.monospacedSystemFont(ofSize: 10, weight: .semibold)
        let textColor = isHovered ? C.accentColor : C.textColor
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        let str = NSAttributedString(string: title, attributes: attrs)
        let textSize = str.size()

        // Calculate layout with optional icon
        let iconSize: CGFloat = 12
        let iconSpacing: CGFloat = 4
        let hasIcon = icon != nil

        let totalWidth = hasIcon ? (iconSize + iconSpacing + textSize.width) : textSize.width
        let startX = (bounds.width - totalWidth) / 2

        // Draw icon if present
        if let icon = icon {
            let iconY = (bounds.height - iconSize) / 2
            let iconRect = NSRect(x: startX, y: iconY, width: iconSize, height: iconSize)
            icon.draw(in: iconRect)
        }

        // Draw text
        let textX = hasIcon ? (startX + iconSize + iconSpacing) : startX
        let textY = (bounds.height - textSize.height) / 2
        str.draw(at: NSPoint(x: textX, y: textY))
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        alphaValue = 0.8
    }

    override func mouseUp(with event: NSEvent) {
        alphaValue = 1.0
        let location = convert(event.locationInWindow, from: nil)
        if bounds.contains(location) {
            if let target = target, let action = action {
                NSApp.sendAction(action, to: target, from: self)
            }
        }
    }
}
