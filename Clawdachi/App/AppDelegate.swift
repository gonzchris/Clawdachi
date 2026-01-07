//
//  AppDelegate.swift
//  Clawdachi
//

import Cocoa
import SpriteKit
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    private var animationRecorder: AnimationRecorder?

    /// Public accessor for the sprite window (used by ChatBubbleWindow)
    var spriteWindow: NSWindow { window }
    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?

    // Voice input hotkey monitors
    private var globalFlagsMonitor: Any?
    private var localFlagsMonitor: Any?
    private var isVoiceHotkeyPressed = false

    private enum Keys {
        static let windowX = "clawdachi.window.x"
        static let windowY = "clawdachi.window.y"
        static let hasStoredPosition = "clawdachi.window.hasStoredPosition"
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up Claude Code integration on first launch
        ClaudeIntegrationSetup.setupIfNeeded()

        // Create borderless window (48x64 scene at 6x scale = 288x384)
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 288, height: 384),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        // Configure for floating transparent behavior
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.hasShadow = true
        window.isMovableByWindowBackground = false  // Drag handled by scene for sprite-only dragging
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]

        // Create SpriteKit view
        let skView = SKView(frame: NSRect(x: 0, y: 0, width: 288, height: 384))
        skView.allowsTransparency = true

        // Create and present scene
        let scene = ClawdachiScene()
        skView.presentScene(scene)

        // Set as window content
        window.contentView = skView

        // Set up debug menu
        DebugMenuController.shared.setupDebugMenu(scene: scene)

        // Restore saved position or center window
        restoreWindowPosition()
        window.orderFront(nil)  // Don't try to become key (borderless windows can't)

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

        // Set up voice input hotkey (Ctrl+Option+Cmd)
        setupVoiceInputHotkey()

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

    // MARK: - Voice Input Hotkey

    private func setupVoiceInputHotkey() {
        // Monitor modifier key changes for Ctrl+Option+Cmd hold/release
        let voiceModifiers: NSEvent.ModifierFlags = [.control, .option, .command]

        globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleVoiceFlagsChanged(event, requiredModifiers: voiceModifiers)
        }

        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleVoiceFlagsChanged(event, requiredModifiers: voiceModifiers)
            return event
        }
    }

    private func handleVoiceFlagsChanged(_ event: NSEvent, requiredModifiers: NSEvent.ModifierFlags) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // Toggle recording when all three modifiers are pressed
        if flags.contains(requiredModifiers) && !isVoiceHotkeyPressed {
            isVoiceHotkeyPressed = true
            // Audio operations must happen on main thread
            DispatchQueue.main.async {
                if VoiceInputService.shared.isRecording {
                    VoiceInputService.shared.stopRecording()
                } else {
                    VoiceInputService.shared.startRecording()
                }
            }
        }
        // Reset flag when modifiers released (allows next toggle)
        else if isVoiceHotkeyPressed && !flags.contains(requiredModifiers) {
            isVoiceHotkeyPressed = false
        }
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
            globalEventMonitor = nil
        }
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
        if let monitor = globalFlagsMonitor {
            NSEvent.removeMonitor(monitor)
            globalFlagsMonitor = nil
        }
        if let monitor = localFlagsMonitor {
            NSEvent.removeMonitor(monitor)
            localFlagsMonitor = nil
        }

        // Cancel any in-progress voice recording
        if VoiceInputService.shared.isRecording {
            VoiceInputService.shared.cancelRecording()
        }
    }
}
