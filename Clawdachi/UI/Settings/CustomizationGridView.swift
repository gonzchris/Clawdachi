//
//  CustomizationGridView.swift
//  Clawdachi
//
//  Item selection grid - RPG inventory style
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

    private var gridScrollView: NSScrollView!
    private var gridView: NSView!
    private var itemCells: [CustomizationItemCell] = []
    private var itemNameLabel: NSTextField!
    private var selectedItemName: String = ""

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

        setupGrid()
        setupItemNameLabel()

        // Initial load
        loadItems(for: currentCategory)
    }

    // MARK: - Grid

    private func setupGrid() {
        // Constrain grid width for better centering
        let maxGridWidth: CGFloat = 400
        let gridWidth = min(bounds.width, maxGridWidth)
        let gridX = (bounds.width - gridWidth) / 2

        // Scroll view for grid - centered horizontally
        gridScrollView = NSScrollView(frame: NSRect(
            x: gridX,
            y: 0,
            width: gridWidth,
            height: bounds.height
        ))
        gridScrollView.hasVerticalScroller = true
        gridScrollView.hasHorizontalScroller = false
        gridScrollView.drawsBackground = false
        gridScrollView.backgroundColor = .clear
        gridScrollView.scrollerStyle = .overlay
        gridScrollView.autohidesScrollers = true

        // Content view
        gridView = NSView(frame: NSRect(x: 0, y: 0, width: gridScrollView.bounds.width, height: bounds.height))
        gridScrollView.documentView = gridView

        addSubview(gridScrollView)
    }

    // MARK: - Item Name Label

    private func setupItemNameLabel() {
        // Item name label - will be positioned in loadItems below the grid content
        itemNameLabel = NSTextField(labelWithString: "")
        itemNameLabel.frame = NSRect(x: 0, y: 0, width: gridScrollView.bounds.width, height: 20)
        itemNameLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .medium)
        itemNameLabel.textColor = C.textColor
        itemNameLabel.backgroundColor = .clear
        itemNameLabel.isBezeled = false
        itemNameLabel.isEditable = false
        itemNameLabel.alignment = .center
        gridView.addSubview(itemNameLabel)
    }

    func updateItemName(_ name: String) {
        selectedItemName = name
        itemNameLabel.stringValue = name
    }

    override var isFlipped: Bool { true }

    // MARK: - Public API

    func loadCategory(_ category: ClosetCategory) {
        currentCategory = category
        loadItems(for: category)
    }

    // MARK: - Loading Items

    private func loadItems(for category: ClosetCategory) {
        // Clear existing cells
        for cell in itemCells {
            cell.removeFromSuperview()
        }
        itemCells.removeAll()

        // Get items for category
        let items = ClosetManager.shared.items(for: category)

        // Calculate grid layout dynamically
        let spacing = C.gridSpacing
        let availableWidth = gridScrollView.bounds.width - spacing

        // For color/themes, force 8 columns with smaller cells
        let columns: Int
        let cellSize: CGFloat
        if category == .themes {
            columns = 8
            cellSize = (availableWidth - spacing * CGFloat(8)) / CGFloat(8)
        } else {
            cellSize = C.itemCellSize
            let maxColumns = 8
            columns = min(maxColumns, max(1, Int(availableWidth / (cellSize + spacing))))
        }
        let rows = max(1, (items.count + columns - 1) / columns)

        // Calculate total grid dimensions and center offsets
        let totalGridWidth = CGFloat(columns) * (cellSize + spacing)
        let leftOffset = (gridScrollView.bounds.width - totalGridWidth) / 2 + spacing / 2

        let labelHeight: CGFloat = 24
        let itemsHeight = CGFloat(rows) * (cellSize + spacing) + spacing
        let contentHeight = itemsHeight + labelHeight
        let viewHeight = max(contentHeight, gridScrollView.bounds.height)

        // Calculate vertical center offset (center the items + label together)
        let topOffset = max(0, (gridScrollView.bounds.height - contentHeight) / 2)

        // Resize grid view if needed
        gridView.frame = NSRect(x: 0, y: 0, width: gridScrollView.bounds.width, height: viewHeight)

        // Position item name label below the items
        let labelY = topOffset + itemsHeight
        itemNameLabel.frame = NSRect(x: 0, y: labelY, width: gridScrollView.bounds.width, height: labelHeight)

        // Create cells
        for (index, item) in items.enumerated() {
            let col = index % columns
            let row = index / columns

            let x = leftOffset + CGFloat(col) * (cellSize + spacing)
            let y = topOffset + spacing + CGFloat(row) * (cellSize + spacing)

            let cellFrame = NSRect(x: x, y: y, width: cellSize, height: cellSize)
            let cell = CustomizationItemCell(frame: cellFrame, item: item)
            cell.delegate = self
            cell.hoverDelegate = self
            cell.isSelected = ClosetManager.shared.isEquipped(item)
            cell.isLocked = item.isPremium && !ClosetManager.shared.isPremiumUnlocked

            itemCells.append(cell)
            gridView.addSubview(cell)
        }

        // Update item name to show selected item
        updateSelectedItemName()
    }

    private func updateSelectedItemName() {
        if let selectedCell = itemCells.first(where: { $0.isSelected }) {
            updateItemName(selectedCell.item.name)
        } else {
            updateItemName("")
        }
    }

    // MARK: - Refresh

    func refresh() {
        loadItems(for: currentCategory)
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

        updateSelectedItemName()
    }
}

