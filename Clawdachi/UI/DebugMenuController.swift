//
//  DebugMenuController.swift
//  Clawdachi
//
//  Debug menu for testing animations and features
//

import Cocoa

/// Manages the Debug menu in the menu bar for testing animations
class DebugMenuController {

    // MARK: - Singleton

    static let shared = DebugMenuController()
    private init() {}

    // MARK: - Properties

    private weak var scene: ClawdachiScene?

    // MARK: - Setup

    /// Set up the debug menu in the menu bar
    func setupDebugMenu(scene: ClawdachiScene) {
        self.scene = scene

        guard let mainMenu = NSApp.mainMenu else {
            // Create main menu if it doesn't exist
            let mainMenu = NSMenu()
            NSApp.mainMenu = mainMenu
            setupDebugMenu(in: mainMenu)
            return
        }

        setupDebugMenu(in: mainMenu)
    }

    private func setupDebugMenu(in mainMenu: NSMenu) {
        // Remove existing Debug menu if any
        let existingIndex = mainMenu.indexOfItem(withTitle: "Debug")
        if existingIndex >= 0 {
            mainMenu.removeItem(at: existingIndex)
        }

        // Create Debug menu
        let debugMenu = NSMenu(title: "Debug")

        // -- Idle Animations submenu --
        let idleItem = NSMenuItem(title: "Idle Animations", action: nil, keyEquivalent: "")
        let idleSubmenu = NSMenu(title: "Idle Animations")

        idleSubmenu.addItem(createItem("Blink", action: #selector(triggerBlink)))
        idleSubmenu.addItem(createItem("Whistle", action: #selector(triggerWhistle)))
        idleSubmenu.addItem(createItem("Smoking", action: #selector(triggerSmoking)))
        idleSubmenu.addItem(createItem("Look Around", action: #selector(triggerLookAround)))

        idleItem.submenu = idleSubmenu
        debugMenu.addItem(idleItem)

        // -- Interaction Animations submenu --
        let interactionItem = NSMenuItem(title: "Interactions", action: nil, keyEquivalent: "")
        let interactionSubmenu = NSMenu(title: "Interactions")

        interactionSubmenu.addItem(createItem("Wave", action: #selector(triggerWave)))
        interactionSubmenu.addItem(createItem("Bounce", action: #selector(triggerBounce)))
        interactionSubmenu.addItem(createItem("Heart", action: #selector(triggerHeart)))
        interactionSubmenu.addItem(createItem("Random Click Reaction", action: #selector(triggerRandomReaction)))

        interactionItem.submenu = interactionSubmenu
        debugMenu.addItem(interactionItem)

        // -- Claude States submenu --
        let claudeItem = NSMenuItem(title: "Claude States", action: nil, keyEquivalent: "")
        let claudeSubmenu = NSMenu(title: "Claude States")

        claudeSubmenu.addItem(createItem("Thinking (3s)", action: #selector(triggerThinking)))
        claudeSubmenu.addItem(createItem("Planning (3s)", action: #selector(triggerPlanning)))
        claudeSubmenu.addItem(createItem("Question Mark", action: #selector(triggerQuestionMark)))
        claudeSubmenu.addItem(createItem("Party Celebration", action: #selector(triggerPartyCelebration)))
        claudeSubmenu.addItem(NSMenuItem.separator())
        claudeSubmenu.addItem(createItem("Clear All Claude States", action: #selector(clearClaudeStates)))

        claudeItem.submenu = claudeSubmenu
        debugMenu.addItem(claudeItem)

        debugMenu.addItem(NSMenuItem.separator())

        // -- Dancing --
        debugMenu.addItem(createItem("Start Dancing", action: #selector(startDancing)))
        debugMenu.addItem(createItem("Stop Dancing", action: #selector(stopDancing)))

        debugMenu.addItem(NSMenuItem.separator())

        // -- Sleep --
        debugMenu.addItem(createItem("Start Sleeping", action: #selector(startSleeping)))
        debugMenu.addItem(createItem("Wake Up", action: #selector(wakeUp)))

        debugMenu.addItem(NSMenuItem.separator())

        // -- Chat Bubble --
        let chatItem = NSMenuItem(title: "Chat Bubbles", action: nil, keyEquivalent: "")
        let chatSubmenu = NSMenu(title: "Chat Bubbles")

        chatSubmenu.addItem(createItem("Single Bubble", action: #selector(testSingleBubble)))
        chatSubmenu.addItem(createItem("Multiple Bubbles", action: #selector(testMultipleBubbles)))
        chatSubmenu.addItem(createItem("Dismiss All", action: #selector(dismissBubbles)))
        chatSubmenu.addItem(NSMenuItem.separator())

        // Greetings submenu
        let greetingsItem = NSMenuItem(title: "Greetings", action: nil, keyEquivalent: "")
        let greetingsSubmenu = NSMenu(title: "Greetings")
        greetingsSubmenu.addItem(createItem("Current Time", action: #selector(testGreetingCurrent)))
        greetingsSubmenu.addItem(NSMenuItem.separator())
        greetingsSubmenu.addItem(createItem("Morning", action: #selector(testGreetingMorning)))
        greetingsSubmenu.addItem(createItem("Afternoon", action: #selector(testGreetingAfternoon)))
        greetingsSubmenu.addItem(createItem("Evening", action: #selector(testGreetingEvening)))
        greetingsSubmenu.addItem(createItem("Late Night", action: #selector(testGreetingLateNight)))
        greetingsItem.submenu = greetingsSubmenu
        chatSubmenu.addItem(greetingsItem)

        chatItem.submenu = chatSubmenu
        debugMenu.addItem(chatItem)

        debugMenu.addItem(NSMenuItem.separator())

        // -- Onboarding --
        debugMenu.addItem(createItem("Show Onboarding", action: #selector(showOnboarding)))
        debugMenu.addItem(createItem("Reset Onboarding", action: #selector(resetOnboarding)))

        // Add to menu bar
        let debugMenuItem = NSMenuItem(title: "Debug", action: nil, keyEquivalent: "")
        debugMenuItem.submenu = debugMenu
        mainMenu.addItem(debugMenuItem)
    }

    private func createItem(_ title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    // MARK: - Idle Animation Actions

    @objc private func triggerBlink() {
        scene?.debugTriggerBlink()
    }

    @objc private func triggerWhistle() {
        scene?.debugTriggerWhistle()
    }

    @objc private func triggerSmoking() {
        scene?.debugTriggerSmoking()
    }

    @objc private func triggerLookAround() {
        scene?.debugTriggerLookAround()
    }

    // MARK: - Interaction Actions

    @objc private func triggerWave() {
        scene?.debugTriggerWave()
    }

    @objc private func triggerBounce() {
        scene?.debugTriggerBounce()
    }

    @objc private func triggerHeart() {
        scene?.debugTriggerHeart()
    }

    @objc private func triggerRandomReaction() {
        scene?.debugTriggerRandomReaction()
    }

    // MARK: - Claude State Actions

    @objc private func triggerThinking() {
        scene?.debugTriggerThinking(duration: 3.0)
    }

    @objc private func triggerPlanning() {
        scene?.debugTriggerPlanning(duration: 3.0)
    }

    @objc private func triggerQuestionMark() {
        scene?.debugTriggerQuestionMark()
    }

    @objc private func triggerPartyCelebration() {
        scene?.debugTriggerPartyCelebration()
    }

    @objc private func clearClaudeStates() {
        scene?.debugClearClaudeStates()
    }

    // MARK: - Dancing Actions

    @objc private func startDancing() {
        scene?.debugStartDancing()
    }

    @objc private func stopDancing() {
        scene?.debugStopDancing()
    }

    // MARK: - Sleep Actions

    @objc private func startSleeping() {
        scene?.debugStartSleeping()
    }

    @objc private func wakeUp() {
        scene?.debugWakeUp()
    }

    // MARK: - Chat Bubble Actions

    @objc private func testSingleBubble() {
        scene?.showChatBubble("testing!")
    }

    @objc private func testMultipleBubbles() {
        scene?.debugTestMultipleBubbles()
    }

    @objc private func dismissBubbles() {
        scene?.dismissChatBubble()
    }

    // MARK: - Greeting Actions

    @objc private func testGreetingCurrent() {
        scene?.showChatBubble(ClawdachiMessages.greetingForCurrentTime(), duration: 4.0)
    }

    @objc private func testGreetingMorning() {
        scene?.showChatBubble(ClawdachiMessages.greetingMorning, duration: 4.0)
    }

    @objc private func testGreetingAfternoon() {
        scene?.showChatBubble(ClawdachiMessages.greetingAfternoon, duration: 4.0)
    }

    @objc private func testGreetingEvening() {
        scene?.showChatBubble(ClawdachiMessages.greetingEvening, duration: 4.0)
    }

    @objc private func testGreetingLateNight() {
        scene?.showChatBubble(ClawdachiMessages.greetingLateNight, duration: 4.0)
    }

    // MARK: - Onboarding Actions

    @objc private func showOnboarding() {
        OnboardingWindow.shared.show()
    }

    @objc private func resetOnboarding() {
        OnboardingManager.reset()
        scene?.showChatBubble("onboarding reset!", duration: 3.0)
    }
}
