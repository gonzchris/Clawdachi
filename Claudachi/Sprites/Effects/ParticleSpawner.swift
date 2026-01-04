//
//  ParticleSpawner.swift
//  Claudachi
//
//  Reusable particle effect spawning utilities
//

import SpriteKit

/// Configuration for a particle effect
struct ParticleConfig {
    /// The texture to display
    let texture: SKTexture

    /// Size of the particle sprite
    let size: CGSize

    /// Starting position relative to parent
    let startPosition: CGPoint

    /// Z-position for layering
    let zPosition: CGFloat

    /// Initial scale before pop-in
    let initialScale: CGFloat

    /// Final scale after pop-in
    let targetScale: CGFloat

    /// Duration of the pop-in animation
    let popInDuration: TimeInterval

    /// Duration of the main movement phase
    let movementDuration: TimeInterval

    /// Movement delta (how far to move)
    let movementDelta: CGPoint

    /// Optional rotation during movement
    let rotation: CGFloat

    /// Duration of fade-out
    let fadeOutDuration: TimeInterval

    /// Delay before starting the animation
    let delay: TimeInterval

    /// Easing for the movement
    let movementEasing: SKActionTimingMode

    init(
        texture: SKTexture,
        size: CGSize,
        startPosition: CGPoint,
        zPosition: CGFloat = SpriteZPositions.effects,
        initialScale: CGFloat = 0.5,
        targetScale: CGFloat = 1.0,
        popInDuration: TimeInterval = AnimationTimings.popInDuration,
        movementDuration: TimeInterval = 1.0,
        movementDelta: CGPoint = CGPoint(x: 0, y: 10),
        rotation: CGFloat = 0,
        fadeOutDuration: TimeInterval = AnimationTimings.fadeOutDuration,
        delay: TimeInterval = 0,
        movementEasing: SKActionTimingMode = .easeOut
    ) {
        self.texture = texture
        self.size = size
        self.startPosition = startPosition
        self.zPosition = zPosition
        self.initialScale = initialScale
        self.targetScale = targetScale
        self.popInDuration = popInDuration
        self.movementDuration = movementDuration
        self.movementDelta = movementDelta
        self.rotation = rotation
        self.fadeOutDuration = fadeOutDuration
        self.delay = delay
        self.movementEasing = movementEasing
    }
}

/// Utility for spawning particle effects
enum ParticleSpawner {

    /// Spawn a basic particle that pops in, moves, and fades out
    /// - Parameters:
    ///   - config: Configuration for the particle
    ///   - parent: The node to add the particle to
    /// - Returns: The created sprite node (for further customization if needed)
    @discardableResult
    static func spawn(config: ParticleConfig, in parent: SKNode) -> SKSpriteNode {
        let particle = SKSpriteNode(texture: config.texture)
        particle.size = config.size
        particle.position = config.startPosition
        particle.alpha = 0
        particle.zPosition = config.zPosition
        particle.setScale(config.initialScale)
        parent.addChild(particle)

        // Build the animation sequence
        var actions: [SKAction] = []

        // Optional delay
        if config.delay > 0 {
            actions.append(SKAction.wait(forDuration: config.delay))
        }

        // Pop-in with slight overshoot
        let popIn = SKAction.group([
            SKAction.fadeIn(withDuration: config.popInDuration),
            SKAction.scale(to: config.targetScale * 1.15, duration: config.popInDuration)
        ])
        actions.append(popIn)

        // Settle to target scale
        let settle = SKAction.scale(to: config.targetScale, duration: config.popInDuration * 0.6)
        settle.timingMode = .easeOut
        actions.append(settle)

        // Movement with optional rotation
        let move = SKAction.moveBy(
            x: config.movementDelta.x,
            y: config.movementDelta.y,
            duration: config.movementDuration
        )
        move.timingMode = config.movementEasing

        var movementActions: [SKAction] = [move]

        if abs(config.rotation) > 0.01 {
            let wobble = SKAction.sequence([
                SKAction.rotate(byAngle: config.rotation, duration: config.movementDuration / 2),
                SKAction.rotate(byAngle: -config.rotation, duration: config.movementDuration / 2)
            ])
            movementActions.append(wobble)
        }

        // Fade out near the end of movement
        let fadeOutDelay = max(0, config.movementDuration - config.fadeOutDuration)
        let fadeSequence = SKAction.sequence([
            SKAction.wait(forDuration: fadeOutDelay),
            SKAction.fadeOut(withDuration: config.fadeOutDuration)
        ])
        movementActions.append(fadeSequence)

        actions.append(SKAction.group(movementActions))

        // Remove from parent
        actions.append(SKAction.removeFromParent())

        particle.run(SKAction.sequence(actions))

        return particle
    }

