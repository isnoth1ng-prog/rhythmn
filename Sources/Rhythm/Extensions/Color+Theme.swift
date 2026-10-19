import SwiftUI

extension Color {
    // Premium OLED Dark Palette
    static let appBackground = Color(hex: "08080C")
    static let appBackgroundSecondary = Color(hex: "12121E")
    static let appSurface = Color(hex: "181826")
    static let appSurfaceLight = Color(hex: "232338")
    static let appCardBg = Color(hex: "1C1C2E").opacity(0.7)
    
    // Vibrant Neon Accents
    static let appAccentPink = Color(hex: "FF2D55")
    static let appAccentPurple = Color(hex: "AF52DE")
    static let appAccentCyan = Color(hex: "00C8FE")
    static let appAccentOrange = Color(hex: "FF6B35")
    static let appTextSecondary = Color.white.opacity(0.65)
    static let appTextTertiary = Color.white.opacity(0.4)
    
    // Gradients
    static var appAccentGradient: LinearGradient {
        LinearGradient(
            colors: [.appAccentPink, .appAccentPurple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var appNeonGradient: LinearGradient {
        LinearGradient(
            colors: [.appAccentPink, .appAccentPurple, .appAccentCyan],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    static var appCardGradient: LinearGradient {
        LinearGradient(
            colors: [Color.white.opacity(0.1), Color.white.opacity(0.03)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
