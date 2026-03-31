import AppKit
import Foundation

@Observable
@MainActor
final class MenuBarViewModel {
    private let wallpaperEngine: WallpaperEngine
    private let playbackCoordinator: PlaybackCoordinator
    private let displayManager: DisplayManager
    private let powerManager: PowerManager
    private let libraryManager: LibraryManager
    private let appState: AppState
    private let resourceMonitor: ResourceMonitor

    init(appState: AppState) {
        self.appState = appState
        self.wallpaperEngine = appState.wallpaperEngine
        self.playbackCoordinator = appState.playbackCoordinator
        self.displayManager = appState.displayManager
        self.powerManager = appState.powerManager
        self.libraryManager = appState.libraryManager
        self.resourceMonitor = appState.resourceMonitor
    }

    var isEngineRunning: Bool { wallpaperEngine.isRunning }

    var displays: [DisplayInfo] { displayManager.displays }

    func wallpaperTitle(for display: DisplayInfo) -> String? {
        guard let wallpaperID = wallpaperEngine.activeWallpapers[display.id],
              let wallpaper = libraryManager.wallpaper(for: wallpaperID) else { return nil }
        return wallpaper.title
    }

    // MARK: - Resource Stats

    var cpuText: String {
        String(format: "%.1f%%", resourceMonitor.cpuUsage)
    }

    var memoryText: String {
        String(format: "%.0f MB", resourceMonitor.memoryMB)
    }

    var batteryText: String {
        let level = resourceMonitor.batteryLevel
        if level < 0 { return "N/A" }
        return "\(level)%"
    }

    var batteryIcon: String {
        let level = resourceMonitor.batteryLevel
        if resourceMonitor.isOnBattery {
            if level > 75 { return "battery.100" }
            if level > 50 { return "battery.75" }
            if level > 25 { return "battery.50" }
            return "battery.25"
        }
        return "battery.100.bolt"
    }

    var powerIcon: String {
        switch powerManager.powerSource {
        case .battery: return "battery.50percent"
        case .ac: return "bolt.fill"
        case .unknown: return "questionmark.circle"
        }
    }

    var powerStatusText: String {
        switch powerManager.currentPolicy {
        case .fullQuality: return L10n.fullQuality
        case .balanced: return L10n.balanced
        case .lowPower: return L10n.lowPower
        case .paused: return L10n.pausedSavingPower
        }
    }

    func pauseAll() { playbackCoordinator.pauseAll() }
    func resumeAll() { playbackCoordinator.resumeAll() }
    func startEngine() { appState.startEngine() }

    func stopAndQuit() {
        appState.stopEngine()
        NSApp.terminate(nil)
    }

    func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.title.contains("LiveWall") && !($0 is WallpaperWindow) }) {
            window.makeKeyAndOrderFront(nil)
        }
    }

}
