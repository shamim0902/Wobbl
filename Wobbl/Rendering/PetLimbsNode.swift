import SpriteKit

final class PetLimbsNode: SKNode {
    // Arms: upper segment from shoulder, forearm hangs
    private let leftUpperArm = SKShapeNode()
    private let leftForearm = SKShapeNode()
    private let rightUpperArm = SKShapeNode()
    private let rightForearm = SKShapeNode()

    // Gloves at the end of each forearm
    private let leftGlove = SKShapeNode()
    private let rightGlove = SKShapeNode()

    // Legs: thigh from hip, shin hangs
    private let leftThigh = SKShapeNode()
    private let leftShin = SKShapeNode()
    private let rightThigh = SKShapeNode()
    private let rightShin = SKShapeNode()

    // Shoes at the end of each shin
    private let leftShoe = SKShapeNode()
    private let rightShoe = SKShapeNode()

    // Joint pivot nodes (rotation happens here)
    private let leftShoulder = SKNode()
    private let rightShoulder = SKNode()
    private let leftHip = SKNode()
    private let rightHip = SKNode()
    private let leftKnee = SKNode()
    private let rightKnee = SKNode()
    private let leftElbow = SKNode()
    private let rightElbow = SKNode()
    private let leftWrist = SKNode()
    private let rightWrist = SKNode()
    private let leftAnkle = SKNode()
    private let rightAnkle = SKNode()

    // Dimensions
    private let armLength: CGFloat = 18.0
    private let forearmLength: CGFloat = 18.0
    private let thighLength: CGFloat = 32.0
    private let shinLength: CGFloat = 28.0
    private let limbWidth: CGFloat = 3.0
    private let limbColor = SKColor(red: 0.15, green: 0.10, blue: 0.20, alpha: 0.9)
    private let gloveColor = SKColor(red: 0.18, green: 0.12, blue: 0.26, alpha: 1.0)
    private let shoeColor = SKColor(red: 0.10, green: 0.07, blue: 0.16, alpha: 1.0)

    // Surfboard
    private let surfboard = SKShapeNode()

    private(set) var isWalking = false
    private var walkPhase: CGFloat = 0.0
    private var idleSwayWorkItem: DispatchWorkItem?
    private var boxingComboWorkItem: DispatchWorkItem?

