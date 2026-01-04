//
//  ClaudachiStateMachine.swift
//  Claudachi
//

import Foundation

/// Represents the current state of Claudachi
enum ClaudachiState: Equatable {
    case idle
    case gettingIdea
    case coding(item: String, category: ItemCategory)
    case celebrating(item: String)
    case failed
    case sleeping
}

/// Manages Claudachi's state transitions and triggers
class ClaudachiStateMachine {

    // MARK: - State

    private(set) var currentState: ClaudachiState = .idle

    // MARK: - Configuration

    /// Minimum time between idea triggers (seconds)
    var ideaMinInterval: TimeInterval = 60 * 10  // 10 minutes default

    /// Maximum time between idea triggers (seconds)
    var ideaMaxInterval: TimeInterval = 60 * 20  // 20 minutes default

    /// Whether automatic idea generation is enabled
    var autoIdeaEnabled: Bool = true

    // MARK: - Callbacks

    var onStateChange: ((ClaudachiState, ClaudachiState) -> Void)?
    var onIdeaTriggered: ((String, ItemCategory) -> Void)?

    // MARK: - Private State

    private var ideaTimer: Timer?
    private var isTransitioning = false

    // MARK: - Idea Generation

    private let hats = [
        "cowboy", "top", "chef", "wizard", "party", "pirate", "crown", "beanie",
        "baseball cap", "beret", "fedora", "santa", "propeller", "viking"
    ]

    private let glasses = [
        "sunglasses", "monocle", "3D glasses", "heart-shaped", "nerd",
        "round", "star-shaped", "pixel", "aviator"
    ]

    private let foods = [
        "pizza slice", "burger", "sushi", "ice cream cone", "cookie",
        "ramen bowl", "taco", "donut", "cupcake", "coffee cup", "bubble tea"
    ]

    private let props = [
        "tiny laptop", "sword", "balloon", "book", "umbrella", "magic wand",
        "guitar", "paintbrush", "skateboard", "telescope", "lantern"
    ]

    // MARK: - Initialization

    init() {}

    // MARK: - State Transitions

    func transition(to newState: ClaudachiState) {
        guard !isTransitioning else { return }
        guard newState != currentState else { return }

        let oldState = currentState
        isTransitioning = true

        // Validate transition
        guard isValidTransition(from: oldState, to: newState) else {
            isTransitioning = false
            return
        }

        currentState = newState
        onStateChange?(oldState, newState)
        isTransitioning = false
    }

    private func isValidTransition(from: ClaudachiState, to: ClaudachiState) -> Bool {
        switch (from, to) {
        case (.idle, .gettingIdea): return true
        case (.idle, .sleeping): return true
        case (.gettingIdea, .coding): return true
        case (.gettingIdea, .idle): return true  // Cancelled
        case (.coding, .celebrating): return true
        case (.coding, .failed): return true
        case (.celebrating, .idle): return true
        case (.failed, .idle): return true
        case (.sleeping, .idle): return true
        default: return false
        }
    }

    // MARK: - Idea Timer

    func startIdeaTimer() {
        stopIdeaTimer()
        guard autoIdeaEnabled else { return }

        scheduleNextIdea()
    }

    func stopIdeaTimer() {
        ideaTimer?.invalidate()
        ideaTimer = nil
    }

    private func scheduleNextIdea() {
        let interval = TimeInterval.random(in: ideaMinInterval...ideaMaxInterval)

        ideaTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.triggerIdea()
        }
    }

    /// Manually trigger an idea (for testing or user-initiated)
    func triggerIdea() {
        guard currentState == .idle else {
            // Reschedule if not idle
            if autoIdeaEnabled {
                scheduleNextIdea()
            }
            return
        }

        // Generate a random idea
        let (item, category) = generateRandomIdea()

        // Notify and transition
        onIdeaTriggered?(item, category)
        transition(to: .gettingIdea)
    }

    private func generateRandomIdea() -> (item: String, category: ItemCategory) {
        let category = ItemCategory.allCases.randomElement()!
        let item: String

        switch category {
        case .hat:
            item = hats.randomElement()!
        case .glasses:
            item = glasses.randomElement()!
        case .food:
            item = foods.randomElement()!
        case .prop:
            item = props.randomElement()!
        }

        return (item, category)
    }

    // MARK: - Coding Flow

    /// Call this after the "getting idea" animation completes
    func beginCoding(item: String, category: ItemCategory) {
        transition(to: .coding(item: item, category: category))
    }

    /// Call this when coding succeeds (item generated)
    func codingSucceeded(item: String) {
        transition(to: .celebrating(item: item))
    }

    /// Call this when coding fails
    func codingFailed() {
        transition(to: .failed)
    }

    /// Call this after celebration/failure animation completes
    func returnToIdle() {
        transition(to: .idle)

        // Reschedule next idea if auto-enabled
        if autoIdeaEnabled {
            scheduleNextIdea()
        }
    }

    // MARK: - Sleep

    func sleep() {
        stopIdeaTimer()
        transition(to: .sleeping)
    }

    func wake() {
        transition(to: .idle)
        if autoIdeaEnabled {
            startIdeaTimer()
        }
    }
}
