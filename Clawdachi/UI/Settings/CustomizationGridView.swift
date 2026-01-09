//
//  CustomizationGridView.swift
//  Clawdachi
//
//  Right panel with category tabs and item selection grid - RPG inventory style
//

import AppKit

// MARK: - Delegate Protocol

protocol CustomizationGridDelegate: AnyObject {
    func itemGrid(_ grid: CustomizationGridView, didSelectItem item: ClosetItem, in category: ClosetCategory)
    func itemGrid(_ grid: CustomizationGridView, didDeselectItem item: ClosetItem, in category: ClosetCategory)
    func itemGrid(_ grid: CustomizationGridView, didTapLockedItem item: ClosetItem, in category: ClosetCategory)
}

// MARK: - Item Grid View

class CustomizationGridView: NSView {

    private typealias C = SettingsConstants

    // MARK: - Properties

    weak var delegate: CustomizationGridDelegate?

    private var tabBar: CustomizationTabBar!
    private var gridScrollView: NSScrollView!
    private var gridView: NSView!
    private var equippedLabel: NSTextField!
    private var itemCells: [CustomizationItemCell] = []

    private var currentCategory: ClosetCategory = .themes

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        wantsLayer = true

        setupTabBar()
        setupGrid()
        setupEquippedSection()

        // Initial load
        loadItems(for: currentCategory)
    }

    // MARK: - Tab Bar

    private func setupTabBar() {
        // Tab bar at bottom (view is flipped)
        let tabFrame = NSRect(
            x: 0,
            y: bounds.height - C.tabHeight,
            width: bounds.width,
            height: C.tabHeight
        )
        tabBar = CustomizationTabBar(frame: tabFrame, categories: ClosetCategory.allCases)
        tabBar.delegate = self
        addSubview(tabBar)
    }

    // MARK: - Grid

    private func setupGrid() {
        // Position grid at top (view is flipped, so y=0 is top)
        let gridY: CGFloat = 4
        let gridHeight = (C.itemCellSize + C.gridSpacing) * CGFloat(C.gridVisibleRows) + C.gridSpacing

        // Scroll view for grid
        gridScrollView = NSScrollView(frame: NSRect(
            x: 4,
            y: gridY,
            width: bounds.width - 8,
            height: gridHeight
        ))
        gridScrollView.hasVerticalScroller = false
        gridScrollView.hasHorizontalScroller = false
        gridScrollView.drawsBackground = false
        gridScrollView.backgroundColor = .clear

        // Content view
        gridView = NSView(frame: NSRect(x: 0, y: 0, width: gridScrollView.bounds.width, height: gridHeight))
        gridScrollView.documentView = gridView

        addSubview(gridScrollView)
    }

    // MARK: - Equipped Section

    private func setupEquippedSection() {
        // Equipped items label at bottom
        equippedLabel = NSTextField(labelWithString: "")
        equippedLabel.frame = NSRect(x: 4, y: 4, width: bounds.width - 8, height: 52)
        equippedLabel.font = NSFont.monospacedSystemFont(ofSize: C.equippedFontSize, weight: .regular)
        equippedLabel.textColor = C.textDimColor
        equippedLabel.backgroundColor = .clear
        equippedLabel.isBezeled = false
        equippedLabel.isEditable = false
        equippedLabel.maximumNumberOfLines = 4
        equippedLabel.lineBreakMode = .byWordWrapping
        addSubview(equippedLabel)

        updateEquippedLabel()
    }

    override var isFlipped: Bool { true }

    // MARK: - Loading Items

    private func loadItems(for category: ClosetCategory) {
        // Clear existing cells
        for cell in itemCells {
            cell.removeFromSuperview()
        }
        itemCells.removeAll()

        // Get items for category
        let items = ClosetManager.shared.items(for: category)

        // Calculate grid layout
        let cellSize = C.itemCellSize
        let spacing = C.gridSpacing
        let columns = C.gridColumns
        let rows = max(C.gridVisibleRows, (items.count + columns - 1) / columns)

        // Resize grid view if needed
        let gridHeight = CGFloat(rows) * (cellSize + spacing) + spacing
        gridView.frame = NSRect(x: 0, y: 0, width: gridScrollView.bounds.width, height: max(gridHeight, gridScrollView.bounds.height))

        // Create cells
        for (index, item) in items.enumerated() {
            let col = index % columns
            let row = index / columns

            let x = spacing + CGFloat(col) * (cellSize + spacing)
            let y = spacing + CGFloat(row) * (cellSize + spacing)

            let cellFrame = NSRect(x: x, y: y, width: cellSize, height: cellSize)
            let cell = CustomizationItemCell(frame: cellFrame, item: item)
            cell.delegate = self
            cell.isSelected = ClosetManager.shared.isEquipped(item)
            cell.isLocked = item.isPremium && !ClosetManager.shared.isPremiumUnlocked

            itemCells.append(cell)
            gridView.addSubview(cell)
        }
    }

    // MARK: - Refresh

    func refresh() {
        loadItems(for: currentCategory)
        updateEquippedLabel()
    }

    private func updateEquippedLabel() {
        let manager = ClosetManager.shared

        var lines: [String] = []

        if let hat = manager.equippedHat {
            lines.append("Hat: \(hat.name)")
        }

        if let glasses = manager.equippedGlasses {
            lines.append("Glasses: \(glasses.name)")
        }

        if let held = manager.equippedHeld {
            lines.append("Held: \(held.name)")
        }

        equippedLabel.stringValue = lines.joined(separator: "\n")
    }
}

