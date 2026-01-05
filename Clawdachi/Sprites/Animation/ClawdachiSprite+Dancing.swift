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
        guard !isDancing, !isPerformingAction else { return }
        isDancing = true

        // Pause competing idle animations (whistle, look-around)
        removeAction(forKey: "whistleSchedule")
        removeAction(forKey: "whistleCompletion")
        removeAction(forKey: "lookAroundSchedule")
        isWhistling = false
        isLookingAround = false

        // Start dance animations
        startBodySway()
        startArmWave()
        startLegTap()
        startDanceMusicNotes()
    }

    func stopDancing() {
        guard isDancing else { return }
        isDancing = false

        // Stop dance animations on their respective nodes
        bodyNode.removeAction(forKey: "bodySway")
        leftArmNode.removeAction(forKey: "leftArmWave")
        rightArmNode.removeAction(forKey: "rightArmWave")
        outerLeftLegNode.removeAction(forKey: "leftLegTap")
        innerLeftLegNode.removeAction(forKey: "leftLegTap")
        outerRightLegNode.removeAction(forKey: "rightLegTap")
        innerRightLegNode.removeAction(forKey: "rightLegTap")
        removeAction(forKey: "danceMusicNotes")

        // Reset positions
        bodyNode.zRotation = 0
        leftArmNode.zRotation = 0
        rightArmNode.zRotation = 0
        outerLeftLegNode.zRotation = 0
        innerLeftLegNode.zRotation = 0
        outerRightLegNode.zRotation = 0
        innerRightLegNode.zRotation = 0

        // Resume idle animations
        scheduleNextWhistle()
        scheduleNextLookAround()
    }

    // MARK: - Body Sway (side to side lean)

    private func startBodySway() {
        let swayAngle: CGFloat = 0.06  // Subtle rotation
        let swayDuration = AnimationTimings.danceSwayDuration

        let leanLeft = SKAction.rotate(toAngle: swayAngle, duration: swayDuration / 2)
        let leanRight = SKAction.rotate(toAngle: -swayAngle, duration: swayDuration / 2)
        leanLeft.timingMode = .easeInEaseOut
        leanRight.timingMode = .easeInEaseOut

        let swayCycle = SKAction.repeatForever(SKAction.sequence([leanLeft, leanRight]))
        bodyNode.run(swayCycle, withKey: "bodySway")
    }

    // MARK: - Arm Wave (alternating up/down like "raise the roof")

    private func startArmWave() {
        let waveAngle: CGFloat = 0.5  // More pronounced than idle
        let waveDuration = AnimationTimings.danceSwayDuration / 2

        // Left arm - starts up
        let leftUp = SKAction.rotate(toAngle: waveAngle, duration: waveDuration)
        let leftDown = SKAction.rotate(toAngle: 0, duration: waveDuration)
        leftUp.timingMode = .easeOut
        leftDown.timingMode = .easeIn
        let leftWave = SKAction.repeatForever(SKAction.sequence([leftUp, leftDown]))
        leftArmNode.run(leftWave, withKey: "leftArmWave")

        // Right arm - starts down (opposite phase)
        let rightDown = SKAction.rotate(toAngle: -waveAngle, duration: waveDuration)
        let rightUp = SKAction.rotate(toAngle: 0, duration: waveDuration)
        rightDown.timingMode = .easeOut
        rightUp.timingMode = .easeIn
        let rightWave = SKAction.repeatForever(SKAction.sequence([rightDown, rightUp]))
        rightArmNode.run(rightWave, withKey: "rightArmWave")
    }

    // MARK: - Leg Tap (alternating little kicks)

    private func startLegTap() {
        let tapAngle: CGFloat = 0.2
        let tapDuration = AnimationTimings.danceSwayDuration / 2

        // Left legs tap
        let leftOut = SKAction.rotate(toAngle: tapAngle, duration: tapDuration / 2)
        let leftBack = SKAction.rotate(toAngle: 0, duration: tapDuration / 2)
        let leftWait = SKAction.wait(forDuration: tapDuration)
        leftOut.timingMode = .easeOut
        leftBack.timingMode = .easeIn
        let leftTap = SKAction.repeatForever(SKAction.sequence([leftOut, leftBack, leftWait]))
        outerLeftLegNode.run(leftTap, withKey: "leftLegTap")
        innerLeftLegNode.run(leftTap, withKey: "leftLegTap")

        // Right legs tap (offset)
        let rightOut = SKAction.rotate(toAngle: -tapAngle, duration: tapDuration / 2)
        let rightBack = SKAction.rotate(toAngle: 0, duration: tapDuration / 2)
        let rightWait = SKAction.wait(forDuration: tapDuration)
        rightOut.timingMode = .easeOut
        rightBack.timingMode = .easeIn
        let rightTap = SKAction.repeatForever(SKAction.sequence([rightWait, rightOut, rightBack]))
        outerRightLegNode.run(rightTap, withKey: "rightLegTap")
        innerRightLegNode.run(rightTap, withKey: "rightLegTap")
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

        run(loop, withKey: "danceMusicNotes")
    }

    private func spawnDanceNote(fromLeft: Bool) {
        // Randomly choose single or double note
        let texture = Bool.random() ? musicNoteTexture : doubleNoteTexture
        let note = SKSpriteNode(texture: texture)
        note.size = CGSize(width: 8, height: 8)
        note.position = CGPoint(x: fromLeft ? -8 : 8, y: 10)
        note.alpha = 0
        note.zPosition = SpriteZPositions.effects
        note.setScale(0.6)
        addChild(note)

        let popIn = SKAction.group([
            SKAction.fadeIn(withDuration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])

        let floatX: CGFloat = fromLeft ? -3 : 3
        let float = SKAction.moveBy(x: floatX, y: 12, duration: 0.8)
        float.timingMode = .easeOut

        let wobble = SKAction.sequence([
            SKAction.rotate(byAngle: 0.3, duration: 0.4),
            SKAction.rotate(byAngle: -0.3, duration: 0.4)
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
