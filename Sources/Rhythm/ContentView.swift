import SwiftUI

struct ContentView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var libraryVM: LibraryViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBackground
                .ignoresSafeArea()

            MainTabView()

            if playerVM.currentTrack != nil {
                VStack(spacing: 0) {
                    MiniPlayerView()
                        .environmentObject(playerVM)
                        .environmentObject(libraryVM)
                    Spacer().frame(height: 52) // clearance above tab bar
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            }
        }
        .ignoresSafeArea(.keyboard)
        .animation(.spring(response: 0.38, dampingFraction: 0.8), value: playerVM.currentTrack != nil)
        .fullScreenCover(isPresented: $playerVM.showFullPlayer) {
            FullPlayerView()
                .environmentObject(playerVM)
                .environmentObject(libraryVM)
        }
    }
}