// MARK: - Tab Bar Delegate

extension CustomizationGridView: CustomizationTabBarDelegate {
    func tabBar(_ tabBar: CustomizationTabBar, didSelectCategory category: ClosetCategory) {
        currentCategory = category
        loadItems(for: category)
    }
}

// MARK: - Item Cell Delegate

extension CustomizationGridView: CustomizationItemCellDelegate {
    func cellWasTapped(_ cell: CustomizationItemCell) {
        let item = cell.item

        if cell.isLocked {
            delegate?.itemGrid(self, didTapLockedItem: item, in: item.category)
            cell.shake()
            return
        }

        if cell.isSelected {
            // Deselect (unequip) - but themes can't be unequipped
            if item.category != .themes {
                cell.isSelected = false
                delegate?.itemGrid(self, didDeselectItem: item, in: item.category)
            }
        } else {
            // Deselect other cells in same category
            for otherCell in itemCells where otherCell !== cell {
                otherCell.isSelected = false
            }
            // Select this one
            cell.isSelected = true
            delegate?.itemGrid(self, didSelectItem: item, in: item.category)
        }

        updateEquippedLabel()
    }
}

// MARK: - Tab Bar

protocol CustomizationTabBarDelegate: AnyObject {
    func tabBar(_ tabBar: CustomizationTabBar, didSelectCategory category: ClosetCategory)
}

class CustomizationTabBar: NSView {

    private typealias C = SettingsConstants

    weak var delegate: CustomizationTabBarDelegate?

    private var categories: [ClosetCategory]
    private var selectedIndex: Int = 0
    private var tabButtons: [CustomizationTabButton] = []

    init(frame: NSRect, categories: [ClosetCategory]) {
        self.categories = categories
        super.init(frame: frame)
        setupTabs()
    }

    required init?(coder: NSCoder) {
        self.categories = ClosetCategory.allCases
        super.init(coder: coder)
        setupTabs()
    }

    private func setupTabs() {
        let tabWidth = bounds.width / CGFloat(categories.count)

        for (index, category) in categories.enumerated() {
            let tabFrame = NSRect(
                x: CGFloat(index) * tabWidth,
                y: 0,
                width: tabWidth,
                height: bounds.height
            )
            let tab = CustomizationTabButton(frame: tabFrame, title: category.shortName, index: index)
            tab.isSelected = (index == selectedIndex)
            tab.target = self
            tab.action = #selector(tabTapped(_:))
            tabButtons.append(tab)
            addSubview(tab)
        }
    }

    @objc private func tabTapped(_ sender: CustomizationTabButton) {
        guard sender.index != selectedIndex else { return }

        tabButtons[selectedIndex].isSelected = false
        selectedIndex = sender.index
        tabButtons[selectedIndex].isSelected = true

        delegate?.tabBar(self, didSelectCategory: categories[selectedIndex])
    }
}

class CustomizationTabButton: NSView {

    private typealias C = SettingsConstants

    let title: String
    let index: Int
    var isSelected: Bool = false {
        didSet { needsDisplay = true }
    }

    weak var target: AnyObject?
    var action: Selector?

    private var isHovered = false
    private var trackingArea: NSTrackingArea?

    init(frame: NSRect, title: String, index: Int) {
        self.title = title
        self.index = index
        super.init(frame: frame)
        setupTracking()
    }

    required init?(coder: NSCoder) {
        self.title = ""
        self.index = 0
        super.init(coder: coder)
        setupTracking()
    }

