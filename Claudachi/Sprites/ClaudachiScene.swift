//
//  ClaudachiScene.swift
//  Claudachi
//

import SpriteKit
import AppKit

class ClaudachiScene: SKScene {

    private var claudachi: ClaudachiSprite!
    private var isSleeping = false

    override init() {
        super.init(size: CGSize(width: 32, height: 32))
        scaleMode = .aspectFill
        backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        setupCharacter()
    }

    private func setupCharacter() {
        claudachi = ClaudachiSprite()
        claudachi.position = CGPoint(x: 16, y: 16) // Center of 32x32 scene
        addChild(claudachi)
    }

    // MARK: - Interaction

    override func mouseDown(with event: NSEvent) {
        claudachi.triggerClickReaction()
    }

    override func rightMouseDown(with event: NSEvent) {
        showContextMenu(with: event)
    }

    // MARK: - Context Menu

    private func showContextMenu(with event: NSEvent) {
        guard let view = self.view else { return }

        let menu = NSMenu(title: "Claudachi")

        // Header (disabled, just for display)
        let headerItem = NSMenuItem(title: "Claudachi", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        menu.addItem(NSMenuItem.separator())

        // Inventory (disabled for now - Phase 4)
        let inventoryItem = NSMenuItem(title: "Inventory", action: nil, keyEquivalent: "")
        inventoryItem.isEnabled = false
        menu.addItem(inventoryItem)

        // Settings (disabled for now - Phase 5)
        let settingsItem = NSMenuItem(title: "Settings", action: nil, keyEquivalent: "")
        settingsItem.isEnabled = false
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // Sleep mode toggle
        let sleepItem = NSMenuItem(
            title: isSleeping ? "Wake Up" : "Sleep Mode",
            action: #selector(toggleSleep),
            keyEquivalent: ""
        )
        sleepItem.target = self
        menu.addItem(sleepItem)

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