    func setup() {
        // Limb line paths
        let armPath = makeLimbPath(length: armLength)
        let forearmPath = makeLimbPath(length: forearmLength)
        let thighPath = makeLimbPath(length: thighLength)
        let shinPath = makeLimbPath(length: shinLength)

        // Style stick limbs
        for limb in [leftUpperArm, leftForearm, rightUpperArm, rightForearm,
                     leftThigh, leftShin, rightThigh, rightShin] {
            limb.strokeColor = limbColor
            limb.lineWidth = limbWidth
            limb.lineCap = .round
        }

        leftUpperArm.path = armPath
        leftForearm.path = forearmPath
        rightUpperArm.path = armPath
        rightForearm.path = forearmPath
        leftThigh.path = thighPath
        leftShin.path = shinPath
        rightThigh.path = thighPath
        rightShin.path = shinPath

        // Gloves — bold filled ovals hanging from wrist
        let glovePath = CGPath(
            roundedRect: CGRect(x: -8, y: -13, width: 16, height: 13),
            cornerWidth: 7, cornerHeight: 7, transform: nil
        )
        for glove in [leftGlove, rightGlove] {
            glove.path = glovePath
            glove.fillColor = gloveColor
            glove.strokeColor = gloveColor
            glove.lineWidth = 1.0
        }

        // Shoes — rounded side-profile shape; toe points in +x (mirrors with xScale flip)
        let shoePath = CGPath(
            roundedRect: CGRect(x: -4, y: -8, width: 18, height: 8),
            cornerWidth: 4, cornerHeight: 4, transform: nil
        )
        for shoe in [leftShoe, rightShoe] {
            shoe.path = shoePath
            shoe.fillColor = shoeColor
            shoe.strokeColor = shoeColor
            shoe.lineWidth = 1.0
        }

        // ── Arm hierarchy ──────────────────────────────────────────
        // shoulder → upperArm → elbow → forearm → wrist → glove
        leftShoulder.position = CGPoint(x: -38, y: -10)
        leftShoulder.addChild(leftUpperArm)
        leftElbow.position = CGPoint(x: 0, y: -armLength)
        leftUpperArm.addChild(leftElbow)
        leftElbow.addChild(leftForearm)
        leftWrist.position = CGPoint(x: 0, y: -forearmLength)
        leftForearm.addChild(leftWrist)
        leftWrist.addChild(leftGlove)

        rightShoulder.position = CGPoint(x: 38, y: -10)
        rightShoulder.addChild(rightUpperArm)
        rightElbow.position = CGPoint(x: 0, y: -armLength)
        rightUpperArm.addChild(rightElbow)
        rightElbow.addChild(rightForearm)
        rightWrist.position = CGPoint(x: 0, y: -forearmLength)
        rightForearm.addChild(rightWrist)
        rightWrist.addChild(rightGlove)

        // ── Leg hierarchy ──────────────────────────────────────────
        // hip → thigh → knee → shin → ankle → shoe
        leftHip.position = CGPoint(x: -16, y: -50)
        leftHip.addChild(leftThigh)
        leftKnee.position = CGPoint(x: 0, y: -thighLength)
        leftThigh.addChild(leftKnee)
        leftKnee.addChild(leftShin)
        leftAnkle.position = CGPoint(x: 0, y: -shinLength)
        leftShin.addChild(leftAnkle)
        leftAnkle.addChild(leftShoe)

        rightHip.position = CGPoint(x: 16, y: -50)
        rightHip.addChild(rightThigh)
        rightKnee.position = CGPoint(x: 0, y: -thighLength)
        rightThigh.addChild(rightKnee)
        rightKnee.addChild(rightShin)
        rightAnkle.position = CGPoint(x: 0, y: -shinLength)
        rightShin.addChild(rightAnkle)
        rightAnkle.addChild(rightShoe)

        setupSurfboard()   // added first so it renders behind legs
        addChild(leftShoulder)
        addChild(rightShoulder)
        addChild(leftHip)
        addChild(rightHip)

        setStandingPose()
    }

