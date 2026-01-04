//
//  ClaudachiScene.swift
//  Claudachi
//

import SpriteKit
import AppKit

class ClaudachiScene: SKScene {

    // MARK: - Properties

    private var claudachi: ClaudachiSprite!
    private var isSleeping = false

    // MARK: - Initialization

    override init() {
        super.init(size: CGSize(width: 48, height: 48))
        scaleMode = .aspectFill
        backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        longPressTimer?.invalidate()
    }

    override func didMove(to view: SKView) {
        setupCharacter()

        // Watch for app losing focus to cancel drag
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidResignActive),
            name: NSApplication.didResignActiveNotification,
            object: nil
        )
    }

    private func setupCharacter() {
        claudachi = ClaudachiSprite()
        claudachi.position = CGPoint(x: 24, y: 24)
        addChild(claudachi)
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        guard !isSleeping else { return }
        claudachi.updateEyeTracking(globalMouse: NSEvent.mouseLocation, currentTime: currentTime)
    }

    // MARK: - Interaction

    private var isDragging = false
    private var dragStartLocation: CGPoint = .zero
    private var longPressTimer: Timer?

    override func mouseDown(with event: NSEvent) {
        dragStartLocation = event.locationInWindow
        isDragging = false

        // Start long-press timer for heart reaction (3 seconds)
        longPressTimer?.invalidate()
        longPressTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            guard let self = self, !self.isDragging, !self.isSleeping else { return }
            self.claudachi.performHeartReaction()
        }
    }

    override func mouseDragged(with event: NSEvent) {
        // Cancel long-press timer when dragging
        longPressTimer?.invalidate()
        longPressTimer = nil

        // Start drag animation only on first movement (skip if sleeping)
        if !isDragging && !isSleeping {
            claudachi.startDragWiggle()
        }
        isDragging = true
    }

    override func mouseUp(with event: NSEvent) {
        // Cancel long-press timer
        longPressTimer?.invalidate()
        longPressTimer = nil

        endDragIfNeeded()

        // If it was a click (not a drag), trigger reaction
        if !isDragging && !isSleeping {
            claudachi.triggerClickReaction()
        }

        isDragging = false
    }

    override func rightMouseDown(with event: NSEvent) {
        longPressTimer?.invalidate()
        longPressTimer = nil
        endDragIfNeeded()
        showContextMenu(with: event)
    }

    // MARK: - Drag Safety

    private func endDragIfNeeded() {
        claudachi.stopDragWiggle()
        isDragging = false
    }

    @objc private func appDidResignActive() {
        endDragIfNeeded()
    }

    // MARK: - Context Menu

    private func showContextMenu(with event: NSEvent) {
        guard let view = self.view else { return }

        let menu = NSMenu(title: "Claudachi")

        // Header
        let headerItem = NSMenuItem(title: "Claudachi", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        menu.addItem(NSMenuItem.separator())

        // Sleep mode toggle
        let sleepItem = NSMenuItem(
            title: isSleeping ? "Wake Up" : "Sleep Mode",
            action: #selector(toggleSleep),
            keyEquivalent: ""
        )
        sleepItem.target = self
        menu.addItem(sleepItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(
            title: "Quit Claudachi",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        // Show menu at click location
        let locationInView = event.locationInWindow
        menu.popUp(positioning: nil, at: locationInView, in: view)
    }

    @objc private func toggleSleep() {
        if isSleeping {
            isSleeping = false
            claudachi.wakeUp()
        } else {
            isSleeping = true
            claudachi.startSleeping()
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
