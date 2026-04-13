import SwiftUI

@main
struct WobblApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No visible window scene — the app lives in the menu bar
        // and uses a custom floating NSWindow for the pet
        Settings {
            EmptyView()
        }
    }
}
