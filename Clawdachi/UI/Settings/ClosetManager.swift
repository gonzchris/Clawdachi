//
//  ClosetManager.swift
//  Clawdachi
//
//  Manages equipped items, themes, and closet persistence
//

import Foundation
import AppKit

// MARK: - Data Models

/// Categories of closet items
enum ClosetCategory: String, CaseIterable {
    case themes
    case outfits
    case hats
    case glasses
    case held

    var displayName: String {
        switch self {
        case .themes: return "COLOR"
        case .outfits: return "OUTFITS"
        case .hats: return "HATS"
        case .glasses: return "GLASSES"
        case .held: return "HELD"
        }
    }
}

/// A single closet item
struct ClosetItem: Identifiable, Equatable {
    let id: String
    let name: String
    let category: ClosetCategory
    let isPremium: Bool

    static func == (lhs: ClosetItem, rhs: ClosetItem) -> Bool {
        lhs.id == rhs.id
    }
}

/// Color theme definition
struct ClosetTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let colors: ThemeColors
    let isPremium: Bool

    struct ThemeColors {
        let primary: PixelColor
        let shadow: PixelColor
        let highlight: PixelColor
    }

    static func == (lhs: ClosetTheme, rhs: ClosetTheme) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Closet Manager

/// Singleton manager for closet state and persistence
class ClosetManager {

    static let shared = ClosetManager()

    // MARK: - Equipped State

    private(set) var currentTheme: ClosetTheme
    private(set) var equippedOutfit: ClosetItem?
    private(set) var equippedHat: ClosetItem?
    private(set) var equippedGlasses: ClosetItem?
    private(set) var equippedHeld: ClosetItem?

    // MARK: - Available Items

