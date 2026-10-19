import SwiftUI

struct HomeView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @StateObject private var viewModel = HomeViewModel()
    @State private var showSettings: Bool = false
    @AppStorage("custom_backend_url") private var backendUrl: String = "http://192.168.0.13:8000/api"

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    if viewModel.isLoading {
                        loadingPlaceholder
                    } else {
                        // MARK: - Новинки
                        SectionHeaderView(title: "Новинки")

                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 14) {
                                ForEach(viewModel.newReleases) { track in
                                    TrackCardView(track: track)
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        // MARK: - Рекомендации
                        SectionHeaderView(title: "Рекомендации")

                        LazyVStack(spacing: 4) {
                            ForEach(Array(viewModel.recommendations.enumerated()), id: \.element.id) { index, track in
                                TrackRowView(track: track) {
                                    playerVM.playQueue(tracks: viewModel.recommendations, startIndex: index)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, playerVM.currentTrack != nil ? 80 : 16)
            }
            .background(
                LinearGradient(
                    colors: [.appBackground, .appBackgroundSecondary],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Главная")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .alert("Настройки сервера", isPresented: $showSettings) {
                TextField("URL бэкенда", text: $backendUrl)
                Button("Сохранить") {
                    Task {
                        await viewModel.loadContent()
                    }
                }
                Button("Сервер ПК (192.168.0.13)") {
                    backendUrl = "http://192.168.0.13:8000/api"
                    Task {
                        await viewModel.loadContent()
                    }
                }
                Button("По умолчанию (localhost)") {
                    backendUrl = "http://localhost:8000/api"
                    Task {
                        await viewModel.loadContent()
                    }
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Укажите адрес сервера VibeFlow (например, http://192.168.0.13:8000/api для ПК с yt-dlp). При недоступности сервера приложение автономно воспроизводит треки и синхронные тексты.")
            }
            .task {
                await viewModel.loadContent()
            }
            .refreshable {
                await viewModel.loadContent()
            }
        }
    }

    // MARK: - Loading Placeholder

    private var loadingPlaceholder: some View {
        VStack(alignment: .leading, spacing: 24) {
            ShimmerView(width: 120, height: 24, cornerRadius: 6)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(0..<5, id: \.self) { _ in
                        VStack(alignment: .leading, spacing: 8) {
                            ShimmerView(width: 160, height: 160, cornerRadius: 12)
                            ShimmerView(width: 120, height: 14, cornerRadius: 4)
                            ShimmerView(width: 80, height: 12, cornerRadius: 4)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }

            ShimmerView(width: 160, height: 24, cornerRadius: 6)
                .padding(.horizontal, 16)

            VStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { _ in
                    HStack(spacing: 12) {
                        ShimmerView(width: 50, height: 50, cornerRadius: 8)
                        VStack(alignment: .leading, spacing: 6) {
                            ShimmerView(width: 180, height: 14, cornerRadius: 4)
                            ShimmerView(width: 120, height: 12, cornerRadius: 4)
                        }
                        Spacer()
                        ShimmerView(width: 36, height: 12, cornerRadius: 4)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