    /// Spawn a particle that bursts outward from center (for celebrations)
    /// - Parameters:
    ///   - texture: Texture for the particle
    ///   - size: Size of the particle
    ///   - startNearCenter: Starting position (near center, scaled down)
    ///   - targetPosition: Final burst position
    ///   - delay: Delay before starting
    ///   - parent: Parent node to add to
    @discardableResult
    static func spawnBurst(
        texture: SKTexture,
        size: CGSize,
        startNearCenter: CGPoint,
        targetPosition: CGPoint,
        delay: TimeInterval = 0,
        parent: SKNode
    ) -> SKSpriteNode {
        let particle = SKSpriteNode(texture: texture)
        particle.size = size
        particle.position = startNearCenter
        particle.alpha = 0
        particle.zPosition = SpriteZPositions.effects
        particle.setScale(0.2)
        parent.addChild(particle)

        var actions: [SKAction] = []

        if delay > 0 {
            actions.append(SKAction.wait(forDuration: delay))
        }

        // Burst outward
        let moveOut = SKAction.move(to: targetPosition, duration: 0.2)
        moveOut.timingMode = .easeOut

        let popIn = SKAction.group([
            SKAction.fadeIn(withDuration: 0.08),
            SKAction.scale(to: 1.3, duration: 0.15)
        ])

        actions.append(SKAction.group([popIn, moveOut]))

        // Spin
        let spin = SKAction.rotate(byAngle: .pi * 2, duration: 0.3)
        actions.append(spin)

        // Settle and fade
        let settleAndFade = SKAction.group([
            SKAction.scale(to: 0.8, duration: 0.3),
            SKAction.sequence([
                SKAction.wait(forDuration: 0.2),
                SKAction.fadeOut(withDuration: 0.15)
            ])
        ])
        actions.append(settleAndFade)
        actions.append(SKAction.removeFromParent())

        particle.run(SKAction.sequence(actions))

        return particle
    }

    /// Spawn a falling particle (like sweat drops)
    /// - Parameters:
    ///   - texture: Texture for the particle
    ///   - size: Size of the particle
    ///   - startPosition: Starting position
    ///   - fallDistance: How far to fall
    ///   - horizontalDrift: Horizontal movement while falling
    ///   - duration: Fall duration
    ///   - rotation: Initial rotation angle
    ///   - parent: Parent node to add to
    @discardableResult
    static func spawnFalling(
        texture: SKTexture,
        size: CGSize,
        startPosition: CGPoint,
        fallDistance: CGFloat,
        horizontalDrift: CGFloat = 0,
        duration: TimeInterval = AnimationTimings.sweatDropFallDuration,
        rotation: CGFloat = 0,
        parent: SKNode
    ) -> SKSpriteNode {
        let particle = SKSpriteNode(texture: texture)
        particle.size = size
        particle.position = startPosition
        particle.alpha = 0
        particle.zPosition = SpriteZPositions.effects
        particle.setScale(0.8)
        particle.zRotation = rotation
        parent.addChild(particle)

        // Fade in
        let fadeIn = SKAction.fadeIn(withDuration: 0.08)

        // Fall down with easing
        let fall = SKAction.moveBy(x: horizontalDrift, y: -fallDistance, duration: duration)
        fall.timingMode = .easeIn

        // Fade out near end
        let fadeOut = SKAction.sequence([
            SKAction.wait(forDuration: duration * 0.6),
            SKAction.fadeOut(withDuration: duration * 0.4)
        ])

        let sequence = SKAction.sequence([
            fadeIn,
            SKAction.group([fall, fadeOut]),
            SKAction.removeFromParent()
        ])

        particle.run(sequence)

        return particle
    }
}
