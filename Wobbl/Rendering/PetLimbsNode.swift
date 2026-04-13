import SpriteKit

final class PetLimbsNode: SKNode {
    // Arms: upper segment from shoulder, forearm hangs
    private let leftUpperArm = SKShapeNode()
    private let leftForearm = SKShapeNode()
    private let rightUpperArm = SKShapeNode()
    private let rightForearm = SKShapeNode()

    // Legs: thigh from hip, shin hangs
    private let leftThigh = SKShapeNode()
    private let leftShin = SKShapeNode()
    private let rightThigh = SKShapeNode()
    private let rightShin = SKShapeNode()

    // Joint pivot nodes (rotation happens here)
    private let leftShoulder = SKNode()
    private let rightShoulder = SKNode()
    private let leftHip = SKNode()
    private let rightHip = SKNode()
    private let leftKnee = SKNode()
    private let rightKnee = SKNode()
    private let leftElbow = SKNode()
    private let rightElbow = SKNode()

    // Dimensions
    private let armLength: CGFloat = 14.0
    private let forearmLength: CGFloat = 12.0
    private let thighLength: CGFloat = 32.0
    private let shinLength: CGFloat = 28.0
    private let limbWidth: CGFloat = 3.0
    private let limbColor = SKColor(red: 0.15, green: 0.10, blue: 0.20, alpha: 0.9)

    private(set) var isWalking = false
    private var walkPhase: CGFloat = 0.0

    func setup() {
        // Create limb line paths
        let armPath = makeLimbPath(length: armLength)
        let forearmPath = makeLimbPath(length: forearmLength)
        let thighPath = makeLimbPath(length: thighLength)
        let shinPath = makeLimbPath(length: shinLength)

        // Style all limbs
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

        // Build arm hierarchy: shoulder → upperArm → elbow → forearm
        leftShoulder.position = CGPoint(x: -38, y: -10)
        leftShoulder.addChild(leftUpperArm)
        leftElbow.position = CGPoint(x: 0, y: -armLength)
        leftUpperArm.addChild(leftElbow)
        leftElbow.addChild(leftForearm)

        rightShoulder.position = CGPoint(x: 38, y: -10)
        rightShoulder.addChild(rightUpperArm)
        rightElbow.position = CGPoint(x: 0, y: -armLength)
        rightUpperArm.addChild(rightElbow)
        rightElbow.addChild(rightForearm)

        // Build leg hierarchy: hip → thigh → knee → shin
        leftHip.position = CGPoint(x: -16, y: -50)
        leftHip.addChild(leftThigh)
        leftKnee.position = CGPoint(x: 0, y: -thighLength)
        leftThigh.addChild(leftKnee)
        leftKnee.addChild(leftShin)

        rightHip.position = CGPoint(x: 16, y: -50)
        rightHip.addChild(rightThigh)
        rightKnee.position = CGPoint(x: 0, y: -thighLength)
        rightThigh.addChild(rightKnee)
        rightKnee.addChild(rightShin)

        addChild(leftShoulder)
        addChild(rightShoulder)
        addChild(leftHip)
        addChild(rightHip)

        // Start in standing pose
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

        // Arms hang slightly out
        let armReset = SKAction.rotate(toAngle: 0.15, duration: 0.3)
        let armResetNeg = SKAction.rotate(toAngle: -0.15, duration: 0.3)
        leftShoulder.run(armReset)
        rightShoulder.run(armResetNeg)
        leftElbow.run(SKAction.rotate(toAngle: 0, duration: 0.2))
        rightElbow.run(SKAction.rotate(toAngle: 0, duration: 0.2))

        // Legs straight
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
        let legSwing: CGFloat = 0.45     // radians
        let armSwing: CGFloat = 0.35
        let kneeFlexFwd: CGFloat = 0.3   // knee bends when leg is forward
        let elbowFlex: CGFloat = 0.25

        // One full walk cycle: left forward → right forward
        let leftLegFwd = makeSwing(node: leftHip, to: legSwing, duration: stepDuration)
        let rightLegBack = makeSwing(node: rightHip, to: -legSwing * 0.3, duration: stepDuration)
        let leftKneeBend = makeSwing(node: leftKnee, to: kneeFlexFwd, duration: stepDuration)
        let rightKneeStraight = makeSwing(node: rightKnee, to: 0, duration: stepDuration)

        let leftArmBack = makeSwing(node: leftShoulder, to: -armSwing, duration: stepDuration)
        let rightArmFwd = makeSwing(node: rightShoulder, to: armSwing, duration: stepDuration)
        let leftElbowFlex = makeSwing(node: leftElbow, to: elbowFlex, duration: stepDuration)
        let rightElbowFlex = makeSwing(node: rightElbow, to: -elbowFlex, duration: stepDuration)

        let step1 = SKAction.group([
            leftLegFwd, rightLegBack, leftKneeBend, rightKneeStraight,
            leftArmBack, rightArmFwd, leftElbowFlex, rightElbowFlex
        ])

        let rightLegFwd = makeSwing(node: rightHip, to: legSwing, duration: stepDuration)
        let leftLegBack = makeSwing(node: leftHip, to: -legSwing * 0.3, duration: stepDuration)
        let rightKneeBend = makeSwing(node: rightKnee, to: kneeFlexFwd, duration: stepDuration)
        let leftKneeStraight2 = makeSwing(node: leftKnee, to: 0, duration: stepDuration)

        let rightArmBack = makeSwing(node: rightShoulder, to: -armSwing, duration: stepDuration)
        let leftArmFwd = makeSwing(node: leftShoulder, to: armSwing, duration: stepDuration)
        let rightElbowFlex2 = makeSwing(node: rightElbow, to: elbowFlex, duration: stepDuration)
        let leftElbowFlex2 = makeSwing(node: leftElbow, to: -elbowFlex, duration: stepDuration)

        let step2 = SKAction.group([
            rightLegFwd, leftLegBack, rightKneeBend, leftKneeStraight2,
            rightArmBack, leftArmFwd, rightElbowFlex2, leftElbowFlex2
        ])

        let cycle = SKAction.sequence([step1, step2])
        run(.repeatForever(cycle), withKey: "walkCycle")
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
        for joint in [leftShoulder, rightShoulder, leftHip, rightHip, leftKnee, rightKnee, leftElbow, rightElbow] {
            joint.removeAction(forKey: "swing")
        }
    }

