import SwiftUI

struct SearchView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @StateObject private var searchVM = SearchViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Search Bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.appTextSecondary)

                    TextField("", text: $searchVM.query, prompt: Text("Поиск музыки...").foregroundColor(.appTextSecondary))
                        .foregroundColor(.white)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    if !searchVM.query.isEmpty {
                        Button {
                            searchVM.query = ""
                            searchVM.search()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.appTextSecondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // MARK: - Search Type Picker
                Picker("", selection: $searchVM.searchType) {
                    ForEach(SearchType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // MARK: - Results
                if searchVM.query.isEmpty {
                    emptyState
                } else if searchVM.isSearching {
                    Spacer()
                    ProgressView()
                        .tint(.appAccentPink)
                        .scaleEffect(1.2)
                    Spacer()
                } else {
                    resultsView
                }
            }
            .background(
                LinearGradient(
                    colors: [.appBackground, .appBackgroundSecondary],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Поиск")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onChange(of: searchVM.query) { _ in
                searchVM.search()
            }
            .onChange(of: searchVM.searchType) { _ in
                searchVM.search()
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.appAccentPink.opacity(0.6), .appAccentPurple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Введите запрос")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.appTextSecondary)

            Text("Найдите любимую музыку и артистов")
                .font(.system(size: 14))
                .foregroundColor(.appTextSecondary.opacity(0.7))
            Spacer()
        }
    }

    // MARK: - Results

    private var resultsView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 4) {
                switch searchVM.searchType {
                case .tracks:
                    if searchVM.trackResults.isEmpty {
                        noResultsView
                    } else {
                        ForEach(Array(searchVM.trackResults.enumerated()), id: \.element.id) { index, track in
                            TrackRowView(track: track) {
                                playerVM.playQueue(tracks: searchVM.trackResults, startIndex: index)
                            }
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
            .padding(.bottom, playerVM.currentTrack != nil ? 80 : 16)
        }
    }

    private func artistRow(_ artist: Artist) -> some View {
        HStack(spacing: 14) {
            AsyncImage(url: URL(string: artist.imageUrl)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    artistPlaceholder
                case .empty:
                    artistPlaceholder
                        .shimmer(isActive: true)
                @unknown default:
                    artistPlaceholder
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(artist.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                if let subscriberCount = artist.subscriberCount {
                    Text(subscriberCount)
                        .font(.system(size: 13))
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.appTextSecondary)
        }
        .padding(.vertical, 8)
    }

    private var artistPlaceholder: some View {
        Circle()
            .fill(Color.appSurface)
            .overlay {
                Image(systemName: "person.fill")
                    .foregroundColor(.appTextSecondary)
            }
    }

    private var noResultsView: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 60)
            Image(systemName: "music.note.list")
                .font(.system(size: 40))
                .foregroundColor(.appTextSecondary)
            Text("Ничего не найдено")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
