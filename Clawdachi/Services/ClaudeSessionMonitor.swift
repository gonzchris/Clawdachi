//
//  ClaudeSessionMonitor.swift
//  Clawdachi
//
//  Monitors Claude Code sessions by polling ~/.clawdachi/sessions/ for status files
//

import Foundation

/// Public session info for UI display
struct SessionInfo: Equatable {
    let id: String
    let status: String
    let timestamp: Double
    let cwd: String?
    let tty: String?  // Terminal TTY device (e.g., /dev/ttys003)

    /// Display name for the session (project folder name or truncated ID)
    var displayName: String {
        if let cwd = cwd {
            return (cwd as NSString).lastPathComponent
        }
        // Fallback to truncated session ID
        let idWithoutPrefix = id.hasPrefix("claude-session-")
            ? String(id.dropFirst("claude-session-".count))
            : id
        return String(idWithoutPrefix.prefix(8))
    }

    /// Priority for "any active" mode selection (higher = more important)
    var activityPriority: Int {
        switch status {
        case "thinking", "planning":
            return 4  // Highest - actively working
        case "tools":
            return 3  // Running tools
        case "waiting":
            return 2  // Waiting for input
        case "idle":
            return 1  // Lowest - not doing anything
        default:
            return 0  // Unknown status
        }
    }
}

/// How to select which session to monitor
enum SessionSelectionMode: Equatable {
    /// Monitor whichever session is most actively working (recommended default)
    case anyActive
    /// Follow the focused terminal tab (original behavior)
    case followFocusedTab
    /// Monitor a specific session by ID
    case specific(String)
}

/// Monitors Claude Code session status by watching session files
class ClaudeSessionMonitor {

    // MARK: - Properties

    /// Whether any Claude session is currently active
    private(set) var isActive = false

    /// Current status from most recent session ("thinking", "tools", etc.)
    private(set) var currentStatus: String?

    /// All currently active sessions (non-stale)
    private(set) var activeSessions: [SessionInfo] = []

    /// Current selection mode for which session to monitor
    var selectionMode: SessionSelectionMode = .anyActive {
        didSet {
            // Re-check status immediately when mode changes
            checkSessionStatus()
        }
    }

    /// The TTY of the currently focused terminal (nil if not a terminal or unknown)
    private(set) var focusedTTY: String?

    /// For hysteresis in anyActive mode - prevents flickering between equal-priority sessions
    private var lastMonitoredSessionId: String?
    private var lastMonitoredTime: Date?
    private let stickinessInterval: TimeInterval = 5.0

    /// Update focused TTY (used when in followFocusedTab mode)
    /// - Parameter tty: The TTY device of the focused terminal (e.g., "/dev/ttys003")
    func updateFocusedTTY(_ tty: String?) {
        focusedTTY = tty

        // Only trigger re-check if we're in followFocusedTab mode
        if case .followFocusedTab = selectionMode {
            checkSessionStatus()
        }
    }

    /// Callback when session status changes (isActive, status, sessionId)
    var onStatusChanged: ((Bool, String?, String?) -> Void)?

    /// Callback when the list of active sessions changes
    var onSessionListChanged: (([SessionInfo]) -> Void)?

    /// Polling timer
    private var pollTimer: Timer?

    /// Polling interval in seconds (2.0s balances responsiveness with resource usage)
    private let pollInterval: TimeInterval = 2.0

    /// Sessions directory path
    private let sessionsPath: URL

    /// Last known directory modification date (for change detection)
    private var lastDirectoryModDate: Date?

    /// Cached file modification dates (filename -> modDate)
    private var fileModDates: [String: Date] = [:]

    /// Cached parsed sessions (filename -> SessionInfo)
    private var cachedSessions: [String: SessionInfo] = [:]

    /// Serial queue for thread-safe cache access
    private let cacheQueue = DispatchQueue(label: "com.clawdachi.sessioncache")

    // MARK: - Initialization

