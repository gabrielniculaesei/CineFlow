import SwiftUI

struct AppTheme {
    // MARK: - Colors
    static let background = Color(red: 0.07, green: 0.07, blue: 0.13)
    static let cardBackground = Color(red: 0.12, green: 0.12, blue: 0.20)
    static let cardBackgroundLight = Color(red: 0.16, green: 0.16, blue: 0.25)
    static let accent = Color(red: 1.0, green: 0.78, blue: 0.28) // Gold
    static let accentSecondary = Color(red: 0.91, green: 0.30, blue: 0.24) // Cinema Red
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.65, green: 0.65, blue: 0.75)
    static let textTertiary = Color(red: 0.45, green: 0.45, blue: 0.55)
    
    // Genre Colors
    static let actionColor = Color(red: 1.0, green: 0.35, blue: 0.25)
    static let comedyColor = Color(red: 1.0, green: 0.82, blue: 0.20)
    static let dramaColor = Color(red: 0.58, green: 0.44, blue: 0.86)
    static let horrorColor = Color(red: 0.30, green: 0.69, blue: 0.31)
    static let romanceColor = Color(red: 0.93, green: 0.36, blue: 0.55)
    static let sciFiColor = Color(red: 0.25, green: 0.61, blue: 0.96)
    static let thrillerColor = Color(red: 0.85, green: 0.26, blue: 0.22)
    static let animationColor = Color(red: 0.98, green: 0.55, blue: 0.24)
    static let mysteryColor = Color(red: 0.40, green: 0.73, blue: 0.72)
    static let adventureColor = Color(red: 0.47, green: 0.84, blue: 0.38)
    static let crimeColor = Color(red: 0.60, green: 0.60, blue: 0.60)
    static let fantasyColor = Color(red: 0.73, green: 0.52, blue: 0.90)
    
    static func genreColor(for genre: Genre) -> Color {
        switch genre {
        case .action: return actionColor
        case .comedy: return comedyColor
        case .drama: return dramaColor
        case .horror: return horrorColor
        case .romance: return romanceColor
        case .sciFi: return sciFiColor
        case .thriller: return thrillerColor
        case .animation: return animationColor
        case .mystery: return mysteryColor
        case .adventure: return adventureColor
        case .crime: return crimeColor
        case .fantasy: return fantasyColor
        }
    }
    
    // MARK: - Gradients
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.07, green: 0.07, blue: 0.13),
            Color(red: 0.10, green: 0.08, blue: 0.18)
        ],
        startPoint: .top, endPoint: .bottom
    )
    
    static let cardGradient = LinearGradient(
        colors: [
            Color(red: 0.15, green: 0.15, blue: 0.25).opacity(0.8),
            Color(red: 0.10, green: 0.10, blue: 0.18).opacity(0.9)
        ],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    
    static let goldGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.85, blue: 0.35),
            Color(red: 1.0, green: 0.70, blue: 0.20)
        ],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    
    static let accentGradient = LinearGradient(
        colors: [
            Color(red: 0.91, green: 0.30, blue: 0.24),
            Color(red: 0.80, green: 0.20, blue: 0.40)
        ],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    
    // MARK: - Dimensions
    static let cornerRadius: CGFloat = 16
    static let smallCornerRadius: CGFloat = 10
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
}

// MARK: - View Modifiers

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = AppTheme.cornerRadius
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppTheme.cardBackground.opacity(0.7))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.05), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .offset(x: phase)
                .onAppear {
                    withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                        phase = 200
                    }
                }
            )
            .clipped()
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = AppTheme.cornerRadius) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
    
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}
