//
//  AppDelegate.swift
//  Claudachi
//

import Cocoa
import SpriteKit
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    private var animationRecorder: AnimationRecorder?
    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?

    private enum Keys {
        static let windowX = "claudachi.window.x"
        static let windowY = "claudachi.window.y"
        static let hasStoredPosition = "claudachi.window.hasStoredPosition"
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create borderless window (48x48 scene at 6x scale = 288x288)
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 288, height: 288),
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
        let skView = SKView(frame: NSRect(x: 0, y: 0, width: 288, height: 288))
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

        // Set up animation recorder
        animationRecorder = AnimationRecorder(scene: scene, view: skView)

        // Set up keyboard shortcut for recording (Cmd+Shift+R)
        setupRecordingShortcut()

        // Request notification permissions for recording feedback
        requestNotificationPermissions()
    }

    private func setupRecordingShortcut() {
        // Global monitor for when app is not focused
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }

        // Local monitor for when app is focused
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleKeyEvent(event) == true {
                return nil  // Consume the event
            }
            return event
        }
    }

    @discardableResult
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        // Check for Cmd+Shift+R
        let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let requiredFlags: NSEvent.ModifierFlags = [.command, .shift]

        if modifierFlags == requiredFlags,
           event.charactersIgnoringModifiers?.lowercased() == "r" {
            animationRecorder?.toggleRecording()
            return true
        }
        return false
    }

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
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

    func applicationWillTerminate(_ notification: Notification) {
        // Clean up event monitors
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
