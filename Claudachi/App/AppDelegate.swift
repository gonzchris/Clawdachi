//
//  AppDelegate.swift
//  Claudachi
//

import Cocoa
import SpriteKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    private enum Keys {
        static let windowX = "claudachi.window.x"
        static let windowY = "claudachi.window.y"
        static let hasStoredPosition = "claudachi.window.hasStoredPosition"
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create borderless window (32x32 sprite at 6x scale = 192x192)
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 192, height: 192),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        // Configure for floating transparent behavior
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]

        // Create SpriteKit view
        let skView = SKView(frame: NSRect(x: 0, y: 0, width: 192, height: 192))
        skView.allowsTransparency = true

        // Create and present scene
        let scene = ClaudachiScene()
        skView.presentScene(scene)

        // Set as window content
        window.contentView = skView

        // Restore saved position or center window
        restoreWindowPosition()
        window.makeKeyAndOrderFront(nil)

        // Observe window movement to save position
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMove),
            name: NSWindow.didMoveNotification,
            object: window
        )
    }

    private func restoreWindowPosition() {
        let defaults = UserDefaults.standard

        if defaults.bool(forKey: Keys.hasStoredPosition) {
            let x = defaults.double(forKey: Keys.windowX)
            let y = defaults.double(forKey: Keys.windowY)
            let origin = CGPoint(x: x, y: y)

            // Validate position is on a visible screen
            if isPositionVisible(origin) {
                window.setFrameOrigin(origin)
                return
            }
        }

        // Default: center on screen
        window.center()
    }

    private func isPositionVisible(_ origin: CGPoint) -> Bool {
        let windowFrame = NSRect(origin: origin, size: window.frame.size)

        // Check if window intersects with any screen
        for screen in NSScreen.screens {
            if windowFrame.intersects(screen.visibleFrame) {
                return true
            }
        }
        return false
    }

    @objc private func windowDidMove(_ notification: Notification) {
        saveWindowPosition()
    }

    private func saveWindowPosition() {
        let origin = window.frame.origin
        let defaults = UserDefaults.standard

        defaults.set(origin.x, forKey: Keys.windowX)
        defaults.set(origin.y, forKey: Keys.windowY)
        defaults.set(true, forKey: Keys.hasStoredPosition)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
