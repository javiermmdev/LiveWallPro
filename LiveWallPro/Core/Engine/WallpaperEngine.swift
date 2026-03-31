import AppKit
import AVFoundation
import Foundation

/// Central orchestrator: manages WallpaperWindows, coordinates playback per display,
/// and reacts to display and power changes.
@Observable
@MainActor
final class WallpaperEngine {
    private(set) var isRunning: Bool = false
    private(set) var activeWallpapers: [CGDirectDisplayID: UUID] = [:]

    /// Called when a wallpaper is set or removed, for persistence.
    var onAssignmentChanged: ((_ displayID: CGDirectDisplayID, _ wallpaperID: UUID?, _ scalingMode: ScalingMode?) -> Void)?

    private var windows: [CGDirectDisplayID: WallpaperWindow] = [:]
    private let displayManager: DisplayManager
    private let playbackCoordinator: PlaybackCoordinator
    private let powerManager: PowerManager
    private let settings: SettingsStore

    init(
        displayManager: DisplayManager,
        playbackCoordinator: PlaybackCoordinator,
        powerManager: PowerManager,
        settings: SettingsStore
    ) {
        self.displayManager = displayManager
        self.playbackCoordinator = playbackCoordinator
        self.powerManager = powerManager
        self.settings = settings
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true

        // Create windows for all current displays
        for display in displayManager.displays {
            ensureWindow(for: display)
        }
    }

    func stop() {
        isRunning = false
        playbackCoordinator.teardownAll()
        for (_, window) in windows {
            window.hideFromDesktop()
            window.close()
        }
        windows.removeAll()
        activeWallpapers.removeAll()
    }

    func setWallpaper(_ wallpaper: Wallpaper, for displayID: CGDirectDisplayID, scalingMode: ScalingMode = .fill) {
        guard let display = displayManager.display(for: displayID) else { return }

        ensureWindow(for: display)

        let url = wallpaper.fileURL
        let id = wallpaper.id

        Task {
            await playbackCoordinator.setupPlayer(for: displayID, videoURL: url, wallpaperID: id)

            if let player = playbackCoordinator.player(for: displayID) {
                windows[displayID]?.setPlayer(player)
                windows[displayID]?.setScalingMode(scalingMode)
                windows[displayID]?.showOnDesktop()
                playbackCoordinator.play(displayID: displayID)
            }
        }

        activeWallpapers[displayID] = wallpaper.id
        onAssignmentChanged?(displayID, wallpaper.id, scalingMode)
    }

    func removeWallpaper(for displayID: CGDirectDisplayID) {
        playbackCoordinator.teardownPlayer(for: displayID)
        windows[displayID]?.setPlayer(nil)
        windows[displayID]?.hideFromDesktop()
        activeWallpapers.removeValue(forKey: displayID)
        onAssignmentChanged?(displayID, nil, nil)
    }

    func setWallpaperOnAllDisplays(_ wallpaper: Wallpaper, scalingMode: ScalingMode = .fill) {
        for display in displayManager.displays {
            setWallpaper(wallpaper, for: display.id, scalingMode: scalingMode)
        }
    }

    func handleDisplaysChanged() {
        let currentDisplayIDs = Set(displayManager.displays.map(\.id))
        let windowDisplayIDs = Set(windows.keys)

        // Remove windows for disconnected displays
        for displayID in windowDisplayIDs.subtracting(currentDisplayIDs) {
            removeWallpaper(for: displayID)
            windows[displayID]?.close()
            windows.removeValue(forKey: displayID)
        }

        // Update frames for existing displays
        for display in displayManager.displays {
            if let window = windows[display.id] {
                window.updateFrame(for: display)
            }
        }
    }

    func handlePowerPolicyChange(_ policy: PowerPolicy) {
        playbackCoordinator.applyPowerPolicy(policy)
    }

    private func ensureWindow(for display: DisplayInfo) {
        if windows[display.id] == nil {
            let window = WallpaperWindow(display: display)
            windows[display.id] = window
        }
    }
}
