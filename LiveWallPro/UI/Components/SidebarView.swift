import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @Bindable var viewModel: LibraryViewModel

    private var theme: GradientThemePreset {
        appState.settings.gradientTheme
    }

    var body: some View {
        List(selection: $viewModel.selectedSidebarItem) {
            Section("Library") {
                ForEach([SidebarItem.allWallpapers, .favorites, .recent, .vertical]) { item in
                    Label(item.rawValue, systemImage: item.icon)
                        .tag(item)
                }
            }

            Section("Displays") {
                Label(SidebarItem.displays.rawValue, systemImage: SidebarItem.displays.icon)
                    .tag(SidebarItem.displays)

                ForEach(appState.displayManager.displays) { display in
                    DisplaySidebarRow(
                        display: display,
                        wallpaperTitle: wallpaperTitle(for: display)
                    )
                }
            }

            Section {
                EngineStatusRow(isRunning: appState.wallpaperEngine.isRunning)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(.ultraThinMaterial)
        .frame(minWidth: 200)
    }

    private func wallpaperTitle(for display: DisplayInfo) -> String? {
        guard let wallpaperID = appState.wallpaperEngine.activeWallpapers[display.id] else { return nil }
        return appState.libraryManager.wallpaper(for: wallpaperID)?.title
    }
}

private struct DisplaySidebarRow: View {
    let display: DisplayInfo
    let wallpaperTitle: String?

    var body: some View {
        HStack {
            Image(systemName: display.isBuiltIn ? "laptopcomputer" : "display")
            VStack(alignment: .leading, spacing: 2) {
                Text(display.name)
                    .font(.caption)
                if let title = wallpaperTitle {
                    Text(title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No wallpaper")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.leading, 8)
    }
}

private struct EngineStatusRow: View {
    let isRunning: Bool

    var body: some View {
        HStack {
            Image(systemName: "circle.fill")
                .foregroundStyle(isRunning ? .green : .gray)
                .font(.caption2)
            Text(isRunning ? "Engine Active" : "Engine Stopped")
                .font(.caption)
        }
        .foregroundStyle(.secondary)
    }
}
