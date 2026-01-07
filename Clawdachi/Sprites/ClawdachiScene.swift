//
//  ClawdachiScene.swift
//  Clawdachi
//

import SpriteKit
import AppKit

class ClawdachiScene: SKScene {

    // MARK: - Properties

    private var clawdachi: ClawdachiSprite!
    private var isSleeping = false
    private var musicMonitor: MusicPlaybackMonitor!
    private var claudeMonitor: ClaudeSessionMonitor!
    private var wasClaudeActive = false

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
        claudeMonitor = ClaudeSessionMonitor()

        // Load saved preference
        if let savedId = UserDefaults.standard.string(forKey: "clawdachi.monitoring.instanceId") {
            claudeMonitor.selectedSessionId = savedId
        }

        claudeMonitor.onStatusChanged = { [weak self] isActive, status in
            self?.handleClaudeStatusChanged(isActive: isActive, status: status)
        }
    }

    private func handleClaudeStatusChanged(isActive: Bool, status: String?) {
        // Don't interrupt sleep
        guard !isSleeping else { return }

        if isActive && status == "planning" {
            // Claude is in plan mode - show planning pose (thinking + lightbulb)
            clawdachi.dismissQuestionMark()
            clawdachi.dismissPartyCelebration()

            // Only start if not already planning
            if !clawdachi.isClaudePlanning {
                clawdachi.stopClaudeThinking()  // Stop regular thinking if active
                clawdachi.startClaudePlanning()

                // Show planning message only when first starting
                if !wasClaudeActive {
                    showChatBubble(randomPlanningMessage(), duration: 3.0)
                }
            }
            wasClaudeActive = true
        } else if isActive && (status == "thinking" || status == "tools") {
            // Claude is working - show thinking pose
            clawdachi.dismissLightbulb()
            clawdachi.dismissQuestionMark()
            clawdachi.dismissPartyCelebration()

            // Stop planning if was planning, then start thinking
            if clawdachi.isClaudePlanning {
                clawdachi.stopClaudePlanning()
            }
            clawdachi.startClaudeThinking()

            // Show thinking message only when first starting
            if !wasClaudeActive {
                showChatBubble(randomThinkingMessage(), duration: 3.0)
            }
            wasClaudeActive = true
        } else if isActive && status == "waiting" {
            // Claude stopped responding - waiting for user input
            clawdachi.stopClaudeThinking()
            clawdachi.stopClaudePlanning()
            clawdachi.stopDancing()  // Stop dancing while waiting
            clawdachi.dismissPartyCelebration()
            clawdachi.showQuestionMark()

            // Show waiting message
            showChatBubble(randomWaitingMessage(), duration: 4.0)
            // Keep wasClaudeActive true - still in session
            // Don't resume dancing - question mark means user interaction needed
        } else {
            // Claude session truly ended - show completion celebration
            clawdachi.stopClaudeThinking()
            clawdachi.stopClaudePlanning()
            clawdachi.dismissQuestionMark()

            // Show party celebration when transitioning from active → complete
            // Persists until user clicks sprite or new CLI status
            if wasClaudeActive {
                clawdachi.showPartyCelebration()
                showChatBubble(randomCompletionMessage(), duration: 4.0)
                wasClaudeActive = false
            }
        }
    }

    // MARK: - Claude Event Messages

    private func randomThinkingMessage() -> String {
        let messages = [
            "on it!",
            "one sec!",
            "i got this!"
        ]
        return messages.randomElement() ?? "on it!"
    }

    private func randomPlanningMessage() -> String {
        let messages = [
            "got an idea!",
            "let me plan this",
            "mapping it out!"
        ]
        return messages.randomElement() ?? "got an idea!"
    }

    private func randomWaitingMessage() -> String {
        let messages = [
            "your turn!",
            "whatcha think?",
            "need your input!",
            "over to you!",
            "waiting on you~",
            "yes? no? maybe?"
        ]
        return messages.randomElement() ?? "your turn!"
    }

    private func randomCompletionMessage() -> String {
        let messages = [
            "all done!",
            "ta-da!",
            "finished!",
            "nailed it!",
            "done and done!",
            "woohoo!",
            "mission complete!"
        ]
        return messages.randomElement() ?? "all done!"
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

        // Header
        let headerItem = NSMenuItem(title: "Clawdachi", action: nil, keyEquivalent: "")
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

        // Monitor Instance submenu
        let instanceItem = NSMenuItem(title: "Monitor Instance", action: nil, keyEquivalent: "")
        let instanceSubmenu = NSMenu(title: "Monitor Instance")
        buildInstanceSubmenu(instanceSubmenu)
        instanceItem.submenu = instanceSubmenu
        menu.addItem(instanceItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(
            title: "Quit Clawdachi",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        // Show menu at click location
        let locationInView = event.locationInWindow
        menu.popUp(positioning: nil, at: locationInView, in: view)
    }

    private func buildInstanceSubmenu(_ menu: NSMenu) {
        let sessions = claudeMonitor.activeSessions
        let selectedId = claudeMonitor.selectedSessionId

        // Auto option (always present)
        let autoItem = NSMenuItem(
            title: "Auto (Most Recent)",
            action: #selector(selectAutoInstance),
            keyEquivalent: ""
        )
        autoItem.target = self
        autoItem.state = (selectedId == nil) ? .on : .off
        menu.addItem(autoItem)

        // Separator if there are sessions
        if !sessions.isEmpty {
            menu.addItem(NSMenuItem.separator())
        }

        // Individual sessions
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
                action: #selector(selectInstance(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = session.id
            item.state = (selectedId == session.id) ? .on : .off
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

    @objc private func selectAutoInstance() {
        claudeMonitor.selectedSessionId = nil
        saveMonitorPreference(nil)
    }

    @objc private func selectInstance(_ sender: NSMenuItem) {
        guard let sessionId = sender.representedObject as? String else { return }
        claudeMonitor.selectedSessionId = sessionId
        saveMonitorPreference(sessionId)
    }

    private func saveMonitorPreference(_ sessionId: String?) {
        let defaults = UserDefaults.standard
        if let sessionId = sessionId {
            defaults.set(sessionId, forKey: "clawdachi.monitoring.instanceId")
        } else {
            defaults.removeObject(forKey: "clawdachi.monitoring.instanceId")
        }
    }

    @objc private func toggleSleep() {
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
            wasClaudeActive = false  // Clear so we don't bounce on wake
            isSleeping = true
            clawdachi.startSleeping()
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Chat Bubble

    /// Show a chat bubble with the given message
    /// - Parameters:
    ///   - message: Text to display in the bubble
    ///   - duration: Auto-dismiss duration (default 5s, nil = manual only)
    func showChatBubble(_ message: String, duration: TimeInterval? = 5.0) {
        guard let window = view?.window else { return }
        ChatBubbleWindow.show(message: message, relativeTo: window, duration: duration)

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
        showChatBubble(randomThinkingMessage(), duration: 3.0)

        // Auto-stop after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.clawdachi.stopClaudeThinking()
        }
    }

    func debugTriggerPlanning(duration: TimeInterval) {
        guard !isSleeping else { return }
        clawdachi.stopDancing()
        clawdachi.startClaudePlanning()
        showChatBubble(randomPlanningMessage(), duration: 3.0)

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
        showChatBubble(randomWaitingMessage(), duration: 4.0)
    }

    func debugTriggerPartyCelebration() {
        guard !isSleeping else { return }
        clawdachi.stopDancing()
        clawdachi.stopClaudeThinking()
        clawdachi.stopClaudePlanning()
        clawdachi.dismissQuestionMark()
        clawdachi.showPartyCelebration()
        showChatBubble(randomCompletionMessage(), duration: 4.0)
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
        wasClaudeActive = false
        isSleeping = true
        clawdachi.startSleeping()
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
