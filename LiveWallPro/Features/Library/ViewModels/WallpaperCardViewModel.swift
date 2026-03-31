import AppKit
import Foundation

@Observable
@MainActor
final class WallpaperCardViewModel {
    private let libraryManager: LibraryManager
    private let wallpaperEngine: WallpaperEngine
    private let displayManager: DisplayManager

    let wallpaper: Wallpaper

    init(wallpaper: Wallpaper, libraryManager: LibraryManager, wallpaperEngine: WallpaperEngine, displayManager: DisplayManager) {
        self.wallpaper = wallpaper
        self.libraryManager = libraryManager
        self.wallpaperEngine = wallpaperEngine
        self.displayManager = displayManager
    }

    var isActive: Bool {
        wallpaperEngine.activeWallpapers.values.contains(wallpaper.id)
    }

    var displays: [DisplayInfo] {
        displayManager.displays
    }

    func setAsWallpaper() {
        setOnAllDisplays()
    }

    func setOnAllDisplays() {
        wallpaperEngine.setWallpaperOnAllDisplays(wallpaper)
        libraryManager.recordUsage(wallpaper)
    }

    func setOnDisplay(_ displayID: CGDirectDisplayID) {
        wallpaperEngine.setWallpaper(wallpaper, for: displayID)
        libraryManager.recordUsage(wallpaper)
    }

    func setScaling(_ mode: ScalingMode) {
        guard let mainDisplay = displayManager.displays.first else { return }
        wallpaperEngine.setWallpaper(wallpaper, for: mainDisplay.id, scalingMode: mode)
    }

    func toggleFavorite() {
        libraryManager.toggleFavorite(wallpaper)
    }

    func delete() {
        for (displayID, wallpaperID) in wallpaperEngine.activeWallpapers {
            if wallpaperID == wallpaper.id {
                wallpaperEngine.removeWallpaper(for: displayID)
            }
        }
        libraryManager.deleteWallpaper(wallpaper)
    }

    func setCategory(_ category: WallpaperCategory?) {
        libraryManager.setCategory(category, for: wallpaper)
    }

    func showInFinder() {
        NSWorkspace.shared.selectFile(wallpaper.filePath, inFileViewerRootedAtPath: "")
    }
}
