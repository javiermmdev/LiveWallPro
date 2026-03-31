import Foundation
import SwiftData

/// Manages the local wallpaper library: loading, filtering, sorting and CRUD.
/// Keeps an in-memory `wallpapers` array so SwiftUI `@Observable` works correctly —
/// filtering from SwiftData fetch descriptors bypasses observation.
@Observable
@MainActor
final class LibraryManager {

    // MARK: - State

    private let modelContext: ModelContext
    private(set) var wallpapers: [Wallpaper] = []
    private(set) var isLoading: Bool = false

    // MARK: - Init

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Loading

    func loadWallpapers() throws {
        let descriptor = FetchDescriptor<Wallpaper>(
            sortBy: [SortDescriptor(\.addedDate, order: .reverse)]
        )
        wallpapers = try modelContext.fetch(descriptor)
    }

    // MARK: - Filtering & Sorting

    /// Returns wallpapers matching a sidebar filter, search query and sort order.
    func wallpapers(matching filter: SidebarItem, searchText: String, sortOrder: WallpaperSortOrder) -> [Wallpaper] {
        var results = wallpapers

        switch filter {
        case .allWallpapers, .displays:
            break
        case .favorites:
            results = results.filter { $0.isFavorite }
        case .recent:
            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            results = results.filter { $0.addedDate >= sevenDaysAgo }
        case .vertical:
            results = results.filter { $0.isVertical }
        }

        results = applySearch(results, text: searchText)
        return applySorting(results, order: sortOrder)
    }

    /// Returns wallpapers belonging to a specific category.
    func wallpapers(inCategory category: WallpaperCategory, searchText: String = "", sortOrder: WallpaperSortOrder = .dateAdded) -> [Wallpaper] {
        var results = wallpapers.filter { $0.category == category.rawValue }
        results = applySearch(results, text: searchText)
        return applySorting(results, order: sortOrder)
    }

    func wallpaperCount(for category: WallpaperCategory) -> Int {
        wallpapers.count { $0.category == category.rawValue }
    }

    func firstThumbnail(for category: WallpaperCategory) -> URL? {
        guard let wallpaper = wallpapers.first(where: { $0.category == category.rawValue }),
              let path = wallpaper.thumbnailPath else { return nil }
        return URL(fileURLWithPath: path)
    }

    // MARK: - Private Helpers

    private func applySearch(_ wallpapers: [Wallpaper], text: String) -> [Wallpaper] {
        guard !text.isEmpty else { return wallpapers }
        let query = text.lowercased()
        return wallpapers.filter { wallpaper in
            wallpaper.title.lowercased().contains(query) ||
            wallpaper.creator.lowercased().contains(query) ||
            wallpaper.tags.contains { $0.lowercased().contains(query) }
        }
    }

    private func applySorting(_ wallpapers: [Wallpaper], order: WallpaperSortOrder) -> [Wallpaper] {
        var results = wallpapers
        switch order {
        case .dateAdded:  results.sort { $0.addedDate > $1.addedDate }
        case .title:      results.sort { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .duration:   results.sort { $0.duration > $1.duration }
        case .resolution: results.sort { ($0.resolutionWidth * $0.resolutionHeight) > ($1.resolutionWidth * $1.resolutionHeight) }
        case .favorites:  results.sort { ($0.isFavorite ? 0 : 1) < ($1.isFavorite ? 0 : 1) }
        case .mostUsed:   results.sort { $0.timesUsed > $1.timesUsed }
        }
        return results
    }

    // MARK: - CRUD

    func setCategory(_ category: WallpaperCategory?, for wallpaper: Wallpaper) {
        wallpaper.category = category?.rawValue
        try? modelContext.save()
        try? loadWallpapers()
    }

    func addWallpaper(_ wallpaper: Wallpaper) {
        modelContext.insert(wallpaper)
        try? modelContext.save()
        try? loadWallpapers()
    }

    func deleteWallpaper(_ wallpaper: Wallpaper) {
        if let thumbnailPath = wallpaper.thumbnailPath {
            try? FileManager.default.removeItem(atPath: thumbnailPath)
        }

        // Remove from in-memory array first so SwiftUI re-renders immediately
        wallpapers.removeAll { $0.id == wallpaper.id }

        modelContext.delete(wallpaper)
        do {
            try modelContext.save()
        } catch {
            print("[LibraryManager] Failed to save after delete: \(error)")
            try? loadWallpapers() // Restore consistent state on error
        }
    }

    func toggleFavorite(_ wallpaper: Wallpaper) {
        wallpaper.isFavorite.toggle()
        try? modelContext.save()
    }

    func recordUsage(_ wallpaper: Wallpaper) {
        wallpaper.timesUsed += 1
        wallpaper.lastUsedDate = Date()
        try? modelContext.save()
    }

    func updateTags(_ wallpaper: Wallpaper, tags: [String]) {
        wallpaper.tags = tags
        try? modelContext.save()
    }

    func wallpaper(for id: UUID) -> Wallpaper? {
        wallpapers.first { $0.id == id }
    }
}
