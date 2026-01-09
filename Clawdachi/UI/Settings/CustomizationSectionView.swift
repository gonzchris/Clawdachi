//
//  CustomizationSectionView.swift
//  Clawdachi
//
//  Customization section with vertical layout: preview, tabs, grid
//

import AppKit
import SpriteKit

/// Customization section with preview and item selection
class CustomizationSectionView: NSView {

    private typealias C = SettingsConstants

    // MARK: - Properties

    private var previewView: CustomizationPreviewView!
    private var tabBar: CustomizationTabBar!
    private var itemGridView: CustomizationGridView!
    private var resetButton: SettingsButton!

    private var currentCategory: ClosetCategory = .themes

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

        setupPreviewView()
        setupTabBar()
        setupItemGridView()
        setupResetButton()
    }

    // MARK: - Subview Setup

    private func setupPreviewView() {
        // Preview centered at top
        let previewAreaHeight: CGFloat = C.previewBoxSize + 20
        let previewFrame = NSRect(
            x: 0,
            y: 0,
            width: bounds.width,
            height: previewAreaHeight
        )
        previewView = CustomizationPreviewView(frame: previewFrame)
        addSubview(previewView)
    }

    private func setupTabBar() {
        // Tabs centered below preview
        let previewAreaHeight: CGFloat = C.previewBoxSize + 20
        let tabWidth: CGFloat = min(bounds.width - C.panelPadding * 2, 400)
        let tabX = (bounds.width - tabWidth) / 2

        let tabFrame = NSRect(
            x: tabX,
            y: previewAreaHeight + C.gridSpacing,
            width: tabWidth,
            height: C.tabHeight
        )
        tabBar = CustomizationTabBar(frame: tabFrame, categories: ClosetCategory.allCases)
        tabBar.delegate = self
        addSubview(tabBar)
    }

    private func setupItemGridView() {
        // Grid below tabs
        let previewAreaHeight: CGFloat = C.previewBoxSize + 20
        let tabAreaHeight = C.tabHeight + C.gridSpacing * 2
        let topOffset = previewAreaHeight + tabAreaHeight
        let bottomPadding: CGFloat = 40  // Space for reset button

        let gridFrame = NSRect(
            x: 0,
            y: topOffset,
            width: bounds.width,
            height: bounds.height - topOffset - bottomPadding
        )
        itemGridView = CustomizationGridView(frame: gridFrame)
        itemGridView.delegate = self
        addSubview(itemGridView)
    }

    private func setupResetButton() {
        let buttonWidth: CGFloat = 70
        let resetFrame = NSRect(
            x: bounds.width - buttonWidth - C.panelPadding,
            y: bounds.height - 34,
            width: buttonWidth,
            height: 24
        )
        resetButton = SettingsButton(frame: resetFrame, title: "RESET")
        resetButton.target = self
        resetButton.action = #selector(resetButtonClicked)
        addSubview(resetButton)
    }

    override var isFlipped: Bool { true }

    // MARK: - Button Actions

    @objc private func resetButtonClicked() {
        ClosetManager.shared.resetToDefaults()
        previewView.updatePreview()
        itemGridView.refresh()
    }

    // MARK: - Animation Control

    func startAnimation() {
        previewView.startAnimation()
    }

    func stopAnimation() {
        previewView.stopAnimation()
    }

    // MARK: - Refresh

    func refresh() {
        previewView.updatePreview()
        itemGridView.refresh()
    }
}

// MARK: - Tab Bar Delegate

extension CustomizationSectionView: CustomizationTabBarDelegate {
    func tabBar(_ tabBar: CustomizationTabBar, didSelectCategory category: ClosetCategory) {
        currentCategory = category
        itemGridView.loadCategory(category)
    }
}

// MARK: - Grid Delegate

extension CustomizationSectionView: CustomizationGridDelegate {
    func itemGrid(_ grid: CustomizationGridView, didSelectItem item: ClosetItem, in category: ClosetCategory) {
        ClosetManager.shared.equip(item, in: category)
        previewView.updatePreview()
    }

    func itemGrid(_ grid: CustomizationGridView, didDeselectItem item: ClosetItem, in category: ClosetCategory) {
        ClosetManager.shared.unequip(category)
        previewView.updatePreview()
    }

    func itemGrid(_ grid: CustomizationGridView, didTapLockedItem item: ClosetItem, in category: ClosetCategory) {
        // Locked item tapped - could show upgrade prompt in future
    }
}