// MARK: - Item Cell Hover Delegate

extension CustomizationGridView: CustomizationItemCellHoverDelegate {
    func cellDidHover(_ cell: CustomizationItemCell) {
        updateItemName(cell.item.name)
    }

    func cellDidUnhover(_ cell: CustomizationItemCell) {
        updateSelectedItemName()
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
        let spacing = C.tabSpacing
        let totalSpacing = spacing * CGFloat(categories.count + 1)
        let tabWidth = (bounds.width - totalSpacing) / CGFloat(categories.count)

        for (index, category) in categories.enumerated() {
            let tabFrame = NSRect(
                x: spacing + CGFloat(index) * (tabWidth + spacing),
                y: 2,
                width: tabWidth,
                height: bounds.height - 4
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

protocol CustomizationItemCellHoverDelegate: AnyObject {
    func cellDidHover(_ cell: CustomizationItemCell)
    func cellDidUnhover(_ cell: CustomizationItemCell)
}

class CustomizationItemCell: NSView {

    private typealias C = SettingsConstants

    let item: ClosetItem
    weak var delegate: CustomizationItemCellDelegate?
    weak var hoverDelegate: CustomizationItemCellHoverDelegate?

    var isSelected: Bool = false {
        didSet {
            needsDisplay = true
            if isSelected {
                startPulseAnimation()
            } else {
                stopPulseAnimation()
            }
        }
    }
    var isLocked: Bool = false {
        didSet { needsDisplay = true }
    }

    private var isHovered = false
    private var trackingArea: NSTrackingArea?
    private var glowLayer: CALayer?

    init(frame: NSRect, item: ClosetItem) {
        self.item = item
        super.init(frame: frame)
        wantsLayer = true
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
            // Get theme colors and show a color swatch with eyes
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

                // Draw two black eyes
                NSColor.black.setFill()
                let eyeSize: CGFloat = 4
                let eyeY = colorRect.midY + 1
                let eyeSpacing: CGFloat = 6

                // Left eye
                let leftEyeRect = NSRect(
                    x: colorRect.midX - eyeSpacing - eyeSize / 2,
                    y: eyeY - eyeSize / 2,
                    width: eyeSize,
                    height: eyeSize
                )
                NSBezierPath(ovalIn: leftEyeRect).fill()

                // Right eye
                let rightEyeRect = NSRect(
                    x: colorRect.midX + eyeSpacing - eyeSize / 2,
                    y: eyeY - eyeSize / 2,
                    width: eyeSize,
                    height: eyeSize
                )
                NSBezierPath(ovalIn: rightEyeRect).fill()
            }
        } else if item.category == .outfits {
            // Draw sprite preview with outfit - fill the entire cell
            if let previewImage = ClawdachiOutfitSprites.generatePreviewImage(for: item.id, size: rect.width) {
                previewImage.draw(in: rect,
                                  from: .zero,
                                  operation: .sourceOver,
                                  fraction: isLocked ? 0.5 : 1.0)
            } else {
                // Fallback to letter for outfits without preview
                drawLetterPlaceholder(in: rect)
            }
        } else if item.category == .hats {
            // Draw sprite preview with hat - fill the entire cell
            if let previewImage = ClawdachiOutfitSprites.generateHatPreviewImage(for: item.id, size: rect.width) {
                previewImage.draw(in: rect,
                                  from: .zero,
                                  operation: .sourceOver,
                                  fraction: isLocked ? 0.5 : 1.0)
            } else {
                // Fallback to letter for hats without preview
                drawLetterPlaceholder(in: rect)
            }
        } else if item.category == .glasses {
            // Draw sprite preview with glasses - fill the entire cell
            if let previewImage = ClawdachiOutfitSprites.generateGlassesPreviewImage(for: item.id, size: rect.width) {
                previewImage.draw(in: rect,
                                  from: .zero,
                                  operation: .sourceOver,
                                  fraction: isLocked ? 0.5 : 1.0)
            } else {
                // Fallback to letter for glasses without preview
                drawLetterPlaceholder(in: rect)
            }
        } else if item.category == .held {
            // Draw sprite preview with held item - fill the entire cell
            if let previewImage = ClawdachiOutfitSprites.generateHeldItemPreviewImage(for: item.id, size: rect.width) {
                previewImage.draw(in: rect,
                                  from: .zero,
                                  operation: .sourceOver,
                                  fraction: isLocked ? 0.5 : 1.0)
            } else {
                // Fallback to letter for held items without preview
                drawLetterPlaceholder(in: rect)
            }
        } else {
            // Draw first letter of item name as placeholder
            drawLetterPlaceholder(in: rect)
        }
    }

    private func drawLetterPlaceholder(in rect: NSRect) {
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

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        needsDisplay = true
        hoverDelegate?.cellDidHover(self)
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        needsDisplay = true
        hoverDelegate?.cellDidUnhover(self)
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

    // MARK: - Pulse Animation

    private func startPulseAnimation() {
        guard glowLayer == nil else { return }

        // Create glow layer
        let glow = CALayer()
        glow.frame = bounds.insetBy(dx: 1, dy: 1)
        glow.cornerRadius = 4
        glow.borderWidth = 2
        glow.borderColor = C.accentColor.cgColor
        glow.shadowColor = C.accentColor.cgColor
        glow.shadowRadius = 6
        glow.shadowOpacity = 0.8
        glow.shadowOffset = .zero
        layer?.addSublayer(glow)
        glowLayer = glow

        // Pulse animation on shadow opacity
        let pulseOpacity = CABasicAnimation(keyPath: "shadowOpacity")
        pulseOpacity.fromValue = 0.3
        pulseOpacity.toValue = 0.9
        pulseOpacity.duration = 0.8
        pulseOpacity.autoreverses = true
        pulseOpacity.repeatCount = .infinity
        pulseOpacity.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        glow.add(pulseOpacity, forKey: "pulseOpacity")

        // Subtle pulse on shadow radius
        let pulseRadius = CABasicAnimation(keyPath: "shadowRadius")
        pulseRadius.fromValue = 4
        pulseRadius.toValue = 8
        pulseRadius.duration = 0.8
        pulseRadius.autoreverses = true
        pulseRadius.repeatCount = .infinity
        pulseRadius.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        glow.add(pulseRadius, forKey: "pulseRadius")
    }

    private func stopPulseAnimation() {
        glowLayer?.removeAllAnimations()
        glowLayer?.removeFromSuperlayer()
        glowLayer = nil
    }
}

// MARK: - ClosetCategory Extension

extension ClosetCategory {
    /// Display name for tab labels
    var shortName: String {
        switch self {
        case .themes: return "Color"
        case .outfits: return "Outfits"
        case .hats: return "Hats"
        case .glasses: return "Glasses"
        case .held: return "Held"
        }
    }
}
