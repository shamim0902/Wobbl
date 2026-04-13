import SpriteKit

enum MouthShape {
    case smile
    case neutral
    case frown
    case openSmall   // surprise
    case openWide    // vomit/yawn
    case wavy        // sick/nauseous
    case pant        // hot - alternating open/close
}

final class PetMouthNode: SKShapeNode {
    private var currentShape: MouthShape = .smile

    func setup() {
        strokeColor = ColorPalette.mouth
        fillColor = .clear
        lineWidth = 2.0
        lineCap = .round
        position = CGPoint(x: 0, y: -14)
        isAntialiased = true
        setShape(.smile, animated: false)
    }

    func setShape(_ shape: MouthShape, animated: Bool = true) {
        currentShape = shape
        let newPath = mouthPath(for: shape)

        if animated {
            // Simple fade transition
            let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 0.08)
            let changePath = SKAction.run { [weak self] in
                self?.path = newPath
                self?.fillColor = self?.fillColorFor(shape) ?? .clear
            }
            let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.08)
            run(SKAction.sequence([fadeOut, changePath, fadeIn]))
        } else {
            path = newPath
            fillColor = fillColorFor(shape)
        }
    }

    private func mouthPath(for shape: MouthShape) -> CGPath {
        let p = CGMutablePath()

        switch shape {
        case .smile:
            p.move(to: CGPoint(x: -9, y: 0))
            p.addQuadCurve(to: CGPoint(x: 9, y: 0), control: CGPoint(x: 0, y: -8))

        case .neutral:
            p.move(to: CGPoint(x: -7, y: 0))
            p.addLine(to: CGPoint(x: 7, y: 0))

        case .frown:
            p.move(to: CGPoint(x: -9, y: -2))
            p.addQuadCurve(to: CGPoint(x: 9, y: -2), control: CGPoint(x: 0, y: 5))

        case .openSmall:
            p.addEllipse(in: CGRect(x: -5, y: -5, width: 10, height: 9))

        case .openWide:
            p.addEllipse(in: CGRect(x: -8, y: -6, width: 16, height: 12))

        case .wavy:
            p.move(to: CGPoint(x: -10, y: 0))
            p.addCurve(
                to: CGPoint(x: 10, y: 0),
                control1: CGPoint(x: -4, y: -6),
                control2: CGPoint(x: 4, y: 6)
            )

        case .pant:
            p.addEllipse(in: CGRect(x: -6, y: -4, width: 12, height: 8))
        }

        return p
    }

    private func fillColorFor(_ shape: MouthShape) -> SKColor {
        switch shape {
        case .openSmall, .openWide, .pant:
            return ColorPalette.mouth
        default:
            return .clear
        }
    }
}
