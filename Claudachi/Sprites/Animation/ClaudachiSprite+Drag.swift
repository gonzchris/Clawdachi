//
//  ClaudachiSprite+Drag.swift
//  Claudachi
//
//  Drag animations: wiggling limbs, sweat drops
//

import SpriteKit

extension ClaudachiSprite {

    // MARK: - Drag Animation

    func startDragWiggle() {
        guard !isDragging else { return }
        isDragging = true

        let armWiggleDuration: TimeInterval = 0.12

        let leftArmUp = SKAction.rotate(toAngle: 0.4, duration: armWiggleDuration)
        let leftArmDown = SKAction.rotate(toAngle: -0.3, duration: armWiggleDuration)
        leftArmUp.timingMode = .easeInEaseOut
        leftArmDown.timingMode = .easeInEaseOut
        let leftArmWiggle = SKAction.sequence([leftArmUp, leftArmDown])
        leftArmNode.run(SKAction.repeatForever(leftArmWiggle), withKey: "dragWiggle")

        let rightArmUp = SKAction.rotate(toAngle: -0.4, duration: armWiggleDuration)
        let rightArmDown = SKAction.rotate(toAngle: 0.3, duration: armWiggleDuration)
        rightArmUp.timingMode = .easeInEaseOut
        rightArmDown.timingMode = .easeInEaseOut
        let rightArmWiggle = SKAction.sequence([rightArmDown, rightArmUp])
        rightArmNode.run(SKAction.repeatForever(rightArmWiggle), withKey: "dragWiggle")

        let legWiggleDuration: TimeInterval = 0.15

        // Outer legs wiggle outward
        let outerLeftOut = SKAction.rotate(toAngle: -0.3, duration: legWiggleDuration)
        let outerLeftIn = SKAction.rotate(toAngle: 0.15, duration: legWiggleDuration)
        outerLeftOut.timingMode = .easeInEaseOut
        outerLeftIn.timingMode = .easeInEaseOut
        let outerLeftWiggle = SKAction.sequence([outerLeftOut, outerLeftIn])
        outerLeftLegNode.run(SKAction.repeatForever(outerLeftWiggle), withKey: "dragWiggle")

        let outerRightOut = SKAction.rotate(toAngle: 0.3, duration: legWiggleDuration)
        let outerRightIn = SKAction.rotate(toAngle: -0.15, duration: legWiggleDuration)
        outerRightOut.timingMode = .easeInEaseOut
        outerRightIn.timingMode = .easeInEaseOut
        let outerRightWiggle = SKAction.sequence([outerRightIn, outerRightOut])
        outerRightLegNode.run(SKAction.repeatForever(outerRightWiggle), withKey: "dragWiggle")

        // Inner legs wiggle with offset timing
        let innerLeftOut = SKAction.rotate(toAngle: -0.2, duration: legWiggleDuration)
        let innerLeftIn = SKAction.rotate(toAngle: 0.25, duration: legWiggleDuration)
        innerLeftOut.timingMode = .easeInEaseOut
        innerLeftIn.timingMode = .easeInEaseOut
        let innerLeftWiggle = SKAction.sequence([innerLeftIn, innerLeftOut])
        innerLeftLegNode.run(SKAction.repeatForever(innerLeftWiggle), withKey: "dragWiggle")

        let innerRightOut = SKAction.rotate(toAngle: 0.2, duration: legWiggleDuration)
        let innerRightIn = SKAction.rotate(toAngle: -0.25, duration: legWiggleDuration)
        innerRightOut.timingMode = .easeInEaseOut
        innerRightIn.timingMode = .easeInEaseOut
        let innerRightWiggle = SKAction.sequence([innerRightOut, innerRightIn])
        innerRightLegNode.run(SKAction.repeatForever(innerRightWiggle), withKey: "dragWiggle")

        // Delay sweat drops so they only appear during prolonged drags
        let sweatDelay = TimeInterval.random(in: 1.0...2.0)
        run(SKAction.sequence([
            SKAction.wait(forDuration: sweatDelay),
            SKAction.run { [weak self] in self?.spawnSweatDrop() }
        ]), withKey: "sweatDropSchedule")

        // Start surprised "O" mouth animation
        startDragMouthAnimation()
    }

    private func startDragMouthAnimation() {
        mouthNode.removeAction(forKey: "faceBreathing")
        mouthNode.texture = whistleMouthTexture
        mouthNode.setScale(0.8)
        mouthNode.alpha = 0

        // Delay before mouth appears
        let showDelay = TimeInterval.random(in: 0.4...0.7)
        let fadeIn = SKAction.fadeIn(withDuration: 0.1)
        let popIn = SKAction.scale(to: 1.0, duration: 0.1)
        popIn.timingMode = .easeOut

        mouthNode.run(SKAction.sequence([
            SKAction.wait(forDuration: showDelay),
            SKAction.group([fadeIn, popIn]),
            SKAction.run { [weak self] in self?.scheduleDragMouthPop() }
        ]), withKey: "dragMouthPop")
    }

