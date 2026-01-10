//
//  OnboardingManager.swift
//  Clawdachi
//
//  Manages onboarding state and first-launch detection
//

import Foundation

/// Manages onboarding state and first-launch detection
class OnboardingManager {

    // MARK: - Singleton

    static let shared = OnboardingManager()

    // MARK: - Keys

    private enum Keys {
        static let onboardingVersion = "clawdachi.onboarding.version"
    }

    /// Current onboarding version - increment to re-show onboarding
    private static let currentVersion = 1

    // MARK: - Properties

    /// Current step in the onboarding flow
    private(set) var currentStep: OnboardingConstants.Step = .boot

    /// Callback when step changes
    var onStepChange: ((OnboardingConstants.Step) -> Void)?

    /// Callback when onboarding completes
    var onComplete: ((CGPoint) -> Void)?

    // MARK: - Initialization

    private init() {}

    // MARK: - First Launch Detection

    /// Whether onboarding needs to be shown
    static var needsOnboarding: Bool {
        let savedVersion = UserDefaults.standard.integer(forKey: Keys.onboardingVersion)
        return savedVersion < currentVersion
    }

    /// Mark onboarding as complete
    func markComplete() {
        UserDefaults.standard.set(OnboardingManager.currentVersion, forKey: Keys.onboardingVersion)
    }

    /// Reset onboarding (for testing)
    static func reset() {
        UserDefaults.standard.removeObject(forKey: Keys.onboardingVersion)
    }

    // MARK: - Navigation

    /// Move to next step
    func nextStep() {
        guard let next = currentStep.next else { return }
        currentStep = next
        onStepChange?(currentStep)
    }

    /// Move to previous step
    func previousStep() {
        guard let previous = currentStep.previous else { return }
        currentStep = previous
        onStepChange?(previous)
    }

    /// Go to a specific step
    func goToStep(_ step: OnboardingConstants.Step) {
        currentStep = step
        onStepChange?(step)
    }

    /// Reset to first step
    func resetSteps() {
        currentStep = .boot
    }

    // MARK: - Completion

    /// Complete onboarding and launch the app
    /// - Parameter launchPosition: The screen position where the sprite should land
    func completeOnboarding(launchPosition: CGPoint) {
        markComplete()
        onComplete?(launchPosition)
    }

    // MARK: - State

    /// Whether we're on the first step (hide back button)
    var isFirstStep: Bool {
        currentStep == .boot
    }

    /// Whether we're on the last step (show launch instead of next)
    var isLastStep: Bool {
        currentStep == .customize
    }

    /// Whether navigation forward should be enabled
    /// Boot sequence needs to complete before enabling Next
    var canNavigateForward: Bool = false
}
