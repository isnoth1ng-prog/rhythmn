import SwiftUI

struct HomeView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var libraryVM: LibraryViewModel
    @StateObject private var viewModel = HomeViewModel()
    @State private var showSettings: Bool = false
    @State private var selectedGenre: String = "Все"
    @AppStorage("custom_backend_url") private var backendUrl: String = "http://192.168.0.13:8000/api"

    private let genres = ["Все", "🔥 Чарты", "⚡ Фонк", "🎤 Рэп", "🎸 Рок", "🌌 Чилл", "🏎 В авто"]

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    // MARK: - Greeting Header & Status
                    headerSection
                        .padding(.horizontal, 18)
                        .padding(.top, 4)

                    // MARK: - Quick Genre Pills
                    genreFilterPills
                        .padding(.horizontal, 16)

                    if viewModel.isLoading {
                        loadingPlaceholder
                    } else {
                        // MARK: - Новинки (Horizontal Carousel)
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeaderView(title: "Новинки недели")
                                .padding(.horizontal, 18)

                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 16) {
                                    ForEach(viewModel.newReleases) { track in
                                        TrackCardView(track: track)
                                            .environmentObject(playerVM)
                                    }
                                }
                                .padding(.horizontal, 18)
                            }
                        }

                        // MARK: - Рекомендации (Vertical List)
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeaderView(title: "Рекомендации для вас")
                                .padding(.horizontal, 18)

                            LazyVStack(spacing: 6) {
                                ForEach(Array(viewModel.recommendations.enumerated()), id: \.element.id) { index, track in
                                    TrackRowView(track: track, trackNumber: index + 1) {
                                        playerVM.playQueue(tracks: viewModel.recommendations, startIndex: index)
                                    }
                                    .environmentObject(playerVM)
                                    .environmentObject(libraryVM)
                                }
                            }
                            .padding(.horizontal, 14)
                        }
                    }

                    Spacer().frame(height: playerVM.currentTrack != nil ? 90 : 30)
                }
            }
            .background(
                LinearGradient(
                    colors: [Color.appBackground, Color.appBackgroundSecondary, Color(hex: "08080C")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 8) {
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.appAccentGradient)
                        
                        Text("Rhythm")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    serverStatusBadge
                }
            }
            .alert("Настройки сервера", isPresented: $showSettings) {
                TextField("URL бэкенда", text: $backendUrl)
                Button("Сохранить") {
                    Task { await viewModel.loadContent() }
                }
                Button("Сервер ПК (192.168.0.13)") {
                    backendUrl = "http://192.168.0.13:8000/api"
                    Task { await viewModel.loadContent() }
                }
                Button("По умолчанию (localhost)") {
                    backendUrl = "http://localhost:8000/api"
                    Task { await viewModel.loadContent() }
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Укажите адрес сервера VibeFlow (например, ссылку Cloudflare https://xxx.trycloudflare.com/api или локальный IP ПК http://192.168.0.13:8000/api). При недоступности сервера музыка играет автономно.")
            }
            .task {
                await viewModel.loadContent()
            }
            .refreshable {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                await viewModel.loadContent()
            }
        }
    }

    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(timeGreeting)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.appAccentPink)
                .textCase(.uppercase)

            Text("Музыка для вас")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }

    private var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Доброе утро"
        case 12..<18: return "Добрый день"
        case 18..<23: return "Добрый вечер"
        default: return "Доброй ночи"
        }
    }

    // MARK: - Server Status Badge in Navigation Bar
    
    private var serverStatusBadge: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showSettings = true
        } label: {
            HStack(spacing: 5) {
                Circle()
                    .fill(badgeColor)
                    .frame(width: 8, height: 8)

                Text(badgeText)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))

                Image(systemName: "gearshape.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.08))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
        }
    }

    private var badgeColor: Color {
        if backendUrl.contains("trycloudflare") {
            return .appAccentCyan
        } else if backendUrl.contains("192.168") || backendUrl.contains("localhost") {
            return .green
        } else {
            return .orange
        }
    }

    private var badgeText: String {
        if backendUrl.contains("trycloudflare") {
            return "Туннель"
        } else if backendUrl.contains("192.168") {
            return "ПК Сервер"
        } else {
            return "Сервер"
        }
    }

    // MARK: - Quick Genre Pills
    
    private var genreFilterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(genres, id: \.self) { genre in
                    let isSelected = (selectedGenre == genre)
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectedGenre = genre
                    } label: {
                        Text(genre)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(isSelected ? .white : .appTextSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                isSelected
                                    ? Color.appAccentGradient
                                    : LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.04)], startPoint: .top, endPoint: .bottom)
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(isSelected ? Color.clear : Color.white.opacity(0.1), lineWidth: 0.5)
                            )
                    }
                }
            }
        }
    }

    // MARK: - Loading Placeholder
    
    private var loadingPlaceholder: some View {
        VStack(alignment: .leading, spacing: 24) {
            ShimmerView(width: 140, height: 24, cornerRadius: 6)
                .padding(.horizontal, 18)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0..<4, id: \.self) { _ in
                        VStack(alignment: .leading, spacing: 8) {
                            ShimmerView(width: 156, height: 156, cornerRadius: 18)
                            ShimmerView(width: 120, height: 14, cornerRadius: 4)
                            ShimmerView(width: 80, height: 12, cornerRadius: 4)
                        }
                    }
                }
                .padding(.horizontal, 18)
            }

            ShimmerView(width: 160, height: 24, cornerRadius: 6)
                .padding(.horizontal, 18)

            VStack(spacing: 10) {
                ForEach(0..<5, id: \.self) { _ in
                    HStack(spacing: 12) {
                        ShimmerView(width: 50, height: 50, cornerRadius: 10)
                        VStack(alignment: .leading, spacing: 6) {
                            ShimmerView(width: 180, height: 14, cornerRadius: 4)
                            ShimmerView(width: 110, height: 12, cornerRadius: 4)
                        }
                        Spacer()
                        ShimmerView(width: 36, height: 12, cornerRadius: 4)
                    }
                    .padding(.horizontal, 18)
                }
            }
        }
    }
}
