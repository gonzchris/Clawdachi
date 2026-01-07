//
//  TextInjector.swift
//  Clawdachi
//
//  Types text into the currently focused window using CGEvent keyboard simulation
//

import Foundation
import CoreGraphics
import Carbon.HIToolbox

/// Types text into the currently focused application using keyboard events
final class TextInjector {

    // MARK: - Public

    /// Type the given text into the currently focused window
    func typeText(_ text: String) {
        guard !text.isEmpty else { return }

        // Type each character
        for character in text {
            typeCharacter(character)
        }
    }

    // MARK: - Private

    private func typeCharacter(_ char: Character) {
        // Try to get keycode for common characters
        if let keyInfo = keyCodeForCharacter(char) {
            typeWithKeyCode(keyInfo.keyCode, modifiers: keyInfo.modifiers)
        } else {
            // Fallback: use Unicode input for special characters
            typeUnicodeCharacter(char)
        }
    }

    private func typeWithKeyCode(_ keyCode: CGKeyCode, modifiers: CGEventFlags) {
        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) else {
            return
        }

        if !modifiers.isEmpty {
            keyDown.flags = modifiers
        }

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)

        // Small delay between keystrokes for reliability
        usleep(3000)  // 3ms
    }

    private func typeUnicodeCharacter(_ char: Character) {
        let utf16 = Array(String(char).utf16)

        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) else {
            return
        }

        keyDown.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)

        usleep(3000)
    }

    // MARK: - Key Code Mapping

    private struct KeyInfo {
        let keyCode: CGKeyCode
        let modifiers: CGEventFlags
    }

    private func keyCodeForCharacter(_ char: Character) -> KeyInfo? {
        // Map common ASCII characters to their key codes
        let lowercased = char.lowercased().first ?? char
        let needsShift = char.isUppercase || shiftedCharacters.contains(char)

        guard let keyCode = characterKeyCodeMap[lowercased] else {
            return nil
        }

        let modifiers: CGEventFlags = needsShift ? .maskShift : []
        return KeyInfo(keyCode: keyCode, modifiers: modifiers)
    }

    // Characters that require shift
    private let shiftedCharacters: Set<Character> = [
        "!", "@", "#", "$", "%", "^", "&", "*", "(", ")",
        "_", "+", "{", "}", "|", ":", "\"", "<", ">", "?", "~"
    ]

    // Key code map for standard US keyboard layout
    private let characterKeyCodeMap: [Character: CGKeyCode] = [
        // Letters
        "a": 0x00, "s": 0x01, "d": 0x02, "f": 0x03, "h": 0x04,
        "g": 0x05, "z": 0x06, "x": 0x07, "c": 0x08, "v": 0x09,
        "b": 0x0B, "q": 0x0C, "w": 0x0D, "e": 0x0E, "r": 0x0F,
        "y": 0x10, "t": 0x11, "1": 0x12, "2": 0x13, "3": 0x14,
        "4": 0x15, "6": 0x16, "5": 0x17, "=": 0x18, "9": 0x19,
        "7": 0x1A, "-": 0x1B, "8": 0x1C, "0": 0x1D, "]": 0x1E,
        "o": 0x1F, "u": 0x20, "[": 0x21, "i": 0x22, "p": 0x23,
        "l": 0x25, "j": 0x26, "'": 0x27, "k": 0x28, ";": 0x29,
        "\\": 0x2A, ",": 0x2B, "/": 0x2C, "n": 0x2D, "m": 0x2E,
        ".": 0x2F, "`": 0x32,

        // Special characters (same key, different with shift)
        "!": 0x12, "@": 0x13, "#": 0x14, "$": 0x15, "%": 0x17,
        "^": 0x16, "&": 0x1A, "*": 0x1C, "(": 0x19, ")": 0x1D,
        "_": 0x1B, "+": 0x18, "{": 0x21, "}": 0x1E, "|": 0x2A,
        ":": 0x29, "\"": 0x27, "<": 0x2B, ">": 0x2F, "?": 0x2C,
        "~": 0x32,

        // Whitespace and control
        " ": 0x31,  // Space
        "\t": 0x30, // Tab
        "\n": 0x24, // Return
    ]
}
