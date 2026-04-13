import Foundation
import AppKit

/// Detects "shaking" by monitoring rapid, erratic mouse/trackpad movements.
/// Uses mouse velocity and direction changes to compute an agitation score.
/// Works on ALL Macs — no special hardware or permissions needed.
final class AccelerometerReader {
    private var onReading: ((AccelReading) -> Void)?
    private var globalMonitor: Any?
    private var localMonitor: Any?

    // Movement history for velocity and direction analysis
    private var movementHistory: [(dx: CGFloat, dy: CGFloat, time: TimeInterval)] = []
    private let historyWindow: TimeInterval = 0.5  // analyze last 0.5 seconds
    private let maxHistorySize = 50

    // Smoothed agitation values (fed as pseudo-accelerometer readings)
    private var smoothedMagnitude: Double = 0
    private let smoothingFactor: Double = 0.3

    var isAvailable: Bool { true }  // Always available

    func start(callback: @escaping (AccelReading) -> Void) {
        onReading = callback

        // Monitor mouse/trackpad movement globally
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]) { [weak self] event in
            self?.processMouseEvent(event)
        }

        // Also monitor within our own window
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]) { [weak self] event in
            self?.processMouseEvent(event)
            return event
        }
    }

    func stop() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
        }
        globalMonitor = nil
        localMonitor = nil
    }

    private func processMouseEvent(_ event: NSEvent) {
        let now = ProcessInfo.processInfo.systemUptime
        let dx = event.deltaX
        let dy = event.deltaY

        // Add to movement history
        movementHistory.append((dx: dx, dy: dy, time: now))

        // Trim old entries
        movementHistory.removeAll { now - $0.time > historyWindow }
        if movementHistory.count > maxHistorySize {
            movementHistory.removeFirst(movementHistory.count - maxHistorySize)
        }

        // Compute agitation metrics
        let agitation = computeAgitation(now: now)

        // Smooth the agitation
        smoothedMagnitude = smoothedMagnitude * (1 - smoothingFactor) + agitation * smoothingFactor

        // Convert to pseudo-accelerometer reading
        // X = horizontal agitation, Y = vertical agitation, Z = baseline (like gravity)
        let horizontalBias = computeHorizontalBias()
        let reading = AccelReading(
            x: horizontalBias * smoothedMagnitude,
            y: (1 - abs(horizontalBias)) * smoothedMagnitude,
            z: max(0, 1.0 - smoothedMagnitude),  // "gravity" decreases as agitation increases
            timestamp: now
        )

        onReading?(reading)
    }

    /// Compute an agitation score (0.0 = calm, 2.0+ = very agitated/shaking)
    private func computeAgitation(now: TimeInterval) -> Double {
        guard movementHistory.count >= 3 else { return 0 }

        // 1. Raw speed: average movement magnitude
        let speeds = movementHistory.map { sqrt($0.dx * $0.dx + $0.dy * $0.dy) }
        let avgSpeed = speeds.reduce(0, +) / CGFloat(speeds.count)

        // 2. Direction changes: count how often the direction reverses
        var directionChanges: CGFloat = 0
        for i in 1..<movementHistory.count {
            let prev = movementHistory[i - 1]
            let curr = movementHistory[i]
            // Dot product of consecutive movements — negative = direction reversed
            let dot = prev.dx * curr.dx + prev.dy * curr.dy
            if dot < 0 {
                directionChanges += 1
            }
        }
        let changeRate = directionChanges / CGFloat(max(movementHistory.count - 1, 1))

        // 3. Combine: high speed + frequent direction changes = shaking
        // Speed > 30 pixels/event is fast, > 60 is very fast
        let speedFactor = min(Double(avgSpeed) / 25.0, 3.0)

        // Change rate > 0.4 means lots of back-and-forth
        let directionFactor = min(Double(changeRate) / 0.3, 2.0)

        // Agitation = speed × direction-change multiplier
        let agitation = speedFactor * (0.5 + directionFactor * 0.5)

        return agitation
    }

    /// Compute horizontal bias (-1 to 1) to simulate tilt direction
    private func computeHorizontalBias() -> Double {
        guard !movementHistory.isEmpty else { return 0 }
        let recent = movementHistory.suffix(10)
        let avgDx = recent.map(\.dx).reduce(0, +) / CGFloat(recent.count)
        let avgDy = recent.map(\.dy).reduce(0, +) / CGFloat(recent.count)
        let totalMag = sqrt(avgDx * avgDx + avgDy * avgDy)
        guard totalMag > 0.1 else { return 0 }
        return Double(avgDx / totalMag)
    }

    deinit {
        stop()
    }
}
