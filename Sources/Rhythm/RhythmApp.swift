import SwiftUI

@main
struct RhythmApp: App {
    @UIApplicationDelegateAdaptor(RhythmAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
