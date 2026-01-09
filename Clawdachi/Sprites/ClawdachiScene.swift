//
//  ClawdachiScene.swift
//  Clawdachi
//

import SpriteKit
import AppKit

class ClawdachiScene: SKScene {

    // MARK: - Shared Instance

    private(set) static weak var shared: ClawdachiScene?

    // MARK: - Properties

    private(set) var clawdachi: ClawdachiSprite!
    private var isSleeping = false
    private var musicMonitor: MusicPlaybackMonitor!
    private var claudeMonitor: ClaudeSessionMonitor!
    private var terminalFocusMonitor: TerminalFocusMonitor!
    private var claudeStatusHandler: ClaudeStatusHandler!

    // MARK: - Initialization

    override init() {
        super.init(size: CGSize(width: 48, height: 64))
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
        ClawdachiScene.shared = self
        setupCharacter()
        setupMusicMonitor()
        setupClaudeMonitor()

        // Watch for app losing focus to cancel drag
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidResignActive),
            name: NSApplication.didResignActiveNotification,
            object: nil
        )

        // Show time-of-day greeting after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.showChatBubble(ClawdachiMessages.greetingForCurrentTime(), duration: 4.0)
        }
    }

    private func setupMusicMonitor() {
        musicMonitor = MusicPlaybackMonitor()
        musicMonitor.onPlaybackStateChanged = { [weak self] isPlaying in
            self?.handleMusicPlaybackChanged(isPlaying)
        }
    }

    private func handleMusicPlaybackChanged(_ isPlaying: Bool) {
        // Don't dance while sleeping or during any Claude Code activity
        guard !isSleeping, !clawdachi.isClaudeThinking, !clawdachi.isClaudePlanning,
              !clawdachi.isQuestionMarkVisible, !clawdachi.isLightbulbVisible,
              !clawdachi.isPartyCelebrationVisible else { return }

        if isPlaying {
            clawdachi.startDancing()
        } else {
            clawdachi.stopDancing()
        }
    }

    private func setupClaudeMonitor() {
        claudeMonitor = ClaudeSessionMonitor.shared

        // Load saved selection mode preference
        if let mode = loadSelectionMode() {
            claudeMonitor.selectionMode = mode
        }

        // Set up Claude status handler
        claudeStatusHandler = ClaudeStatusHandler()
        claudeStatusHandler.onUpdateAnimations = { [weak self] status in
            self?.updateAnimationsForStatus(status)
        }
        claudeStatusHandler.onShowThinkingMessage = { [weak self] in
            self?.showChatBubble(ClawdachiMessages.randomThinkingMessage(), duration: 3.0)
        }
        claudeStatusHandler.onShowPlanningMessage = { [weak self] in
            self?.showChatBubble(ClawdachiMessages.randomPlanningMessage(), duration: 3.0)
        }
        claudeStatusHandler.onShowWaitingMessage = { [weak self] in
            self?.showChatBubble(ClawdachiMessages.randomWaitingMessage(), duration: 4.0)
        }
        claudeStatusHandler.onShowCompletion = { [weak self] in
            self?.clawdachi.showPartyCelebration()
            self?.showChatBubble(ClawdachiMessages.randomCompletionMessage(), duration: 4.0, verticalOffset: ChatBubbleConstants.celebrationVerticalOffset, horizontalOffset: ChatBubbleConstants.celebrationHorizontalOffset)
        }

        claudeMonitor.onStatusChanged = { [weak self] isActive, status, sessionId in
            guard let self = self, !self.isSleeping else { return }
            self.claudeStatusHandler.handleStatusChanged(isActive: isActive, status: status, sessionId: sessionId)
        }

        // Session switch notification (when anyActive switches between sessions)
        claudeMonitor.onSessionSwitched = { [weak self] _, newSession in
            guard let self = self,
                  !self.isSleeping,
                  SettingsManager.shared.notifyOnSessionSwitch,
                  let session = newSession else { return }
            self.showChatBubble("> watching \(session.displayName)", duration: 2.5)
        }

        // Set up terminal focus monitor (used when in followFocusedTab mode)
        terminalFocusMonitor = TerminalFocusMonitor()
        terminalFocusMonitor.onFocusedTTYChanged = { [weak self] tty in
            self?.claudeMonitor.updateFocusedTTY(tty)
        }
    }

    /// Update sprite animations to reflect the current session's status
    private func updateAnimationsForStatus(_ status: String?) {
        switch status {
        case "planning":
            clawdachi.dismissQuestionMark()
            clawdachi.dismissPartyCelebration()
            if !clawdachi.isClaudePlanning {
                clawdachi.stopClaudeThinking()
                clawdachi.startClaudePlanning()
                showChatBubble(ClawdachiMessages.randomPlanningMessage(), duration: 3.0)
            }
        case "thinking", "tools":
            clawdachi.dismissLightbulb()
            clawdachi.dismissQuestionMark()
            clawdachi.dismissPartyCelebration()
            let wasPlanning = clawdachi.isClaudePlanning
            if clawdachi.isClaudePlanning {
                clawdachi.stopClaudePlanning()
            }
            if !clawdachi.isClaudeThinking {
                clawdachi.startClaudeThinking()
                // Only show message if not transitioning from planning
                if !wasPlanning {
                    showChatBubble(ClawdachiMessages.randomThinkingMessage(), duration: 3.0)
                }
            }
        case "waiting":
            clawdachi.stopClaudeThinking()
            clawdachi.stopClaudePlanning()
            clawdachi.stopDancing()
            clawdachi.dismissPartyCelebration()
            clawdachi.showQuestionMark()
        case "idle":
            clawdachi.stopClaudeThinking()
            clawdachi.stopClaudePlanning()
            clawdachi.dismissQuestionMark()
            // Note: party celebration shown separately on actual transition
        default:
            // No active session or unknown status
            clawdachi.stopClaudeThinking()
            clawdachi.stopClaudePlanning()
            clawdachi.dismissQuestionMark()
        }
    }

    private func setupCharacter() {
        clawdachi = ClawdachiSprite()
        clawdachi.position = CGPoint(x: 24, y: 24)
        addChild(clawdachi)
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        guard !isSleeping else { return }
        clawdachi.updateEyeTracking(globalMouse: NSEvent.mouseLocation, currentTime: currentTime)
    }

    // MARK: - Interaction

    private var isDragging = false
    private var dragStartLocationInScreen: CGPoint = .zero  // Screen coords to avoid jitter
    private var dragStartedOnSprite = false
    private var initialWindowOrigin: CGPoint = .zero
    private var longPressTimer: Timer?

    /// Check if a point in scene coordinates hits the sprite (body or nearby elements)
    private func isPointOnSprite(_ point: CGPoint) -> Bool {
        // Check if point hits any node in the sprite hierarchy
        let hitNodes = nodes(at: point)
        for node in hitNodes {
            // Check if this node is the sprite or a child of the sprite
            var current: SKNode? = node
            while current != nil {
                if current === clawdachi {
                    return true
                }
                current = current?.parent
            }
        }
        return false
    }

    override func mouseDown(with event: NSEvent) {
        // Use screen coordinates to avoid jitter during drag
        dragStartLocationInScreen = NSEvent.mouseLocation
        isDragging = false

        // Check if click is on the sprite
        let locationInScene = event.location(in: self)
        dragStartedOnSprite = isPointOnSprite(locationInScene)

        // Store initial window position for manual dragging
        if let window = view?.window {
            initialWindowOrigin = window.frame.origin
        }

        // Only start long-press timer if clicked on sprite
        longPressTimer?.invalidate()
        if dragStartedOnSprite {
            longPressTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
                guard let self = self, !self.isDragging, !self.isSleeping else { return }
                self.clawdachi.performHeartReaction()
            }
        }
    }

    override func mouseDragged(with event: NSEvent) {
        // Cancel long-press timer when dragging
        longPressTimer?.invalidate()
        longPressTimer = nil

        // Only handle drag if it started on the sprite
        guard dragStartedOnSprite else { return }

        // Start drag animation only on first movement
        // Dragging is an overlay - works alongside any current animation
        if !isDragging {
            if isSleeping {
                clawdachi.startSleepyDrag()  // Annoyed squint when disturbed
            } else {
                clawdachi.startDragWiggle()
            }
        }
        isDragging = true

        // Manually move the window using screen coordinates (avoids jitter)
        if let window = view?.window {
            let currentLocationInScreen = NSEvent.mouseLocation
            let deltaX = currentLocationInScreen.x - dragStartLocationInScreen.x
            let deltaY = currentLocationInScreen.y - dragStartLocationInScreen.y
            let newOrigin = CGPoint(
                x: initialWindowOrigin.x + deltaX,
                y: initialWindowOrigin.y + deltaY
            )
            window.setFrameOrigin(newOrigin)
        }
    }

    override func mouseUp(with event: NSEvent) {
        // Cancel long-press timer
        longPressTimer?.invalidate()
        longPressTimer = nil

        endDragIfNeeded()

        // If it was a click (not a drag) on the sprite, trigger reaction or wake up
        if !isDragging && dragStartedOnSprite {
            // Double-click opens Browse dialog to launch Claude Code
            if event.clickCount == 2 {
                launchClaudeBrowse()
                return
            }
            // Check if any overlay is visible before dismissing
            let hadLightbulb = clawdachi.isLightbulbVisible
            let hadQuestionMark = clawdachi.isQuestionMarkVisible
            let hadPartyCelebration = clawdachi.isPartyCelebrationVisible
            let isThinkingOrPlanning = clawdachi.isClaudeThinking || clawdachi.isClaudePlanning

            if isSleeping {
                clawdachi.dismissLightbulb()
                clawdachi.dismissQuestionMark()
                clawdachi.dismissPartyCelebration()
                isSleeping = false
                clawdachi.wakeUp { [weak self] in
                    // Resume dancing if music is playing after wake animation completes
                    if self?.musicMonitor.isPlaying == true {
                        self?.clawdachi.startDancing()
                    }
                }
            } else if isThinkingOrPlanning {
                // Don't react to clicks while Claude is thinking or planning
                // Let the animation continue undisturbed
                return
            } else if hadLightbulb {
                // Click was to dismiss completion lightbulb - resume idle/dancing
                clawdachi.dismissLightbulb { [weak self] in
                    guard let self = self else { return }
                    self.clawdachi.resumeIdleAnimations()
                    if self.musicMonitor.isPlaying {
                        self.clawdachi.startDancing()
                    }
                }
            } else if hadQuestionMark {
                // Click was to dismiss question mark - resume idle/dancing after fade completes
                clawdachi.dismissQuestionMark { [weak self] in
                    guard let self = self else { return }
                    self.clawdachi.resumeIdleAnimations()
                    if self.musicMonitor.isPlaying {
                        self.clawdachi.startDancing()
                    }
                }
            } else if hadPartyCelebration {
                // Click was to dismiss party celebration - resume idle/dancing after fade completes
                clawdachi.dismissPartyCelebration { [weak self] in
                    guard let self = self else { return }
                    self.clawdachi.resumeIdleAnimations()
                    if self.musicMonitor.isPlaying {
                        self.clawdachi.startDancing()
                    }
                }
            } else {
                clawdachi.triggerClickReaction()
            }
        }

        isDragging = false
        dragStartedOnSprite = false
    }

    override func rightMouseDown(with event: NSEvent) {
        longPressTimer?.invalidate()
        longPressTimer = nil
        endDragIfNeeded()

        // Only show context menu if right-clicked on sprite
        let locationInScene = event.location(in: self)
        guard isPointOnSprite(locationInScene) else { return }

        // Dismiss any Claude overlays and resume idle animations
        let hadOverlay = clawdachi.isLightbulbVisible || clawdachi.isQuestionMarkVisible || clawdachi.isPartyCelebrationVisible
        clawdachi.dismissLightbulb()
        clawdachi.dismissQuestionMark()
        clawdachi.dismissPartyCelebration()
        if hadOverlay {
            clawdachi.resumeIdleAnimations()
        }
        showContextMenu(with: event)
    }

    // MARK: - Drag Safety

    private func endDragIfNeeded() {
        if isSleeping {
            clawdachi.stopSleepyDrag()
        } else {
            clawdachi.stopDragWiggle()
        }
        isDragging = false
    }

    @objc private func appDidResignActive() {
        endDragIfNeeded()
    }

    // MARK: - Context Menu

    private func showContextMenu(with event: NSEvent) {
        guard let view = self.view else { return }

        let menu = NSMenu(title: "Clawdachi")

        // Launch Claude Code submenu (top of menu)
        let launchItem = NSMenuItem(title: "Launch Claude Code", action: nil, keyEquivalent: "")
        launchItem.image = NSImage(systemSymbolName: "terminal", accessibilityDescription: nil)
        let launchSubmenu = NSMenu(title: "Launch Claude Code")
        buildLaunchClaudeSubmenu(launchSubmenu)
        launchItem.submenu = launchSubmenu
        menu.addItem(launchItem)

        menu.addItem(NSMenuItem.separator())

        // Settings
        let settingsItem = NSMenuItem(
            title: "Settings",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        // Sleep mode toggle
        let sleepItem = NSMenuItem(
            title: isSleeping ? "Wake Up" : "Sleep Mode",
            action: #selector(toggleSleep),
            keyEquivalent: "z"
        )
        sleepItem.target = self
        sleepItem.image = NSImage(systemSymbolName: isSleeping ? "sun.max.fill" : "moon.fill", accessibilityDescription: nil)
        menu.addItem(sleepItem)

        // Quit
        let quitItem = NSMenuItem(
            title: "Quit Clawdachi",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        quitItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        menu.addItem(quitItem)

        // Show menu at click location
        let locationInView = event.locationInWindow
        menu.popUp(positioning: nil, at: locationInView, in: view)
    }

    private func buildInstanceSubmenu(_ menu: NSMenu) {
        let sessions = claudeMonitor.activeSessions
        let currentMode = claudeMonitor.selectionMode

        // "Any Active" option (recommended default)
        let anyActiveItem = NSMenuItem(
            title: "Any Active (Recommended)",
            action: #selector(selectAnyActiveMode),
            keyEquivalent: ""
        )
        anyActiveItem.target = self
        anyActiveItem.state = (currentMode == .anyActive) ? .on : .off
        menu.addItem(anyActiveItem)

        // "Follow Focused Tab" option (original TTY-based behavior)
        let followFocusedItem = NSMenuItem(
            title: "Follow Focused Tab",
            action: #selector(selectFollowFocusedMode),
            keyEquivalent: ""
        )
        followFocusedItem.target = self
        followFocusedItem.state = (currentMode == .followFocusedTab) ? .on : .off
        menu.addItem(followFocusedItem)

        // Separator if there are sessions
        if !sessions.isEmpty {
            menu.addItem(NSMenuItem.separator())
        }

        // Individual sessions (for manual selection)
        // Track display names for duplicate detection
        var displayNameCounts: [String: Int] = [:]
        for session in sessions {
            displayNameCounts[session.displayName, default: 0] += 1
        }

        for session in sessions {
            var title = session.displayName
            // Append ID suffix if duplicate names exist
            if displayNameCounts[session.displayName, default: 0] > 1 {
                let shortId = String(session.id.suffix(6))
                title = "\(title) (\(shortId))"
            }

            // Append status indicator
            let statusLabel = statusDisplayLabel(for: session.status)
            if !statusLabel.isEmpty {
                title = "\(title) \(statusLabel)"
            }

            let item = NSMenuItem(
                title: title,
                action: #selector(selectSpecificInstance(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = session.id

            // Check mark for specific mode with matching ID
            if case .specific(let selectedId) = currentMode, selectedId == session.id {
                item.state = .on
            } else {
                item.state = .off
            }
            menu.addItem(item)
        }
    }

    private func statusDisplayLabel(for status: String) -> String {
        switch status {
        case "thinking", "tools":
            return "(thinking...)"
        case "planning":
            return "(planning...)"
        case "waiting":
            return "(waiting)"
        case "error":
            return "(error)"
        default:
            return ""
        }
    }

    @objc private func selectAnyActiveMode() {
        claudeMonitor.selectionMode = .anyActive
        saveSelectionMode(.anyActive)
    }

    @objc private func selectFollowFocusedMode() {
        claudeMonitor.selectionMode = .followFocusedTab
        saveSelectionMode(.followFocusedTab)
    }

    @objc private func selectSpecificInstance(_ sender: NSMenuItem) {
        guard let sessionId = sender.representedObject as? String else { return }
        claudeMonitor.selectionMode = .specific(sessionId)
        saveSelectionMode(.specific(sessionId))
    }

    private func saveSelectionMode(_ mode: SessionSelectionMode) {
        let defaults = UserDefaults.standard
        switch mode {
        case .anyActive:
            defaults.set("anyActive", forKey: "clawdachi.monitoring.mode")
            defaults.removeObject(forKey: "clawdachi.monitoring.instanceId")
        case .followFocusedTab:
            defaults.set("followFocusedTab", forKey: "clawdachi.monitoring.mode")
            defaults.removeObject(forKey: "clawdachi.monitoring.instanceId")
        case .specific(let id):
            defaults.set("specific", forKey: "clawdachi.monitoring.mode")
            defaults.set(id, forKey: "clawdachi.monitoring.instanceId")
        }
    }

    private func loadSelectionMode() -> SessionSelectionMode? {
        let defaults = UserDefaults.standard
        let mode = defaults.string(forKey: "clawdachi.monitoring.mode")

        switch mode {
        case "anyActive":
            return .anyActive
        case "followFocusedTab":
            return .followFocusedTab
        case "specific":
            if let id = defaults.string(forKey: "clawdachi.monitoring.instanceId") {
                return .specific(id)
            }
            return .anyActive
        default:
            // Migration: check for old instanceId format (manual selection)
            if let oldId = defaults.string(forKey: "clawdachi.monitoring.instanceId") {
                // Migrate to new format
                defaults.set("specific", forKey: "clawdachi.monitoring.mode")
                return .specific(oldId)
            }
            // No saved preference - use default (anyActive)
            return nil
        }
    }

    // MARK: - Launch Claude Menu

    private func buildLaunchClaudeSubmenu(_ menu: NSMenu) {
        let launcher = ClaudeLauncher.shared
        let recentDirs = launcher.recentDirectories(limit: 5)
        let availableTerminals = launcher.availableTerminals()
        let preferredTerminal = launcher.preferredTerminal

        // Recent directories
        if recentDirs.isEmpty {
            let emptyItem = NSMenuItem(
                title: "(No recent projects)",
                action: nil,
                keyEquivalent: ""
            )
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for dir in recentDirs {
                let item = NSMenuItem(
                    title: dir.displayName,
                    action: #selector(launchClaudeInDirectory(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = dir.path
                item.image = NSImage(systemSymbolName: "folder", accessibilityDescription: nil)
                menu.addItem(item)
            }
        }

        menu.addItem(NSMenuItem.separator())

        // Browse option
        let browseItem = NSMenuItem(
            title: "Browse...",
            action: #selector(launchClaudeBrowse),
            keyEquivalent: ""
        )
        browseItem.target = self
        browseItem.image = NSImage(systemSymbolName: "folder.badge.plus", accessibilityDescription: nil)
        menu.addItem(browseItem)

        menu.addItem(NSMenuItem.separator())

        // Terminal preference
        if availableTerminals.isEmpty {
            let noTerminalItem = NSMenuItem(
                title: "No supported terminal found",
                action: nil,
                keyEquivalent: ""
            )
            noTerminalItem.isEnabled = false
            menu.addItem(noTerminalItem)
        } else {
            for terminal in availableTerminals {
                let item = NSMenuItem(
                    title: terminal.displayName,
                    action: #selector(selectPreferredTerminal(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = terminal.rawValue
                item.state = (terminal == preferredTerminal) ? .on : .off
                item.image = NSImage(systemSymbolName: "terminal.fill", accessibilityDescription: nil)
                menu.addItem(item)
            }
        }
    }

    @objc private func launchClaudeInDirectory(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? URL else { return }

        showChatBubble("launching claude...", duration: 2.0)

        ClaudeLauncher.shared.launch(in: path) { [weak self] result in
            switch result {
            case .success:
                break  // Already showed launching message
            case .terminalNotInstalled(let terminal):
                self?.showChatBubble("\(terminal.displayName) not found", duration: 3.0)
            case .directoryNotFound:
                self?.showChatBubble("folder not found", duration: 3.0)
            case .appleScriptError(let message):
                self?.showChatBubble("error: \(message)", duration: 3.0)
            }
        }
    }

    @objc private func launchClaudeBrowse() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose a directory to launch Claude Code in"
        panel.prompt = "Launch Claude"

        // Start in last used location or home directory
        if let lastPath = UserDefaults.standard.string(forKey: "clawdachi.launch.lastBrowsedDirectory") {
            panel.directoryURL = URL(fileURLWithPath: lastPath)
        }

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }

            // Save last used location
            UserDefaults.standard.set(url.deletingLastPathComponent().path, forKey: "clawdachi.launch.lastBrowsedDirectory")

            self?.showChatBubble("launching claude...", duration: 2.0)

            ClaudeLauncher.shared.launch(in: url) { [weak self] result in
                switch result {
                case .success:
                    break
                case .terminalNotInstalled(let terminal):
                    self?.showChatBubble("\(terminal.displayName) not found", duration: 3.0)
                case .directoryNotFound:
                    self?.showChatBubble("folder not found", duration: 3.0)
                case .appleScriptError(let message):
                    self?.showChatBubble("error: \(message)", duration: 3.0)
                }
            }
        }
    }

    @objc private func selectPreferredTerminal(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let terminal = ClaudeLauncher.Terminal(rawValue: rawValue) else { return }
        ClaudeLauncher.shared.preferredTerminal = terminal
    }

    @objc func toggleSleep() {
        if isSleeping {
            isSleeping = false
            clawdachi.wakeUp { [weak self] in
                // Resume dancing if music is playing after wake animation completes
                if self?.musicMonitor.isPlaying == true {
                    self?.clawdachi.startDancing()
                }
            }
        } else {
            // Stop dancing and thinking before sleeping
            clawdachi.stopDancing()
            clawdachi.stopClaudeThinking()
            // Clear tracking so we don't get spurious sounds on wake
            claudeStatusHandler.clearTracking()
            isSleeping = true
            clawdachi.startSleeping()
            showChatBubble(ClawdachiMessages.sleepMessage, duration: 3.0)
        }
    }

    @objc private func openSettings() {
        guard let window = view?.window else { return }
        SettingsWindow.shared.toggle(relativeTo: window)
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Chat Bubble

    /// Show a chat bubble with the given message
    /// - Parameters:
    ///   - message: Text to display in the bubble
    ///   - duration: Auto-dismiss duration (default 5s, nil = manual only)
    ///   - verticalOffset: Custom vertical offset (nil = use default)
    ///   - horizontalOffset: Custom horizontal offset (nil = use default, positive = right)
    func showChatBubble(_ message: String, duration: TimeInterval? = 5.0, verticalOffset: CGFloat? = nil, horizontalOffset: CGFloat? = nil) {
        guard let window = view?.window else { return }
        ChatBubbleWindow.show(message: message, relativeTo: window, duration: duration, verticalOffset: verticalOffset, horizontalOffset: horizontalOffset)

        // Trigger speaking animation on the sprite
        clawdachi.startSpeaking(duration: min(duration ?? 2.0, 2.5))
    }

    /// Dismiss any visible chat bubble
    func dismissChatBubble() {
        ChatBubbleWindow.dismiss(animated: true)
    }

    // MARK: - Debug Animation Methods

    func debugTriggerBlink() {
        clawdachi.triggerBlink()
    }

    func debugTriggerWhistle() {
        guard !isSleeping else { return }
        clawdachi.performWhistleAnimation()
    }

    func debugTriggerSmoking() {
        guard !isSleeping else { return }
        clawdachi.performSmokingAnimation()
    }

    func debugTriggerLookAround() {
        guard !isSleeping else { return }
        clawdachi.performLookAround()
    }

    func debugTriggerWave() {
        guard !isSleeping else { return }
        clawdachi.performWave()
    }

    func debugTriggerBounce() {
        guard !isSleeping else { return }
        clawdachi.performBounce()
    }

    func debugTriggerHeart() {
        guard !isSleeping else { return }
        clawdachi.performHeartReaction()
    }

    func debugTriggerRandomReaction() {
        guard !isSleeping else { return }
        clawdachi.triggerClickReaction()
    }

    func debugTriggerThinking(duration: TimeInterval) {
        guard !isSleeping else { return }
        clawdachi.stopDancing()
        clawdachi.startClaudeThinking()

        // Auto-stop after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.clawdachi.stopClaudeThinking()
        }
    }

    func debugTriggerPlanning(duration: TimeInterval) {
        guard !isSleeping else { return }
        clawdachi.stopDancing()
        clawdachi.startClaudePlanning()

        // Auto-stop after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.clawdachi.stopClaudePlanning()
        }
    }

    func debugTriggerQuestionMark() {
        guard !isSleeping else { return }
        clawdachi.stopDancing()
        clawdachi.stopClaudeThinking()
        clawdachi.stopClaudePlanning()
        clawdachi.showQuestionMark()
        showChatBubble(ClawdachiMessages.randomWaitingMessage(), duration: 4.0)
    }

    func debugTriggerPartyCelebration() {
        guard !isSleeping else { return }
        clawdachi.stopDancing()
        clawdachi.stopClaudeThinking()
        clawdachi.stopClaudePlanning()
        clawdachi.dismissQuestionMark()
        clawdachi.showPartyCelebration()
        showChatBubble(ClawdachiMessages.randomCompletionMessage(), duration: 4.0, verticalOffset: ChatBubbleConstants.celebrationVerticalOffset, horizontalOffset: ChatBubbleConstants.celebrationHorizontalOffset)
    }

    func debugClearClaudeStates() {
        clawdachi.stopClaudeThinking()
        clawdachi.stopClaudePlanning()
        clawdachi.dismissQuestionMark()
        clawdachi.dismissPartyCelebration()
        clawdachi.dismissLightbulb()
        clawdachi.resumeIdleAnimations()
    }

    func debugStartDancing() {
        guard !isSleeping else { return }
        clawdachi.startDancing()
    }

    func debugStopDancing() {
        clawdachi.stopDancing()
    }

    func debugStartSleeping() {
        clawdachi.stopDancing()
        clawdachi.stopClaudeThinking()
        clawdachi.stopClaudePlanning()
        clawdachi.dismissQuestionMark()
        clawdachi.dismissPartyCelebration()
        claudeStatusHandler.clearTracking()
        isSleeping = true
        clawdachi.startSleeping()
        showChatBubble(ClawdachiMessages.sleepMessage, duration: 3.0)
    }

    func debugWakeUp() {
        guard isSleeping else { return }
        isSleeping = false
        clawdachi.wakeUp { [weak self] in
            if self?.musicMonitor.isPlaying == true {
                self?.clawdachi.startDancing()
            }
        }
    }

    func debugTestMultipleBubbles() {
        let messages = [
            "hi, i'm clawdachi",
            "i love music!",
            "pet me please?",
            "zzz so sleepy"
        ]

        for (index, message) in messages.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 1.2) { [weak self] in
                self?.showChatBubble(message)
            }
        }
    }
}
