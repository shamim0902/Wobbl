import Foundation
import Combine

final class SensorManager: ObservableObject {
    @Published private(set) var latestSnapshot: SensorSnapshot = .idle

    private let accelerometer = AccelerometerReader()
    private let temperature = TemperatureReader()
    private let idle = IdleDetector()

    private var pollTimer: Timer?
    private var latestAccel: AccelReading?

    func start() {
        // Accelerometer: callback-driven (push model, downsampled to 20Hz)
        accelerometer.start { [weak self] reading in
            guard let self = self else { return }
            self.latestAccel = reading
            self.publishSnapshot()
        }

        // Temperature + idle: polled every 5 seconds
        _ = temperature.open()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.pollSlowSensors()
        }
        // Initial poll
        pollSlowSensors()
    }

    func stop() {
        accelerometer.stop()
        temperature.close()
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func pollSlowSensors() {
        publishSnapshot()
    }

    private func publishSnapshot() {
        let temp = temperature.readCPUTemperature()
        let idleTime = idle.secondsSinceLastInput()

        latestSnapshot = SensorSnapshot(
            acceleration: latestAccel,
            thermal: temp.map { ThermalReading(cpuDieTemperature: $0, timestamp: ProcessInfo.processInfo.systemUptime) },
            secondsSinceLastUserInput: idleTime
        )
    }
}
