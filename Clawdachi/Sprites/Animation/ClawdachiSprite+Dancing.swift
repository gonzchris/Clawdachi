//
//  ClawdachiSprite+Dancing.swift
//  Clawdachi
//
//  Dancing animation: groovy side-to-side sway when music is playing
//

import SpriteKit

extension ClawdachiSprite {

    // MARK: - Dance Animation

    func startDancing() {
        // Only start dancing from idle state (state machine blocks Claude states, etc.)
        guard currentState == .idle else { return }
        isDancing = true

        // Stop any pending idle animation schedules
        removeAction(forKey: AnimationKey.idleAnimationCycle.rawValue)
        removeAction(forKey: AnimationKey.lookAroundSchedule.rawValue)

        // Start dance animations
        startBodySway()
        startArmWave()
        startLegTap()
        startDanceMusicNotes()
    }

    func stopDancing() {
        // Check state OR presence of dance animation (handles state machine transitions)
        guard isDancing || bodyNode.action(forKey: AnimationKey.bodySway.rawValue) != nil else { return }

        // Stop dance animations on their respective nodes
        bodyNode.removeAction(forKey: AnimationKey.bodySway.rawValue)
        leftArmNode.removeAction(forKey: AnimationKey.leftArmWave.rawValue)
        rightArmNode.removeAction(forKey: AnimationKey.rightArmWave.rawValue)
        outerLeftLegNode.removeAction(forKey: AnimationKey.leftLegTap.rawValue)
        innerLeftLegNode.removeAction(forKey: AnimationKey.leftLegTap.rawValue)
        outerRightLegNode.removeAction(forKey: AnimationKey.rightLegTap.rawValue)
        innerRightLegNode.removeAction(forKey: AnimationKey.rightLegTap.rawValue)
        removeAction(forKey: AnimationKey.danceMusicNotes.rawValue)

        // Reset positions
        bodyNode.zRotation = 0
        leftArmNode.zRotation = 0
        rightArmNode.zRotation = 0
        outerLeftLegNode.zRotation = 0
        innerLeftLegNode.zRotation = 0
        outerRightLegNode.zRotation = 0
        innerRightLegNode.zRotation = 0

        // Only reset state and reschedule if we were actually in dancing state
        if currentState == .dancing {
            isDancing = false
            scheduleNextIdleAnimation()  // Resume coordinated whistle/smoke cycle
            scheduleNextLookAround()
        }
    }

    // MARK: - Body Sway (side to side lean)

    private func startBodySway() {
        let swayAngle = DanceConstants.swayAngle
        let swayDuration = AnimationTimings.danceSwayDuration

        let leanLeft = SKAction.rotate(toAngle: swayAngle, duration: swayDuration / 2)
        let leanRight = SKAction.rotate(toAngle: -swayAngle, duration: swayDuration / 2)
        leanLeft.timingMode = .easeInEaseOut
        leanRight.timingMode = .easeInEaseOut

        let swayCycle = SKAction.repeatForever(SKAction.sequence([leanLeft, leanRight]))
        bodyNode.run(swayCycle, withKey: AnimationKey.bodySway.rawValue)
    }

    // MARK: - Arm Wave (alternating up/down like "raise the roof")

    private func startArmWave() {
        let waveAngle = DanceConstants.armWaveAngle
        let waveDuration = AnimationTimings.danceSwayDuration / 2

        // Left arm - starts up
        let leftUp = SKAction.rotate(toAngle: waveAngle, duration: waveDuration)
        let leftDown = SKAction.rotate(toAngle: 0, duration: waveDuration)
        leftUp.timingMode = .easeOut
        leftDown.timingMode = .easeIn
        let leftWave = SKAction.repeatForever(SKAction.sequence([leftUp, leftDown]))
        leftArmNode.run(leftWave, withKey: AnimationKey.leftArmWave.rawValue)

        // Right arm - starts down (opposite phase)
        let rightDown = SKAction.rotate(toAngle: -waveAngle, duration: waveDuration)
        let rightUp = SKAction.rotate(toAngle: 0, duration: waveDuration)
        rightDown.timingMode = .easeOut
        rightUp.timingMode = .easeIn
        let rightWave = SKAction.repeatForever(SKAction.sequence([rightDown, rightUp]))
        rightArmNode.run(rightWave, withKey: AnimationKey.rightArmWave.rawValue)
    }

