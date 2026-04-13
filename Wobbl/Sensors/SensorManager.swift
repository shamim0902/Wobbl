import Foundation
import Combine

final class SensorManager: ObservableObject {
    @Published private(set) var latestSnapshot: SensorSnapshot = .idle

    private let accelerometer = AccelerometerReader()
    private let temperature = TemperatureReader()
    private let idle = IdleDetector()

    private var stateTimer: Timer?
    private var slowSensorTimer: Timer?
    private var latestAccel: AccelReading?
    private var latestThermal: ThermalReading?

    private let stateUpdateInterval: TimeInterval = 0.25
    private let slowSensorPollInterval: TimeInterval = 5.0
    private let accelFreshnessWindow: TimeInterval = 0.35

    func start() {
        // Accelerometer: callback-driven (push model, downsampled to 20Hz)
        accelerometer.start { [weak self] reading in
            guard let self = self else { return }
            self.latestAccel = reading
            self.publishSnapshot()
        }

        _ = temperature.open()
        refreshSlowSensors()
        startStateTimer()
        startSlowSensorTimer()
        publishSnapshot()
    }

    func stop() {
        accelerometer.stop()
        temperature.close()
        stateTimer?.invalidate()
        stateTimer = nil
        slowSensorTimer?.invalidate()
        slowSensorTimer = nil
    }

    private func startStateTimer() {
        let timer = Timer(timeInterval: stateUpdateInterval, repeats: true) { [weak self] _ in
            self?.publishSnapshot()
        }
        RunLoop.main.add(timer, forMode: .common)
        stateTimer = timer
    }

    private func startSlowSensorTimer() {
        let timer = Timer(timeInterval: slowSensorPollInterval, repeats: true) { [weak self] _ in
            self?.refreshSlowSensors()
        }
        RunLoop.main.add(timer, forMode: .common)
        slowSensorTimer = timer
    }

    private func refreshSlowSensors() {
        let now = ProcessInfo.processInfo.systemUptime
        latestThermal = temperature.readCPUTemperature().map {
            ThermalReading(cpuDieTemperature: $0, timestamp: now)
        }
        publishSnapshot()
    }

    private func currentAcceleration(now: TimeInterval) -> AccelReading? {
        guard let latestAccel else { return nil }
        guard now - latestAccel.timestamp <= accelFreshnessWindow else { return nil }
        return latestAccel
    }

    private func publishSnapshot() {
        let now = ProcessInfo.processInfo.systemUptime
        let idleTime = idle.secondsSinceLastInput()

        latestSnapshot = SensorSnapshot(
            acceleration: currentAcceleration(now: now),
            thermal: latestThermal,
            secondsSinceLastUserInput: idleTime
        )
    }
}
