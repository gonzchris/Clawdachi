//
//  ParticleSpawner.swift
//  Clawdachi
//
//  Reusable particle effect spawning utilities with object pooling
//

import SpriteKit

// MARK: - Particle Pool

/// Object pool for reusing particle sprite nodes to reduce memory churn
/// Note: All operations must be called from the main thread (SpriteKit requirement)
final class ParticlePool {

    /// Shared pool instance
    static let shared = ParticlePool()

    /// Pool of available (unused) particles
    private var availableParticles: [SKSpriteNode] = []

    /// Maximum pool size to prevent unbounded growth
    private let maxPoolSize = 20

    private init() {
        // Pre-allocate some particles
        for _ in 0..<10 {
            availableParticles.append(createParticle())
        }
    }

    /// Get a particle from the pool (or create a new one if empty)
    /// Must be called from main thread
    func acquire() -> SKSpriteNode {
        if let particle = availableParticles.popLast() {
            // Ensure particle is detached before reuse
            particle.removeFromParent()
            return particle
        }
        return createParticle()
    }

    /// Return a particle to the pool for reuse
    /// Must be called from main thread (use DispatchQueue.main.async if needed)
    func release(_ particle: SKSpriteNode) {
        // Reset particle state
        particle.removeAllActions()
        particle.removeFromParent()
        particle.texture = nil
        particle.alpha = 1
        particle.position = .zero
        particle.zPosition = 0
        particle.setScale(1)
        particle.zRotation = 0
        particle.size = CGSize(width: 1, height: 1)

        // Only keep up to maxPoolSize particles
        if availableParticles.count < maxPoolSize {
            availableParticles.append(particle)
        }
        // Otherwise, let the particle be deallocated
    }

