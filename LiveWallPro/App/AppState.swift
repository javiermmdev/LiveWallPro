import Foundation
import SwiftData

/// Central dependency container. All services are created here and
/// injected into views via SwiftUI's `.environment()` modifier.
@Observable
@MainActor
final class AppState {

    // MARK: - Services

    let settings: SettingsStore
    let displayManager: DisplayManager
    let playbackCoordinator: PlaybackCoordinator
    let powerManager: PowerManager
    let wallpaperEngine: WallpaperEngine
    let libraryManager: LibraryManager
    let thumbnailPipeline: ThumbnailPipeline
    let importPipeline: ImportPipeline
    let resourceMonitor: ResourceMonitor
    let wallpaperDownloader: WallpaperDownloader

    // MARK: - Init

    init(modelContext: ModelContext) {
        let settings = SettingsStore.shared
        let displayManager = DisplayManager()
        let playbackCoordinator = PlaybackCoordinator()
        let powerManager = PowerManager()

        self.settings = settings
        self.displayManager = displayManager
        self.playbackCoordinator = playbackCoordinator
        self.powerManager = powerManager

        self.wallpaperEngine = WallpaperEngine(
            displayManager: displayManager,
            playbackCoordinator: playbackCoordinator,
            powerManager: powerManager,
            settings: settings
        )

        self.thumbnailPipeline = ThumbnailPipeline(settings: settings)
        self.importPipeline = ImportPipeline(
            modelContext: modelContext,
            thumbnailPipeline: ThumbnailPipeline(settings: settings)
        )
        self.libraryManager = LibraryManager(modelContext: modelContext)
        self.resourceMonitor = ResourceMonitor()
        self.wallpaperDownloader = WallpaperDownloader(settings: settings)
    }

    // MARK: - Lifecycle

    func startEngine() {
        wallpaperEngine.start()
        resourceMonitor.startMonitoring()
        let policy = powerManager.evaluatePolicy(settings: settings)
        wallpaperEngine.handlePowerPolicyChange(policy)
    }

    func stopEngine() {
        wallpaperEngine.stop()
        resourceMonitor.stopMonitoring()
    }

    /// Re-evaluates the active power policy and notifies the engine.
    func refreshPowerPolicy() {
        let policy = powerManager.evaluatePolicy(settings: settings)
        wallpaperEngine.handlePowerPolicyChange(policy)
    }

    // MARK: - ViewModel Factories

    func makeLibraryViewModel() -> LibraryViewModel {
        LibraryViewModel(
            libraryManager: libraryManager,
            importPipeline: importPipeline,
            wallpaperEngine: wallpaperEngine
        )
    }

    func makeCardViewModel(for wallpaper: Wallpaper) -> WallpaperCardViewModel {
        WallpaperCardViewModel(
            wallpaper: wallpaper,
            libraryManager: libraryManager,
            wallpaperEngine: wallpaperEngine,
            displayManager: displayManager
        )
    }

    func makeMenuBarViewModel() -> MenuBarViewModel {
        MenuBarViewModel(appState: self)
    }
}
