import Foundation

struct AccelReading: Sendable {
    let x: Double
    let y: Double
    let z: Double
    let timestamp: TimeInterval

    var magnitude: Double { sqrt(x * x + y * y + z * z) }
    var tiltAngle: Double { atan2(x, z) }

    static let zero = AccelReading(x: 0, y: 0, z: -1, timestamp: 0)
}

struct ThermalReading: Sendable {
    let cpuDieTemperature: Double  // Celsius
    let timestamp: TimeInterval

    static let normal = ThermalReading(cpuDieTemperature: 50.0, timestamp: 0)
}

struct SensorSnapshot {
    let acceleration: AccelReading?
    let thermal: ThermalReading?
    let secondsSinceLastUserInput: TimeInterval

    static let idle = SensorSnapshot(acceleration: nil, thermal: nil, secondsSinceLastUserInput: 0)
}
