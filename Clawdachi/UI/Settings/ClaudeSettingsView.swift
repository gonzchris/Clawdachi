//
//  ClaudeSettingsView.swift
//  Clawdachi
//
//  Claude Code session monitoring settings
//

import AppKit

/// Claude settings section with session monitoring controls
class ClaudeSettingsView: NSView {

    private typealias C = SettingsConstants

    // MARK: - Properties

    private var titleLabel: NSTextField!
    private var modeLabel: NSTextField!
    private var anyActiveRadio: NSButton!
    private var followTabRadio: NSButton!
    private var specificRadio: NSButton!

    private var sessionsLabel: NSTextField!
    private var sessionsScrollView: NSScrollView!
    private var sessionsTableView: NSTableView!
    private var noSessionsLabel: NSTextField!

    private var menuBarCheckbox: NSButton!
    private var notifyCheckbox: NSButton!

    private var sessions: [SessionInfo] = []
    private var selectedSpecificSessionId: String?

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
        setupObservers()
        loadSettings()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        setupObservers()
        loadSettings()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupViews() {
        wantsLayer = true

        setupTitle()
        setupModeRadios()
        setupSessionsList()
        setupToggles()
    }

    override var isFlipped: Bool { true }

    // MARK: - UI Setup

    private func setupTitle() {
        titleLabel = NSTextField(labelWithString: "CLAUDE")
        titleLabel.frame = NSRect(x: 20, y: 20, width: 200, height: 20)
        titleLabel.font = NSFont.monospacedSystemFont(ofSize: C.titleFontSize, weight: .bold)
        titleLabel.textColor = C.accentColor
        addSubview(titleLabel)
    }

    private func setupModeRadios() {
        modeLabel = NSTextField(labelWithString: "Monitoring Mode:")
        modeLabel.frame = NSRect(x: 20, y: 50, width: 150, height: 18)
        modeLabel.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .medium)
        modeLabel.textColor = C.textColor
        addSubview(modeLabel)

        anyActiveRadio = createRadioButton(title: "Any Active (recommended)", y: 72)
        anyActiveRadio.action = #selector(modeChanged(_:))
        anyActiveRadio.tag = 0
        addSubview(anyActiveRadio)

        followTabRadio = createRadioButton(title: "Follow Focused Terminal", y: 94)
        followTabRadio.action = #selector(modeChanged(_:))
        followTabRadio.tag = 1
        addSubview(followTabRadio)

