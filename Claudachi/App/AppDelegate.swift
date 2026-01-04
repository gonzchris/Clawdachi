//
//  AppDelegate.swift
//  Claudachi
//

import Cocoa
import SpriteKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

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

        // Center and show window
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
