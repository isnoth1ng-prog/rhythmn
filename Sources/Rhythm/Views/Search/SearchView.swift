import SwiftUI

struct SearchView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var libraryVM: LibraryViewModel
    @StateObject private var searchVM = SearchViewModel()

    private let browseGenres: [(title: String, colors: [Color], icon: String)] = [
        ("Хип-хоп & Рэп", [.appAccentPink, .appAccentPurple], "flame.fill"),
        ("Поп-хиты", [.appAccentPurple, .appAccentCyan], "star.fill"),
        ("Электроника", [.appAccentCyan, .blue], "bolt.fill"),
        ("Рок & Драйв", [.orange, .red], "guitars.fill"),
        ("Фонк & Басс", [Color(hex: "8A2387"), Color(hex: "E94057")], "speaker.wave.3.fill"),
        ("Lo-Fi & Чилл", [Color(hex: "11998E"), Color(hex: "38EF7D")], "moon.stars.fill")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Search Bar
                searchBar
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                // MARK: - Search Type Segmented Control
                Picker("", selection: $searchVM.searchType) {
                    ForEach(SearchType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // MARK: - Body Content
                if searchVM.query.isEmpty {
                    browseCategoriesView
                } else if searchVM.isSearching {
                    Spacer()
                    ProgressView()
                        .tint(.appAccentPink)
                        .scaleEffect(1.3)
                    Spacer()
                } else {
                    resultsView
                }
            }
            .background(
                LinearGradient(
                    colors: [Color.appBackground, Color.appBackgroundSecondary],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Поиск")
            .navigationBarTitleDisplayMode(.large)
            .onChange(of: searchVM.query) { _ in
                searchVM.search()
            }
            .onChange(of: searchVM.searchType) { _ in
                searchVM.search()
            }
        }
    }

    // MARK: - Search Bar Component
    
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.appAccentPink)

            TextField("", text: $searchVM.query, prompt: Text("Треки, артисты, альбомы...").foregroundColor(.appTextSecondary))
                .foregroundColor(.white)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !searchVM.query.isEmpty {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    searchVM.query = ""
                    searchVM.search()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Browse Categories (When search query is empty)
    
    private var browseCategoriesView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Обзор категорий")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.top, 8)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                    ForEach(browseGenres, id: \.title) { item in
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            searchVM.query = item.title.components(separatedBy: " ").first ?? item.title
                            searchVM.search()
                        } label: {
                            ZStack(alignment: .bottomLeading) {
                                LinearGradient(
                                    colors: item.colors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )

                                // Decorative background icon
                                Image(systemName: item.icon)
                                    .font(.system(size: 42, weight: .black))
                                    .foregroundColor(.white.opacity(0.2))
                                    .offset(x: 50, y: 10)
                                    .rotationEffect(.degrees(-15))

                                Text(item.title)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(14)
                                    .multilineTextAlignment(.leading)
                            }
                            .frame(height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: item.colors[0].opacity(0.35), radius: 10, x: 0, y: 5)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)

                Spacer().frame(height: playerVM.currentTrack != nil ? 90 : 30)
            }
        }
    }

    // MARK: - Results View
    
    private var resultsView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 4) {
                switch searchVM.searchType {
                case .tracks:
                    if searchVM.trackResults.isEmpty {
                        noResultsView
                    } else {
                        ForEach(Array(searchVM.trackResults.enumerated()), id: \.element.id) { index, track in
                            TrackRowView(track: track, trackNumber: index + 1) {
                                playerVM.playQueue(tracks: searchVM.trackResults, startIndex: index)
                            }
                            .environmentObject(playerVM)
                            .environmentObject(libraryVM)
                        }
                    }

                case .artists:
                    if searchVM.artistResults.isEmpty {
                        noResultsView
                    } else {
                        ForEach(searchVM.artistResults) { artist in
                            NavigationLink(destination: ArtistView(artistId: artist.id)) {
                                artistRow(artist)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, playerVM.currentTrack != nil ? 90 : 20)
        }
    }

    private func artistRow(_ artist: Artist) -> some View {
        HStack(spacing: 14) {
            AsyncImage(url: URL(string: artist.imageUrl)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 52, height: 52)
                        .clipped()
                case .failure, .empty:
                    ZStack {
                        Color.appSurface
                        Image(systemName: "person.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.appTextSecondary)
                    }
                    .frame(width: 52, height: 52)
                @unknown default:
                    Color.appSurface
                        .frame(width: 52, height: 52)
                }
            }
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
            .shadow(radius: 4)

            VStack(alignment: .leading, spacing: 3) {
                Text(artist.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)

                if let subscriberCount = artist.subscriberCount {
                    Text(subscriberCount)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.appTextSecondary.opacity(0.6))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var noResultsView: some View {
        VStack(spacing: 14) {
            Spacer().frame(height: 70)
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44))
                .foregroundColor(.appTextSecondary.opacity(0.5))
            Text("Ничего не найдено")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("Попробуйте изменить запрос или поискать другое имя")
                .font(.system(size: 14))
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
    }
}
