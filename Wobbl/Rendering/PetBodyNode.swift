import SpriteKit

final class PetBodyNode: SKShapeNode {
    private let baseRadius: CGFloat = 55.0
    private(set) var wobblePhase: CGFloat = 0.0

    func setup() {
        path = BlobShapeGenerator.blobPath(radius: baseRadius, wobblePhase: 0)
        fillColor = ColorPalette.normalBody.withAlphaComponent(0.92)
        strokeColor = ColorPalette.normalStroke.withAlphaComponent(1.0)
        lineWidth = 2.5
        glowWidth = 0
        isAntialiased = true
    }

    func updateWobble(phase: CGFloat) {
        wobblePhase = phase
        path = BlobShapeGenerator.blobPath(radius: baseRadius, wobblePhase: phase)
    }

    func applySquish(factor: CGFloat, angle: CGFloat = 0) {
        path = BlobShapeGenerator.blobPath(
            radius: baseRadius,
            squish: factor,
            squishAngle: angle,
            wobblePhase: wobblePhase
        )
    }

    func transitionColor(to color: SKColor, duration: TimeInterval = 0.5) {
        let targetFill = color.withAlphaComponent(0.92)
        let targetStroke = color.withAlphaComponent(1.0)
        run(SKAction.customAction(withDuration: duration) { [weak self] _, elapsed in
            guard let self = self else { return }
            let t = elapsed / CGFloat(duration)
            self.fillColor = self.interpolateColor(from: self.fillColor, to: targetFill, t: t)
            self.strokeColor = self.interpolateColor(from: self.strokeColor, to: targetStroke, t: t)
        })
    }

    private func interpolateColor(from: SKColor, to: SKColor, t: CGFloat) -> SKColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        from.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        to.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return SKColor(
            red: r1 + (r2 - r1) * t,
            green: g1 + (g2 - g1) * t,
            blue: b1 + (b2 - b1) * t,
            alpha: a1 + (a2 - a1) * t
        )
    }
}
