import SwiftUI

/// The three top-level navigation destinations.
enum MainTab: String, CaseIterable, Identifiable, Sendable {
    case home    = "Home"
    case explore = "Explore"
    case library = "Library"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home:    return "house"
        case .explore: return "safari"
        case .library: return "square.grid.2x2"
        }
    }

    var localizedName: String {
        switch self {
        case .home:    return L10n.home
        case .explore: return L10n.explore
        case .library: return L10n.library
        }
    }
}

/// Top-level chrome bar: branding (left), pill tab switcher (centre), utility actions (right).
/// Uses `.ultraThinMaterial` so the full-window gradient shows through.
struct NavigationBar: View {
    @Binding var selectedTab: MainTab
    @Binding var searchText: String
    var onImport: () -> Void

    @State private var isSearching = false

    var body: some View {
        HStack(spacing: 0) {
            // MARK: Branding
            HStack(spacing: 6) {
                Text("LiveWall")
                    .font(.system(size: 13, weight: .semibold, design: .default))
                    .foregroundStyle(.white.opacity(0.5))
                Text("Pro")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.6, green: 0.4, blue: 1.0), Color(red: 0.4, green: 0.3, blue: 0.9)],
                            startPoint: .leading, endPoint: .trailing
                        ),
                        in: Capsule()
                    )
            }

            Spacer()

            // MARK: Pill Tab Switcher
            HStack(spacing: 2) {
                ForEach(MainTab.allCases) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 11, weight: .medium))
                            Text(tab.localizedName)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.45))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background {
                            if selectedTab == tab {
                                Capsule()
                                    .fill(.white.opacity(0.1))
                                    .overlay { Capsule().stroke(.white.opacity(0.08), lineWidth: 1) }
                            }
                        }
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background {
                Capsule()
                    .fill(.white.opacity(0.04))
                    .overlay { Capsule().stroke(.white.opacity(0.06), lineWidth: 1) }
            }

            Spacer()

            // MARK: Utility Actions
            HStack(spacing: 4) {
                if isSearching {
                    // Expanded inline search field
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.4))
                        TextField("Search...", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                            .foregroundStyle(.white)
                            .frame(width: 120)
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isSearching = false
                                searchText = ""
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.06), in: Capsule())
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.9, anchor: .trailing)),
                        removal: .opacity
                    ))
                } else {
                    NavBarButton(icon: "magnifyingglass") {
                        withAnimation(.easeInOut(duration: 0.2)) { isSearching = true }
                    }
                }

                NavBarButton(icon: "plus") { onImport() }

                SettingsLink {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.45))
                        .frame(width: 30, height: 30)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                Rectangle()
                    .fill(.black.opacity(0.15))
            }
            .overlay(alignment: .bottom) {
                Rectangle().fill(.white.opacity(0.06)).frame(height: 1)
            }
        }
    }
}

// MARK: - NavBarButton

private struct NavBarButton: View {
    let icon: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(isHovered ? 0.8 : 0.45))
                .frame(width: 30, height: 30)
                .background(isHovered ? .white.opacity(0.06) : .clear, in: RoundedRectangle(cornerRadius: 6))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
