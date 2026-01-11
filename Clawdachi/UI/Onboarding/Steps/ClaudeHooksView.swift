//
//  ClaudeHooksView.swift
//  Clawdachi
//
//  Claude Code integration explanation with animated preview
//

import AppKit
import SpriteKit

/// Delegate for ClaudeHooksView completion
protocol ClaudeHooksViewDelegate: AnyObject {
    func claudeHooksNextClicked()
}

/// View explaining Claude Code integration with animated sprite preview
class ClaudeHooksView: NSView {

    private typealias C = OnboardingConstants
    private typealias SC = SettingsConstants

    // MARK: - Properties

    weak var delegate: ClaudeHooksViewDelegate?

    // Header
    private var titleLabel: NSTextField!
    private var subtitleLabel: NSTextField!
    private var descriptionLabel: NSTextField!

    // Animated preview
    private var previewContainer: NSView!
    private var skView: SKView!
    private var previewScene: SKScene!
    private var previewSprite: ClawdachiSprite!

    // Reaction descriptions
    private var reactionLabels: [NSTextField] = []

    // Terminal selection
    private var terminalHeader: NSTextField!
    private var terminalButtons: [NSButton] = []

    // Continue button
    private var continueButton: NSButton!

    // Bottom bar
    private var versionLabel: NSTextField!

    private var selectedTerminal: ClaudeLauncher.Terminal = .terminalApp
    private var demoTimer: Timer?
    private var currentDemoState: Int = 0

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
        setupHeader()
        setupPreview()
        setupReactionList()
        setupTerminalSelection()
        setupContinueButton()
        setupVersionLabel()

