import SpriteKit

// Idle animation action factories
// These are used by PetScene.startIdleAnimations() and can be reused
// when transitioning back to idle/happy states.

enum IdleAnimations {
    static func breathing() -> SKAction {
        let up = SKAction.scaleY(to: 1.03, duration: 1.25)
        up.timingMode = .easeInEaseOut
        let down = SKAction.scaleY(to: 0.97, duration: 1.25)
        down.timingMode = .easeInEaseOut
        return .repeatForever(.sequence([up, down]))
    }

    static func bobbing() -> SKAction {
        let up = SKAction.moveBy(x: 0, y: 1.5, duration: 1.25)
        up.timingMode = .easeInEaseOut
        let down = SKAction.moveBy(x: 0, y: -1.5, duration: 1.25)
        down.timingMode = .easeInEaseOut
        return .repeatForever(.sequence([up, down]))
    }
}
