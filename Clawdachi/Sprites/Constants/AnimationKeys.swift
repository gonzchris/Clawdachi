//
//  AnimationKeys.swift
//  Clawdachi
//
//  Centralized action key constants to avoid string typos and duplication
//

import Foundation

/// Action keys for sprite animations
enum AnimationKey: String {

    // MARK: - Idle Animations

    /// Body breathing animation
    case breathing

    /// Coordinated whistle/smoke cycle scheduler
    case idleAnimationCycle

    /// Face/mouth breathing animation
    case faceBreathing

    /// Body sway animation
    case sway

    /// Scheduled blink trigger
    case blinkSchedule

    /// Active blink animation
    case blink

    /// Scheduled whistle trigger
    case whistleSchedule

    /// Whistle head lift animation
    case whistleLift

    /// Whistle completion handler
    case whistleCompletion

    /// Scheduled look-around trigger
    case lookAroundSchedule

    // MARK: - Dancing Animations

    /// Body sway during dance
    case bodySway

    /// Left arm wave during dance
    case leftArmWave

    /// Right arm wave during dance
    case rightArmWave

    /// Left leg tap during dance
    case leftLegTap

    /// Right leg tap during dance
    case rightLegTap

    /// Music note spawner during dance
    case danceMusicNotes

    // MARK: - Drag Animations

    /// Limb wiggle during drag
    case dragWiggle

    /// Sweat drop spawner schedule
    case sweatDropSchedule

    /// Worried mouth pop animation
    case dragMouthPop

    /// Sleepy peek during drag (when sleeping)
    case sleepyPeek

    /// Sleepy blink schedule during drag
    case sleepyBlinkSchedule

    /// Sleepy blink animation
    case sleepyBlink

    /// Sleepy close animation
    case sleepyClose

    // MARK: - Sleep Animations

    /// Sleep breathing sway
    case sleepSway

    /// Z particle spawner schedule
    case sleepZSchedule

    /// Yawn animation
    case yawn

    /// Wake up animation
    case wakeUp

    // MARK: - Speaking Animation

    /// Mouth speaking animation
    case speaking

    // MARK: - Smoking Animations

    /// Scheduled smoking trigger
    case smokingSchedule

    /// Arm raise for smoking
    case smokingArmRaise

    /// Smoking end handler
    case smokingEnd

    /// Cigarette ember glow
    case emberGlow

    /// Cigarette tip smoke spawner
    case cigaretteSmoke

    /// Puff animation cycle trigger
    case puffCycle

    /// Single puff arm animation
    case puff

    /// Mouth puff animation
    case mouthPuff

    /// Next puff scheduler
    case puffSchedule

    // MARK: - Interaction Animations

    /// Wave reaction animation
    case wave

    /// Bounce reaction animation
    case bounce

    // MARK: - Claude Thinking Animations

    /// Head tilt during thinking
    case thinkingTilt

    /// Head bob during thinking
    case thinkingBob

    /// Thinking particle spawner
    case thinkingParticleSpawner

    /// Blink animation scheduler during thinking
    case thinkingBlink

    /// Active thinking blink sequence (cancellable)
    case thinkingBlinkSequence

    /// Arm tilt animation scheduler during thinking
    case thinkingArmTilt

    // MARK: - Claude Planning Animations

    /// Head tilt during planning
    case planningTilt

    /// Head bob during planning
    case planningBob

    /// Blink animation scheduler during planning
    case planningBlink

    /// Active planning blink sequence (cancellable)
    case planningBlinkSequence

    /// Lightbulb spark spawner
    case lightbulbSparkSpawner

    // MARK: - Claude Party Celebration

    /// Blower cycle animation
    case blowerCycle

    /// Body bounce during party
    case partyBounce

    /// Arm celebration animation
    case partyArm

    // MARK: - Voice Input Listening

    /// Body pulse during listening
    case listeningPulse

    /// Sound wave animation above head
    case listeningSoundWaves

    /// Sound wave particle spawner
    case listeningParticleSpawner
}
