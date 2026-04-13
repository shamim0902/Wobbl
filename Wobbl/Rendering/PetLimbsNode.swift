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
        let legSwing: CGFloat = 0.45
        let armSwing: CGFloat = 0.35
        let kneeFlexFwd: CGFloat = 0.3
        let elbowFlex: CGFloat = 0.25

        let leftLegFwd      = makeSwing(node: leftHip,      to: legSwing,          duration: stepDuration)
        let rightLegBack     = makeSwing(node: rightHip,     to: -legSwing * 0.3,   duration: stepDuration)
        let leftKneeBend     = makeSwing(node: leftKnee,     to: kneeFlexFwd,       duration: stepDuration)
        let rightKneeStraight = makeSwing(node: rightKnee,  to: 0,                 duration: stepDuration)
        let leftArmBack      = makeSwing(node: leftShoulder, to: -armSwing,         duration: stepDuration)
        let rightArmFwd      = makeSwing(node: rightShoulder,to: armSwing,          duration: stepDuration)
        let leftElbowFlex    = makeSwing(node: leftElbow,    to: elbowFlex,         duration: stepDuration)
        let rightElbowFlex   = makeSwing(node: rightElbow,   to: -elbowFlex,        duration: stepDuration)

        let step1 = SKAction.group([
            leftLegFwd, rightLegBack, leftKneeBend, rightKneeStraight,
            leftArmBack, rightArmFwd, leftElbowFlex, rightElbowFlex
        ])

        let rightLegFwd      = makeSwing(node: rightHip,     to: legSwing,          duration: stepDuration)
        let leftLegBack      = makeSwing(node: leftHip,      to: -legSwing * 0.3,   duration: stepDuration)
        let rightKneeBend    = makeSwing(node: rightKnee,    to: kneeFlexFwd,       duration: stepDuration)
        let leftKneeStraight2 = makeSwing(node: leftKnee,   to: 0,                 duration: stepDuration)
        let rightArmBack     = makeSwing(node: rightShoulder,to: -armSwing,         duration: stepDuration)
        let leftArmFwd       = makeSwing(node: leftShoulder, to: armSwing,          duration: stepDuration)
        let rightElbowFlex2  = makeSwing(node: rightElbow,   to: elbowFlex,         duration: stepDuration)
        let leftElbowFlex2   = makeSwing(node: leftElbow,    to: -elbowFlex,        duration: stepDuration)

        let step2 = SKAction.group([
            rightLegFwd, leftLegBack, rightKneeBend, leftKneeStraight2,
            rightArmBack, leftArmFwd, rightElbowFlex2, leftElbowFlex2
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
                      leftKnee, rightKnee, leftElbow, rightElbow] {
            joint.removeAction(forKey: "swing")
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
}
