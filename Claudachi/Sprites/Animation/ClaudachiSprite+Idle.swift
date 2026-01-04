//
//  ClaudachiSprite+Idle.swift
//  Claudachi
//
//  Idle animations: breathing, blinking, whistling, looking around
//

import SpriteKit

extension ClaudachiSprite {

    // MARK: - Start All Idle Animations

    func startAnimations() {
        startBreathingAnimation()
        startSwayAnimation()
        scheduleNextBlink()
        scheduleNextWhistle()
        scheduleNextLookAround()
    }

    // MARK: - Breathing

    func startBreathingAnimation() {
        let breatheAction = SKAction.animate(
            with: breathingFrames,
            timePerFrame: breathingDuration / Double(breathingFrames.count),
            resize: false,
            restore: false
        )
        bodyNode.run(SKAction.repeatForever(breatheAction), withKey: "breathing")

        let faceUp = SKAction.moveBy(x: 0, y: 0.4, duration: breathingDuration / 2)
        let faceDown = SKAction.moveBy(x: 0, y: -0.4, duration: breathingDuration / 2)
        faceUp.timingMode = .easeInEaseOut
        faceDown.timingMode = .easeInEaseOut

        let faceBreath = SKAction.sequence([
            SKAction.wait(forDuration: 0.1),
            faceUp,
            faceDown
        ])

        leftEyeNode.run(SKAction.repeatForever(faceBreath), withKey: "faceBreathing")
        rightEyeNode.run(SKAction.repeatForever(faceBreath), withKey: "faceBreathing")
        mouthNode.run(SKAction.repeatForever(faceBreath), withKey: "faceBreathing")
    }

    func startSwayAnimation() {
        let pulseUp = SKAction.scaleX(to: 1.02, duration: swayDuration / 2)
        let pulseDown = SKAction.scaleX(to: 0.98, duration: swayDuration / 2)
        pulseUp.timingMode = .easeInEaseOut
        pulseDown.timingMode = .easeInEaseOut

        let swayCycle = SKAction.sequence([pulseUp, pulseDown])
        run(SKAction.repeatForever(swayCycle), withKey: "sway")
    }

    // MARK: - Looking Around

    func scheduleNextLookAround() {
        let interval = TimeInterval.random(in: lookAroundMinInterval...lookAroundMaxInterval)
        let wait = SKAction.wait(forDuration: interval)
        let look = SKAction.run { [weak self] in self?.performLookAround() }
        run(SKAction.sequence([wait, look]), withKey: "lookAroundSchedule")
    }

    func performLookAround() {
        guard !isLookingAround && !isPerformingAction else {
            scheduleNextLookAround()
            return
        }
        isLookingAround = true

        let directions: [(x: CGFloat, y: CGFloat)] = [
            (1, 0), (-1, 0), (0, 0.5), (1, 0.5), (-1, 0.5)
        ]
        let dir = directions.randomElement()!

        let lookOffset: CGFloat = 1.0
        let lookDuration: TimeInterval = 0.25
        let holdDuration = TimeInterval.random(in: 0.8...2.0)

        let moveToLook = SKAction.moveBy(x: dir.x * lookOffset, y: dir.y * lookOffset, duration: lookDuration)
        moveToLook.timingMode = .easeOut

        let hold = SKAction.wait(forDuration: holdDuration)

        let returnToCenter = SKAction.move(to: leftEyeBasePos, duration: lookDuration)
        returnToCenter.timingMode = .easeInEaseOut

        let returnToCenterRight = SKAction.move(to: rightEyeBasePos, duration: lookDuration)
        returnToCenterRight.timingMode = .easeInEaseOut

        let leftSequence = SKAction.sequence([moveToLook, hold, returnToCenter])
        let rightSequence = SKAction.sequence([moveToLook.copy() as! SKAction, hold, returnToCenterRight])

        leftEyeNode.run(leftSequence)
        rightEyeNode.run(rightSequence)

        let totalDuration = lookDuration * 2 + holdDuration
        run(SKAction.sequence([
            SKAction.wait(forDuration: totalDuration),
            SKAction.run { [weak self] in
                self?.isLookingAround = false
                self?.scheduleNextLookAround()
            }
        ]))
    }

