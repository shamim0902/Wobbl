import SpriteKit

enum EyeExpression {
    case normal
    case wide        // scared
    case squint      // happy/hot
    case closed      // sleep/blink
    case spiral      // dizzy/vomit
    case xEyes       // very sick
}

final class PetEyesNode: SKNode {
    // Bigger, rounder sclera for cuter look
    private let leftSclera = SKShapeNode(ellipseOf: CGSize(width: 24, height: 30))
    private let rightSclera = SKShapeNode(ellipseOf: CGSize(width: 24, height: 30))
    private let leftPupil = SKShapeNode(circleOfRadius: 9.0)
    private let rightPupil = SKShapeNode(circleOfRadius: 9.0)
    // Primary highlight (top-right sparkle)
    private let leftHighlight = SKShapeNode(circleOfRadius: 3.5)
    private let rightHighlight = SKShapeNode(circleOfRadius: 3.5)
    // Secondary highlight (bottom-left dewiness)
    private let leftHighlight2 = SKShapeNode(circleOfRadius: 1.8)
    private let rightHighlight2 = SKShapeNode(circleOfRadius: 1.8)

    private var leftSpiral: SKShapeNode?
    private var rightSpiral: SKShapeNode?

    private var blinkTimer: Timer?
    private var currentExpression: EyeExpression = .normal
    private(set) var isLookingAround = false

    func setup() {
        leftSclera.position = CGPoint(x: -15, y: 8)
        rightSclera.position = CGPoint(x: 15, y: 8)

        leftSclera.fillColor = ColorPalette.sclera
        leftSclera.strokeColor = .clear
        rightSclera.fillColor = ColorPalette.sclera
        rightSclera.strokeColor = .clear

        leftPupil.fillColor = ColorPalette.pupil
        leftPupil.strokeColor = .clear
        leftPupil.position = CGPoint(x: 0, y: -1)
        rightPupil.fillColor = ColorPalette.pupil
        rightPupil.strokeColor = .clear
        rightPupil.position = CGPoint(x: 0, y: -1)

        leftHighlight.fillColor = ColorPalette.highlight
        leftHighlight.strokeColor = .clear
        leftHighlight.position = CGPoint(x: 3, y: 4)
        rightHighlight.fillColor = ColorPalette.highlight
        rightHighlight.strokeColor = .clear
        rightHighlight.position = CGPoint(x: 3, y: 4)

        leftHighlight2.fillColor = SKColor(white: 1.0, alpha: 0.65)
        leftHighlight2.strokeColor = .clear
        leftHighlight2.position = CGPoint(x: -3, y: -3)
        rightHighlight2.fillColor = SKColor(white: 1.0, alpha: 0.65)
        rightHighlight2.strokeColor = .clear
        rightHighlight2.position = CGPoint(x: -3, y: -3)

        leftSclera.addChild(leftPupil)
        leftPupil.addChild(leftHighlight)
        leftPupil.addChild(leftHighlight2)
        rightSclera.addChild(rightPupil)
        rightPupil.addChild(rightHighlight)
        rightPupil.addChild(rightHighlight2)

        addChild(leftSclera)
        addChild(rightSclera)

        startBlinking()
        startEyeShimmer()
    }

    // MARK: - Eye Shimmer (permanent subtle sparkle)

