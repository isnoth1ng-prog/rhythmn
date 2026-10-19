import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Главная")
                }
                .tag(0)

            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Поиск")
                }
                .tag(1)

            LibraryView()
                .tabItem {
                    Image(systemName: "books.vertical.fill")
                    Text("Библиотека")
                }
                .tag(2)

            WaveView()
                .tabItem {
                    Image(systemName: "waveform")
                    Text("Моя Волна")
                }
                .tag(3)
        }
        .tint(Color.appAccentPink)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.appBackground)
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.appTextSecondary)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.appTextSecondary)]
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
