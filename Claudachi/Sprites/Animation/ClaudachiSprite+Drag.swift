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

        let leftFootOut = SKAction.rotate(toAngle: -0.35, duration: legWiggleDuration)
        let leftFootIn = SKAction.rotate(toAngle: 0.2, duration: legWiggleDuration)
        leftFootOut.timingMode = .easeInEaseOut
        leftFootIn.timingMode = .easeInEaseOut
        let leftFootWiggle = SKAction.sequence([leftFootOut, leftFootIn])
        leftFootNode.run(SKAction.repeatForever(leftFootWiggle), withKey: "dragWiggle")

        let rightFootOut = SKAction.rotate(toAngle: 0.35, duration: legWiggleDuration)
        let rightFootIn = SKAction.rotate(toAngle: -0.2, duration: legWiggleDuration)
        rightFootOut.timingMode = .easeInEaseOut
        rightFootIn.timingMode = .easeInEaseOut
        let rightFootWiggle = SKAction.sequence([rightFootIn, rightFootOut])
        rightFootNode.run(SKAction.repeatForever(rightFootWiggle), withKey: "dragWiggle")

        // Delay sweat drops so they only appear during prolonged drags
        let sweatDelay = TimeInterval.random(in: 1.0...2.0)
        run(SKAction.sequence([
            SKAction.wait(forDuration: sweatDelay),
            SKAction.run { [weak self] in self?.spawnSweatDrop() }
        ]), withKey: "sweatDropSchedule")
    }

    func stopDragWiggle() {
        guard isDragging else { return }
        isDragging = false

        removeAction(forKey: "sweatDropSchedule")

        leftArmNode.removeAction(forKey: "dragWiggle")
        rightArmNode.removeAction(forKey: "dragWiggle")
        leftFootNode.removeAction(forKey: "dragWiggle")
        rightFootNode.removeAction(forKey: "dragWiggle")

        let resetDuration: TimeInterval = 0.15
        let resetRotation = SKAction.rotate(toAngle: 0, duration: resetDuration)
        resetRotation.timingMode = .easeOut

        leftArmNode.run(resetRotation)
        rightArmNode.run(resetRotation)
        leftFootNode.run(resetRotation)
        rightFootNode.run(resetRotation)
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
