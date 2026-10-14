import ActivityKit
import UIKit

@MainActor
final class RhythmAppDelegate: NSObject, UIApplicationDelegate {
    func applicationWillTerminate(_ application: UIApplication) {
        Task {
            await RhythmActivityController.endAll()
        }
    }
}