    // MARK: - Mood Variations

    func setScaredPose() {
        isWalking = false
        removeAction(forKey: "walkCycle")
        stopJointAnimations()
        // Arms up in fright
        leftShoulder.run(SKAction.rotate(toAngle: -1.2, duration: 0.15))
        rightShoulder.run(SKAction.rotate(toAngle: 1.2, duration: 0.15))
        leftElbow.run(SKAction.rotate(toAngle: -0.8, duration: 0.1))
        rightElbow.run(SKAction.rotate(toAngle: 0.8, duration: 0.1))
        // Legs slightly bent
        leftHip.run(SKAction.rotate(toAngle: 0.2, duration: 0.15))
        rightHip.run(SKAction.rotate(toAngle: -0.2, duration: 0.15))
    }

    func setSleepPose() {
        isWalking = false
        removeAction(forKey: "walkCycle")
        stopJointAnimations()
        // Arms droop
        leftShoulder.run(SKAction.rotate(toAngle: 0.3, duration: 0.5))
        rightShoulder.run(SKAction.rotate(toAngle: -0.3, duration: 0.5))
        leftElbow.run(SKAction.rotate(toAngle: 0.2, duration: 0.4))
        rightElbow.run(SKAction.rotate(toAngle: -0.2, duration: 0.4))
        // Legs straight relaxed
        leftHip.run(SKAction.rotate(toAngle: 0.05, duration: 0.5))
        rightHip.run(SKAction.rotate(toAngle: -0.05, duration: 0.5))
    }

    func setWavePose() {
        isWalking = false
        removeAction(forKey: "walkCycle")
        stopJointAnimations()
        // Right arm waves
        rightShoulder.run(SKAction.rotate(toAngle: -2.5, duration: 0.3))
        let wave = SKAction.sequence([
            SKAction.rotate(toAngle: -0.3, duration: 0.25),
            SKAction.rotate(toAngle: 0.3, duration: 0.25),
        ])
        rightElbow.run(.repeatForever(wave), withKey: "wave")
        // Left arm hangs
        leftShoulder.run(SKAction.rotate(toAngle: 0.15, duration: 0.3))
    }

    func stopWave() {
        rightElbow.removeAction(forKey: "wave")
    }

    func setSickPose() {
        isWalking = false
        removeAction(forKey: "walkCycle")
        stopJointAnimations()
        // Arms hold stomach
        leftShoulder.run(SKAction.rotate(toAngle: 0.8, duration: 0.3))
        rightShoulder.run(SKAction.rotate(toAngle: -0.8, duration: 0.3))
        leftElbow.run(SKAction.rotate(toAngle: 0.6, duration: 0.2))
        rightElbow.run(SKAction.rotate(toAngle: -0.6, duration: 0.2))
    }
}