    // MARK: - Leg Tap (alternating little kicks)

    private func startLegTap() {
        let tapAngle = DanceConstants.legTapAngle
        let tapDuration = AnimationTimings.danceSwayDuration / 2

        // Left legs tap
        let leftOut = SKAction.rotate(toAngle: tapAngle, duration: tapDuration / 2)
        let leftBack = SKAction.rotate(toAngle: 0, duration: tapDuration / 2)
        let leftWait = SKAction.wait(forDuration: tapDuration)
        leftOut.timingMode = .easeOut
        leftBack.timingMode = .easeIn
        let leftTap = SKAction.repeatForever(SKAction.sequence([leftOut, leftBack, leftWait]))
        outerLeftLegNode.run(leftTap, withKey: AnimationKey.leftLegTap.rawValue)
        innerLeftLegNode.run(leftTap, withKey: AnimationKey.leftLegTap.rawValue)

        // Right legs tap (offset)
        let rightOut = SKAction.rotate(toAngle: -tapAngle, duration: tapDuration / 2)
        let rightBack = SKAction.rotate(toAngle: 0, duration: tapDuration / 2)
        let rightWait = SKAction.wait(forDuration: tapDuration)
        rightOut.timingMode = .easeOut
        rightBack.timingMode = .easeIn
        let rightTap = SKAction.repeatForever(SKAction.sequence([rightWait, rightOut, rightBack]))
        outerRightLegNode.run(rightTap, withKey: AnimationKey.rightLegTap.rawValue)
        innerRightLegNode.run(rightTap, withKey: AnimationKey.rightLegTap.rawValue)
    }

    // MARK: - Music Notes (from both sides)

    private func startDanceMusicNotes() {
        let spawnInterval = AnimationTimings.danceMusicNoteInterval
        var spawnLeft = true

        let spawnAction = SKAction.run { [weak self] in
            guard let self = self, self.isDancing else { return }
            self.spawnDanceNote(fromLeft: spawnLeft)
            spawnLeft.toggle()
        }

        let wait = SKAction.wait(forDuration: spawnInterval)
        let loop = SKAction.repeatForever(SKAction.sequence([spawnAction, wait]))

        run(loop, withKey: AnimationKey.danceMusicNotes.rawValue)
    }

    private func spawnDanceNote(fromLeft: Bool) {
        // Randomly choose single or double note
        let texture = Bool.random() ? musicNoteTexture : doubleNoteTexture
        let note = SKSpriteNode(texture: texture)
        note.size = CGSize(width: 8, height: 8)
        note.position = CGPoint(x: fromLeft ? -8 : 8, y: 10)
        note.alpha = 0
        note.zPosition = SpriteZPositions.effects
        note.setScale(DanceConstants.noteInitialScale)
        addChild(note)

        let popIn = SKAction.group([
            SKAction.fadeIn(withDuration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])

        let floatX: CGFloat = fromLeft ? -3 : 3
        let float = SKAction.moveBy(x: floatX, y: DanceConstants.noteFloatHeight, duration: 0.8)
        float.timingMode = .easeOut

        let wobble = SKAction.sequence([
            SKAction.rotate(byAngle: DanceConstants.noteRotationAngle, duration: 0.4),
            SKAction.rotate(byAngle: -DanceConstants.noteRotationAngle, duration: 0.4)
        ])

        let fadeOut = SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.fadeOut(withDuration: 0.3)
        ])

        let animation = SKAction.sequence([
            popIn,
            SKAction.group([float, wobble, fadeOut]),
            SKAction.removeFromParent()
        ])

        note.run(animation)
    }
}
