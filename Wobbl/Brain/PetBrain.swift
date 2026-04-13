import Foundation
import Combine

final class PetBrain: ObservableObject {
    @Published private(set) var currentState: PetState = .idle

    private var accelHistory = RingBuffer<AccelReading>(capacity: 60) // ~3s at 20Hz
    private var stateEntryTime: TimeInterval = ProcessInfo.processInfo.systemUptime
    private var lastHighMagnitudeTime: TimeInterval = 0
    private var lastTiltTime: TimeInterval = 0
    private var happyStartTime: TimeInterval = 0

    // Hysteresis tracking
    private var isInVomit = false
    private var isInDizzy = false
    private var isInSweat = false
    private var isInShiver = false
    private var scaredUntil: TimeInterval = 0

    func process(_ snapshot: SensorSnapshot) {
        let now = ProcessInfo.processInfo.systemUptime

        // Update acceleration history
        if let accel = snapshot.acceleration {
            accelHistory.append(accel)
        }

        let newState = evaluate(snapshot, now: now)

        if newState != currentState {
            currentState = newState
            stateEntryTime = now
            if case .happy = newState { happyStartTime = now }
        }
    }

    private func evaluate(_ snapshot: SensorSnapshot, now: TimeInterval) -> PetState {
        // 1. SCARED: sudden jerk (high delta in acceleration)
        if now < scaredUntil {
            return .scared
        }
        if let jerk = computeJerk(), jerk > MoodTransitionRules.scared.enter {
            scaredUntil = now + MoodTransitionRules.scaredDuration
            return .scared
        }

        // 2. VOMIT: sustained high acceleration magnitude
        if let avgMag = recentAverageMagnitude(windowSeconds: 1.0, now: now) {
            if avgMag > MoodTransitionRules.vomit.enter {
                isInVomit = true
                lastHighMagnitudeTime = now
            }
            if isInVomit && avgMag < MoodTransitionRules.vomit.exit
                && (now - lastHighMagnitudeTime) > MoodTransitionRules.recoveryDelay {
                isInVomit = false
            }
            if isInVomit {
                let intensity = min((avgMag - 1.0) / 1.5, 1.0)
                return .vomit(intensity: max(intensity, 0.3))
            }
        }

        // 3. DIZZY: sustained tilt
        if let accel = snapshot.acceleration {
            let tilt = abs(accel.tiltAngle)
            if tilt > MoodTransitionRules.dizzy.enter {
                if lastTiltTime == 0 { lastTiltTime = now }
                if (now - lastTiltTime) > MoodTransitionRules.dizzy.holdTime {
                    isInDizzy = true
                }
            } else if tilt < MoodTransitionRules.dizzy.exit {
                lastTiltTime = 0
                if isInDizzy && (now - stateEntryTime) > MoodTransitionRules.recoveryDelay {
                    isInDizzy = false
                }
            }
            if isInDizzy {
                return .dizzy(tiltAngle: accel.tiltAngle)
            }
        }

        // 4. SWEAT: high CPU temperature
        if let temp = snapshot.thermal?.cpuDieTemperature {
            if temp > MoodTransitionRules.sweat.enter {
                isInSweat = true
            } else if temp < MoodTransitionRules.sweat.exit {
                isInSweat = false
            }
            if isInSweat {
                return .sweat(temperature: temp)
            }
        }

        // 5. SHIVER: low CPU temperature
        if let temp = snapshot.thermal?.cpuDieTemperature {
            if temp < MoodTransitionRules.shiver.enter {
                isInShiver = true
            } else if temp > MoodTransitionRules.shiver.exit {
                isInShiver = false
            }
            if isInShiver {
                return .shiver
            }
        }

        // 6. SLEEP: idle too long
        if snapshot.secondsSinceLastUserInput > MoodTransitionRules.sleep.enter {
            return .sleep(duration: snapshot.secondsSinceLastUserInput)
        }

        // 7. IDLE vs HAPPY
        if case .happy = currentState,
           (now - happyStartTime) > MoodTransitionRules.happyToIdleTime {
            return .idle
        }

        return .happy
    }

    // MARK: - Acceleration Analysis

    private func computeJerk() -> Double? {
        let readings = accelHistory.toArray()
        guard readings.count >= 2 else { return nil }

        let latest = readings[readings.count - 1]
        let previous = readings[readings.count - 2]
        let dt = latest.timestamp - previous.timestamp
        guard dt > 0 else { return nil }

        let dx = latest.x - previous.x
        let dy = latest.y - previous.y
        let dz = latest.z - previous.z
        return sqrt(dx * dx + dy * dy + dz * dz) / dt
    }

    private func recentAverageMagnitude(windowSeconds: TimeInterval, now: TimeInterval) -> Double? {
        let readings = accelHistory.toArray()
        let recent = readings.filter { now - $0.timestamp <= windowSeconds }
        guard !recent.isEmpty else { return nil }
        let sum = recent.reduce(0.0) { $0 + $1.magnitude }
        return sum / Double(recent.count)
    }
}
