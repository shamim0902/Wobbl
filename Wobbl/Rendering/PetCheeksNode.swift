import SpriteKit

final class PetCheeksNode: SKNode {
    private let leftCheek = SKShapeNode(circleOfRadius: 7.0)
    private let rightCheek = SKShapeNode(circleOfRadius: 7.0)

    func setup() {
        leftCheek.position = CGPoint(x: -26, y: -3)
        rightCheek.position = CGPoint(x: 26, y: -3)

        leftCheek.fillColor = ColorPalette.blush
        leftCheek.strokeColor = .clear
        leftCheek.alpha = 1.0

        rightCheek.fillColor = ColorPalette.blush
        rightCheek.strokeColor = .clear
        rightCheek.alpha = 1.0

        addChild(leftCheek)
        addChild(rightCheek)
    }

    func setBlushIntensity(_ intensity: CGFloat, color: SKColor? = nil) {
        let blushColor = color ?? ColorPalette.blush
        let alpha = 0.3 + min(intensity, 1.0) * 0.5
        let adjustedColor = blushColor.withAlphaComponent(alpha)

        leftCheek.fillColor = adjustedColor
        rightCheek.fillColor = adjustedColor
    }

    func animateBlush(to intensity: CGFloat, color: SKColor? = nil, duration: TimeInterval = 0.3) {
        let blushColor = color ?? ColorPalette.blush
        let alpha = 0.3 + min(intensity, 1.0) * 0.5
        let targetColor = blushColor.withAlphaComponent(alpha)

        let action = SKAction.customAction(withDuration: duration) { node, _ in
            (node as? SKShapeNode)?.fillColor = targetColor
        }
        leftCheek.run(action)
        rightCheek.run(action)
    }
}
