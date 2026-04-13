import SpriteKit

// Reaction animation action factories for various pet states.
// These are called by AnimationController when transitioning to reactive states.

enum ReactionAnimations {
    static func vomitWobble() -> SKAction {
        let wobble = SKAction.sequence([
            SKAction.rotate(byAngle: 0.05, duration: 0.1),
            SKAction.rotate(byAngle: -0.10, duration: 0.1),
            SKAction.rotate(byAngle: 0.05, duration: 0.1),
        ])
        return .repeatForever(wobble)
    }

    static func shiverVibration() -> SKAction {
        let shiver = SKAction.sequence([
            SKAction.moveBy(x: 1.5, y: 0, duration: 0.04),
            SKAction.moveBy(x: -3, y: 0, duration: 0.04),
            SKAction.moveBy(x: 1.5, y: 0, duration: 0.04),
        ])
        return .repeatForever(shiver)
    }

    static func scaredSquish() -> SKAction {
        return SKAction.sequence([
            SKAction.scaleY(to: 0.7, duration: 0.08),
            SKAction.scaleY(to: 1.15, duration: 0.12),
            SKAction.scaleY(to: 1.0, duration: 0.15),
        ])
    }

    static func scaredTremble() -> SKAction {
        let tremble = SKAction.sequence([
            SKAction.moveBy(x: 1, y: 0.5, duration: 0.03),
            SKAction.moveBy(x: -2, y: -1, duration: 0.03),
            SKAction.moveBy(x: 1, y: 0.5, duration: 0.03),
        ])
        return .repeatForever(tremble)
    }

    static func dizzySway() -> SKAction {
        let sway = SKAction.sequence([
            SKAction.moveBy(x: 3, y: 0, duration: 0.4),
            SKAction.moveBy(x: -6, y: 0, duration: 0.8),
            SKAction.moveBy(x: 3, y: 0, duration: 0.4),
        ])
        sway.timingMode = .easeInEaseOut
        return .repeatForever(sway)
    }
}