    private func createParticle() -> SKSpriteNode {
        SKSpriteNode()
    }
}

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
    /// Uses object pooling to reduce memory churn
    /// - Parameters:
    ///   - config: Configuration for the particle
    ///   - parent: The node to add the particle to
    /// - Returns: The created sprite node (for further customization if needed)
    @discardableResult
    static func spawn(config: ParticleConfig, in parent: SKNode) -> SKSpriteNode {
        // Get particle from pool instead of creating new one
        let particle = ParticlePool.shared.acquire()
        particle.texture = config.texture
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

        // Return particle to pool instead of removing
        // Use async dispatch to ensure action sequence completes before release
        actions.append(SKAction.run { [weak particle] in
            guard let particle = particle else { return }
            DispatchQueue.main.async {
                ParticlePool.shared.release(particle)
            }
        })

        particle.run(SKAction.sequence(actions))

        return particle
    }

    /// Spawn a falling particle (like sweat drops)
    /// Uses object pooling to reduce memory churn
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
        let particle = ParticlePool.shared.acquire()
        particle.texture = texture
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
            SKAction.run { [weak particle] in
                guard let particle = particle else { return }
                DispatchQueue.main.async {
                    ParticlePool.shared.release(particle)
                }
            }
        ])

        particle.run(sequence)

        return particle
    }

    // MARK: - Preset-Based Spawning

    /// Spawn a music note particle (floating up with wobble)
    /// - Parameters:
    ///   - texture: Music note texture
    ///   - variation: Path variation (0, 1, or 2 for different trajectories)
    ///   - delay: Delay before spawning
    ///   - parent: Parent node to add to
    @discardableResult
    static func spawnMusicNote(
        texture: SKTexture,
        variation: Int = 0,
        delay: TimeInterval = 0,
        parent: SKNode
    ) -> SKSpriteNode {
        let paths: [(dx: CGFloat, dy: CGFloat, rotation: CGFloat)] = [
            (5, 12, 0.3),
            (7, 10, -0.2),
            (4, 14, 0.4)
        ]
        let path = paths[variation % paths.count]

        let config = ParticleConfig(
            texture: texture,
            size: CGSize(width: 8, height: 8),
            startPosition: CGPoint(x: 5, y: -3),
            zPosition: SpriteZPositions.effects,
            initialScale: 0.5,
            targetScale: 0.9,
            popInDuration: 0.12,
            movementDuration: 1.0,
            movementDelta: CGPoint(x: path.dx, y: path.dy),
            rotation: path.rotation,
            fadeOutDuration: 0.25,
            delay: delay,
            movementEasing: .easeOut
        )

        return spawn(config: config, in: parent)
    }

    /// Spawn a heart particle (floating up with pulse)
    /// Uses object pooling to reduce memory churn
    /// - Parameters:
    ///   - texture: Heart texture
    ///   - offsetX: Horizontal offset from center
    ///   - offsetY: Vertical offset from center
    ///   - size: Size multiplier (1.0 = normal)
    ///   - delay: Delay before spawning
    ///   - parent: Parent node to add to
    @discardableResult
    static func spawnHeart(
        texture: SKTexture,
        offsetX: CGFloat = 0,
        offsetY: CGFloat = 10,
        size: CGFloat = 1.0,
        delay: TimeInterval = 0,
        parent: SKNode
    ) -> SKSpriteNode {
        let heart = ParticlePool.shared.acquire()
        heart.texture = texture
        heart.size = CGSize(width: 12 * size, height: 12 * size)
        heart.position = CGPoint(x: offsetX, y: offsetY)
        heart.alpha = 0
        heart.zPosition = SpriteZPositions.effects + 1
        heart.setScale(0.3)
        parent.addChild(heart)

        var actions: [SKAction] = []

        if delay > 0 {
            actions.append(SKAction.wait(forDuration: delay))
        }

        // Pop in with overshoot
        let popIn = SKAction.group([
            SKAction.fadeIn(withDuration: 0.1),
            SKAction.scale(to: size * 1.3, duration: 0.15)
        ])

        let settleScale = SKAction.scale(to: size, duration: 0.1)
        settleScale.timingMode = .easeInEaseOut

        actions.append(popIn)
        actions.append(settleScale)

        // Float up with gentle sway and pulse
        let floatDuration: TimeInterval = 0.7
        let floatUp = SKAction.moveBy(x: CGFloat.random(in: -2...2), y: 8, duration: floatDuration)
        floatUp.timingMode = .easeOut

        let pulse = SKAction.sequence([
            SKAction.scale(to: size * 1.1, duration: 0.15),
            SKAction.scale(to: size * 0.95, duration: 0.15)
        ])

        let fadeOut = SKAction.sequence([
            SKAction.wait(forDuration: floatDuration - 0.2),
            SKAction.fadeOut(withDuration: 0.2)
        ])

        actions.append(SKAction.group([floatUp, pulse, fadeOut]))
        actions.append(SKAction.run { [weak heart] in
            guard let heart = heart else { return }
            DispatchQueue.main.async {
                ParticlePool.shared.release(heart)
            }
        })

        heart.run(SKAction.sequence(actions))
        return heart
    }

    /// Spawn a sleep Z particle (floating up, growing)
    /// Uses object pooling to reduce memory churn
    /// - Parameters:
    ///   - texture: Z texture
    ///   - parent: Parent node to add to
    @discardableResult
    static func spawnSleepZ(
        texture: SKTexture,
        parent: SKNode
    ) -> SKSpriteNode {
        let z = ParticlePool.shared.acquire()
        z.texture = texture
        z.size = CGSize(width: 12, height: 12)
        z.position = CGPoint(x: 7, y: 8)
        z.alpha = 0
        z.zPosition = SpriteZPositions.effects + 1
        z.setScale(0.4)
        parent.addChild(z)

        let fadeIn = SKAction.fadeIn(withDuration: 0.4)

        let floatUp = SKAction.moveBy(x: 6, y: 14, duration: 2.0)
        floatUp.timingMode = .easeOut

        let grow = SKAction.scale(to: 1.0, duration: 2.0)

        let wobble = SKAction.sequence([
            SKAction.rotate(byAngle: 0.15, duration: 1.0),
            SKAction.rotate(byAngle: -0.15, duration: 1.0)
        ])

        let floatSequence = SKAction.group([floatUp, grow, wobble])
        let fadeOut = SKAction.fadeOut(withDuration: 0.4)

        z.run(SKAction.sequence([fadeIn, floatSequence, fadeOut, SKAction.run { [weak z] in
            guard let z = z else { return }
            DispatchQueue.main.async {
                ParticlePool.shared.release(z)
            }
        }]))

        return z
    }

    /// Spawn a sweat drop particle (falling down)
    /// - Parameters:
    ///   - texture: Sweat drop texture
    ///   - isLeftSide: Whether to spawn on left side (affects angle and drift)
    ///   - parent: Parent node to add to
    @discardableResult
    static func spawnSweatDrop(
        texture: SKTexture,
        isLeftSide: Bool,
        parent: SKNode
    ) -> SKSpriteNode {
        let xOffset: CGFloat = isLeftSide ? CGFloat.random(in: -8 ... -5) : CGFloat.random(in: 5...8)
        let horizontalDrift: CGFloat = isLeftSide ? -3 : 3
        let rotation: CGFloat = isLeftSide ? 0.2 : -0.2

        return spawnFalling(
            texture: texture,
            size: CGSize(width: 2, height: 4),
            startPosition: CGPoint(x: xOffset, y: 5),
            fallDistance: 22,
            horizontalDrift: horizontalDrift,
            duration: 0.5,
            rotation: rotation,
            parent: parent
        )
    }

    /// Spawn a smoke particle (floating up, expanding)
    /// Uses object pooling to reduce memory churn
    /// - Parameters:
    ///   - texture: Smoke texture
    ///   - startPosition: Where to spawn (typically near mouth)
    ///   - variation: 0, 1, or 2 for different trajectories
    ///   - delay: Delay before spawning
    ///   - parent: Parent node to add to
    @discardableResult
    static func spawnSmoke(
        texture: SKTexture,
        startPosition: CGPoint = CGPoint(x: 3, y: 2),
        variation: Int = 0,
        delay: TimeInterval = 0,
        parent: SKNode
    ) -> SKSpriteNode {
        // Different smoke paths for variety
        let paths: [(dx: CGFloat, dy: CGFloat, rotation: CGFloat)] = [
            (CGFloat.random(in: -2...2), CGFloat.random(in: 10...14), 0.3),
            (CGFloat.random(in: -3...1), CGFloat.random(in: 9...12), -0.2),
            (CGFloat.random(in: 0...4), CGFloat.random(in: 11...15), 0.4)
        ]
        let path = paths[variation % paths.count]

        let smoke = ParticlePool.shared.acquire()
        smoke.texture = texture
        smoke.size = CGSize(width: 6, height: 6)
        smoke.position = startPosition
        smoke.alpha = 0
        smoke.zPosition = SpriteZPositions.effects
        smoke.setScale(0.4)
        parent.addChild(smoke)

        var actions: [SKAction] = []

        if delay > 0 {
            actions.append(SKAction.wait(forDuration: delay))
        }

        // Fade in
        let fadeIn = SKAction.fadeAlpha(to: 0.7, duration: 0.15)
        actions.append(fadeIn)

        // Float up while expanding (smoke dissipates)
        let floatDuration = AnimationTimings.smokeFloatDuration
        let floatUp = SKAction.moveBy(x: path.dx, y: path.dy, duration: floatDuration)
        floatUp.timingMode = .easeOut

        // Smoke expands as it rises
        let expand = SKAction.scale(to: 1.4, duration: floatDuration)
        expand.timingMode = .easeOut

        // Wobble rotation
        let wobble = SKAction.sequence([
            SKAction.rotate(byAngle: path.rotation, duration: floatDuration / 2),
            SKAction.rotate(byAngle: -path.rotation, duration: floatDuration / 2)
        ])

        // Fade out near end
        let fadeOut = SKAction.sequence([
            SKAction.wait(forDuration: floatDuration * 0.5),
            SKAction.fadeOut(withDuration: floatDuration * 0.5)
        ])

        actions.append(SKAction.group([floatUp, expand, wobble, fadeOut]))
        actions.append(SKAction.run { [weak smoke] in
            guard let smoke = smoke else { return }
            DispatchQueue.main.async {
                ParticlePool.shared.release(smoke)
            }
        })

        smoke.run(SKAction.sequence(actions))

        return smoke
    }
}