    init() {
        sessionsPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".clawdachi/sessions")
        startPolling()
    }

    deinit {
        stopPolling()
    }

    // MARK: - Polling

    private func startPolling() {
        // Check immediately
        checkSessionStatus()

        // Then poll periodically - ensure timer runs on main run loop in common mode
        // so it fires even during UI tracking (like dragging)
        pollTimer = Timer(timeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.checkSessionStatus()
        }
        RunLoop.main.add(pollTimer!, forMode: .common)
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func checkSessionStatus() {
        // Check on serial queue to avoid blocking main thread and ensure thread safety
        cacheQueue.async { [weak self] in
            guard let self = self else { return }

            let result = self.readSessionFiles()

            DispatchQueue.main.async {
                self.updateStatus(
                    isActive: result.isActive,
                    status: result.status,
                    sessionId: result.sessionId,
                    allSessions: result.allSessions
                )
            }
        }
    }

    // MARK: - Session File Reading

    private func readSessionFiles() -> (isActive: Bool, status: String?, sessionId: String?, allSessions: [SessionInfo]) {
        let fileManager = FileManager.default

        // Ensure directory exists
        guard fileManager.fileExists(atPath: sessionsPath.path) else {
            clearCache()
            return (false, nil, nil, [])
        }

        // Check directory modification date to skip unnecessary file reads
        let dirAttributes = try? fileManager.attributesOfItem(atPath: sessionsPath.path)
        let dirModDate = dirAttributes?[.modificationDate] as? Date

        // If directory hasn't changed and we have cached data, use cache
        // (but still need to check timestamps for staleness)
        let dirChanged = dirModDate != lastDirectoryModDate
        if dirChanged {
            lastDirectoryModDate = dirModDate
        }

        do {
            let files = try fileManager.contentsOfDirectory(
                at: sessionsPath,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: .skipsHiddenFiles
            )

            let jsonFiles = files.filter { $0.pathExtension == "json" }

            if jsonFiles.isEmpty {
                clearCache()
                return (false, nil, nil, [])
            }

            // Track which files still exist (for cache cleanup)
            var currentFiles = Set<String>()

            // Collect all valid sessions
            var sessions: [SessionInfo] = []
            var sessionsToDelete: [URL] = []
            let now = Date().timeIntervalSince1970

            for file in jsonFiles {
                let filename = file.lastPathComponent
                currentFiles.insert(filename)

                // Check file modification date
                let fileAttributes = try? file.resourceValues(forKeys: [.contentModificationDateKey])
                let fileModDate = fileAttributes?.contentModificationDate

                // Use cached session if file hasn't changed
                if let cachedModDate = fileModDates[filename],
                   let currentModDate = fileModDate,
                   cachedModDate == currentModDate,
                   let cachedSession = cachedSessions[filename] {
                    // First check if terminal is still open (applies to ALL sessions)
                    if !isTerminalOpen(tty: cachedSession.tty) {
                        // Terminal closed - mark for cleanup regardless of status
                        sessionsToDelete.append(file)
                        continue
                    }

                    // For idle sessions, terminal check is sufficient
                    if cachedSession.status == "idle" {
                        sessions.append(cachedSession)
                    } else {
                        // For active sessions, also apply staleness threshold
                        let age = now - cachedSession.timestamp
                        if age <= AnimationTimings.sessionStalenessThreshold {
                            sessions.append(cachedSession)
                        } else {
                            // Stale active session - mark for cleanup
                            sessionsToDelete.append(file)
                        }
                    }
                    continue
                }

                // File is new or modified - parse it
                if let session = parseSessionFile(at: file) {
                    // Update cache
                    cachedSessions[filename] = session
                    fileModDates[filename] = fileModDate

                    // First check if terminal is still open (applies to ALL sessions)
                    if !isTerminalOpen(tty: session.tty) {
                        // Terminal closed - mark for cleanup regardless of status
                        sessionsToDelete.append(file)
                        continue
                    }

                    // For idle sessions, terminal check is sufficient
                    if session.status == "idle" {
                        sessions.append(session)
                    } else {
                        // For active sessions, also apply staleness threshold
                        let age = now - session.timestamp
                        if age <= AnimationTimings.sessionStalenessThreshold {
                            sessions.append(session)
                        } else {
                            // Stale active session - mark for cleanup
                            sessionsToDelete.append(file)
                        }
                    }
                }
            }

            // Clean up stale session files (closed terminals + expired active sessions)
            for file in sessionsToDelete {
                try? fileManager.removeItem(at: file)
                let filename = file.lastPathComponent
                cachedSessions.removeValue(forKey: filename)
                fileModDates.removeValue(forKey: filename)
                currentFiles.remove(filename)
            }

            // Clean up cache for deleted files
            let deletedFiles = Set(cachedSessions.keys).subtracting(currentFiles)
            for filename in deletedFiles {
                cachedSessions.removeValue(forKey: filename)
                fileModDates.removeValue(forKey: filename)
            }

            // Sort by timestamp (most recent first)
            sessions.sort { $0.timestamp > $1.timestamp }

            // Determine which session to monitor based on selection mode
            let monitoredSession: SessionInfo?

            switch selectionMode {
            case .specific(let sessionId):
                // User selected a specific session
                monitoredSession = sessions.first { $0.id == sessionId }

            case .followFocusedTab:
                // TTY-based selection: only show session for focused terminal
                if let tty = focusedTTY {
                    monitoredSession = sessions.first { $0.tty == tty }
                } else {
                    monitoredSession = nil
                }

            case .anyActive:
                // Priority-based selection: pick the most active session
                // Sort by: 1) activity priority (desc), 2) timestamp (desc for recency)
                let sortedByPriority = sessions.sorted { lhs, rhs in
                    if lhs.activityPriority != rhs.activityPriority {
                        return lhs.activityPriority > rhs.activityPriority
                    }
                    return lhs.timestamp > rhs.timestamp
                }

                guard let topSession = sortedByPriority.first else {
                    monitoredSession = nil
                    break
                }

                // Hysteresis: stick with current session if it's still equally or more active
                // This prevents flickering between sessions of equal priority
                if let lastId = lastMonitoredSessionId,
                   let currentSession = sessions.first(where: { $0.id == lastId }),
                   currentSession.activityPriority >= topSession.activityPriority,
                   let lastTime = lastMonitoredTime,
                   Date().timeIntervalSince(lastTime) < stickinessInterval {
                    monitoredSession = currentSession
                } else {
                    monitoredSession = topSession
                    lastMonitoredSessionId = topSession.id
                    lastMonitoredTime = Date()
                }
            }

            let hasActiveSession = monitoredSession != nil
            return (hasActiveSession, monitoredSession?.status, monitoredSession?.id, sessions)

        } catch {
            return (false, nil, nil, [])
        }
    }

    /// Check if a terminal is still open by verifying the TTY device exists
    private func isTerminalOpen(tty: String?) -> Bool {
        guard let tty = tty, !tty.isEmpty else {
            // No TTY info - assume still open (will be cleaned up by staleness)
            return true
        }
        return FileManager.default.fileExists(atPath: tty)
    }

    private func parseSessionFile(at url: URL) -> SessionInfo? {
        do {
            let data = try Data(contentsOf: url)
            let session = try JSONDecoder().decode(SessionData.self, from: data)
            return SessionInfo(
                id: session.session_id ?? url.deletingPathExtension().lastPathComponent,
                status: session.status,
                timestamp: session.timestamp,
                cwd: session.cwd,
                tty: session.tty
            )
        } catch {
            return nil
        }
    }

    private func clearCache() {
        lastDirectoryModDate = nil
        fileModDates.removeAll()
        cachedSessions.removeAll()
    }

    // MARK: - State Update

    /// Currently monitored session ID
    private(set) var currentSessionId: String?

    private func updateStatus(isActive: Bool, status: String?, sessionId: String?, allSessions: [SessionInfo]) {
        // Check if session list changed
        let sessionsChanged = activeSessions != allSessions
        if sessionsChanged {
            activeSessions = allSessions
            onSessionListChanged?(allSessions)

            // If specific session no longer exists, fall back to anyActive mode
            if case .specific(let selectedId) = selectionMode,
               !allSessions.contains(where: { $0.id == selectedId }) {
                selectionMode = .anyActive
                // Note: This will trigger another checkSessionStatus() via didSet
                return
            }
        }

        // Only fire status callback if state actually changed
        let statusChanged = isActive != self.isActive || status != self.currentStatus || sessionId != self.currentSessionId

        guard statusChanged else { return }

        self.isActive = isActive
        self.currentStatus = status
        self.currentSessionId = sessionId
        onStatusChanged?(isActive, status, sessionId)
    }
}

// MARK: - Session Data Model (internal JSON parsing)

private struct SessionData: Codable {
    let status: String
    let timestamp: Double
    let session_id: String?
    let tool_name: String?
    let cwd: String?
    let tty: String?
}
