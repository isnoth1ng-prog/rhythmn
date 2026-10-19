import SwiftUI

struct ArtistHeaderView: View {
    let artist: Artist
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background Image
            AsyncImage(url: URL(string: artist.imageUrl)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .empty:
                    Color.appSurface
                case .failure:
                    ZStack {
                        Color.appSurface
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.appTextSecondary)
                    }
                @unknown default:
                    Color.appSurface
                }
            }
            .frame(height: 300)
            .frame(maxWidth: .infinity)
            .clipped()
            
            // Gradient Overlay
            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(0.3),
                    .black.opacity(0.85),
                    Color.appBackground
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 300)
            
            // Artist Info
            VStack(alignment: .leading, spacing: 6) {
                Text(artist.name)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 6, x: 0, y: 2)
                
                if let subs = artist.subscriberCount, !subs.isEmpty {
                    Text(subs)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.appTextSecondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .frame(height: 300)
    }
}
