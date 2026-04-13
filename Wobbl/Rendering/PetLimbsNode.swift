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

    private(set) var isWalking = false
    private var walkPhase: CGFloat = 0.0

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

        addChild(leftShoulder)
        addChild(rightShoulder)
        addChild(leftHip)
        addChild(rightHip)

        setStandingPose()
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

        leftShoulder.run(SKAction.rotate(toAngle: 0.15, duration: 0.3))
        rightShoulder.run(SKAction.rotate(toAngle: -0.15, duration: 0.3))
        leftElbow.run(SKAction.rotate(toAngle: 0, duration: 0.2))
        rightElbow.run(SKAction.rotate(toAngle: 0, duration: 0.2))

        leftHip.run(SKAction.rotate(toAngle: 0, duration: 0.3))
        rightHip.run(SKAction.rotate(toAngle: 0, duration: 0.3))
        leftKnee.run(SKAction.rotate(toAngle: 0, duration: 0.2))
        rightKnee.run(SKAction.rotate(toAngle: 0, duration: 0.2))

        // Gentle arm sway once joints settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self = self else { return }
            let swayL = SKAction.sequence([
                SKAction.rotate(toAngle: 0.22, duration: 1.9),
                SKAction.rotate(toAngle: 0.10, duration: 1.9),
            ])
            let swayR = SKAction.sequence([
                SKAction.rotate(toAngle: -0.22, duration: 1.9),
                SKAction.rotate(toAngle: -0.10, duration: 1.9),
            ])
            self.leftShoulder.run(.repeatForever(swayL), withKey: "idleSway")
            self.rightShoulder.run(.repeatForever(swayR), withKey: "idleSway")
        }
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
        let armFwd: CGFloat  =  0.42   // arm swings forward
        let armBack: CGFloat = -0.38   // arm swings back
        let elbowFwd: CGFloat = 0.32   // elbow bends on the arm coming forward
        let elbowBack: CGFloat = 0.10  // stays nearly straight when arm is back

        // Step 1: left leg forward, right leg back
        let step1 = SKAction.group([
            makeSwing(node: leftHip,       to: legFwd,   duration: stepDuration),
            makeSwing(node: rightHip,      to: legBack,  duration: stepDuration),
            makeSwing(node: leftKnee,      to: kneeUp,   duration: stepDuration),
            makeSwing(node: rightKnee,     to: kneePush, duration: stepDuration),
            makeSwing(node: leftShoulder,  to: armBack,  duration: stepDuration),
            makeSwing(node: rightShoulder, to: armFwd,   duration: stepDuration),
            makeSwing(node: leftElbow,     to: elbowBack,duration: stepDuration),
            makeSwing(node: rightElbow,    to: -elbowFwd,duration: stepDuration),
        ])

        // Step 2: right leg forward, left leg back
        let step2 = SKAction.group([
            makeSwing(node: rightHip,      to: legFwd,   duration: stepDuration),
            makeSwing(node: leftHip,       to: legBack,  duration: stepDuration),
            makeSwing(node: rightKnee,     to: kneeUp,   duration: stepDuration),
            makeSwing(node: leftKnee,      to: kneePush, duration: stepDuration),
            makeSwing(node: rightShoulder, to: armBack,  duration: stepDuration),
            makeSwing(node: leftShoulder,  to: armFwd,   duration: stepDuration),
            makeSwing(node: rightElbow,    to: elbowBack,duration: stepDuration),
            makeSwing(node: leftElbow,     to: -elbowFwd,duration: stepDuration),
        ])

        run(.repeatForever(.sequence([step1, step2])), withKey: "walkCycle")
    }

    private func makeSwing(node: SKNode, to angle: CGFloat, duration: TimeInterval) -> SKAction {
        SKAction.sequence([
            SKAction.run {
                let action = SKAction.rotate(toAngle: angle, duration: duration)
                action.timingMode = .easeInEaseOut
                node.run(action, withKey: "swing")
            },
            SKAction.wait(forDuration: duration)
        ])
    }

    private func stopJointAnimations() {
        for joint in [leftShoulder, rightShoulder, leftHip, rightHip,
                      leftKnee, rightKnee, leftElbow, rightElbow,
                      leftAnkle, rightAnkle] {
            joint.removeAction(forKey: "swing")
        }
        leftShoulder.removeAction(forKey: "idleSway")
        rightShoulder.removeAction(forKey: "idleSway")
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
        leftShoulder.run(SKAction.rotate(toAngle: 0.3, duration: 0.5))
        rightShoulder.run(SKAction.rotate(toAngle: -0.3, duration: 0.5))
        leftElbow.run(SKAction.rotate(toAngle: 0.2, duration: 0.4))
        rightElbow.run(SKAction.rotate(toAngle: -0.2, duration: 0.4))
        leftHip.run(SKAction.rotate(toAngle: 0.05, duration: 0.5))
        rightHip.run(SKAction.rotate(toAngle: -0.05, duration: 0.5))
    }

    func setWavePose() {
        isWalking = false
        removeAction(forKey: "walkCycle")
        stopJointAnimations()
        rightShoulder.run(SKAction.rotate(toAngle: -2.5, duration: 0.3))
        let wave = SKAction.sequence([
            SKAction.rotate(toAngle: -0.3, duration: 0.25),
            SKAction.rotate(toAngle: 0.3, duration: 0.25),
        ])
        rightElbow.run(.repeatForever(wave), withKey: "wave")
        leftShoulder.run(SKAction.rotate(toAngle: 0.15, duration: 0.3))
    }

    func stopWave() {
        rightElbow.removeAction(forKey: "wave")
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
        rightElbow.run(SKAction.rotate(toAngle: 1.4, duration: 0.25)) { [weak self] in
            let scratch = SKAction.sequence([
                SKAction.rotate(toAngle: 1.1, duration: 0.1),
                SKAction.rotate(toAngle: 1.7, duration: 0.1),
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.runBoxingCombo()
        }
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
}
