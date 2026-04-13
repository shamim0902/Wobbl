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
    private let leftSclera = SKShapeNode(ellipseOf: CGSize(width: 22, height: 26))
    private let rightSclera = SKShapeNode(ellipseOf: CGSize(width: 22, height: 26))
    private let leftPupil = SKShapeNode(circleOfRadius: 7.0)
    private let rightPupil = SKShapeNode(circleOfRadius: 7.0)
    private let leftHighlight = SKShapeNode(circleOfRadius: 2.5)
    private let rightHighlight = SKShapeNode(circleOfRadius: 2.5)

    // For spiral eyes (dizzy/vomit)
    private var leftSpiral: SKShapeNode?
    private var rightSpiral: SKShapeNode?

    private var blinkTimer: Timer?
    private var currentExpression: EyeExpression = .normal

    func setup() {
        // Position eyes (wider apart for larger square body)
        leftSclera.position = CGPoint(x: -15, y: 8)
        rightSclera.position = CGPoint(x: 15, y: 8)

        // Style sclera
        leftSclera.fillColor = ColorPalette.sclera
        leftSclera.strokeColor = .clear
        rightSclera.fillColor = ColorPalette.sclera
        rightSclera.strokeColor = .clear

        // Style pupils
        leftPupil.fillColor = ColorPalette.pupil
        leftPupil.strokeColor = .clear
        leftPupil.position = CGPoint(x: 0, y: -1)
        rightPupil.fillColor = ColorPalette.pupil
        rightPupil.strokeColor = .clear
        rightPupil.position = CGPoint(x: 0, y: -1)

        // Style highlights (sparkle in eyes)
        leftHighlight.fillColor = ColorPalette.highlight
        leftHighlight.strokeColor = .clear
        leftHighlight.position = CGPoint(x: 2.5, y: 3)
        rightHighlight.fillColor = ColorPalette.highlight
        rightHighlight.strokeColor = .clear
        rightHighlight.position = CGPoint(x: 2.5, y: 3)

        // Build hierarchy
        leftSclera.addChild(leftPupil)
        leftPupil.addChild(leftHighlight)
        rightSclera.addChild(rightPupil)
        rightPupil.addChild(rightHighlight)

        addChild(leftSclera)
        addChild(rightSclera)

        startBlinking()
    }

    func setExpression(_ expression: EyeExpression) {
        guard expression != currentExpression else { return }
        currentExpression = expression

        // Remove spirals if switching away
        leftSpiral?.removeFromParent()
        rightSpiral?.removeFromParent()
        leftSpiral = nil
        rightSpiral = nil

        // Show normal pupils
        leftPupil.isHidden = false
        rightPupil.isHidden = false

        switch expression {
        case .normal:
            animateScleraScale(yScale: 1.0)
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

    // MARK: - Blinking

    func startBlinking() {
        scheduleBlink()
    }

    func stopBlinking() {
        blinkTimer?.invalidate()
        blinkTimer = nil
    }

    private func scheduleBlink() {
        let interval = TimeInterval.random(in: 3.0...7.0)
        blinkTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.performBlink()
        }
    }

    private func performBlink() {
        guard currentExpression == .normal || currentExpression == .squint else {
            scheduleBlink()
            return
        }

        let close = SKAction.scaleY(to: 0.06, duration: 0.07)
        let hold = SKAction.wait(forDuration: 0.10)
        let open = SKAction.scaleY(to: 1.0, duration: 0.07)
        let blink = SKAction.sequence([close, hold, open])

        leftSclera.run(blink)
        rightSclera.run(blink) { [weak self] in
            self?.scheduleBlink()
        }
    }

    // MARK: - Mouse Tracking

    /// Move pupils to look toward a point in the body node's coordinate space.
    func trackPoint(_ point: CGPoint) {
        guard currentExpression == .normal || currentExpression == .wide || currentExpression == .squint else {
            return  // Don't track during spiral/closed/xEyes
        }

        let maxOffset: CGFloat = 5.0  // Max pixels the pupil can move from center
        let restY: CGFloat = -1.0     // Resting Y position of pupils

        // Calculate offset for left eye (position: x=-15, y=8)
        let toLeftEye = CGPoint(x: point.x - (-15), y: point.y - 8)
        let leftDist = sqrt(toLeftEye.x * toLeftEye.x + toLeftEye.y * toLeftEye.y)
        let leftScale = min(leftDist / 100.0, 1.0)  // Normalize: 100pt = full offset
        let leftOffsetX = (leftDist > 0.1) ? (toLeftEye.x / leftDist) * maxOffset * leftScale : 0
        let leftOffsetY = (leftDist > 0.1) ? (toLeftEye.y / leftDist) * maxOffset * leftScale : 0

        // Calculate offset for right eye (position: x=15, y=8)
        let toRightEye = CGPoint(x: point.x - 15, y: point.y - 8)
        let rightDist = sqrt(toRightEye.x * toRightEye.x + toRightEye.y * toRightEye.y)
        let rightScale = min(rightDist / 100.0, 1.0)
        let rightOffsetX = (rightDist > 0.1) ? (toRightEye.x / rightDist) * maxOffset * rightScale : 0
        let rightOffsetY = (rightDist > 0.1) ? (toRightEye.y / rightDist) * maxOffset * rightScale : 0

        // Move pupils smoothly (no action — direct position for responsiveness)
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

    // MARK: - Pupil Drift (fallback when not tracking)

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
