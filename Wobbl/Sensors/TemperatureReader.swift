import Foundation
import IOKit

// Private IOKit HID Event System for reading real temperature from Apple Silicon sensors.
// Uses the Monitor client type to access PMU die temperature services.
private typealias IOHIDEventSystemClientRef = OpaquePointer
private typealias IOHIDServiceClientRef = OpaquePointer
private typealias IOHIDEventRef = OpaquePointer

@_silgen_name("IOHIDEventSystemClientCreateWithType")
private func IOHIDEventSystemClientCreateWithType(
    _ allocator: CFAllocator?, _ clientType: Int32, _ properties: CFDictionary?
) -> IOHIDEventSystemClientRef?

@_silgen_name("IOHIDEventSystemClientSetMatching")
private func IOHIDEventSystemClientSetMatching(_ client: IOHIDEventSystemClientRef, _ match: CFDictionary)

@_silgen_name("IOHIDEventSystemClientCopyServices")
private func IOHIDEventSystemClientCopyServices(_ client: IOHIDEventSystemClientRef) -> CFArray?

@_silgen_name("IOHIDServiceClientCopyProperty")
private func IOHIDServiceClientCopyProperty(_ service: IOHIDServiceClientRef, _ key: CFString) -> CFTypeRef?

@_silgen_name("IOHIDServiceClientCopyEvent")
private func IOHIDServiceClientCopyEvent(
    _ service: IOHIDServiceClientRef, _ type: Int64, _ matching: CFDictionary?, _ options: Int64
) -> IOHIDEventRef?

@_silgen_name("IOHIDEventGetFloatValue")
private func IOHIDEventGetFloatValue(_ event: IOHIDEventRef, _ field: UInt32) -> Double

private let kIOHIDEventTypeTemperature: Int64 = 15
private let kTempField: UInt32 = (15 << 16) | 0  // float0 has the temperature in °C


final class TemperatureReader {
    private var client: IOHIDEventSystemClientRef?
    private var temperatureServices: [IOHIDServiceClientRef] = []

    func open() -> Bool {
        // Monitor client (type 1) has access to all HID event services
        guard let c = IOHIDEventSystemClientCreateWithType(kCFAllocatorDefault, 1, nil) else {
            return false
        }
        client = c

        // Match temperature sensors (UsagePage=0xFF00, Usage=5 on Apple Silicon)
        let matchDict: [String: Any] = [
            "PrimaryUsagePage": 0xFF00,
            "PrimaryUsage": 5,
        ]
        IOHIDEventSystemClientSetMatching(c, matchDict as CFDictionary)

        guard let services = IOHIDEventSystemClientCopyServices(c) else {
            return false
        }

        let count = CFArrayGetCount(services)
        for i in 0..<count {
            let service = unsafeBitCast(
                CFArrayGetValueAtIndex(services, i),
                to: IOHIDServiceClientRef.self
            )

            if let event = IOHIDServiceClientCopyEvent(service, kIOHIDEventTypeTemperature, nil, 0) {
                let temp = IOHIDEventGetFloatValue(event, kTempField)
                if temp > 10 && temp < 120 {
                    temperatureServices.append(service)
                }
            }
        }

        return !temperatureServices.isEmpty
    }

    /// Read the highest temperature from all CPU die sensors.
    func readCPUTemperature() -> Double? {
        var maxTemp: Double = 0

        for service in temperatureServices {
            guard let event = IOHIDServiceClientCopyEvent(service, kIOHIDEventTypeTemperature, nil, 0) else {
                continue
            }
            let temp = IOHIDEventGetFloatValue(event, kTempField)
            if temp > maxTemp && temp < 120 {
                maxTemp = temp
            }
        }

        return maxTemp > 0 ? maxTemp : nil
    }

    func close() {
        temperatureServices.removeAll()
        client = nil
    }

    deinit {
        close()
    }
}
