import SpriteKit

// Transition helper animations for smooth state changes.

enum TransitionAnimations {
    static func colorFade(to color: SKColor, duration: TimeInterval = 0.4) -> SKAction {
        SKAction.colorize(with: color, colorBlendFactor: 1.0, duration: duration)
    }

    static func resetRotation(duration: TimeInterval = 0.3) -> SKAction {
        SKAction.rotate(toAngle: 0, duration: duration)
    }

    static func resetScale(duration: TimeInterval = 0.2) -> SKAction {
        SKAction.group([
            SKAction.scaleX(to: 1.0, duration: duration),
            SKAction.scaleY(to: 1.0, duration: duration),
        ])
    }
}
