//
//  SettingsConstants.swift
//  Clawdachi
//
//  Constants for the Settings window - RPG inventory style
//

import Foundation
import AppKit

/// Constants for the Settings window styling and layout
enum SettingsConstants {

    // MARK: - Window Sizing

    /// Total window width
    static let windowWidth: CGFloat = 850

    /// Total window height
    static let windowHeight: CGFloat = 575

    /// Title bar height
    static let titleBarHeight: CGFloat = 28

    /// Bottom bar height for buttons
    static let bottomBarHeight: CGFloat = 44

    /// Content height (between title and bottom bar)
    static let contentHeight: CGFloat = windowHeight - titleBarHeight - bottomBarHeight

    /// Border thickness (pixel art style)
    static let borderSize: CGFloat = 4

    /// Inner padding
    static let panelPadding: CGFloat = 10

    // MARK: - Layout Panels

    /// Sidebar width for navigation
    static let sidebarWidth: CGFloat = 188

    /// Content area width (after sidebar)
    static let contentAreaWidth: CGFloat = windowWidth - sidebarWidth

    // MARK: - Customization Section Layout

    /// Left panel width (preview area) within customization
    static let customizationPreviewWidth: CGFloat = 210

    /// Right panel width (items) within customization
    static let customizationGridWidth: CGFloat = contentAreaWidth - customizationPreviewWidth

    // MARK: - Preview

    /// Preview box size (sprite display area)
    static let previewBoxSize: CGFloat = 200

    /// Preview sprite scale
    static let previewScale: CGFloat = 3.0

    // MARK: - Item Grid

    /// Number of columns in item grid (calculated dynamically)
    static let gridColumns: Int = 5

    /// Number of visible rows
    static let gridVisibleRows: Int = 3

    /// Item cell size (slot)
    static let itemCellSize: CGFloat = 64

    /// Spacing between slots
    static let gridSpacing: CGFloat = 8

    // MARK: - Tab Bar

    /// Category tab height
    static let tabHeight: CGFloat = 32

    /// Tab font size
    static let tabFontSize: CGFloat = 12

    /// Spacing between tabs
    static let tabSpacing: CGFloat = 8

    /// Tab horizontal padding
    static let tabPadding: CGFloat = 10

    // MARK: - Fonts

    /// Title font size
    static let titleFontSize: CGFloat = 12

    /// Section header font size
    static let sectionFontSize: CGFloat = 11

    /// Chat bubble font size
    static let chatFontSize: CGFloat = 10

    /// Equipped list font size
    static let equippedFontSize: CGFloat = 9

    // MARK: - Animation

    /// Window fade in duration
    static let fadeInDuration: TimeInterval = 0.15

    /// Window scale in duration
    static let scaleInDuration: TimeInterval = 0.15

    /// Initial scale for pop-in animation
    static let initialScale: CGFloat = 0.95

    /// Hover transition
    static let hoverDuration: TimeInterval = 0.1

    /// Selection pulse
    static let selectDuration: TimeInterval = 0.15

    /// Button shake duration
    static let shakeDuration: TimeInterval = 0.4

    // MARK: - Colors (Terminal Theme)

    /// Main background - deep black
    static let backgroundColor = NSColor(red: 13/255, green: 13/255, blue: 13/255, alpha: 1.0)  // #0D0D0D

    /// Panel/cell background - slightly lighter
    static let panelColor = NSColor(red: 22/255, green: 24/255, blue: 22/255, alpha: 1.0)  // #161816

    /// Frame/border color - subtle green tint
    static let frameColor = NSColor(red: 58/255, green: 68/255, blue: 58/255, alpha: 1.0)  // #3A443A

    /// Frame highlight (top/left edges)
    static let frameHighlight = NSColor(red: 78/255, green: 88/255, blue: 78/255, alpha: 1.0)  // #4E584E

    /// Frame shadow (bottom/right edges)
    static let frameShadow = NSColor(red: 8/255, green: 10/255, blue: 8/255, alpha: 1.0)  // #080A08

    /// Cell background
    static let cellBackgroundColor = NSColor(red: 28/255, green: 32/255, blue: 28/255, alpha: 1.0)  // #1C201C

    /// Cell hover state
    static let cellHoverColor = NSColor(red: 42/255, green: 48/255, blue: 42/255, alpha: 1.0)  // #2A302A

    /// Sidebar selected item background
    static let sidebarSelectedColor = NSColor(red: 36/255, green: 42/255, blue: 36/255, alpha: 1.0)  // #242A24

    /// Primary text color - terminal green/white
    static let textColor = NSColor(red: 200/255, green: 220/255, blue: 200/255, alpha: 1.0)  // #C8DCC8

    /// Dimmed text color
    static let textDimColor = NSColor(red: 100/255, green: 120/255, blue: 100/255, alpha: 1.0)  // #647864

    /// Accent color (Clawdachi orange)
    static let accentColor = NSColor(red: 255/255, green: 153/255, blue: 51/255, alpha: 1.0)  // #FF9933

    /// Accent glow (softer)
    static let accentGlow = NSColor(red: 255/255, green: 153/255, blue: 51/255, alpha: 0.3)

    /// Tab text color
    static let tabTextColor = NSColor(red: 160/255, green: 180/255, blue: 160/255, alpha: 1.0)  // #A0B4A0

    /// Button hover color
    static let buttonHoverColor = NSColor(red: 42/255, green: 48/255, blue: 42/255, alpha: 1.0)  // #2A302A

    /// Locked item overlay
    static let lockedOverlayColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.7)

    /// Locked item text/icon
    static let lockedColor = NSColor(red: 80/255, green: 96/255, blue: 80/255, alpha: 1.0)  // #506050

    // MARK: - ASCII Box Characters (for frame rendering)

    enum ASCII {
        static let topLeft = "┌"
        static let topRight = "┐"
        static let bottomLeft = "└"
        static let bottomRight = "┘"
        static let horizontal = "─"
        static let vertical = "│"
        static let teeRight = "├"
        static let teeLeft = "┤"
        static let teeDown = "┬"
        static let teeUp = "┴"
        static let cross = "┼"

        /// Character render width
        static let charWidth: CGFloat = 8

        /// Character render height
        static let charHeight: CGFloat = 12
    }

    // MARK: - Settings Sections

    enum Section: String, CaseIterable {
        case customize = "Customize"
        case claude = "Claude Code"
        case general = "General"
        case sound = "Sound"
        case about = "About"
    }

    // MARK: - Messages

    enum Messages {
        static let `default` = "looking good!"
        static let equipped = "equipped!"
        static let removed = "removed"
        static let locked = "unlock plus!"
        static let reset = "back to basics"
        static let themeChanged = "new look!"
        static let outfitEquipped = "nice outfit!"
        static let hatEquipped = "nice hat!"
        static let glassesEquipped = "lookin smart!"
        static let heldEquipped = "handy!"
        static let itemRemoved = "off it goes"
        static let lockedItem = "plus feature!"
    }
}
