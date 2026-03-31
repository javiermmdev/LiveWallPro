import SwiftUI
import SwiftData

@main
struct LiveWallProApp: App {
    @State private var appState: AppState?
    @Environment(\.modelContext) private var modelContext

    // MARK: - SwiftData Container

    /// Shared persistent store for Wallpaper and DisplayAssignment models.
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Wallpaper.self, DisplayAssignment.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Scenes

    var body: some Scene {
        Window("LiveWall Pro", id: "main") {
            ContentView()
                .environment(appStateInstance)
                .frame(minWidth: 960, minHeight: 640)
                .preferredColorScheme(.dark)
                .onAppear {
                    try? appStateInstance.libraryManager.loadWallpapers()
                    appStateInstance.startEngine()
                }
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(width: 1140, height: 760)
        .windowStyle(.hiddenTitleBar)

        /// Lightweight status indicator and quick controls in the menu bar.
        MenuBarExtra("LiveWall Pro", image: "MenuBarIcon") {
            MenuBarView()
                .environment(appStateInstance)
        }

        Settings {
            SettingsView()
                .environment(appStateInstance)
                .frame(minWidth: 550, minHeight: 450)
        }
    }

    // MARK: - Helpers

    /// Lazily creates AppState once the model container is ready.
    private var appStateInstance: AppState {
        if let appState { return appState }
        let state = AppState(modelContext: sharedModelContainer.mainContext)
        Task { @MainActor in self.appState = state }
        return state
    }
}
