import Foundation
import IOKit

// Swift-friendly wrappers for common IOKit operations.

enum IOKitHelpers {
    /// Find a matching IOService by class name.
    static func findService(className: String) -> io_service_t? {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching(className)
        )
        return service != 0 ? service : nil
    }

    /// Open a connection to an IOService.
    static func openConnection(to service: io_service_t, type: UInt32 = 0) -> io_connect_t? {
        var connection: io_connect_t = 0
        let result = IOServiceOpen(service, mach_task_self_, type, &connection)
        return result == KERN_SUCCESS ? connection : nil
    }
}