        // Load saved terminal preference
        selectedTerminal = ClaudeLauncher.shared.preferredTerminal
        updateTerminalSelection()
    }

    override var isFlipped: Bool { true }

    // MARK: - Header Section

    private let topPadding: CGFloat = 20  // Extra top padding to push content down

    private func setupHeader() {
        // Main title
        titleLabel = NSTextField(labelWithString: "CLAWDACHI × CLAUDE CODE")
        titleLabel.frame = NSRect(x: 0, y: C.panelPadding + topPadding, width: bounds.width, height: 24)
        titleLabel.font = NSFont.monospacedSystemFont(ofSize: C.sectionFontSize + 2, weight: .bold)
        titleLabel.textColor = C.accentColor
        titleLabel.alignment = .center
        addSubview(titleLabel)

        // Subtitle
        subtitleLabel = NSTextField(labelWithString: "Clawdachi tracks your Claude Code sessions and shows their status in real time.")
        subtitleLabel.frame = NSRect(x: 0, y: C.panelPadding + topPadding + 28, width: bounds.width, height: 18)
        subtitleLabel.font = NSFont.monospacedSystemFont(ofSize: C.terminalFontSize, weight: .bold)
        subtitleLabel.textColor = C.textColor
        subtitleLabel.alignment = .center
        addSubview(subtitleLabel)
    }

    // MARK: - Animated Preview (Left Column)

    private func setupPreview() {
        let contentY: CGFloat = 95 + topPadding
        let previewSize: CGFloat = 120

        // Calculate center of the reaction list content to center sprite above it
        // Reaction list: action (105) + arrow (20) + desc (250) = ~375px wide
        // Center should align with the arrow position
        let reactionListCenterX: CGFloat = 280
        let previewX = reactionListCenterX - previewSize / 2

        previewContainer = NSView(frame: NSRect(
            x: previewX,
            y: contentY,
            width: previewSize,
            height: previewSize
        ))
        previewContainer.wantsLayer = true
        previewContainer.layer?.backgroundColor = SC.cellBackgroundColor.cgColor
        previewContainer.layer?.cornerRadius = 6
        previewContainer.layer?.borderWidth = 2
        previewContainer.layer?.borderColor = SC.frameColor.cgColor
        addSubview(previewContainer)

        // SpriteKit view
        skView = SKView(frame: NSRect(x: 0, y: 0, width: previewSize, height: previewSize))
        skView.allowsTransparency = true
        previewContainer.addSubview(skView)

        // Create scene
        let sceneSize: CGFloat = 50
        previewScene = SKScene(size: CGSize(width: sceneSize, height: sceneSize))
        previewScene.backgroundColor = .clear
        previewScene.scaleMode = .aspectFit

        // Create sprite
        previewSprite = ClawdachiSprite()
        previewSprite.position = CGPoint(x: sceneSize / 2, y: sceneSize / 2 - 2)
        previewScene.addChild(previewSprite)

        skView.presentScene(previewScene)
    }

    // MARK: - Reaction List (Below Preview)

    private func setupReactionList() {
        let reactions = [
            ("thinking", "Claude is working on code"),
            ("planning", "Claude is designing a solution"),
            ("celebrating", "Session complete!"),
            ("vibing", "Dancing to your music"),
            ("napping", "Taking a break while you're away")
        ]

        // Position list to be centered under the sprite preview
        // Sprite is centered at x=280, so center the list there too
        let listCenterX: CGFloat = 280
        let startY: CGFloat = 250
        let rowHeight: CGFloat = 24

        for (index, (action, description)) in reactions.enumerated() {
            let yOffset = startY + CGFloat(index) * rowHeight

            // Action label (orange) - right aligned before arrow
            let actionLabel = NSTextField(labelWithString: action)
            actionLabel.frame = NSRect(x: listCenterX - 115, y: yOffset, width: 105, height: 18)
            actionLabel.font = NSFont.monospacedSystemFont(ofSize: C.terminalFontSize + 1, weight: .bold)
            actionLabel.textColor = C.accentColor
            actionLabel.alignment = .right
            addSubview(actionLabel)
            reactionLabels.append(actionLabel)

            // Arrow
            let arrowLabel = NSTextField(labelWithString: "→")
            arrowLabel.frame = NSRect(x: listCenterX - 5, y: yOffset, width: 20, height: 18)
            arrowLabel.font = NSFont.monospacedSystemFont(ofSize: C.terminalFontSize + 1, weight: .regular)
            arrowLabel.textColor = C.textDimColor
            arrowLabel.alignment = .center
            addSubview(arrowLabel)
            reactionLabels.append(arrowLabel)

            // Description label
            let descLabel = NSTextField(labelWithString: description)
            descLabel.frame = NSRect(x: listCenterX + 20, y: yOffset, width: 250, height: 18)
            descLabel.font = NSFont.monospacedSystemFont(ofSize: C.terminalFontSize + 1, weight: .regular)
            descLabel.textColor = C.textColor
            descLabel.alignment = .left
            addSubview(descLabel)
            reactionLabels.append(descLabel)
        }
    }

    // MARK: - Terminal Selection (Right Column)

    private func setupTerminalSelection() {
        // Right column - vertically centered with the left column content
        let rightColumnCenterX: CGFloat = bounds.width * 0.75
        let contentY: CGFloat = 145 + topPadding

        // Header
        let headerWidth: CGFloat = 200
        terminalHeader = NSTextField(labelWithString: "PREFERRED TERMINAL")
        terminalHeader.frame = NSRect(x: rightColumnCenterX - headerWidth / 2, y: contentY, width: headerWidth, height: 20)
        terminalHeader.font = NSFont.monospacedSystemFont(ofSize: C.terminalFontSize + 1, weight: .bold)
        terminalHeader.textColor = C.accentColor
        terminalHeader.alignment = .center
        addSubview(terminalHeader)

        // Terminal buttons - stacked vertically, centered under header
        let terminals: [ClaudeLauncher.Terminal] = [.terminalApp, .iTerm]
        let buttonWidth: CGFloat = 150
        let buttonHeight: CGFloat = 24
        let buttonSpacing: CGFloat = 8
        let buttonX = rightColumnCenterX - buttonWidth / 2
        var buttonY: CGFloat = contentY + 35

        for (index, terminal) in terminals.enumerated() {
            let button = NSButton(frame: NSRect(x: buttonX, y: buttonY, width: buttonWidth, height: buttonHeight))
            button.setButtonType(.radio)
            button.title = terminal.displayName
            button.font = NSFont.monospacedSystemFont(ofSize: C.terminalFontSize + 1, weight: .regular)
            button.contentTintColor = C.textColor
            button.tag = index
            button.target = self
            button.action = #selector(terminalButtonClicked(_:))

            // Check if terminal is installed
            let isInstalled = ClaudeLauncher.shared.isTerminalInstalled(terminal)
            button.isEnabled = isInstalled
            if !isInstalled {
                button.contentTintColor = C.textDimColor
                button.title = "\(terminal.displayName) (n/a)"
            }

            addSubview(button)
            terminalButtons.append(button)
            buttonY += buttonHeight + buttonSpacing
        }
    }

    @objc private func terminalButtonClicked(_ sender: NSButton) {
        let terminals: [ClaudeLauncher.Terminal] = [.terminalApp, .iTerm]
        guard sender.tag < terminals.count else { return }

        selectedTerminal = terminals[sender.tag]
        ClaudeLauncher.shared.preferredTerminal = selectedTerminal
        updateTerminalSelection()
    }

    private func updateTerminalSelection() {
        let terminals: [ClaudeLauncher.Terminal] = [.terminalApp, .iTerm]
        for (index, button) in terminalButtons.enumerated() {
            button.state = terminals[index] == selectedTerminal ? .on : .off
        }
    }

    // MARK: - Continue Button

    private func setupContinueButton() {
        continueButton = NSButton(frame: NSRect(
            x: (bounds.width - 200) / 2,
            y: bounds.height - 55,
            width: 200,
            height: 24
        ))
        continueButton.title = "> Continue to Customize"
        continueButton.bezelStyle = .inline
        continueButton.isBordered = false
        continueButton.font = NSFont.monospacedSystemFont(ofSize: C.terminalFontSize, weight: .bold)
        continueButton.contentTintColor = C.accentColor
        continueButton.target = self
        continueButton.action = #selector(continueButtonClicked)

        // Hover tracking
        let trackingArea = NSTrackingArea(
            rect: continueButton.bounds,
            options: [.activeAlways, .mouseEnteredAndExited],
            owner: self,
            userInfo: ["button": "continue"]
        )
        continueButton.addTrackingArea(trackingArea)

        addSubview(continueButton)
    }

    private func setupVersionLabel() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        versionLabel = NSTextField(labelWithString: "v\(version)")
        versionLabel.frame = NSRect(
            x: 0,
            y: bounds.height + 15,
            width: bounds.width,
            height: 16
        )
        versionLabel.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        versionLabel.textColor = C.textDimColor
        versionLabel.alignment = .center
        addSubview(versionLabel)
    }

    // MARK: - Mouse Handling

    override func mouseEntered(with event: NSEvent) {
        if let userInfo = event.trackingArea?.userInfo as? [String: String],
           userInfo["button"] == "continue" {
            NSCursor.pointingHand.set()
            continueButton.contentTintColor = NSColor.white
        }
    }

    override func mouseExited(with event: NSEvent) {
        if let userInfo = event.trackingArea?.userInfo as? [String: String],
           userInfo["button"] == "continue" {
            NSCursor.arrow.set()
            continueButton.contentTintColor = C.accentColor
        }
    }

    // MARK: - Actions

    @objc private func continueButtonClicked() {
        delegate?.claudeHooksNextClicked()
    }

    // MARK: - Animation

    /// Called when view appears
    func startProgressAnimation() {
        // Start sprite animations
        previewSprite?.regenerateTextures()
        previewSprite?.startAnimations()

        // Start demo cycle after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.startDemoCycle()
        }
    }

    /// Cycle through different states to demo reactions
    private func startDemoCycle() {
        stopAnimation()
        currentDemoState = 0

        // Cycle through: idle -> thinking -> planning -> party -> idle
        demoTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            self?.advanceDemoState()
        }
    }

    private func advanceDemoState() {
        currentDemoState = (currentDemoState + 1) % 6

        switch currentDemoState {
        case 0:
            // Idle - reset all states
            previewSprite?.wakeUp()
            previewSprite?.stopDancing()
            previewSprite?.stopClaudeThinking()
            previewSprite?.stopClaudePlanning()
            previewSprite?.dismissPartyCelebration()
            previewSprite?.startAnimations()
            highlightReaction(index: nil)
        case 1:
            // Thinking
            previewSprite?.startClaudeThinking()
            highlightReaction(index: 0)
        case 2:
            // Planning
            previewSprite?.stopClaudeThinking()
            previewSprite?.startClaudePlanning()
            highlightReaction(index: 1)
        case 3:
            // Celebrating
            previewSprite?.stopClaudePlanning()
            previewSprite?.showPartyCelebration()
            highlightReaction(index: 2)
        case 4:
            // Vibing (dancing)
            previewSprite?.dismissPartyCelebration()
            previewSprite?.stateManager.forceState(.idle)
            previewSprite?.startAnimations()
            previewSprite?.startDancing()
            highlightReaction(index: 3)
        case 5:
            // Napping (sleeping)
            previewSprite?.stopDancing()
            previewSprite?.startSleeping()
            highlightReaction(index: 4)
        default:
            break
        }
    }

    private func highlightReaction(index: Int?) {
        // Each reaction has 3 labels (action, arrow, description)
        for (i, label) in reactionLabels.enumerated() {
            let reactionIndex = i / 3
            let isHighlighted = index == reactionIndex

            if i % 3 == 0 {
                // Action label
                label.textColor = isHighlighted ? NSColor.white : C.accentColor
            } else if i % 3 == 1 {
                // Arrow
                label.textColor = isHighlighted ? C.accentColor : C.textDimColor
            } else {
                // Description
                label.textColor = isHighlighted ? NSColor.white : C.textColor
            }
        }
    }

    /// Stop animations
    func stopAnimation() {
        demoTimer?.invalidate()
        demoTimer = nil
        previewSprite?.stopClaudeThinking()
        previewSprite?.stopClaudePlanning()
        previewSprite?.dismissPartyCelebration()
    }
}
