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
    private var terminalFocusMonitor: TerminalFocusMonitor!

    // Track last known status per session (to detect actual state transitions vs tab switches)
    private var sessionLastStatus: [String: String] = [:]

    // Track which sessions have played sounds this work cycle (reset when session starts working again)
    private var sessionsPlayedQuestionSound: Set<String> = []
    private var sessionsPlayedCompleteSound: Set<String> = []

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
        setupVoiceInput()

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
            claudeMonitor.autoSelectByTTY = false  // Manual selection overrides TTY
        }

        claudeMonitor.onStatusChanged = { [weak self] isActive, status, sessionId in
            self?.handleClaudeStatusChanged(isActive: isActive, status: status, sessionId: sessionId)
        }

        // Set up terminal focus monitor to auto-select session by focused tab
        terminalFocusMonitor = TerminalFocusMonitor()
        terminalFocusMonitor.onFocusedTTYChanged = { [weak self] tty in
            self?.claudeMonitor.selectSessionByTTY(tty)
        }
    }

    private func handleClaudeStatusChanged(isActive: Bool, status: String?, sessionId: String?) {
        // Don't interrupt sleep
        guard !isSleeping else { return }

        // Always update animations to reflect current monitored session's state
        updateAnimationsForStatus(status)

        // For sound logic, we need a valid session ID
        guard let id = sessionId else { return }

        let currentStatus = status ?? "none"
        let previousStatus = sessionLastStatus[id]

        // Update stored status
        sessionLastStatus[id] = currentStatus

        // Check if this is an actual state transition (not just a tab switch)
        let isRealTransition = previousStatus != currentStatus

        guard isRealTransition else {
            // Just switched tabs to view this session - no sounds
            return
        }

        // Determine if previous status was "working"
        let wasWorking = previousStatus == "thinking" || previousStatus == "tools" || previousStatus == "planning"

        // Handle actual state transitions
        if currentStatus == "waiting" && wasWorking {
            // Transitioned from working to waiting - play question sound
            if !sessionsPlayedQuestionSound.contains(id) {
                sessionsPlayedQuestionSound.insert(id)
                SoundManager.shared.playQuestionSound()
                showChatBubble(randomWaitingMessage(), duration: 4.0)
            }
        } else if currentStatus == "idle" && wasWorking {
            // Transitioned from working to idle - play complete sound
            if !sessionsPlayedCompleteSound.contains(id) {
                sessionsPlayedCompleteSound.insert(id)
                clawdachi.showPartyCelebration()
                SoundManager.shared.playCompleteSound()
                showChatBubble(randomCompletionMessage(), duration: 4.0)
            }
        } else if currentStatus == "thinking" || currentStatus == "tools" || currentStatus == "planning" {
            // Started working - reset sound tracking for fresh cycle
            sessionsPlayedQuestionSound.remove(id)
            sessionsPlayedCompleteSound.remove(id)

            // Show message if transitioning from non-working to working
            let wasNotWorking = previousStatus == nil || previousStatus == "idle" || previousStatus == "none"
            if wasNotWorking {
                if currentStatus == "planning" {
                    showChatBubble(randomPlanningMessage(), duration: 3.0)
                } else {
                    showChatBubble(randomThinkingMessage(), duration: 3.0)
                }
            }
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
            }
        case "thinking", "tools":
            clawdachi.dismissLightbulb()
            clawdachi.dismissQuestionMark()
            clawdachi.dismissPartyCelebration()
            let wasThinking = clawdachi.isClaudeThinking
            if clawdachi.isClaudePlanning {
                clawdachi.stopClaudePlanning()
            }
            clawdachi.startClaudeThinking()
            // Show message only when first entering thinking mode
            if !wasThinking {
                showChatBubble("*thinking*", duration: 3.0)
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

    // MARK: - Voice Input Setup

    private func setupVoiceInput() {
        let voiceService = VoiceInputService.shared

        // Wire up recording state to sprite animation
        voiceService.onRecordingStateChanged = { [weak self] isRecording in
            guard let self = self else { return }
            if isRecording {
                self.clawdachi.startListening()
                self.showChatBubble(self.randomListeningMessage(), duration: nil)
            } else {
                self.clawdachi.stopListening()
                ChatBubbleWindow.dismiss(animated: true)
            }
        }

        // Wire up transcription completion
        voiceService.onTranscriptionComplete = { [weak self] text in
            guard let self = self, let text = text else { return }
            // Show brief confirmation
            let truncated = text.count > 30 ? String(text.prefix(27)) + "..." : text
            self.showChatBubble("sent: \(truncated)", duration: 2.0)
        }

        // Wire up errors
        voiceService.onError = { [weak self] message in
            self?.showChatBubble(message, duration: 3.0)
        }
    }

    private func randomListeningMessage() -> String {
        let messages = [
            "listening...",
            "go ahead!",
            "speak up!",
            "i'm all ears!"
        ]
        return messages.randomElement() ?? "listening..."
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

        // Cancel voice recording if app loses focus
        if VoiceInputService.shared.isRecording {
            VoiceInputService.shared.cancelRecording()
        }
    }

    // MARK: - Keyboard Handling (Voice Input)

    override func keyDown(with event: NSEvent) {
        // Spacebar (keyCode 49) toggles voice input when window is focused
        if event.keyCode == 49 && !event.isARepeat {
            if VoiceInputService.shared.isRecording {
                VoiceInputService.shared.stopRecording()
            } else {
                VoiceInputService.shared.startRecording()
            }
        }
    }

    // MARK: - Context Menu

    private func showContextMenu(with event: NSEvent) {
        guard let view = self.view else { return }

        let menu = NSMenu(title: "Clawdachi")

        // Launch Claude Code submenu (top of menu)
        let launchItem = NSMenuItem(title: "Launch Claude Code", action: nil, keyEquivalent: "")
        let launchSubmenu = NSMenu(title: "Launch Claude Code")
        buildLaunchClaudeSubmenu(launchSubmenu)
        launchItem.submenu = launchSubmenu
        menu.addItem(launchItem)

        menu.addItem(NSMenuItem.separator())

        // Monitor Instance submenu
        let instanceItem = NSMenuItem(title: "Monitor Instance", action: nil, keyEquivalent: "")
        let instanceSubmenu = NSMenu(title: "Monitor Instance")
        buildInstanceSubmenu(instanceSubmenu)
        instanceItem.submenu = instanceSubmenu
        menu.addItem(instanceItem)

        // Voice Input submenu
        let voiceItem = NSMenuItem(title: "Voice Input", action: nil, keyEquivalent: "")
        let voiceSubmenu = NSMenu(title: "Voice Input")
        buildVoiceInputSubmenu(voiceSubmenu)
        voiceItem.submenu = voiceSubmenu
        menu.addItem(voiceItem)

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
        let isAutoMode = selectedId == nil

        // Auto option (always present) - now uses focused terminal tab
        let autoTitle = "Auto (Focused Tab)"
        let autoItem = NSMenuItem(
            title: autoTitle,
            action: #selector(selectAutoInstance),
            keyEquivalent: ""
        )
        autoItem.target = self
        autoItem.state = isAutoMode ? .on : .off
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
        claudeMonitor.autoSelectByTTY = true  // Re-enable TTY-based selection
        saveMonitorPreference(nil)
    }

    @objc private func selectInstance(_ sender: NSMenuItem) {
        guard let sessionId = sender.representedObject as? String else { return }
        claudeMonitor.selectedSessionId = sessionId
        claudeMonitor.autoSelectByTTY = false  // Disable TTY auto-selection when manually selecting
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

    // MARK: - Voice Input Menu

    private func buildVoiceInputSubmenu(_ menu: NSMenu) {
        let useWhisper = VoiceInputService.useWhisper
        let whisperDownloaded = WhisperModelManager.shared.isModelDownloaded

        // Native option
        let nativeItem = NSMenuItem(
            title: "macOS Native",
            action: #selector(selectNativeRecognition),
            keyEquivalent: ""
        )
        nativeItem.target = self
        nativeItem.state = useWhisper ? .off : .on
        menu.addItem(nativeItem)

        // Whisper option (or download option)
        if whisperDownloaded {
            let whisperItem = NSMenuItem(
                title: "Whisper (Better Accuracy)",
                action: #selector(selectWhisperRecognition),
                keyEquivalent: ""
            )
            whisperItem.target = self
            whisperItem.state = useWhisper ? .on : .off
            menu.addItem(whisperItem)
        } else if WhisperModelManager.shared.isDownloading {
            let downloadingItem = NSMenuItem(
                title: "Downloading... \(Int(WhisperModelManager.shared.downloadProgress * 100))%",
                action: nil,
                keyEquivalent: ""
            )
            downloadingItem.isEnabled = false
            menu.addItem(downloadingItem)
        } else {
            let downloadItem = NSMenuItem(
                title: "Download Whisper (~\(WhisperModelManager.shared.modelSizeDescription))",
                action: #selector(downloadWhisperModel),
                keyEquivalent: ""
            )
            downloadItem.target = self
            menu.addItem(downloadItem)
        }

        menu.addItem(NSMenuItem.separator())

        // Hotkey hint
        let hotkeyItem = NSMenuItem(
            title: "Hotkey: Ctrl+Opt+Cmd (hold)",
            action: nil,
            keyEquivalent: ""
        )
        hotkeyItem.isEnabled = false
        menu.addItem(hotkeyItem)

        let spacebarItem = NSMenuItem(
            title: "Or: Click sprite + hold Space",
            action: nil,
            keyEquivalent: ""
        )
        spacebarItem.isEnabled = false
        menu.addItem(spacebarItem)
    }

    @objc private func selectNativeRecognition() {
        VoiceInputService.useWhisper = false
    }

    @objc private func selectWhisperRecognition() {
        VoiceInputService.useWhisper = true
    }

    @objc private func downloadWhisperModel() {
        showChatBubble("downloading whisper...", duration: nil)

        WhisperModelManager.shared.onDownloadProgress = { [weak self] progress in
            let percent = Int(progress * 100)
            // Update bubble periodically
            if percent % 10 == 0 || percent == 100 {
                ChatBubbleWindow.dismiss(animated: false)
                self?.showChatBubble("downloading: \(percent)%", duration: nil)
            }
        }

        WhisperModelManager.shared.onDownloadComplete = { [weak self] result in
            ChatBubbleWindow.dismiss(animated: true)
            switch result {
            case .success:
                self?.showChatBubble("whisper ready!", duration: 3.0)
                VoiceInputService.shared.reloadWhisperRecognizer()
            case .failure:
                self?.showChatBubble("download failed", duration: 3.0)
            }
        }

        WhisperModelManager.shared.downloadModel()
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
            // Clear tracking so we don't get spurious sounds on wake
            sessionLastStatus.removeAll()
            sessionsPlayedQuestionSound.removeAll()
            sessionsPlayedCompleteSound.removeAll()
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
        sessionLastStatus.removeAll()
        sessionsPlayedQuestionSound.removeAll()
        sessionsPlayedCompleteSound.removeAll()
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