    private func setupSurfboard() {
        // Surfboard: leaf shape — pointed at both ends, wider in the middle
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -46, y: 0))
        path.addCurve(to: CGPoint(x: 46, y: 0),
                      control1: CGPoint(x: -22, y: 10),
                      control2: CGPoint(x: 22, y: 10))
        path.addCurve(to: CGPoint(x: -46, y: 0),
                      control1: CGPoint(x: 22, y: -10),
                      control2: CGPoint(x: -22, y: -10))
        path.closeSubpath()

        surfboard.path = path
        surfboard.fillColor = .white
        surfboard.strokeColor = SKColor(red: 0.65, green: 0.82, blue: 0.95, alpha: 1.0)
        surfboard.lineWidth = 2.0
        // Deck stripe — a thin coloured line down the centre
        let stripe = SKShapeNode()
        let stripePath = CGMutablePath()
        stripePath.move(to: CGPoint(x: -30, y: 0))
        stripePath.addLine(to: CGPoint(x: 30, y: 0))
        stripe.path = stripePath
        stripe.strokeColor = SKColor(red: 0.55, green: 0.75, blue: 0.95, alpha: 0.7)
        stripe.lineWidth = 2.5
        stripe.lineCap = .round
        surfboard.addChild(stripe)

        surfboard.position = CGPoint(x: 0, y: -118)
        surfboard.zPosition = -1
        surfboard.isHidden = true
        addChild(surfboard)
    }

    private func makeLimbPath(length: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: 0, y: -length))
        return path
    }

    // MARK: - Poses

    func setStandingPose() {
        isWalking = false
        removeAction(forKey: "walkCycle")
        stopJointAnimations()

        // Spring-eased arm settle
        leftShoulder.run(SKAction.easedRotate(toAngle: 0.15, duration: 0.55, easing: { Easing.spring($0, damping: 0.5) }))
        rightShoulder.run(SKAction.easedRotate(toAngle: -0.15, duration: 0.55, easing: { Easing.spring($0, damping: 0.5) }))
        leftElbow.run(SKAction.easedRotate(toAngle: 0, duration: 0.45, easing: Easing.easeOutBack))
        rightElbow.run(SKAction.easedRotate(toAngle: 0, duration: 0.45, easing: Easing.easeOutBack))

        leftHip.run(SKAction.easedRotate(toAngle: 0, duration: 0.6, easing: { Easing.spring($0, damping: 0.5) }))
        rightHip.run(SKAction.easedRotate(toAngle: 0, duration: 0.6, easing: { Easing.spring($0, damping: 0.5) }))
        leftKnee.run(SKAction.easedRotate(toAngle: 0, duration: 0.45, easing: Easing.easeOutBack))
        rightKnee.run(SKAction.easedRotate(toAngle: 0, duration: 0.45, easing: Easing.easeOutBack))
        leftAnkle.run(SKAction.easedRotate(toAngle: 0, duration: 0.4, easing: Easing.easeOutBack))
        rightAnkle.run(SKAction.easedRotate(toAngle: 0, duration: 0.4, easing: Easing.easeOutBack))

        // Gentle arm sway + weight shift once joints settle
        let swayItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            // Arm sway synced to breathing harmonic (2.5s)
            let swayL = SKAction.sequence([
                SKAction.rotate(toAngle: 0.20, duration: 2.5),
                SKAction.rotate(toAngle: 0.10, duration: 2.5),
            ])
            let swayR = SKAction.sequence([
                SKAction.rotate(toAngle: -0.20, duration: 2.5),
                SKAction.rotate(toAngle: -0.10, duration: 2.5),
            ])
            swayL.timingMode = .easeInEaseOut
            swayR.timingMode = .easeInEaseOut
            self.leftShoulder.run(.repeatForever(swayL), withKey: "idleSway")
            self.rightShoulder.run(.repeatForever(swayR), withKey: "idleSway")

            // Subtle weight shift — slow alternating hip lean
            let weightL = SKAction.sequence([
                SKAction.rotate(toAngle:  0.06, duration: 3.5),
                SKAction.rotate(toAngle: -0.02, duration: 3.5),
            ])
            let weightR = SKAction.sequence([
                SKAction.rotate(toAngle: -0.06, duration: 3.5),
                SKAction.rotate(toAngle:  0.02, duration: 3.5),
            ])
            weightL.timingMode = .easeInEaseOut
            weightR.timingMode = .easeInEaseOut
            self.leftHip.run(.repeatForever(weightL), withKey: "idleSway")
            self.rightHip.run(.repeatForever(weightR), withKey: "idleSway")

            // Occasional hand fidget
            self.scheduleHandFidget()
        }
        idleSwayWorkItem = swayItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: swayItem)
    }

    private var fidgetWorkItem: DispatchWorkItem?

    private func scheduleHandFidget() {
        fidgetWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            let wrist = Bool.random() ? self.leftWrist : self.rightWrist
            let angle: CGFloat = Bool.random() ? 0.3 : -0.3
            wrist.run(.sequence([
                SKAction.easedRotate(toAngle: angle, duration: 0.35, easing: Easing.easeOutBack),
                SKAction.wait(forDuration: 0.2),
                SKAction.easedRotate(toAngle: 0, duration: 0.4, easing: Easing.easeOutBack),
            ]), withKey: "fidget")
            self.scheduleHandFidget()
        }
        fidgetWorkItem = item
        DispatchQueue.main.asyncAfter(
            deadline: .now() + TimeInterval.random(in: 10.0...20.0),
            execute: item
        )
    }

    // MARK: - Walking

    func startWalking(speed: CGFloat = 1.0) {
        guard !isWalking else { return }
        isWalking = true
        walkPhase = 0
        stopJointAnimations()

        let stepDuration = 0.35 / speed
        animateWalkCycle(stepDuration: stepDuration)
    }

    func stopWalking() {
        setStandingPose()
    }

    private func animateWalkCycle(stepDuration: TimeInterval) {
        // Leg/arm ranges — bigger swing + proper back-leg kick
        let legFwd: CGFloat  =  0.52   // forward thigh swing
        let legBack: CGFloat = -0.38   // backward thigh kick (was -0.135, now proper push-off)
        let kneeUp: CGFloat  =  0.44   // knee lift on the forward leg
        let kneePush: CGFloat = 0.16   // slight back-knee bend for push-off feel
        let armFwd: CGFloat  =  0.26   // gentle forward swing
        let armBack: CGFloat = -0.22   // gentle backward swing
        let elbowFwd: CGFloat = 0.18   // mild elbow bend coming forward
        let elbowBack: CGFloat = 0.05  // nearly straight going back
        let ankleFwd: CGFloat = -0.30  // ankle counter-rotates to keep foot flat
        let ankleBack: CGFloat = 0.18

        // Step 1: left leg forward, right leg back
        let step1 = SKAction.group([
            makeSwing(node: leftHip,       to: legFwd,    duration: stepDuration),
            makeSwing(node: rightHip,      to: legBack,   duration: stepDuration),
            makeSwing(node: leftKnee,      to: kneeUp,    duration: stepDuration),
            makeSwing(node: rightKnee,     to: kneePush,  duration: stepDuration),
            makeSwing(node: leftAnkle,     to: ankleFwd,  duration: stepDuration),
            makeSwing(node: rightAnkle,    to: ankleBack, duration: stepDuration),
            makeSwing(node: leftShoulder,  to: armBack,   duration: stepDuration),
            makeSwing(node: rightShoulder, to: armFwd,    duration: stepDuration),
            makeSwing(node: leftElbow,     to: elbowBack, duration: stepDuration),
            makeSwing(node: rightElbow,    to: -elbowFwd, duration: stepDuration),
        ])

        // Step 2: right leg forward, left leg back
        let step2 = SKAction.group([
            makeSwing(node: rightHip,      to: legFwd,    duration: stepDuration),
            makeSwing(node: leftHip,       to: legBack,   duration: stepDuration),
            makeSwing(node: rightKnee,     to: kneeUp,    duration: stepDuration),
            makeSwing(node: leftKnee,      to: kneePush,  duration: stepDuration),
            makeSwing(node: rightAnkle,    to: ankleFwd,  duration: stepDuration),
            makeSwing(node: leftAnkle,     to: ankleBack, duration: stepDuration),
            makeSwing(node: rightShoulder, to: armBack,   duration: stepDuration),
            makeSwing(node: leftShoulder,  to: armFwd,    duration: stepDuration),
            makeSwing(node: rightElbow,    to: elbowBack, duration: stepDuration),
            makeSwing(node: leftElbow,     to: -elbowFwd, duration: stepDuration),
        ])

        run(.repeatForever(.sequence([step1, step2])), withKey: "walkCycle")
    }

    private func makeSwing(node: SKNode, to angle: CGFloat, duration: TimeInterval) -> SKAction {
        SKAction.sequence([
            SKAction.run {
                node.run(
                    SKAction.easedRotate(toAngle: angle, duration: duration, easing: Easing.easeOutBack),
                    withKey: "swing"
                )
            },
            SKAction.wait(forDuration: duration)
        ])
    }

    private func stopJointAnimations() {
        idleSwayWorkItem?.cancel()
        idleSwayWorkItem = nil
        boxingComboWorkItem?.cancel()
        boxingComboWorkItem = nil
        fidgetWorkItem?.cancel()
        fidgetWorkItem = nil
        for joint in [leftShoulder, rightShoulder, leftHip, rightHip,
                      leftKnee, rightKnee, leftElbow, rightElbow,
                      leftAnkle, rightAnkle, leftWrist, rightWrist] {
            joint.removeAllActions()
        }
    }

    // MARK: - Mood Poses

    func setScaredPose() {
        isWalking = false
        removeAction(forKey: "walkCycle")
        stopJointAnimations()
        leftShoulder.run(SKAction.rotate(toAngle: -1.2, duration: 0.15))
        rightShoulder.run(SKAction.rotate(toAngle: 1.2, duration: 0.15))
        leftElbow.run(SKAction.rotate(toAngle: -0.8, duration: 0.1))
        rightElbow.run(SKAction.rotate(toAngle: 0.8, duration: 0.1))
        leftHip.run(SKAction.rotate(toAngle: 0.2, duration: 0.15))
        rightHip.run(SKAction.rotate(toAngle: -0.2, duration: 0.15))
    }

    func setSleepPose() {
        isWalking = false
        removeAction(forKey: "walkCycle")
        stopJointAnimations()

        // Legs splay out fully horizontal — lying on the floor
        leftHip.run(SKAction.rotate(toAngle: 1.55, duration: 0.65))
        rightHip.run(SKAction.rotate(toAngle: -1.55, duration: 0.65))
        leftKnee.run(SKAction.rotate(toAngle: -0.3, duration: 0.55))
        rightKnee.run(SKAction.rotate(toAngle: 0.3, duration: 0.55))
        leftAnkle.run(SKAction.rotate(toAngle: 1.2, duration: 0.5))
        rightAnkle.run(SKAction.rotate(toAngle: -1.2, duration: 0.5))

        // Arms droop loosely at sides — no movement once settled
        leftShoulder.run(SKAction.rotate(toAngle: 0.4, duration: 0.55))
        rightShoulder.run(SKAction.rotate(toAngle: -0.4, duration: 0.55))
        leftElbow.run(SKAction.rotate(toAngle: 0.25, duration: 0.45))
        rightElbow.run(SKAction.rotate(toAngle: -0.25, duration: 0.45))
    }

    func setWavePose() {
        isWalking = false
        removeAction(forKey: "walkCycle")
        stopJointAnimations()
        rightShoulder.run(SKAction.rotate(toAngle: -2.5, duration: 0.3))
        let wave = SKAction.sequence([
            SKAction.rotate(toAngle: -0.3, duration: 0.45),
            SKAction.rotate(toAngle: 0.3, duration: 0.45),
        ])
        rightElbow.run(.repeatForever(wave), withKey: "wave")
        leftShoulder.run(SKAction.rotate(toAngle: 0.15, duration: 0.3))
    }

    func stopWave() {
        rightElbow.removeAction(forKey: "wave")
    }

    // MARK: - Surfing

    func startSurfing() {
        isWalking = false
        removeAction(forKey: "walkCycle")
        stopJointAnimations()

        surfboard.isHidden = false
        let popIn = SKAction.sequence([
            SKAction.scale(to: 0.85, duration: 0),
            SKAction.scale(to: 1.0, duration: 0.3),
        ])
        popIn.timingMode = .easeOut
        surfboard.run(popIn)

        // Arms spread wide for balance
        leftShoulder.run(SKAction.rotate(toAngle: 0.88, duration: 0.45))
        rightShoulder.run(SKAction.rotate(toAngle: -0.88, duration: 0.45))
        leftElbow.run(SKAction.rotate(toAngle: 0.18, duration: 0.35))
        rightElbow.run(SKAction.rotate(toAngle: -0.18, duration: 0.35))

        // Knees bent — surf stance
        leftHip.run(SKAction.rotate(toAngle: 0.14, duration: 0.45))
        rightHip.run(SKAction.rotate(toAngle: -0.14, duration: 0.45))
        leftKnee.run(SKAction.rotate(toAngle: 0.40, duration: 0.35))
        rightKnee.run(SKAction.rotate(toAngle: 0.40, duration: 0.35))
    }

    func stopSurfing() {
        let shrink = SKAction.sequence([
            SKAction.scale(to: 0.0, duration: 0.2),
            SKAction.run { [weak self] in self?.surfboard.isHidden = true },
            SKAction.scale(to: 1.0, duration: 0),
        ])
        surfboard.run(shrink)
    }

    func setSickPose() {
        isWalking = false
        removeAction(forKey: "walkCycle")
        stopJointAnimations()
        leftShoulder.run(SKAction.rotate(toAngle: 0.8, duration: 0.3))
        rightShoulder.run(SKAction.rotate(toAngle: -0.8, duration: 0.3))
        leftElbow.run(SKAction.rotate(toAngle: 0.6, duration: 0.2))
        rightElbow.run(SKAction.rotate(toAngle: -0.6, duration: 0.2))
    }

    // MARK: - Relaxed Sit (legs horizontal, chill face)

    func setRelaxedSitPose() {
        isWalking = false
        removeAction(forKey: "walkCycle")
        stopJointAnimations()

        // Thighs stretch out horizontally to each side
        leftHip.run(SKAction.rotate(toAngle: 1.48, duration: 0.55))
        rightHip.run(SKAction.rotate(toAngle: -1.48, duration: 0.55))

        // Shins hang slightly downward from the horizontal thigh
        leftKnee.run(SKAction.rotate(toAngle: -0.28, duration: 0.45))
        rightKnee.run(SKAction.rotate(toAngle: 0.28, duration: 0.45))

        // Ankles rotate so shoes face roughly downward (natural dangle)
        leftAnkle.run(SKAction.rotate(toAngle: 1.1, duration: 0.4))
        rightAnkle.run(SKAction.rotate(toAngle: -1.1, duration: 0.4))

        // Arms prop loosely behind / at sides — relaxed slouch
        leftShoulder.run(SKAction.rotate(toAngle: 0.48, duration: 0.45))
        rightShoulder.run(SKAction.rotate(toAngle: -0.48, duration: 0.45))
        leftElbow.run(SKAction.rotate(toAngle: 0.32, duration: 0.35))
        rightElbow.run(SKAction.rotate(toAngle: -0.32, duration: 0.35))
    }

    func setSittingPose() {
        isWalking = false
        removeAction(forKey: "walkCycle")
        stopJointAnimations()
        // Legs fold forward — cross-legged sit on floor
        leftHip.run(SKAction.rotate(toAngle: 1.2, duration: 0.45))
        rightHip.run(SKAction.rotate(toAngle: -1.2, duration: 0.45))
        leftKnee.run(SKAction.rotate(toAngle: -1.3, duration: 0.35))
        rightKnee.run(SKAction.rotate(toAngle: 1.3, duration: 0.35))
        // Arms rest relaxed inward
        leftShoulder.run(SKAction.rotate(toAngle: 0.5, duration: 0.4))
        rightShoulder.run(SKAction.rotate(toAngle: -0.5, duration: 0.4))
        leftElbow.run(SKAction.rotate(toAngle: 0.3, duration: 0.3))
        rightElbow.run(SKAction.rotate(toAngle: -0.3, duration: 0.3))
    }

    func startScratch() {
        isWalking = false
        removeAction(forKey: "walkCycle")
        stopJointAnimations()
        // Left arm hangs at rest
        leftShoulder.run(SKAction.rotate(toAngle: 0.15, duration: 0.3))
        leftElbow.run(SKAction.rotate(toAngle: 0, duration: 0.25))
        // Right arm raises up toward head
        rightShoulder.run(SKAction.rotate(toAngle: -2.0, duration: 0.3))
        rightElbow.run(SKAction.rotate(toAngle: 1.4, duration: 0.4)) { [weak self] in
            let scratch = SKAction.sequence([
                SKAction.rotate(toAngle: 1.1, duration: 0.18),
                SKAction.rotate(toAngle: 1.7, duration: 0.18),
            ])
            self?.rightElbow.run(.repeatForever(scratch), withKey: "scratch")
        }
    }

    func stopScratch() {
        rightElbow.removeAction(forKey: "scratch")
    }

    // MARK: - Boxing

    func startBoxing() {
        isWalking = false
        removeAction(forKey: "walkCycle")
        stopJointAnimations()

        // Boxer guard stance — arms raised, elbows bent inward
        leftShoulder.run(SKAction.rotate(toAngle: -1.0, duration: 0.25))
        rightShoulder.run(SKAction.rotate(toAngle: 1.0, duration: 0.25))
        leftElbow.run(SKAction.rotate(toAngle: 0.8, duration: 0.2))
        rightElbow.run(SKAction.rotate(toAngle: -0.8, duration: 0.2))
        leftHip.run(SKAction.rotate(toAngle: 0.12, duration: 0.25))
        rightHip.run(SKAction.rotate(toAngle: -0.12, duration: 0.25))

        // Start combo after guard is set
        let comboItem = DispatchWorkItem { [weak self] in
            self?.runBoxingCombo()
        }
        boxingComboWorkItem = comboItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: comboItem)
    }

    private func runBoxingCombo() {
        // Left jab: shoot arm out then pull back
        let jabLeft = SKAction.sequence([
            SKAction.run { [weak self] in
                self?.leftShoulder.run(SKAction.rotate(toAngle: -1.7, duration: 0.1), withKey: "swingLS")
                self?.leftElbow.run(SKAction.rotate(toAngle: 0.1, duration: 0.1), withKey: "swingLE")
            },
            SKAction.wait(forDuration: 0.14),
            SKAction.run { [weak self] in
                self?.leftShoulder.run(SKAction.rotate(toAngle: -1.0, duration: 0.16), withKey: "swingLS")
                self?.leftElbow.run(SKAction.rotate(toAngle: 0.8, duration: 0.14), withKey: "swingLE")
            },
            SKAction.wait(forDuration: 0.22),
        ])

        // Right jab
        let jabRight = SKAction.sequence([
            SKAction.run { [weak self] in
                self?.rightShoulder.run(SKAction.rotate(toAngle: 1.7, duration: 0.1), withKey: "swingRS")
                self?.rightElbow.run(SKAction.rotate(toAngle: -0.1, duration: 0.1), withKey: "swingRE")
            },
            SKAction.wait(forDuration: 0.14),
            SKAction.run { [weak self] in
                self?.rightShoulder.run(SKAction.rotate(toAngle: 1.0, duration: 0.16), withKey: "swingRS")
                self?.rightElbow.run(SKAction.rotate(toAngle: -0.8, duration: 0.14), withKey: "swingRE")
            },
            SKAction.wait(forDuration: 0.22),
        ])

        let rest = SKAction.wait(forDuration: TimeInterval.random(in: 0.3...0.7))
        run(.repeatForever(.sequence([jabLeft, jabRight, rest])), withKey: "boxing")
    }

    func stopBoxing() {
        removeAction(forKey: "boxing")
        for joint in [leftShoulder, rightShoulder, leftElbow, rightElbow] {
            joint.removeAction(forKey: "swingLS")
            joint.removeAction(forKey: "swingLE")
            joint.removeAction(forKey: "swingRS")
            joint.removeAction(forKey: "swingRE")
        }
    }

    // MARK: - Excited Bounce

    func setExcitedPose() {
        isWalking = false
        removeAction(forKey: "walkCycle")
        stopJointAnimations()

        // Arms raised, elbows bent inward — "yay!" pose
        leftShoulder.run(SKAction.easedRotate(toAngle: -2.0, duration: 0.35, easing: Easing.easeOutBack))
        rightShoulder.run(SKAction.easedRotate(toAngle: 2.0, duration: 0.35, easing: Easing.easeOutBack))
        leftElbow.run(SKAction.rotate(toAngle: -0.7, duration: 0.3))
        rightElbow.run(SKAction.rotate(toAngle: 0.7, duration: 0.3))

        // Excited bounce on hips
        let bounceL = SKAction.sequence([
            SKAction.rotate(toAngle: 0.08, duration: 0.22),
            SKAction.rotate(toAngle: -0.04, duration: 0.22),
        ])
        let bounceR = SKAction.sequence([
            SKAction.rotate(toAngle: -0.08, duration: 0.22),
            SKAction.rotate(toAngle: 0.04, duration: 0.22),
        ])
        bounceL.timingMode = .easeInEaseOut
        bounceR.timingMode = .easeInEaseOut
        leftHip.run(.repeatForever(bounceL), withKey: "excitedBounce")
        rightHip.run(.repeatForever(bounceR), withKey: "excitedBounce")
    }

    func stopExcited() {
        leftHip.removeAction(forKey: "excitedBounce")
        rightHip.removeAction(forKey: "excitedBounce")
    }

    // MARK: - Shy Peek

    private var shyPeekWorkItem: DispatchWorkItem?

    func setShyPose() {
        isWalking = false
        removeAction(forKey: "walkCycle")
        stopJointAnimations()

        // Both arms cover face
        leftShoulder.run(SKAction.rotate(toAngle: -1.7, duration: 0.35))
        rightShoulder.run(SKAction.rotate(toAngle: 1.7, duration: 0.35))
        leftElbow.run(SKAction.rotate(toAngle: -1.3, duration: 0.3))
        rightElbow.run(SKAction.rotate(toAngle: 1.3, duration: 0.3))

        // After 1.5s, one arm lowers to peek
        let peekItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.rightShoulder.run(SKAction.easedRotate(toAngle: 0.8, duration: 0.5, easing: Easing.easeOutBack))
            self.rightElbow.run(SKAction.rotate(toAngle: 0.4, duration: 0.4))
        }
        shyPeekWorkItem = peekItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: peekItem)
    }

    func stopShy() {
        shyPeekWorkItem?.cancel()
        shyPeekWorkItem = nil
    }

    // MARK: - Curious Tilt

    func setCuriousPose() {
        isWalking = false
        removeAction(forKey: "walkCycle")
        stopJointAnimations()

        // One arm raised (thinking)
        rightShoulder.run(SKAction.easedRotate(toAngle: -1.2, duration: 0.4, easing: Easing.easeOutBack))
        rightElbow.run(SKAction.rotate(toAngle: 1.0, duration: 0.35))
        leftShoulder.run(SKAction.rotate(toAngle: 0.15, duration: 0.4))
        leftElbow.run(SKAction.rotate(toAngle: 0, duration: 0.3))
    }

    // MARK: - Yawn + Stretch

    func setYawnPose(completion: (() -> Void)? = nil) {
        isWalking = false
        removeAction(forKey: "walkCycle")
        stopJointAnimations()

        // Arms stretch fully upward
        leftShoulder.run(SKAction.easedRotate(toAngle: -2.6, duration: 0.6, easing: Easing.easeInOutCubic))
        rightShoulder.run(SKAction.easedRotate(toAngle: 2.6, duration: 0.6, easing: Easing.easeInOutCubic))
        leftElbow.run(SKAction.rotate(toAngle: -0.1, duration: 0.5))
        rightElbow.run(SKAction.rotate(toAngle: 0.1, duration: 0.5))

        // Hold 1.5s then lower
        run(.sequence([
            SKAction.wait(forDuration: 2.2),
            SKAction.run { [weak self] in
                self?.leftShoulder.run(SKAction.easedRotate(toAngle: 0.15, duration: 0.6, easing: { Easing.spring($0, damping: 0.5) }))
                self?.rightShoulder.run(SKAction.easedRotate(toAngle: -0.15, duration: 0.6, easing: { Easing.spring($0, damping: 0.5) }))
                self?.leftElbow.run(SKAction.rotate(toAngle: 0, duration: 0.4))
                self?.rightElbow.run(SKAction.rotate(toAngle: 0, duration: 0.4))
            },
            SKAction.wait(forDuration: 0.7),
            SKAction.run { completion?() },
        ]), withKey: "yawnSequence")
    }

    // MARK: - Sneeze

    func setSneezePose() {
        isWalking = false
        removeAction(forKey: "walkCycle")
        stopJointAnimations()

        // Arms slightly forward bracing
        leftShoulder.run(SKAction.rotate(toAngle: 0.4, duration: 0.3))
        rightShoulder.run(SKAction.rotate(toAngle: -0.4, duration: 0.3))
        leftElbow.run(SKAction.rotate(toAngle: 0.3, duration: 0.25))
        rightElbow.run(SKAction.rotate(toAngle: -0.3, duration: 0.25))
    }
}
