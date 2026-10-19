import SwiftUI

struct AlbumCardView: View {
    let album: Album
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                AsyncImage(url: URL(string: album.thumbnailUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty:
                        ZStack {
                            Color.appSurface
                            ProgressView()
                                .tint(.appAccentPink)
                        }
                    case .failure:
                        ZStack {
                            Color.appSurface
                            Image(systemName: "opticaldisc")
                                .font(.system(size: 32))
                                .foregroundColor(.appTextSecondary)
                        }
                    @unknown default:
                        Color.appSurface
                    }
                }
                .aspectRatio(1.0, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(album.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if let year = album.year, !year.isEmpty {
                        Text(year)
                            .font(.system(size: 12))
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}