    private func setupTracking() {
        let options: NSTrackingArea.Options = [.activeAlways, .mouseEnteredAndExited]
        trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea!)
    }

    override func draw(_ dirtyRect: NSRect) {
        let bgColor = isSelected ? C.accentColor : (isHovered ? C.buttonHoverColor : C.panelColor)
        let textColor = isSelected ? C.backgroundColor : C.tabTextColor

        // Background
        let bgPath = NSBezierPath(roundedRect: bounds.insetBy(dx: 2, dy: 2), xRadius: 4, yRadius: 4)
        bgColor.setFill()
        bgPath.fill()

        // Text
        let font = NSFont.monospacedSystemFont(ofSize: C.tabFontSize, weight: isSelected ? .bold : .medium)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        let str = NSAttributedString(string: title, attributes: attrs)
        let size = str.size()
        let point = NSPoint(
            x: (bounds.width - size.width) / 2,
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

// MARK: - Item Cell

protocol CustomizationItemCellDelegate: AnyObject {
    func cellWasTapped(_ cell: CustomizationItemCell)
}

class CustomizationItemCell: NSView {

    private typealias C = SettingsConstants

    let item: ClosetItem
    weak var delegate: CustomizationItemCellDelegate?

    var isSelected: Bool = false {
        didSet { needsDisplay = true }
    }
    var isLocked: Bool = false {
        didSet { needsDisplay = true }
    }

    private var isHovered = false
    private var trackingArea: NSTrackingArea?

    init(frame: NSRect, item: ClosetItem) {
        self.item = item
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
        // Background slot
        let bgColor = isHovered ? C.cellHoverColor : C.cellBackgroundColor
        let bgPath = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 4, yRadius: 4)
        bgColor.setFill()
        bgPath.fill()

        // Selection glow
        if isSelected {
            C.accentColor.setStroke()
            let strokePath = NSBezierPath(roundedRect: bounds.insetBy(dx: 2, dy: 2), xRadius: 3, yRadius: 3)
            strokePath.lineWidth = 2
            strokePath.stroke()
        }

        // Item icon
        let iconRect = bounds.insetBy(dx: 6, dy: 6)
        drawItemIcon(in: iconRect)

        // Locked overlay
        if isLocked {
            C.lockedOverlayColor.setFill()
            bgPath.fill()

            // Lock icon
            let lockFont = NSFont.systemFont(ofSize: 14)
            let lockAttrs: [NSAttributedString.Key: Any] = [
                .font: lockFont,
                .foregroundColor: C.textDimColor
            ]
            let lockStr = NSAttributedString(string: "🔒", attributes: lockAttrs)
            let lockSize = lockStr.size()
            let lockPoint = NSPoint(
                x: (bounds.width - lockSize.width) / 2,
                y: (bounds.height - lockSize.height) / 2
            )
            lockStr.draw(at: lockPoint)
        }
    }

    private func drawItemIcon(in rect: NSRect) {
        if item.category == .themes {
            // Get theme colors and show a color swatch
            if let theme = ClosetManager.shared.availableThemes.first(where: { $0.id == item.id }) {
                let nsColor = NSColor(
                    red: CGFloat(theme.colors.primary.r) / 255,
                    green: CGFloat(theme.colors.primary.g) / 255,
                    blue: CGFloat(theme.colors.primary.b) / 255,
                    alpha: 1.0
                )
                nsColor.setFill()
                let colorRect = rect.insetBy(dx: 2, dy: 2)
                let path = NSBezierPath(roundedRect: colorRect, xRadius: 4, yRadius: 4)
                path.fill()
            }
        } else {
            // Draw first letter of item name as placeholder
            let font = NSFont.monospacedSystemFont(ofSize: 16, weight: .bold)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: isLocked ? C.lockedColor : C.textColor
            ]
            let letter = String(item.name.prefix(1))
            let str = NSAttributedString(string: letter, attributes: attrs)
            let size = str.size()
            let point = NSPoint(
                x: rect.midX - size.width / 2,
                y: rect.midY - size.height / 2
            )
            str.draw(at: point)
        }
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
            delegate?.cellWasTapped(self)
        }
    }

    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = C.shakeDuration
        animation.values = [-4, 4, -3, 3, -2, 2, 0]
        layer?.add(animation, forKey: "shake")
    }
}

// MARK: - ClosetCategory Extension

extension ClosetCategory {
    /// Display name for tab labels
    var shortName: String {
        switch self {
        case .themes: return "Color"
        case .hats: return "Hats"
        case .glasses: return "Glasses"
        case .held: return "Held"
        }
    }
}
