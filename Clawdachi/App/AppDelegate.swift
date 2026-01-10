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
    private var scene: ClawdachiScene?

    /// Public accessor for the sprite window (used by ChatBubbleWindow)
    var spriteWindow: NSWindow { window }
    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?

    private enum Keys {
        static let windowX = "clawdachi.window.x"
        static let windowY = "clawdachi.window.y"
        static let hasStoredPosition = "clawdachi.window.hasStoredPosition"
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Apply dock icon visibility setting
        SettingsManager.shared.applyDockIconSetting()

        // Initialize menu bar controller (will show icon if enabled in settings)
        _ = MenuBarController.shared

        // Request notification permissions for recording feedback
        requestNotificationPermissions()

        // Check if onboarding is needed
        if OnboardingManager.needsOnboarding {
            showOnboarding()
        } else {
            // Normal launch - set up Claude integration and show sprite
            ClaudeIntegrationSetup.setupIfNeeded()
            setupMainWindow()
            restoreWindowPosition()
            window.orderFront(nil)

            // Set up keyboard shortcut for recording
            setupRecordingShortcut()

            // Show time-of-day greeting after short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.scene?.showChatBubble(ClawdachiMessages.greetingForCurrentTime(), duration: 4.0)
            }
        }
    }

    // MARK: - Onboarding

    private func showOnboarding() {
        // Set up completion handler
        OnboardingWindow.shared.onComplete = { [weak self] position in
            self?.launchAfterOnboarding(at: position)
        }

        // Show onboarding window
        OnboardingWindow.shared.show()
    }

    /// Called after onboarding completes to launch the main app
    private func launchAfterOnboarding(at position: CGPoint) {
        // Set up Claude integration (always enabled)
        ClaudeIntegrationSetup.setupIfNeeded()

        // Set up the main window
        setupMainWindow()

        // Position at the specified location (bottom-left corner from jump animation)
        window.setFrameOrigin(position)

        // Keep window hidden for now - showSpriteAfterJump will reveal it
        window.alphaValue = 0
        window.orderFront(nil)

        // Set up keyboard shortcuts
        setupRecordingShortcut()

        // TEMP: Show sprite immediately for debugging
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.showSpriteAfterJump()
        }
    }

    /// Called by OnboardingWindow after jump animation completes
    func showSpriteAfterJump() {
        guard let window = window else { return }

        // Ensure window is visible
        window.alphaValue = 1.0
        window.orderFront(nil)
        window.makeKeyAndOrderFront(nil)

        // Show welcome message
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.scene?.showChatBubble("> i'm free!", duration: 4.0)
        }
    }

    // MARK: - Main Window Setup

    private func setupMainWindow() {
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
        scene = ClawdachiScene()
        skView.presentScene(scene)

        // Set as window content
        window.contentView = skView

        // Set up debug menu
        DebugMenuController.shared.setupDebugMenu(scene: scene!)

        // Observe window movement to save position
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMove),
            name: NSWindow.didMoveNotification,
            object: window
        )

        // Set up animation recorder
        animationRecorder = AnimationRecorder(scene: scene!, view: skView)
    }

    private func setupRecordingShortcut() {
        // Global monitor for recording only (works when app is not focused)
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleGlobalKeyEvent(event)
        }

        // Local monitor for all shortcuts (only when app is focused)
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleLocalKeyEvent(event) == true {
                return nil  // Consume the event
            }
            return event
        }
    }

    private func handleGlobalKeyEvent(_ event: NSEvent) {
        let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // Only Cmd+Shift+R (recording) works globally
        if modifierFlags == [.command, .shift],
           event.charactersIgnoringModifiers?.lowercased() == "r" {
            animationRecorder?.toggleRecording()
        }
    }

    private func handleLocalKeyEvent(_ event: NSEvent) -> Bool {
        let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // Check for Cmd+Shift+R (recording)
        if modifierFlags == [.command, .shift],
           event.charactersIgnoringModifiers?.lowercased() == "r" {
            animationRecorder?.toggleRecording()
            return true
        }

        // Check for Cmd+, (settings) - local only
        if modifierFlags == [.command],
           event.charactersIgnoringModifiers == "," {
            openSettings()
            return true
        }

        // Check for Cmd+Z (sleep mode toggle) - local only
        if modifierFlags == [.command],
           event.charactersIgnoringModifiers?.lowercased() == "z" {
            toggleSleep()
            return true
        }

        return false
    }

    private func toggleSleep() {
        guard let scene = scene else { return }
        scene.toggleSleep()
    }

    private func openSettings() {
        guard let mainWindow = window else { return }
        SettingsWindow.shared.toggle(relativeTo: mainWindow)
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
        // Don't terminate during onboarding transition (window is nil until main window is created)
        return window != nil
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
    }
}