    private func startEyeShimmer() {
        // Primary highlights: gentle pulse
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.35, duration: 1.4),
            SKAction.scale(to: 0.9, duration: 1.4),
        ])
        pulse.timingMode = .easeInEaseOut
        leftHighlight.run(.repeatForever(pulse))
        // Slightly offset phase for the right eye
        rightHighlight.run(.sequence([
            SKAction.wait(forDuration: 0.7),
            .repeatForever(pulse),
        ]))

        // Secondary highlights: slower counter-pulse for depth
        let pulse2 = SKAction.sequence([
            SKAction.scale(to: 0.7, duration: 1.8),
            SKAction.scale(to: 1.25, duration: 1.8),
        ])
        pulse2.timingMode = .easeInEaseOut
        leftHighlight2.run(.repeatForever(pulse2))
        rightHighlight2.run(.repeatForever(pulse2))
    }

    func setExpression(_ expression: EyeExpression) {
        guard expression != currentExpression else { return }
        currentExpression = expression

        leftSpiral?.removeFromParent()
        rightSpiral?.removeFromParent()
        leftSpiral = nil
        rightSpiral = nil

        leftPupil.isHidden = false
        rightPupil.isHidden = false

        switch expression {
        case .normal:
            animateScleraScale(yScale: 1.0)
            leftPupil.run(SKAction.scale(to: 1.0, duration: 0.15))
            rightPupil.run(SKAction.scale(to: 1.0, duration: 0.15))
        case .wide:
            animateScleraScale(yScale: 1.3)
            leftPupil.run(SKAction.scale(to: 0.7, duration: 0.15))
            rightPupil.run(SKAction.scale(to: 0.7, duration: 0.15))
        case .squint:
            animateScleraScale(yScale: 0.5)
        case .closed:
            animateScleraScale(yScale: 0.06)
        case .spiral:
            leftPupil.isHidden = true
            rightPupil.isHidden = true
            addSpiralEyes()
        case .xEyes:
            leftPupil.isHidden = true
            rightPupil.isHidden = true
            addXEyes()
        }
    }

    // MARK: - Blinking (less frequent, occasionally double)

    func startBlinking() {
        scheduleBlink()
    }

    func stopBlinking() {
        blinkTimer?.invalidate()
        blinkTimer = nil
        // Cancel any in-flight blink animation so expression changes land cleanly
        leftSclera.removeAllActions()
        rightSclera.removeAllActions()
    }

    private func scheduleBlink() {
        let interval = TimeInterval.random(in: 8.0...18.0)
        blinkTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.performBlink()
        }
    }

    private func performBlink() {
        guard currentExpression == .normal || currentExpression == .squint else {
            scheduleBlink()
            return
        }

        let isDoubleBlink = Int.random(in: 0..<4) == 0

        let close = SKAction.scaleY(to: 0.06, duration: 0.08)
        let hold = SKAction.wait(forDuration: 0.08)
        let open = SKAction.scaleY(to: 1.0, duration: 0.12)
        var sequence: [SKAction] = [close, hold, open]

        if isDoubleBlink {
            let halfOpen = SKAction.scaleY(to: 0.55, duration: 0.07)
            let closeAgain = SKAction.scaleY(to: 0.06, duration: 0.06)
            let holdAgain = SKAction.wait(forDuration: 0.06)
            let openFinal = SKAction.scaleY(to: 1.0, duration: 0.12)
            sequence += [halfOpen, closeAgain, holdAgain, openFinal]
        }

        let blink = SKAction.sequence(sequence)
        leftSclera.run(blink)
        rightSclera.run(blink) { [weak self] in
            self?.scheduleBlink()
        }
    }

    // MARK: - Mouse Tracking

    func trackPoint(_ point: CGPoint) {
        // Skip if another eye behavior is running
        guard !isLookingAround else { return }
        guard currentExpression == .normal || currentExpression == .wide || currentExpression == .squint else { return }

        let maxOffset: CGFloat = 5.0
        let restY: CGFloat = -1.0

        let toLeftEye = CGPoint(x: point.x - (-15), y: point.y - 8)
        let leftDist = sqrt(toLeftEye.x * toLeftEye.x + toLeftEye.y * toLeftEye.y)
        let leftScale = min(leftDist / 100.0, 1.0)
        let leftOffsetX = leftDist > 0.1 ? (toLeftEye.x / leftDist) * maxOffset * leftScale : 0
        let leftOffsetY = leftDist > 0.1 ? (toLeftEye.y / leftDist) * maxOffset * leftScale : 0

        let toRightEye = CGPoint(x: point.x - 15, y: point.y - 8)
        let rightDist = sqrt(toRightEye.x * toRightEye.x + toRightEye.y * toRightEye.y)
        let rightScale = min(rightDist / 100.0, 1.0)
        let rightOffsetX = rightDist > 0.1 ? (toRightEye.x / rightDist) * maxOffset * rightScale : 0
        let rightOffsetY = rightDist > 0.1 ? (toRightEye.y / rightDist) * maxOffset * rightScale : 0

        let smoothing: CGFloat = 0.25
        leftPupil.position = CGPoint(
            x: leftPupil.position.x + (leftOffsetX - leftPupil.position.x) * smoothing,
            y: leftPupil.position.y + ((restY + leftOffsetY) - leftPupil.position.y) * smoothing
        )
        rightPupil.position = CGPoint(
            x: rightPupil.position.x + (rightOffsetX - rightPupil.position.x) * smoothing,
            y: rightPupil.position.y + ((restY + rightOffsetY) - rightPupil.position.y) * smoothing
        )
    }

    // MARK: - Look Around (idle wander)

    func startLookAround() {
        guard !isLookingAround else { return }
        isLookingAround = true

        let positions: [CGPoint] = [
            CGPoint(x: -4, y: 1),
            CGPoint(x: 4, y: 1),
            CGPoint(x: 0, y: 3),
            CGPoint(x: 3, y: -1),
            CGPoint(x: -3, y: -1),
            CGPoint(x: 1, y: 2),
            CGPoint(x: 0, y: -1),
        ]

        var actions: [SKAction] = []
        for pos in positions.shuffled() {
            let moveDuration = TimeInterval.random(in: 0.6...1.3)
            let holdDuration = TimeInterval.random(in: 0.5...1.4)
            let move = SKAction.move(to: pos, duration: moveDuration)
            move.timingMode = .easeInEaseOut
            actions.append(move)
            actions.append(SKAction.wait(forDuration: holdDuration))
        }

        let seq = SKAction.repeatForever(SKAction.sequence(actions))
        leftPupil.run(seq, withKey: "lookAround")
        rightPupil.run(seq, withKey: "lookAround")
    }

    func stopLookAround() {
        guard isLookingAround else { return }
        isLookingAround = false
        leftPupil.removeAction(forKey: "lookAround")
        rightPupil.removeAction(forKey: "lookAround")
        returnPupilsToCenter()
    }

    func returnPupilsToCenter() {
        let move = SKAction.move(to: CGPoint(x: 0, y: -1), duration: 0.4)
        move.timingMode = .easeInEaseOut
        leftPupil.run(move)
        rightPupil.run(move)
    }

    // MARK: - Pupil Drift

    func driftPupils(to offset: CGPoint, duration: TimeInterval = 0.5) {
        let clampedX = max(-3, min(3, offset.x))
        let clampedY = max(-3, min(3, offset.y))
        let move = SKAction.move(to: CGPoint(x: clampedX, y: -1 + clampedY), duration: duration)
        move.timingMode = .easeInEaseOut
        leftPupil.run(move)
        rightPupil.run(move)
    }

    // MARK: - Helpers

    private func animateScleraScale(yScale: CGFloat, duration: TimeInterval = 0.15) {
        let action = SKAction.scaleY(to: yScale, duration: duration)
        action.timingMode = .easeInEaseOut
        leftSclera.run(action)
        rightSclera.run(action)
    }

    private func addSpiralEyes() {
        let left = createSpiralNode()
        left.position = .zero
        leftSclera.addChild(left)
        leftSpiral = left

        let right = createSpiralNode()
        right.position = .zero
        rightSclera.addChild(right)
        rightSpiral = right

        let spin = SKAction.rotate(byAngle: .pi * 2, duration: 0.6)
        left.run(.repeatForever(spin))
        right.run(.repeatForever(spin))
    }

    private func addXEyes() {
        let left = createXNode()
        left.position = .zero
        leftSclera.addChild(left)
        leftSpiral = left

        let right = createXNode()
        right.position = .zero
        rightSclera.addChild(right)
        rightSpiral = right
    }

    private func createSpiralNode() -> SKShapeNode {
        let path = CGMutablePath()
        let turns: CGFloat = 2.5
        let maxRadius: CGFloat = 5.0
        let steps = 60

        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let angle = t * turns * 2.0 * .pi
            let r = t * maxRadius
            let x = cos(angle) * r
            let y = sin(angle) * r
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }

        let node = SKShapeNode(path: path)
        node.strokeColor = ColorPalette.pupil
        node.lineWidth = 1.5
        node.fillColor = .clear
        return node
    }

    private func createXNode() -> SKShapeNode {
        let path = CGMutablePath()
        let s: CGFloat = 4.0
        path.move(to: CGPoint(x: -s, y: -s))
        path.addLine(to: CGPoint(x: s, y: s))
        path.move(to: CGPoint(x: s, y: -s))
        path.addLine(to: CGPoint(x: -s, y: s))

        let node = SKShapeNode(path: path)
        node.strokeColor = ColorPalette.pupil
        node.lineWidth = 2.0
        return node
    }
}