    let availableThemes: [ClosetTheme]
    let availableOutfits: [ClosetItem]
    let availableHats: [ClosetItem]
    let availableGlasses: [ClosetItem]
    let availableHeld: [ClosetItem]

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let theme = "clawdachi.closet.theme"
        static let outfit = "clawdachi.closet.outfit"
        static let hat = "clawdachi.closet.hat"
        static let glasses = "clawdachi.closet.glasses"
        static let held = "clawdachi.closet.held"
    }

    // MARK: - Initialization

    private init() {
        // Define available themes
        availableThemes = [
            ClosetTheme(
                id: "orange",
                name: "Classic Orange",
                colors: ClosetTheme.ThemeColors(
                    primary: PixelColor(r: 255, g: 153, b: 51),    // #FF9933
                    shadow: PixelColor(r: 204, g: 102, b: 0),      // #CC6600
                    highlight: PixelColor(r: 255, g: 187, b: 119)  // #FFBB77
                ),
                isPremium: false
            ),
            ClosetTheme(
                id: "purple",
                name: "Berry Purple",
                colors: ClosetTheme.ThemeColors(
                    primary: PixelColor(r: 179, g: 102, b: 255),   // #B366FF
                    shadow: PixelColor(r: 128, g: 51, b: 204),     // #8033CC
                    highlight: PixelColor(r: 209, g: 153, b: 255)  // #D199FF
                ),
                isPremium: true
            ),
            ClosetTheme(
                id: "blue",
                name: "Ocean Blue",
                colors: ClosetTheme.ThemeColors(
                    primary: PixelColor(r: 51, g: 179, b: 255),    // #33B3FF
                    shadow: PixelColor(r: 0, g: 128, b: 204),      // #0080CC
                    highlight: PixelColor(r: 119, g: 209, b: 255)  // #77D1FF
                ),
                isPremium: true
            ),
            ClosetTheme(
                id: "green",
                name: "Forest Green",
                colors: ClosetTheme.ThemeColors(
                    primary: PixelColor(r: 102, g: 204, b: 102),   // #66CC66
                    shadow: PixelColor(r: 51, g: 153, b: 51),      // #339933
                    highlight: PixelColor(r: 153, g: 230, b: 153)  // #99E699
                ),
                isPremium: true
            ),
            ClosetTheme(
                id: "pink",
                name: "Sunset Pink",
                colors: ClosetTheme.ThemeColors(
                    primary: PixelColor(r: 255, g: 102, b: 153),   // #FF6699
                    shadow: PixelColor(r: 204, g: 51, b: 102),     // #CC3366
                    highlight: PixelColor(r: 255, g: 153, b: 187)  // #FF99BB
                ),
                isPremium: true
            ),
            ClosetTheme(
                id: "midnight",
                name: "Midnight",
                colors: ClosetTheme.ThemeColors(
                    primary: PixelColor(r: 64, g: 64, b: 96),      // #404060
                    shadow: PixelColor(r: 32, g: 32, b: 64),       // #202040
                    highlight: PixelColor(r: 96, g: 96, b: 128)    // #606080
                ),
                isPremium: true
            ),
            ClosetTheme(
                id: "lavender",
                name: "Lavender",
                colors: ClosetTheme.ThemeColors(
                    primary: PixelColor(r: 200, g: 162, b: 200),   // #C8A2C8
                    shadow: PixelColor(r: 150, g: 112, b: 150),    // #967096
                    highlight: PixelColor(r: 230, g: 200, b: 230)  // #E6C8E6
                ),
                isPremium: true
            ),
            ClosetTheme(
                id: "mono",
                name: "Monochrome",
                colors: ClosetTheme.ThemeColors(
                    primary: PixelColor(r: 136, g: 136, b: 136),   // #888888
                    shadow: PixelColor(r: 85, g: 85, b: 85),       // #555555
                    highlight: PixelColor(r: 187, g: 187, b: 187)  // #BBBBBB
                ),
                isPremium: true
            ),
            ClosetTheme(
                id: "cherry",
                name: "Cherry Red",
                colors: ClosetTheme.ThemeColors(
                    primary: PixelColor(r: 220, g: 53, b: 69),     // #DC3545
                    shadow: PixelColor(r: 165, g: 29, b: 42),      // #A51D2A
                    highlight: PixelColor(r: 255, g: 102, b: 117)  // #FF6675
                ),
                isPremium: true
            ),
            ClosetTheme(
                id: "lemon",
                name: "Lemon Yellow",
                colors: ClosetTheme.ThemeColors(
                    primary: PixelColor(r: 255, g: 220, b: 77),    // #FFDC4D
                    shadow: PixelColor(r: 204, g: 170, b: 26),     // #CCAA1A
                    highlight: PixelColor(r: 255, g: 238, b: 153)  // #FFEE99
                ),
                isPremium: true
            ),
            ClosetTheme(
                id: "teal",
                name: "Teal",
                colors: ClosetTheme.ThemeColors(
                    primary: PixelColor(r: 32, g: 178, b: 170),    // #20B2AA
                    shadow: PixelColor(r: 0, g: 128, b: 128),      // #008080
                    highlight: PixelColor(r: 102, g: 210, b: 204)  // #66D2CC
                ),
                isPremium: true
            ),
            ClosetTheme(
                id: "coral",
                name: "Coral",
                colors: ClosetTheme.ThemeColors(
                    primary: PixelColor(r: 255, g: 127, b: 80),    // #FF7F50
                    shadow: PixelColor(r: 205, g: 92, b: 52),      // #CD5C34
                    highlight: PixelColor(r: 255, g: 170, b: 136)  // #FFAA88
                ),
                isPremium: true
            ),
            ClosetTheme(
                id: "mint",
                name: "Mint",
                colors: ClosetTheme.ThemeColors(
                    primary: PixelColor(r: 152, g: 224, b: 190),   // #98E0BE
                    shadow: PixelColor(r: 102, g: 179, b: 145),    // #66B391
                    highlight: PixelColor(r: 192, g: 245, b: 220)  // #C0F5DC
                ),
                isPremium: true
            ),
            ClosetTheme(
                id: "peach",
                name: "Peach",
                colors: ClosetTheme.ThemeColors(
                    primary: PixelColor(r: 255, g: 185, b: 155),   // #FFB99B
                    shadow: PixelColor(r: 220, g: 140, b: 110),    // #DC8C6E
                    highlight: PixelColor(r: 255, g: 218, b: 200)  // #FFDAC8
                ),
                isPremium: true
            ),
            ClosetTheme(
                id: "sky",
                name: "Sky Blue",
                colors: ClosetTheme.ThemeColors(
                    primary: PixelColor(r: 135, g: 206, b: 250),   // #87CEFA
                    shadow: PixelColor(r: 85, g: 156, b: 200),     // #559CC8
                    highlight: PixelColor(r: 185, g: 230, b: 255)  // #B9E6FF
                ),
                isPremium: true
            ),
            ClosetTheme(
                id: "gold",
                name: "Gold",
                colors: ClosetTheme.ThemeColors(
                    primary: PixelColor(r: 255, g: 193, b: 37),    // #FFC125
                    shadow: PixelColor(r: 204, g: 145, b: 0),      // #CC9100
                    highlight: PixelColor(r: 255, g: 223, b: 128)  // #FFDF80
                ),
                isPremium: true
            )
        ]

        // Define available outfits
        availableOutfits = [
            ClosetItem(id: "bikini", name: "Bikini Mode", category: .outfits, isPremium: false),
            ClosetItem(id: "hoodie", name: "Hoodie", category: .outfits, isPremium: true),
            ClosetItem(id: "tuxedo", name: "Tuxedo", category: .outfits, isPremium: true),
            ClosetItem(id: "superhero", name: "Superhero Cape", category: .outfits, isPremium: true),
            ClosetItem(id: "wizard", name: "Wizard Robe", category: .outfits, isPremium: true),
            ClosetItem(id: "astronaut", name: "Astronaut Suit", category: .outfits, isPremium: false),
            ClosetItem(id: "pirate", name: "Pirate Outfit", category: .outfits, isPremium: true),
        ]

        // Define available hats
        availableHats = [
            ClosetItem(id: "tophat", name: "Top Hat", category: .hats, isPremium: true),
            ClosetItem(id: "beanie", name: "Beanie", category: .hats, isPremium: true),
            ClosetItem(id: "cowboy", name: "Cowboy Hat", category: .hats, isPremium: false),
            ClosetItem(id: "crown", name: "Crown", category: .hats, isPremium: true),
            ClosetItem(id: "propeller", name: "Propeller Cap", category: .hats, isPremium: true),
            ClosetItem(id: "headphones", name: "Headphones", category: .hats, isPremium: false),
        ]

        // Define available glasses
        availableGlasses = [
            ClosetItem(id: "sunglasses", name: "Sunglasses", category: .glasses, isPremium: false),
            ClosetItem(id: "nerd", name: "Nerd Glasses", category: .glasses, isPremium: false),
            ClosetItem(id: "3d", name: "3D Glasses", category: .glasses, isPremium: true),
        ]

        // Define available held items
        availableHeld = [
            ClosetItem(id: "coffee", name: "Coffee Mug", category: .held, isPremium: true),
            ClosetItem(id: "cigarette", name: "Cigarette", category: .held, isPremium: false),
            ClosetItem(id: "laptop", name: "Tiny Laptop", category: .held, isPremium: true),
        ]

        // Set default theme
        currentTheme = availableThemes[0]

        // Load saved state
        loadState()
    }

    // MARK: - Persistence

    private func loadState() {
        let defaults = UserDefaults.standard

        // Load theme
        if let themeId = defaults.string(forKey: Keys.theme),
           let theme = availableThemes.first(where: { $0.id == themeId }) {
            currentTheme = theme
        }

        // Load outfit
        if let outfitId = defaults.string(forKey: Keys.outfit) {
            equippedOutfit = availableOutfits.first(where: { $0.id == outfitId })
        }

        // Load hat
        if let hatId = defaults.string(forKey: Keys.hat) {
            equippedHat = availableHats.first(where: { $0.id == hatId })
        }

        // Load glasses
        if let glassesId = defaults.string(forKey: Keys.glasses) {
            equippedGlasses = availableGlasses.first(where: { $0.id == glassesId })
        }

        // Load held
        if let heldId = defaults.string(forKey: Keys.held) {
            equippedHeld = availableHeld.first(where: { $0.id == heldId })
        }
    }

    private func saveState() {
        let defaults = UserDefaults.standard

        defaults.set(currentTheme.id, forKey: Keys.theme)
        defaults.set(equippedOutfit?.id, forKey: Keys.outfit)
        defaults.set(equippedHat?.id, forKey: Keys.hat)
        defaults.set(equippedGlasses?.id, forKey: Keys.glasses)
        defaults.set(equippedHeld?.id, forKey: Keys.held)
    }

    // MARK: - Equip/Unequip

    func equip(_ item: ClosetItem, in category: ClosetCategory) {
        switch category {
        case .themes:
            if let theme = availableThemes.first(where: { $0.id == item.id }) {
                currentTheme = theme
            }
        case .outfits:
            equippedOutfit = item
        case .hats:
            equippedHat = item
        case .glasses:
            equippedGlasses = item
        case .held:
            equippedHeld = item
        }
        saveState()
        notifyChange()
    }

    func equipTheme(_ theme: ClosetTheme) {
        currentTheme = theme
        saveState()
        notifyChange()
    }

    func unequip(_ category: ClosetCategory) {
        switch category {
        case .themes:
            // Can't unequip theme, reset to default
            currentTheme = availableThemes[0]
        case .outfits:
            equippedOutfit = nil
        case .hats:
            equippedHat = nil
        case .glasses:
            equippedGlasses = nil
        case .held:
            equippedHeld = nil
        }
        saveState()
        notifyChange()
    }

    func resetToDefaults() {
        currentTheme = availableThemes[0]
        equippedOutfit = nil
        equippedHat = nil
        equippedGlasses = nil
        equippedHeld = nil
        saveState()
        notifyChange()
    }

    // MARK: - Query

    func items(for category: ClosetCategory) -> [ClosetItem] {
        switch category {
        case .themes:
            // Convert themes to items for grid display
            return availableThemes.map { theme in
                ClosetItem(id: theme.id, name: theme.name, category: .themes, isPremium: theme.isPremium)
            }
        case .outfits:
            return availableOutfits
        case .hats:
            return availableHats
        case .glasses:
            return availableGlasses
        case .held:
            return availableHeld
        }
    }

    func equippedItem(for category: ClosetCategory) -> ClosetItem? {
        switch category {
        case .themes:
            return ClosetItem(id: currentTheme.id, name: currentTheme.name, category: .themes, isPremium: currentTheme.isPremium)
        case .outfits:
            return equippedOutfit
        case .hats:
            return equippedHat
        case .glasses:
            return equippedGlasses
        case .held:
            return equippedHeld
        }
    }

    func isEquipped(_ item: ClosetItem) -> Bool {
        switch item.category {
        case .themes:
            return currentTheme.id == item.id
        case .outfits:
            return equippedOutfit?.id == item.id
        case .hats:
            return equippedHat?.id == item.id
        case .glasses:
            return equippedGlasses?.id == item.id
        case .held:
            return equippedHeld?.id == item.id
        }
    }

    // MARK: - Premium Check

    var isPremiumUnlocked: Bool {
        // TODO: Integrate with PremiumManager when implemented
        // For testing, return true to unlock all items
        return true
    }

    func canEquip(_ item: ClosetItem) -> Bool {
        return !item.isPremium || isPremiumUnlocked
    }

    // MARK: - Notifications

    private func notifyChange() {
        NotificationCenter.default.post(name: .closetItemChanged, object: nil)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let closetItemChanged = Notification.Name("closetItemChanged")
}
