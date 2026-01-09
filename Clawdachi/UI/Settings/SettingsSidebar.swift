//
//  SettingsSidebar.swift
//  Clawdachi
//
//  Sidebar navigation for Settings window
//

import AppKit

// MARK: - Delegate Protocol

protocol SettingsSidebarDelegate: AnyObject {
    func sidebar(_ sidebar: SettingsSidebar, didSelectSection section: SettingsConstants.Section)
}

// MARK: - Sidebar View

class SettingsSidebar: NSView {

    private typealias C = SettingsConstants

    weak var delegate: SettingsSidebarDelegate?

    private var sidebarItems: [SidebarItem] = []
    private var selectedIndex: Int = 0

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupItems()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupItems()
    }

    private func setupItems() {
        let itemHeight: CGFloat = 36
        let padding: CGFloat = 8

        for (index, section) in C.Section.allCases.enumerated() {
            let itemFrame = NSRect(
                x: padding,
                y: padding + CGFloat(index) * (itemHeight + 4),
                width: bounds.width - padding * 2,
                height: itemHeight
            )

            let item = SidebarItem(frame: itemFrame, section: section, index: index)
            item.isSelected = (index == selectedIndex)
            item.target = self
            item.action = #selector(itemTapped(_:))
            sidebarItems.append(item)
            addSubview(item)
        }
    }

    override var isFlipped: Bool { true }

    @objc private func itemTapped(_ sender: SidebarItem) {
        guard sender.index != selectedIndex else { return }

        sidebarItems[selectedIndex].isSelected = false
        selectedIndex = sender.index
        sidebarItems[selectedIndex].isSelected = true

        delegate?.sidebar(self, didSelectSection: C.Section.allCases[selectedIndex])
    }
}

// MARK: - Sidebar Item

class SidebarItem: NSView {

    private typealias C = SettingsConstants

    let section: SettingsConstants.Section
    let index: Int

    var isSelected: Bool = false {
        didSet { needsDisplay = true }
    }

    weak var target: AnyObject?
    var action: Selector?

    private var isHovered = false
    private var trackingArea: NSTrackingArea?

    init(frame: NSRect, section: SettingsConstants.Section, index: Int) {
        self.section = section
        self.index = index
        super.init(frame: frame)
        setupTracking()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    private func setupTracking() {
        let options: NSTrackingArea.Options = [.activeAlways, .mouseEnteredAndExited]
        trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea!)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let options: NSTrackingArea.Options = [.activeAlways, .mouseEnteredAndExited]
        trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea!)
    }

    override func draw(_ dirtyRect: NSRect) {
        // Background
        if isSelected {
            C.sidebarSelectedColor.setFill()
            let bgPath = NSBezierPath(roundedRect: bounds.insetBy(dx: 2, dy: 2), xRadius: 4, yRadius: 4)
            bgPath.fill()

            // Selection indicator
            C.accentColor.setFill()
            let indicatorRect = NSRect(x: 0, y: 4, width: 3, height: bounds.height - 8)
            NSBezierPath(roundedRect: indicatorRect, xRadius: 1.5, yRadius: 1.5).fill()
        } else if isHovered {
            C.cellHoverColor.setFill()
            let bgPath = NSBezierPath(roundedRect: bounds.insetBy(dx: 2, dy: 2), xRadius: 4, yRadius: 4)
            bgPath.fill()
        }

        // Text
        let font = NSFont.monospacedSystemFont(ofSize: C.sectionFontSize, weight: isSelected ? .semibold : .regular)
        let textColor = isSelected ? C.accentColor : C.textColor
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        let str = NSAttributedString(string: section.rawValue, attributes: attrs)
        let size = str.size()
        let point = NSPoint(
            x: 12,
            y: (bounds.height - size.height) / 2
        )
        str.draw(at: point)
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        if bounds.contains(location) {
            if let target = target, let action = action {
                NSApp.sendAction(action, to: target, from: self)
            }
        }
    }
}
