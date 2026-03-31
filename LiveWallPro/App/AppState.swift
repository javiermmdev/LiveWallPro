import AppKit
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

    private let modelContext: ModelContext

    // MARK: - Init

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
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

        // Persist wallpaper assignments whenever the engine sets or removes one
        self.wallpaperEngine.onAssignmentChanged = { [weak self] displayID, wallpaperID, scalingMode in
            guard let self else { return }
            if let wallpaperID, let scalingMode {
                self.saveAssignment(displayID: displayID, wallpaperID: wallpaperID, scalingMode: scalingMode)
            } else {
                self.removeAssignment(displayID: displayID)
            }
        }

        // On sleep: pause all players to release GPU resources
        self.powerManager.onSleep = { [weak self] in
            guard let self else { return }
            self.playbackCoordinator.pauseAll()
        }

        // On wake: rebuild players from scratch (AVPlayers break after system sleep)
        self.powerManager.onWake = { [weak self] in
            guard let self else { return }
            self.handleWake()
        }
    }

    // MARK: - Lifecycle

    func startEngine() {
        wallpaperEngine.start()
        resourceMonitor.startMonitoring()
        let policy = powerManager.evaluatePolicy(settings: settings)
        wallpaperEngine.handlePowerPolicyChange(policy)
        restoreWallpapers()
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

    /// Rebuilds all wallpaper players after wake from sleep.
    /// AVQueuePlayer + AVPlayerLooper instances become unreliable after system
    /// hibernation, so we tear down every player and recreate them from the
    /// persisted DisplayAssignments.
    private func handleWake() {
        guard wallpaperEngine.isRunning else { return }

        // Tear down stale players but keep windows alive
        playbackCoordinator.teardownAll()

        // Re-read assignments and set up fresh players
        restoreWallpapers()

        // Apply the current power policy
        refreshPowerPolicy()
    }

    // MARK: - Wallpaper Persistence

    /// Saves a display→wallpaper assignment to SwiftData.
    func saveAssignment(displayID: CGDirectDisplayID, wallpaperID: UUID, scalingMode: ScalingMode = .fill) {
        let key = String(displayID)
        let descriptor = FetchDescriptor<DisplayAssignment>(
            predicate: #Predicate { $0.displayID == key }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.wallpaperID = wallpaperID
            existing.scalingMode = scalingMode
        } else {
            let assignment = DisplayAssignment(displayID: key, wallpaperID: wallpaperID)
            assignment.scalingMode = scalingMode
            modelContext.insert(assignment)
        }
        try? modelContext.save()
    }

    /// Removes the persisted assignment for a display.
    func removeAssignment(displayID: CGDirectDisplayID) {
        let key = String(displayID)
        let descriptor = FetchDescriptor<DisplayAssignment>(
            predicate: #Predicate { $0.displayID == key }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            modelContext.delete(existing)
            try? modelContext.save()
        }
    }

    /// Restores wallpapers from persisted DisplayAssignments.
    func restoreWallpapers() {
        guard wallpaperEngine.isRunning else { return }
        let descriptor = FetchDescriptor<DisplayAssignment>()
        guard let assignments = try? modelContext.fetch(descriptor), !assignments.isEmpty else { return }

        for assignment in assignments {
            guard let wallpaperID = assignment.wallpaperID,
                  let wallpaper = libraryManager.wallpaper(for: wallpaperID),
                  let displayID = CGDirectDisplayID(assignment.displayID) else { continue }
            wallpaperEngine.setWallpaper(wallpaper, for: displayID, scalingMode: assignment.scalingMode)
        }
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
