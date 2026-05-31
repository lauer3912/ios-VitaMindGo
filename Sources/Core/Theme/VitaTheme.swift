import SwiftUI

// MARK: - Design Tokens
enum VitaTheme {
    // MARK: - Colors
    enum Colors {
        static let primary = Color(hex: "6B4EFF")
        static let secondary = Color(hex: "00D9A")
        static let accent = Color(hex: "FFD700")
        static let background = Color(hex: "0D0B1E")
        static let surface = Color(hex: "1A1730")
        static let surfaceLight = Color(hex: "252040")
        
        static let cardRare = Color(hex: "FF6B6B")
        static let cardEpic = Color(hex: "9B59B6")
        static let cardLegendary = Color(hex: "FFD700")
        static let cardCommon = Color(hex: "4ECDC4")
        static let cardUncommon = Color(hex: "6B4EFF")
        
        static let success = Color(hex: "2ECC71")
        static let warning = Color(hex: "F39C12")
        static let error = Color(hex: "E74C3C")
        
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.7)
        static let textTertiary = Color.white.opacity(0.5)
    }
    
    // MARK: - Gradients
    enum Gradients {
        static let primary = LinearGradient(
            colors: [Colors.primary, Colors.primary.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let gold = LinearGradient(
            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let cardBackground = LinearGradient(
            colors: [Color(hex: "1A1730"), Color(hex: "0D0B1E")],
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let epic = LinearGradient(
            colors: [Color(hex: "9B59B6"), Color(hex: "8E44AD")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Shadows
    enum Shadows {
        static let card = Shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
        static let glow = Shadow(color: Colors.primary.opacity(0.5), radius: 12, x: 0, y: 0)
        static let glowGold = Shadow(color: Colors.accent.opacity(0.6), radius: 15, x: 0, y: 0)
    }
    
    // MARK: - Fonts
    enum Fonts {
        static let displayBold = SwiftUI.Font.system(size: 28, weight: .bold, design: .rounded)
        static let displaySemibold = SwiftUI.Font.system(size: 24, weight: .semibold, design: .rounded)
        static let title = SwiftUI.Font.system(size: 20, weight: .bold, design: .rounded)
        static let titleMedium = SwiftUI.Font.system(size: 18, weight: .medium, design: .rounded)
        static let body = SwiftUI.Font.system(size: 16, weight: .regular, design: .default)
        static let caption = SwiftUI.Font.system(size: 13, weight: .regular, design: .default)
        static let captionBold = SwiftUI.Font.system(size: 12, weight: .bold, design: .rounded)
        static let statNumber = SwiftUI.Font.system(size: 32, weight: .bold, design: .monospaced)
        static let statLabel = SwiftUI.Font.system(size: 11, weight: .medium, design: .rounded)
    }
    
    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let card: CGFloat = 16
    }
}

// MARK: - Color Extension
extension Color {
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

// MARK: - Shadow Model
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Modifier for Shadows
struct CardShadow: ViewModifier {
    let shadow: Shadow
    
    func body(content: Content) -> some View {
        content
            .shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

extension View {
    func cardShadow(_ shadow: Shadow) -> some View {
        modifier(CardShadow(shadow: shadow))
    }
}