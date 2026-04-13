import SpriteKit

final class PetEffectsNode: SKNode {
    private var activeEmitters: [String: SKEmitterNode] = [:]
    private var activeNodes: [String: SKNode] = [:]

    func setup() {
        // Container positioned above the body center
    }

    // MARK: - Sweat Drops

    func startSweat() {
        guard activeEmitters["sweat"] == nil else { return }
        let emitter = makeSweatEmitter()
        emitter.position = CGPoint(x: 0, y: 40)
        addChild(emitter)
        activeEmitters["sweat"] = emitter
    }

    func stopSweat() {
        activeEmitters["sweat"]?.removeFromParent()
        activeEmitters["sweat"] = nil
    }

    // MARK: - Vomit Particles

    func startVomit() {
        guard activeEmitters["vomit"] == nil else { return }
        let emitter = makeVomitEmitter()
        emitter.position = CGPoint(x: 0, y: -24)
        addChild(emitter)
        activeEmitters["vomit"] = emitter
    }

    func stopVomit() {
        activeEmitters["vomit"]?.removeFromParent()
        activeEmitters["vomit"] = nil
    }

    // MARK: - ZZZ Sleep Bubbles

    func startZZZ() {
        guard activeNodes["zzz"] == nil else { return }
        let container = SKNode()
        container.position = CGPoint(x: 20, y: 28)
        addChild(container)
        activeNodes["zzz"] = container

        let emitZ = SKAction.run { [weak container] in
            guard let container = container else { return }
            let z = SKLabelNode(text: "Z")
            z.fontName = "Avenir-Heavy"
            z.fontSize = CGFloat.random(in: 10...16)
            z.fontColor = ColorPalette.zzzColor
            z.position = .zero
            z.alpha = 0.8
            container.addChild(z)

            let moveUp = SKAction.moveBy(x: CGFloat.random(in: 5...15), y: 30, duration: 2.0)
            let fadeOut = SKAction.fadeOut(withDuration: 2.0)
            let scaleUp = SKAction.scale(to: 1.5, duration: 2.0)
            let group = SKAction.group([moveUp, fadeOut, scaleUp])
            z.run(SKAction.sequence([group, .removeFromParent()]))
        }
        let wait = SKAction.wait(forDuration: 0.8, withRange: 0.4)
        container.run(.repeatForever(.sequence([emitZ, wait])))
    }

    func stopZZZ() {
        activeNodes["zzz"]?.removeAllActions()
        activeNodes["zzz"]?.removeFromParent()
        activeNodes["zzz"] = nil
    }

    // MARK: - Dizzy Stars

    func startStars() {
        guard activeNodes["stars"] == nil else { return }
        let orbit = SKNode()
        orbit.position = CGPoint(x: 0, y: 25)
        addChild(orbit)
        activeNodes["stars"] = orbit

        let starCount = 3
        for i in 0..<starCount {
            let angle = (CGFloat(i) / CGFloat(starCount)) * 2.0 * .pi
            let star = createStarShape(size: 5)
            star.position = CGPoint(x: cos(angle) * 35, y: sin(angle) * 16)
            orbit.addChild(star)
        }

        let spin = SKAction.rotate(byAngle: .pi * 2, duration: 1.2)
        orbit.run(.repeatForever(spin))
    }

    func stopStars() {
        activeNodes["stars"]?.removeAllActions()
        activeNodes["stars"]?.removeFromParent()
        activeNodes["stars"] = nil
    }

    // MARK: - Stop All

    func stopAll() {
        for (_, emitter) in activeEmitters { emitter.removeFromParent() }
        for (_, node) in activeNodes { node.removeAllActions(); node.removeFromParent() }
        activeEmitters.removeAll()
        activeNodes.removeAll()
    }

    // MARK: - Emitter Factories

    private func makeSweatEmitter() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 2.5
        emitter.particleLifetime = 1.2
        emitter.particleLifetimeRange = 0.3
        emitter.particleSize = CGSize(width: 4, height: 6)
        emitter.particleColor = ColorPalette.sweatDrop
        emitter.particleColorBlendFactor = 1.0
        emitter.emissionAngle = .pi * 0.6
        emitter.emissionAngleRange = .pi * 0.5
        emitter.particleSpeed = 25
        emitter.particleSpeedRange = 10
        emitter.yAcceleration = -60
        emitter.particleAlphaSpeed = -0.6
        emitter.particleScale = 0.8
        emitter.particleScaleSpeed = -0.3
        emitter.particleTexture = SKTexture(image: generateDropImage(size: 8, color: ColorPalette.sweatDrop))
        return emitter
    }

    private func makeVomitEmitter() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 8
        emitter.particleLifetime = 0.8
        emitter.particleLifetimeRange = 0.3
        emitter.particleSize = CGSize(width: 5, height: 5)
        emitter.particleColor = ColorPalette.vomitGreen
        emitter.particleColorBlendFactor = 1.0
        emitter.emissionAngle = -.pi / 2
        emitter.emissionAngleRange = .pi * 0.3
        emitter.particleSpeed = 40
        emitter.particleSpeedRange = 15
        emitter.yAcceleration = -80
        emitter.particleAlphaSpeed = -0.8
        emitter.particleScale = 1.0
        emitter.particleScaleRange = 0.4
        emitter.particleScaleSpeed = -0.5
        emitter.particleTexture = SKTexture(image: generateDropImage(size: 8, color: ColorPalette.vomitGreen))
        return emitter
    }

    // MARK: - Texture Generation

    private func generateDropImage(size: CGFloat, color: SKColor) -> NSImage {
        let imgSize = NSSize(width: size, height: size * 1.3)
        let image = NSImage(size: imgSize, flipped: false) { rect in
            let path = NSBezierPath()
            let cx = rect.midX
            path.move(to: NSPoint(x: cx, y: rect.maxY))
            path.curve(
                to: NSPoint(x: cx, y: rect.minY),
                controlPoint1: NSPoint(x: rect.maxX + 1, y: rect.midY),
                controlPoint2: NSPoint(x: rect.maxX, y: rect.minY)
            )
            path.curve(
                to: NSPoint(x: cx, y: rect.maxY),
                controlPoint1: NSPoint(x: rect.minX, y: rect.minY),
                controlPoint2: NSPoint(x: rect.minX - 1, y: rect.midY)
            )
            color.setFill()
            path.fill()
            return true
        }
        return image
    }

    private func createStarShape(size: CGFloat) -> SKShapeNode {
        let path = CGMutablePath()
        let points = 5
        let innerRadius = size * 0.4
        let outerRadius = size

        for i in 0..<(points * 2) {
            let angle = (CGFloat(i) / CGFloat(points * 2)) * 2.0 * .pi - .pi / 2
            let r = i % 2 == 0 ? outerRadius : innerRadius
            let x = cos(angle) * r
            let y = sin(angle) * r
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        path.closeSubpath()

        let star = SKShapeNode(path: path)
        star.fillColor = ColorPalette.starYellow
        star.strokeColor = .clear
        return star
    }
}
