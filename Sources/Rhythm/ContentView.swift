import SwiftUI

struct ContentView: View {
    @EnvironmentObject var playerVM: PlayerViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBackground
                .ignoresSafeArea()

            MainTabView()

            if playerVM.currentTrack != nil {
                VStack(spacing: 0) {
                    MiniPlayerView()
                    Spacer().frame(height: 54) // tab bar height
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .ignoresSafeArea(.keyboard)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: playerVM.currentTrack != nil)
        .fullScreenCover(isPresented: $playerVM.showFullPlayer) {
            FullPlayerView()
                .environmentObject(playerVM)
        }
    }
}
