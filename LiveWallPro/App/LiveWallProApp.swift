import SwiftUI
import SwiftData

@main
struct LiveWallProApp: App {

    // MARK: - SwiftData Container

    /// Static so it is created exactly once for the entire process lifetime.
    private static let container: ModelContainer = {
        let schema = Schema([Wallpaper.self, DisplayAssignment.self])
        let storeURL = URL.applicationSupportDirectory
            .appending(path: "LiveWallPro.store")
        let config = ModelConfiguration(schema: schema, url: storeURL)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    /// Single AppState for the whole app, created once from the static container.
    private static let appState = AppState(modelContext: container.mainContext)

    // MARK: - Scenes

    var body: some Scene {
        Window("LiveWall Pro", id: "main") {
            ContentView()
                .environment(Self.appState)
                .frame(minWidth: 960, minHeight: 640)
                .preferredColorScheme(.dark)
                .onAppear {
                    try? Self.appState.libraryManager.loadWallpapers()
                    Self.appState.startEngine()
                }
        }
        .modelContainer(Self.container)
        .defaultSize(width: 1140, height: 760)
        .windowStyle(.hiddenTitleBar)

        /// Lightweight status indicator and quick controls in the menu bar.
        MenuBarExtra("LiveWall Pro", image: "MenuBarIcon") {
            MenuBarView()
                .environment(Self.appState)
        }

        Settings {
            SettingsView()
                .environment(Self.appState)
                .frame(minWidth: 550, minHeight: 450)
        }
    }
}
