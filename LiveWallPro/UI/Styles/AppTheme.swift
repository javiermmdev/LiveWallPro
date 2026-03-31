import SwiftUI

/// Centralized theme constants for the app's premium glassmorphism aesthetic.
enum AppTheme {
    // Card styling
    static let cardCornerRadius: CGFloat = 16
    static let cardShadowRadius: CGFloat = 8
    static let cardHoverShadowRadius: CGFloat = 16

    // Grid
    static let gridMinItemWidth: CGFloat = 260
    static let gridMaxItemWidth: CGFloat = 400
    static let gridSpacing: CGFloat = 16
    static let gridPadding: CGFloat = 20

    // Badge
    static let badgeCornerRadius: CGFloat = 6
    static let badgePaddingH: CGFloat = 8
    static let badgePaddingV: CGFloat = 4

    // Animations
    static let hoverAnimationDuration: Double = 0.25
    static let hoverScaleEffect: CGFloat = 1.03
}

// MARK: - Gradient Theme Presets

enum GradientThemePreset: String, CaseIterable, Identifiable, Sendable {
    case aurora = "Aurora"
    case ocean = "Ocean"
    case sunset = "Sunset"
    case lavender = "Lavender"
    case emerald = "Emerald"
    case cherry = "Cherry"
    case midnight = "Midnight"
    case cosmic = "Cosmic"

    var id: String { rawValue }

    var colors: [Color] {
        switch self {
        case .aurora:
            return [Color(red: 0.1, green: 0.05, blue: 0.2),
                    Color(red: 0.15, green: 0.1, blue: 0.35),
                    Color(red: 0.05, green: 0.2, blue: 0.3)]
        case .ocean:
            return [Color(red: 0.02, green: 0.05, blue: 0.15),
                    Color(red: 0.05, green: 0.12, blue: 0.3),
                    Color(red: 0.02, green: 0.08, blue: 0.2)]
        case .sunset:
            return [Color(red: 0.2, green: 0.05, blue: 0.1),
                    Color(red: 0.3, green: 0.08, blue: 0.15),
                    Color(red: 0.15, green: 0.05, blue: 0.2)]
        case .lavender:
            return [Color(red: 0.12, green: 0.05, blue: 0.2),
                    Color(red: 0.2, green: 0.08, blue: 0.28),
                    Color(red: 0.1, green: 0.05, blue: 0.18)]
        case .emerald:
            return [Color(red: 0.02, green: 0.1, blue: 0.08),
                    Color(red: 0.05, green: 0.18, blue: 0.12),
                    Color(red: 0.02, green: 0.08, blue: 0.1)]
        case .cherry:
            return [Color(red: 0.2, green: 0.02, blue: 0.08),
                    Color(red: 0.28, green: 0.05, blue: 0.12),
                    Color(red: 0.15, green: 0.02, blue: 0.1)]
        case .midnight:
            return [Color(red: 0.05, green: 0.05, blue: 0.1),
                    Color(red: 0.08, green: 0.08, blue: 0.18),
                    Color(red: 0.03, green: 0.03, blue: 0.08)]
        case .cosmic:
            return [Color(red: 0.15, green: 0.02, blue: 0.2),
                    Color(red: 0.08, green: 0.05, blue: 0.25),
                    Color(red: 0.2, green: 0.02, blue: 0.15)]
        }
    }

    var accentColor: Color {
        switch self {
        case .aurora: return Color(red: 0.3, green: 0.8, blue: 0.7)
        case .ocean: return Color(red: 0.3, green: 0.6, blue: 1.0)
        case .sunset: return Color(red: 1.0, green: 0.5, blue: 0.3)
        case .lavender: return Color(red: 0.7, green: 0.5, blue: 1.0)
        case .emerald: return Color(red: 0.3, green: 0.9, blue: 0.5)
        case .cherry: return Color(red: 1.0, green: 0.3, blue: 0.4)
        case .midnight: return Color(red: 0.5, green: 0.6, blue: 0.9)
        case .cosmic: return Color(red: 0.8, green: 0.3, blue: 1.0)
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var meshGradient: some View {
        ZStack {
            gradient
            // Subtle noise-like overlay for depth
            RadialGradient(
                colors: [colors[1].opacity(0.4), .clear],
                center: .topTrailing,
                startRadius: 50,
                endRadius: 400
            )
            RadialGradient(
                colors: [colors.last!.opacity(0.3), .clear],
                center: .bottomLeading,
                startRadius: 30,
                endRadius: 350
            )
        }
    }
}

// MARK: - Glass Modifiers

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = AppTheme.cardCornerRadius

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(.white.opacity(0.12), lineWidth: 1)
                    }
            }
    }
}

struct GlassPanel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(.white.opacity(0.06))
                    .frame(width: 1)
            }
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = AppTheme.cardCornerRadius) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }

    func glassPanel() -> some View {
        modifier(GlassPanel())
    }
}