    // MARK: - Blinking

    func scheduleNextBlink() {
        let interval = TimeInterval.random(in: blinkMinInterval...blinkMaxInterval)
        let wait = SKAction.wait(forDuration: interval)
        let blink = SKAction.run { [weak self] in self?.performBlink() }
        run(SKAction.sequence([wait, blink]), withKey: "blinkSchedule")
    }

    func performBlink() {
        guard !isBlinking else { return }
        isBlinking = true

        let blinkAnimation = SKAction.animate(
            with: blinkFrames,
            timePerFrame: blinkDuration / Double(blinkFrames.count),
            resize: false,
            restore: true
        )

        let completion = SKAction.run { [weak self] in
            self?.isBlinking = false
            self?.scheduleNextBlink()
        }

        leftEyeNode.run(SKAction.sequence([blinkAnimation, completion]), withKey: "blink")
        rightEyeNode.run(blinkAnimation, withKey: "blink")
    }

    // MARK: - Whistling

    func scheduleNextWhistle() {
        let interval = TimeInterval.random(in: whistleMinInterval...whistleMaxInterval)
        let wait = SKAction.wait(forDuration: interval)
        let whistle = SKAction.run { [weak self] in self?.performWhistle() }
        run(SKAction.sequence([wait, whistle]), withKey: "whistleSchedule")
    }

    func performWhistle() {
        guard !isWhistling && !isPerformingAction else { return }
        isWhistling = true

        mouthNode.setScale(0.8)
        let popIn = SKAction.group([
            SKAction.fadeIn(withDuration: 0.1),
            SKAction.scale(to: 1.1, duration: 0.1)
        ])
        let settle = SKAction.scale(to: 1.0, duration: 0.08)
        let hold = SKAction.wait(forDuration: whistleDuration - 0.3)
        let popOut = SKAction.group([
            SKAction.fadeOut(withDuration: 0.15),
            SKAction.scale(to: 0.8, duration: 0.15)
        ])
        mouthNode.run(SKAction.sequence([popIn, settle, hold, popOut]))

        spawnMusicNote(delay: 0.2, variation: 0)
        spawnMusicNote(delay: 0.7, variation: 1)
        spawnMusicNote(delay: 1.2, variation: 2)

        let liftUp = SKAction.scaleY(to: 1.03, duration: 0.3)
        liftUp.timingMode = .easeOut
        let holdLift = SKAction.wait(forDuration: whistleDuration - 0.5)
        let liftBack = SKAction.scaleY(to: 1.0, duration: 0.2)
        liftBack.timingMode = .easeInEaseOut
        run(SKAction.sequence([liftUp, holdLift, liftBack]), withKey: "whistleLift")

        let completion = SKAction.sequence([
            SKAction.wait(forDuration: whistleDuration + 0.2),
            SKAction.run { [weak self] in
                self?.isWhistling = false
                self?.scheduleNextWhistle()
            }
        ])
        run(completion, withKey: "whistleCompletion")
    }

    func spawnMusicNote(delay: TimeInterval, variation: Int) {
        ParticleSpawner.spawnMusicNote(
            texture: musicNoteTexture,
            variation: variation,
            delay: delay,
            parent: self
        )
    }

    // MARK: - Idle Animation Control

    func pauseIdleAnimations() {
        removeAction(forKey: "sway")
        removeAction(forKey: "whistleSchedule")
        removeAction(forKey: "blinkSchedule")
        removeAction(forKey: "lookAroundSchedule")
        isWhistling = false
        isLookingAround = false
    }

    func resumeIdleAnimations() {
        isPerformingAction = false
        setScale(1.0)
        startSwayAnimation()
        scheduleNextBlink()
        scheduleNextWhistle()
        scheduleNextLookAround()
    }
}