        specificRadio = createRadioButton(title: "Specific Instance", y: 116)
        specificRadio.action = #selector(modeChanged(_:))
        specificRadio.tag = 2
        addSubview(specificRadio)
    }

    private func createRadioButton(title: String, y: CGFloat) -> NSButton {
        let radio = NSButton(radioButtonWithTitle: title, target: self, action: nil)
        radio.frame = NSRect(x: 28, y: y, width: 250, height: 20)
        styleRadio(radio)
        return radio
    }

    private func styleRadio(_ radio: NSButton) {
        radio.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        radio.contentTintColor = C.accentColor
        if let title = radio.title as NSString? {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .regular),
                .foregroundColor: C.textColor
            ]
            radio.attributedTitle = NSAttributedString(string: title as String, attributes: attrs)
        }
    }

    private func setupSessionsList() {
        sessionsLabel = NSTextField(labelWithString: "Active Sessions:")
        sessionsLabel.frame = NSRect(x: 20, y: 146, width: 150, height: 18)
        sessionsLabel.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .medium)
        sessionsLabel.textColor = C.textColor
        addSubview(sessionsLabel)

        // Scroll view for sessions list
        sessionsScrollView = NSScrollView(frame: NSRect(x: 20, y: 168, width: 310, height: 100))
        sessionsScrollView.hasVerticalScroller = true
        sessionsScrollView.hasHorizontalScroller = false
        sessionsScrollView.autohidesScrollers = true
        sessionsScrollView.borderType = .noBorder
        sessionsScrollView.drawsBackground = true
        sessionsScrollView.backgroundColor = C.cellBackgroundColor

        // Table view
        sessionsTableView = NSTableView()
        sessionsTableView.backgroundColor = .clear
        sessionsTableView.style = .plain
        sessionsTableView.selectionHighlightStyle = .regular
        sessionsTableView.rowHeight = 24
        sessionsTableView.intercellSpacing = NSSize(width: 0, height: 2)
        sessionsTableView.headerView = nil
        sessionsTableView.delegate = self
        sessionsTableView.dataSource = self
        sessionsTableView.target = self
        sessionsTableView.action = #selector(sessionRowClicked)

        // Single column for session name + status
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("session"))
        column.width = 290
        sessionsTableView.addTableColumn(column)

        sessionsScrollView.documentView = sessionsTableView
        addSubview(sessionsScrollView)

        // No sessions label
        noSessionsLabel = NSTextField(labelWithString: "No active sessions")
        noSessionsLabel.frame = NSRect(x: 20, y: 200, width: 310, height: 36)
        noSessionsLabel.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        noSessionsLabel.textColor = C.textDimColor
        noSessionsLabel.alignment = .center
        noSessionsLabel.isHidden = true
        addSubview(noSessionsLabel)
    }

    private func setupToggles() {
        menuBarCheckbox = NSButton(checkboxWithTitle: "Show menu bar icon", target: self, action: #selector(checkboxChanged(_:)))
        menuBarCheckbox.frame = NSRect(x: 20, y: 280, width: 250, height: 24)
        styleCheckbox(menuBarCheckbox)
        addSubview(menuBarCheckbox)

        notifyCheckbox = NSButton(checkboxWithTitle: "Notify when switching sessions", target: self, action: #selector(checkboxChanged(_:)))
        notifyCheckbox.frame = NSRect(x: 20, y: 306, width: 280, height: 24)
        styleCheckbox(notifyCheckbox)
        addSubview(notifyCheckbox)
    }

    private func styleCheckbox(_ checkbox: NSButton) {
        checkbox.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        checkbox.contentTintColor = C.accentColor
        if let title = checkbox.title as NSString? {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .regular),
                .foregroundColor: C.textColor
            ]
            checkbox.attributedTitle = NSAttributedString(string: title as String, attributes: attrs)
        }
    }

    // MARK: - Observers

    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionsDidUpdate(_:)),
            name: .claudeSessionsDidUpdate,
            object: nil
        )
    }

    @objc private func sessionsDidUpdate(_ notification: Notification) {
        if let sessions = notification.userInfo?["sessions"] as? [SessionInfo] {
            self.sessions = sessions
            sessionsTableView.reloadData()
            updateSessionsVisibility()
        }
    }

    // MARK: - Settings

    private func loadSettings() {
        // Load mode
        let mode = ClaudeSessionMonitor.shared.selectionMode
        switch mode {
        case .anyActive:
            anyActiveRadio.state = .on
        case .followFocusedTab:
            followTabRadio.state = .on
        case .specific(let sessionId):
            specificRadio.state = .on
            selectedSpecificSessionId = sessionId
        }

        // Load sessions
        sessions = ClaudeSessionMonitor.shared.activeSessions
        sessionsTableView.reloadData()
        updateSessionsVisibility()

        // Load toggles
        menuBarCheckbox.state = SettingsManager.shared.showMenuBarIcon ? .on : .off
        notifyCheckbox.state = SettingsManager.shared.notifyOnSessionSwitch ? .on : .off

        updateSessionsListEnabled()
    }

    private func updateSessionsVisibility() {
        let hasSessions = !sessions.isEmpty
        sessionsScrollView.isHidden = !hasSessions
        noSessionsLabel.isHidden = hasSessions
    }

    private func updateSessionsListEnabled() {
        let isSpecificMode = specificRadio.state == .on
        sessionsTableView.isEnabled = isSpecificMode
        sessionsLabel.textColor = isSpecificMode ? C.textColor : C.textDimColor
    }

    // MARK: - Actions

    @objc private func modeChanged(_ sender: NSButton) {
        // Ensure only one radio is selected
        anyActiveRadio.state = sender == anyActiveRadio ? .on : .off
        followTabRadio.state = sender == followTabRadio ? .on : .off
        specificRadio.state = sender == specificRadio ? .on : .off

        // Update mode
        switch sender.tag {
        case 0:
            ClaudeSessionMonitor.shared.selectionMode = .anyActive
            SettingsManager.shared.sessionSelectionMode = "anyActive"
        case 1:
            ClaudeSessionMonitor.shared.selectionMode = .followFocusedTab
            SettingsManager.shared.sessionSelectionMode = "followFocusedTab"
        case 2:
            if let sessionId = selectedSpecificSessionId ?? sessions.first?.id {
                ClaudeSessionMonitor.shared.selectionMode = .specific(sessionId)
                SettingsManager.shared.sessionSelectionMode = "specific:\(sessionId)"
            }
        default:
            break
        }

        updateSessionsListEnabled()
        sessionsTableView.reloadData()
    }

    @objc private func sessionRowClicked() {
        let row = sessionsTableView.selectedRow
        guard row >= 0, row < sessions.count else { return }

        let session = sessions[row]
        selectedSpecificSessionId = session.id

        // If not already in specific mode, switch to it
        if specificRadio.state != .on {
            anyActiveRadio.state = .off
            followTabRadio.state = .off
            specificRadio.state = .on
            updateSessionsListEnabled()
        }

        ClaudeSessionMonitor.shared.selectionMode = .specific(session.id)
        SettingsManager.shared.sessionSelectionMode = "specific:\(session.id)"
        sessionsTableView.reloadData()
    }

    @objc private func checkboxChanged(_ sender: NSButton) {
        if sender === menuBarCheckbox {
            SettingsManager.shared.showMenuBarIcon = (sender.state == .on)
            NotificationCenter.default.post(name: .menuBarIconSettingChanged, object: nil)
        } else if sender === notifyCheckbox {
            SettingsManager.shared.notifyOnSessionSwitch = (sender.state == .on)
        }
    }

    // MARK: - Refresh

    func refresh() {
        sessions = ClaudeSessionMonitor.shared.activeSessions
        sessionsTableView.reloadData()
        updateSessionsVisibility()
    }
}

