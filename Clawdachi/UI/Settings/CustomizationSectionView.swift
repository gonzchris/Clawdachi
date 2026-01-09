//
//  CustomizationSectionView.swift
//  Clawdachi
//
//  Customization section combining preview and item grid
//

import AppKit
import SpriteKit

/// Customization section with preview and item selection
class CustomizationSectionView: NSView {

    private typealias C = SettingsConstants

    // MARK: - Properties

    private var previewView: CustomizationPreviewView!
    private var itemGridView: CustomizationGridView!
    private var resetButton: SettingsButton!

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
        setupItemGridView()
        setupResetButton()
    }

    // MARK: - Subview Setup

    private func setupPreviewView() {
        let previewFrame = NSRect(
            x: C.panelPadding,
            y: 0,
            width: C.customizationPreviewWidth - C.panelPadding,
            height: bounds.height - 40  // Leave space for reset button
        )
        previewView = CustomizationPreviewView(frame: previewFrame)
        addSubview(previewView)
    }

    private func setupItemGridView() {
        let gridFrame = NSRect(
            x: C.customizationPreviewWidth,
            y: 0,
            width: C.customizationGridWidth,
            height: bounds.height
        )
        itemGridView = CustomizationGridView(frame: gridFrame)
        itemGridView.delegate = self
        addSubview(itemGridView)
    }

    private func setupResetButton() {
        let resetFrame = NSRect(
            x: C.panelPadding,
            y: bounds.height - 34,
            width: 70,
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
