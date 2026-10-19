import SwiftUI

@main
struct RhythmApp: App {
    @StateObject private var playerVM = PlayerViewModel()
    @StateObject private var libraryVM = LibraryViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(playerVM)
                .environmentObject(libraryVM)
                .preferredColorScheme(.dark)
        }
    }
}