// MARK: - Table View Data Source

extension ClaudeSettingsView: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return sessions.count
    }
}

// MARK: - Table View Delegate

extension ClaudeSettingsView: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let session = sessions[row]
        let cellId = NSUserInterfaceItemIdentifier("SessionCell")

        let cell: SessionRowView
        if let existing = tableView.makeView(withIdentifier: cellId, owner: nil) as? SessionRowView {
            cell = existing
        } else {
            cell = SessionRowView()
            cell.identifier = cellId
        }

        // Check if this is the currently monitored session
        let isMonitored: Bool
        switch ClaudeSessionMonitor.shared.selectionMode {
        case .specific(let id):
            isMonitored = session.id == id
        case .anyActive, .followFocusedTab:
            isMonitored = session.id == ClaudeSessionMonitor.shared.currentSessionId
        }

        cell.configure(with: session, isMonitored: isMonitored)
        return cell
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let rowView = SessionTableRowView()
        return rowView
    }
}

// MARK: - Session Row View

private class SessionRowView: NSView {
    private let indicatorView = NSView()
    private let nameLabel = NSTextField(labelWithString: "")
    private let statusLabel = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        // Indicator dot
        indicatorView.wantsLayer = true
        indicatorView.layer?.cornerRadius = 3
        addSubview(indicatorView)

        // Name label
        nameLabel.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .medium)
        nameLabel.textColor = SettingsConstants.textColor
        nameLabel.lineBreakMode = .byTruncatingTail
        addSubview(nameLabel)

        // Status label
        statusLabel.font = NSFont.monospacedSystemFont(ofSize: 9, weight: .regular)
        statusLabel.alignment = .right
        addSubview(statusLabel)
    }

    override func layout() {
        super.layout()
        indicatorView.frame = NSRect(x: 8, y: (bounds.height - 6) / 2, width: 6, height: 6)
        nameLabel.frame = NSRect(x: 20, y: 4, width: 180, height: 16)
        statusLabel.frame = NSRect(x: 200, y: 4, width: 80, height: 16)
    }

    func configure(with session: SessionInfo, isMonitored: Bool) {
        nameLabel.stringValue = session.displayName

        // Status indicator color and text
        let (color, statusText) = statusDisplay(for: session.status)
        indicatorView.layer?.backgroundColor = isMonitored ? color.cgColor : SettingsConstants.textDimColor.cgColor
        statusLabel.stringValue = statusText
        statusLabel.textColor = color
    }

    private func statusDisplay(for status: String) -> (NSColor, String) {
        switch status {
        case "thinking":
            return (SettingsConstants.accentColor, "thinking...")
        case "planning":
            return (NSColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0), "planning...")
        case "tools":
            return (SettingsConstants.accentColor, "tools...")
        case "waiting":
            return (NSColor.white, "waiting")
        case "idle":
            return (SettingsConstants.textDimColor, "idle")
        default:
            return (SettingsConstants.textDimColor, status)
        }
    }
}

// MARK: - Session Table Row View

private class SessionTableRowView: NSTableRowView {
    override func drawSelection(in dirtyRect: NSRect) {
        if selectionHighlightStyle != .none {
            SettingsConstants.sidebarSelectedColor.setFill()
            let selectionPath = NSBezierPath(roundedRect: bounds.insetBy(dx: 4, dy: 1), xRadius: 3, yRadius: 3)
            selectionPath.fill()
        }
    }

    override func drawBackground(in dirtyRect: NSRect) {
        // Don't draw default background
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let menuBarIconSettingChanged = Notification.Name("menuBarIconSettingChanged")
}