    private func scheduleDragMouthPop() {
        guard isDragging else { return }

        // Randomly pick an animation variation
        let variation = Int.random(in: 0...3)
        var actions: [SKAction] = []

        let delay = TimeInterval.random(in: 0.2...0.6)
        actions.append(SKAction.wait(forDuration: delay))

        switch variation {
        case 0:
            // Quick pop
            let popOut = SKAction.scale(to: 1.3, duration: 0.06)
            let popIn = SKAction.scale(to: 1.0, duration: 0.08)
            popOut.timingMode = .easeOut
            popIn.timingMode = .easeInEaseOut
            actions.append(contentsOf: [popOut, popIn])

        case 1:
            // Bigger gasp
            let popOut = SKAction.scale(to: 1.5, duration: 0.1)
            let hold = SKAction.wait(forDuration: 0.15)
            let popIn = SKAction.scale(to: 1.0, duration: 0.12)
            popOut.timingMode = .easeOut
            popIn.timingMode = .easeInEaseOut
            actions.append(contentsOf: [popOut, hold, popIn])

        case 2:
            // Double pop
            let pop1 = SKAction.scale(to: 1.2, duration: 0.05)
            let back1 = SKAction.scale(to: 1.0, duration: 0.05)
            let pop2 = SKAction.scale(to: 1.25, duration: 0.06)
            let back2 = SKAction.scale(to: 1.0, duration: 0.06)
            actions.append(contentsOf: [pop1, back1, pop2, back2])

        default:
            // Gentle wobble
            let wobbleLeft = SKAction.moveBy(x: -0.3, y: 0, duration: 0.06)
            let wobbleRight = SKAction.moveBy(x: 0.6, y: 0, duration: 0.12)
            let wobbleBack = SKAction.moveBy(x: -0.3, y: 0, duration: 0.06)
            wobbleLeft.timingMode = .easeInEaseOut
            wobbleRight.timingMode = .easeInEaseOut
            wobbleBack.timingMode = .easeInEaseOut
            actions.append(contentsOf: [wobbleLeft, wobbleRight, wobbleBack])
        }

        actions.append(SKAction.run { [weak self] in self?.scheduleDragMouthPop() })
        mouthNode.run(SKAction.sequence(actions), withKey: "dragMouthPop")
    }

    func stopDragWiggle() {
        // Always clean up, even if not currently dragging (safety)
        isDragging = false

        removeAction(forKey: "sweatDropSchedule")

        // Hide mouth and reset position
        mouthNode.removeAction(forKey: "dragMouthPop")
        mouthNode.run(SKAction.fadeOut(withDuration: 0.15))
        mouthNode.run(SKAction.scale(to: 1.0, duration: 0.1))
        mouthNode.run(SKAction.move(to: CGPoint(x: 0, y: -4), duration: 0.1))

        leftArmNode.removeAction(forKey: "dragWiggle")
        rightArmNode.removeAction(forKey: "dragWiggle")
        outerLeftLegNode.removeAction(forKey: "dragWiggle")
        innerLeftLegNode.removeAction(forKey: "dragWiggle")
        innerRightLegNode.removeAction(forKey: "dragWiggle")
        outerRightLegNode.removeAction(forKey: "dragWiggle")

        let resetDuration: TimeInterval = 0.15
        let resetRotation = SKAction.rotate(toAngle: 0, duration: resetDuration)
        resetRotation.timingMode = .easeOut

        leftArmNode.run(resetRotation)
        rightArmNode.run(resetRotation)
        outerLeftLegNode.run(resetRotation)
        innerLeftLegNode.run(resetRotation)
        innerRightLegNode.run(resetRotation)
        outerRightLegNode.run(resetRotation)
    }

    func spawnSweatDrop() {
        guard isDragging else { return }

        let isLeftSide = Bool.random()
        ParticleSpawner.spawnSweatDrop(
            texture: sweatDropTexture,
            isLeftSide: isLeftSide,
            parent: self
        )

        let nextDelay = TimeInterval.random(in: 0.5...0.9)
        run(SKAction.sequence([
            SKAction.wait(forDuration: nextDelay),
            SKAction.run { [weak self] in self?.spawnSweatDrop() }
        ]), withKey: "sweatDropSchedule")
    }
}
