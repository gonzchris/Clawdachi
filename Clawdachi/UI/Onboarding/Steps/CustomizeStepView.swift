//
//  CustomizeStepView.swift
//  Clawdachi
//
//  Customization step for onboarding - allows theme, outfit, hat, glasses selection
//

import AppKit
import SpriteKit

/// Delegate for CustomizeStepView completion
protocol CustomizeStepViewDelegate: AnyObject {
    func customizeStepLaunchClicked()
}

/// Customization step view with preview and item selection
class CustomizeStepView: NSView {

    private typealias C = OnboardingConstants
    private typealias SC = SettingsConstants

    // MARK: - Properties

    weak var delegate: CustomizeStepViewDelegate?

    private var titleLabel: NSTextField!
    private var previewContainer: NSView!
    private var skView: SKView!
    private var previewScene: SKScene!
    private var previewSprite: ClawdachiSprite!
    private var tabBar: CustomizationTabBar!
    private var itemGridView: CustomizationGridView!
    private var continueButton: NSButton!
    private var versionLabel: NSTextField!

    private var currentCategory: ClosetCategory = .themes
    private var hasLaunched = false  // Prevent multiple launch clicks

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

        setupTitle()
        setupPreview()
        setupTabBar()
        setupItemGrid()
        setupContinueButton()
        setupVersionLabel()
    }

    override var isFlipped: Bool { true }

    // MARK: - UI Setup

    private func setupTitle() {
        titleLabel = NSTextField(labelWithString: "CUSTOMIZE CLAWDACHI")
        titleLabel.frame = NSRect(x: 0, y: C.panelPadding, width: bounds.width, height: 24)
        titleLabel.font = NSFont.monospacedSystemFont(ofSize: C.sectionFontSize + 2, weight: .bold)
        titleLabel.textColor = C.accentColor
        titleLabel.alignment = .center
        addSubview(titleLabel)
    }

    private func setupPreview() {
        // Preview container with border - centered horizontally
        let previewSize: CGFloat = 120
        let previewX = (bounds.width - previewSize) / 2
        let previewY: CGFloat = 60

        previewContainer = NSView(frame: NSRect(
            x: previewX,
            y: previewY,
            width: previewSize,
            height: previewSize
        ))
        previewContainer.wantsLayer = true
        previewContainer.layer?.backgroundColor = SC.cellBackgroundColor.cgColor
        previewContainer.layer?.cornerRadius = 6
        previewContainer.layer?.borderWidth = 2
        previewContainer.layer?.borderColor = SC.frameColor.cgColor
        addSubview(previewContainer)

        // SpriteKit view for live preview
        skView = SKView(frame: NSRect(x: 0, y: 0, width: previewSize, height: previewSize))
        skView.allowsTransparency = true
        previewContainer.addSubview(skView)

        // Create square scene to match container (avoids black letterboxing)
        let sceneSize: CGFloat = 45
        previewScene = SKScene(size: CGSize(width: sceneSize, height: sceneSize))
        previewScene.backgroundColor = .clear
        previewScene.scaleMode = .aspectFit

        // Create sprite centered in scene (slightly lower to show full body)
        previewSprite = ClawdachiSprite()
        previewSprite.position = CGPoint(x: sceneSize / 2, y: sceneSize / 2 - 2)
        previewScene.addChild(previewSprite)

        skView.presentScene(previewScene)
    }

    private func setupTabBar() {
        // Tabs centered below preview
        let tabWidth: CGFloat = 400
        let tabX = (bounds.width - tabWidth) / 2
        let tabY: CGFloat = 190  // Below the preview
        let tabFrame = NSRect(
            x: tabX,
            y: tabY,
            width: tabWidth,
            height: SC.tabHeight
        )
        tabBar = CustomizationTabBar(frame: tabFrame, categories: ClosetCategory.allCases)
        tabBar.delegate = self
        addSubview(tabBar)
    }

    private func setupItemGrid() {
        // Grid centered below tabs
        let gridWidth: CGFloat = 500
        let gridX = (bounds.width - gridWidth) / 2
        let gridY: CGFloat = 230  // Below the tab bar
        let gridHeight: CGFloat = 150  // Fixed height for item grid

        let gridFrame = NSRect(x: gridX, y: gridY, width: gridWidth, height: gridHeight)
        itemGridView = CustomizationGridView(frame: gridFrame)
        itemGridView.delegate = self
        addSubview(itemGridView)
    }

    private func setupContinueButton() {
        continueButton = NSButton(frame: NSRect(
            x: (bounds.width - 250) / 2,
            y: bounds.height - 80,
            width: 250,
            height: 24
        ))
        continueButton.title = "> Launch Clawdachi"
        continueButton.bezelStyle = .inline
        continueButton.isBordered = false
        continueButton.font = NSFont.monospacedSystemFont(ofSize: C.terminalFontSize, weight: .bold)
        continueButton.contentTintColor = C.accentColor
        continueButton.target = self
        continueButton.action = #selector(continueButtonClicked)

        // Add hover effect via tracking area
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
            y: bounds.height - 10,
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
        guard !hasLaunched else { return }
        hasLaunched = true
        delegate?.customizeStepLaunchClicked()
    }

    // MARK: - Animation

    func startPreview() {
        // Reset launch state when view becomes active
        hasLaunched = false
        // Regenerate textures to pick up current theme
        previewSprite?.regenerateTextures()
        // Start idle animation
        previewSprite?.startAnimations()
    }

    func stopPreview() {
        previewSprite?.removeAllActions()
    }

    // MARK: - Position

    /// Get the sprite's position within this view (for jump animation)
    func getSpritePosition() -> CGPoint {
        guard let container = previewContainer else { return .zero }
        return CGPoint(
            x: container.frame.midX,
            y: bounds.height - container.frame.midY  // Flip Y for screen coords
        )
    }
}

// MARK: - Tab Bar Delegate

extension CustomizeStepView: CustomizationTabBarDelegate {
    func tabBar(_ tabBar: CustomizationTabBar, didSelectCategory category: ClosetCategory) {
        currentCategory = category
        itemGridView.loadCategory(category)
    }
}

// MARK: - Grid Delegate

extension CustomizeStepView: CustomizationGridDelegate {
    func itemGrid(_ grid: CustomizationGridView, didSelectItem item: ClosetItem, in category: ClosetCategory) {
        ClosetManager.shared.equip(item, in: category)
        // Regenerate textures to update the preview sprite
        previewSprite?.regenerateTextures()
    }

    func itemGrid(_ grid: CustomizationGridView, didDeselectItem item: ClosetItem, in category: ClosetCategory) {
        ClosetManager.shared.unequip(category)
        // Regenerate textures to update the preview sprite
        previewSprite?.regenerateTextures()
    }

    func itemGrid(_ grid: CustomizationGridView, didTapLockedItem item: ClosetItem, in category: ClosetCategory) {
        // Show locked indicator or shake
    }
}
