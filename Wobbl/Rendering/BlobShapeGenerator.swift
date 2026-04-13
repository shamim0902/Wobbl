import CoreGraphics

enum BlobShapeGenerator {
    /// Generate an organic rounded-square (squircle) CGPath with sinusoidal wobble.
    /// - Parameters:
    ///   - radius: Half-size of the square (center to edge)
    ///   - squish: Squish deformation factor (0.0 = none, 1.0 = max)
    ///   - squishAngle: Angle of squish deformation in radians
    ///   - wobblePhase: Animated phase for the living-membrane wobble effect
    ///   - cornerRounding: How rounded the corners are (0.0 = sharp, 1.0 = circle)
    static func blobPath(
        radius: CGFloat,
        squish: CGFloat = 0,
        squishAngle: CGFloat = 0,
        wobblePhase: CGFloat = 0
    ) -> CGPath {
        let path = CGMutablePath()
        let pointCount = 64
        var points: [CGPoint] = []

        for i in 0..<pointCount {
            let theta = (CGFloat(i) / CGFloat(pointCount)) * 2.0 * .pi

            let cosT = cos(theta)
            let sinT = sin(theta)
            // Pure square in polar coordinates
            let baseR = radius / max(abs(cosT), abs(sinT))

            // Organic wobble (3 overlapping sine waves)
            var r = baseR
            r += sin(theta * 3.0 + wobblePhase) * radius * 0.025
            r += sin(theta * 5.0 + wobblePhase * 1.3) * radius * 0.012
            r += sin(theta * 2.0 + wobblePhase * 0.7) * radius * 0.008

            // Squish deformation
            if squish > 0.001 {
                let cosA = cos(theta - squishAngle)
                let sinA = sin(theta - squishAngle)
                r *= (1.0 - squish * 0.3 * cosA * cosA)
                r *= (1.0 + squish * 0.15 * sinA * sinA)
            }

            // Flatten the bottom slightly for a sitting-on-surface look
            let bottomFlatten: CGFloat = theta > .pi ? 0.96 : 1.0
            r *= bottomFlatten

            let x = cosT * r
            let y = sinT * r
            points.append(CGPoint(x: x, y: y))
        }

        // Draw smooth curve through points using Catmull-Rom → Cubic Bezier
        guard points.count >= 4 else { return path }

        path.move(to: catmullRomPoint(
            p0: points[points.count - 1],
            p1: points[0],
            p2: points[1],
            p3: points[2],
            t: 0
        ))

        for i in 0..<points.count {
            let p0 = points[(i - 1 + points.count) % points.count]
            let p1 = points[i]
            let p2 = points[(i + 1) % points.count]
            let p3 = points[(i + 2) % points.count]

            let (cp1, cp2) = catmullRomControlPoints(p0: p0, p1: p1, p2: p2, p3: p3)
            path.addCurve(to: p2, control1: cp1, control2: cp2)
        }

        path.closeSubpath()
        return path
    }

    // MARK: - Catmull-Rom Spline Helpers

    private static func catmullRomPoint(
        p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint, t: CGFloat
    ) -> CGPoint {
        let t2 = t * t
        let t3 = t2 * t
        let x = 0.5 * ((2.0 * p1.x) +
                        (-p0.x + p2.x) * t +
                        (2.0 * p0.x - 5.0 * p1.x + 4.0 * p2.x - p3.x) * t2 +
                        (-p0.x + 3.0 * p1.x - 3.0 * p2.x + p3.x) * t3)
        let y = 0.5 * ((2.0 * p1.y) +
                        (-p0.y + p2.y) * t +
                        (2.0 * p0.y - 5.0 * p1.y + 4.0 * p2.y - p3.y) * t2 +
                        (-p0.y + 3.0 * p1.y - 3.0 * p2.y + p3.y) * t3)
        return CGPoint(x: x, y: y)
    }

    private static func catmullRomControlPoints(
        p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint,
        alpha: CGFloat = 1.0 / 6.0
    ) -> (CGPoint, CGPoint) {
        let cp1 = CGPoint(
            x: p1.x + alpha * (p2.x - p0.x),
            y: p1.y + alpha * (p2.y - p0.y)
        )
        let cp2 = CGPoint(
            x: p2.x - alpha * (p3.x - p1.x),
            y: p2.y - alpha * (p3.y - p1.y)
        )
        return (cp1, cp2)
    }
}
