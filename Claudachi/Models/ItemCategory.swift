//
//  ItemCategory.swift
//  Claudachi
//
//  Domain model for item categories that Claudachi can create
//

import Foundation

/// Categories of items Claudachi can create
enum ItemCategory: String, CaseIterable, Codable {
    case hat
    case glasses
    case food
    case prop

    var displayName: String {
        switch self {
        case .hat: return "hat"
        case .glasses: return "glasses"
        case .food: return "snack"
        case .prop: return "item"
        }
    }

    var promptDescription: String {
        switch self {
        case .hat:
            return "a tiny hat, seen from the front, sized to fit on a small character's head"
        case .glasses:
            return "a pair of glasses/eyewear, front view, sized for a small character"
        case .food:
            return "a small food item, cute and appetizing, suitable for a tiny character to hold"
        case .prop:
            return "a tiny handheld item, simple and iconic"
        }
    }

    /// Category-specific composition rules for sprite generation
    var compositionRules: String {
        switch self {
        case .hat:
            return """
            COMPOSITION (hat):
            - Position in upper 2/3 of sprite
            - Leave 2-3 rows at bottom for head overlap
            - Hat should be 10-14 pixels wide
            - Clear brim/crown shape
            """
        case .glasses:
            return """
            COMPOSITION (glasses):
            - Center horizontally
            - Position in middle third vertically
            - Bridge in center, lenses on each side
            - 12-14 pixels wide
            """
        case .food:
            return """
            COMPOSITION (food):
            - Center in sprite
            - Use 10-12 pixel diameter
            - Recognizable from iconic features
            - Include small detail (bite mark, topping)
            """
        case .prop:
            return """
            COMPOSITION (prop):
            - Center with slight bottom-heavy balance
            - Leave margins on all sides
            - Vertical orientation preferred
            - Clear iconic shape
            """
        }
    }
}
