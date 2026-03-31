import Foundation
import SwiftUI
import UniformTypeIdentifiers

@Observable
@MainActor
final class LibraryViewModel {
    private let libraryManager: LibraryManager
    private let importPipeline: ImportPipeline
    private let wallpaperEngine: WallpaperEngine

    // Navigation
    var selectedTab: MainTab = .home
    var selectedCategory: WallpaperCategory?

    // Filtering
    var selectedSidebarItem: SidebarItem = .allWallpapers
    var searchText: String = ""
    var sortOrder: WallpaperSortOrder = .dateAdded
    var isShowingImporter: Bool = false

    var isImporting: Bool { importPipeline.isImporting }
    var importProgress: Double { importPipeline.importProgress }

    init(libraryManager: LibraryManager, importPipeline: ImportPipeline, wallpaperEngine: WallpaperEngine) {
        self.libraryManager = libraryManager
        self.importPipeline = importPipeline
        self.wallpaperEngine = wallpaperEngine
    }

    // MARK: - Computed

    var filteredWallpapers: [Wallpaper] {
        if let category = selectedCategory {
            return libraryManager.wallpapers(inCategory: category, searchText: searchText, sortOrder: sortOrder)
        }
        return libraryManager.wallpapers(
            matching: selectedSidebarItem,
            searchText: searchText,
            sortOrder: sortOrder
        )
    }

    var wallpaperCount: Int { filteredWallpapers.count }

    var currentTitle: String {
        if let category = selectedCategory {
            return category.rawValue
        }
        switch selectedTab {
        case .home: return L10n.categories
        case .explore: return L10n.exploreTitle
        case .library: return L10n.libraryTitle
        }
    }

    var currentSubtitle: String {
        if selectedCategory != nil {
            return L10n.wallpaperCount(wallpaperCount)
        }
        switch selectedTab {
        case .home: return L10n.browseByCategory
        case .explore: return L10n.allWallpapers
        case .library: return L10n.librarySubtitle
        }
    }

    // MARK: - Navigation

    func selectCategory(_ category: WallpaperCategory) {
        selectedCategory = category
        selectedTab = .explore
    }

    func clearCategory() {
        selectedCategory = nil
    }

    // MARK: - Import

    func importFiles(_ urls: [URL]) async {
        await importPipeline.importFiles(urls)
        try? libraryManager.loadWallpapers()
    }

    func importFromFolder(_ path: String) async {
        let url = URL(fileURLWithPath: path)
        await importPipeline.importFromFolder(url)
        try? libraryManager.loadWallpapers()
    }

    func handleDrop(_ providers: [NSItemProvider]) async {
        var urls: [URL] = []

        for provider in providers {
            if let url = await loadURL(from: provider) {
                urls.append(url)
            }
        }

        let validURLs = urls.filter {
            ImportPipeline.supportedExtensions.contains($0.pathExtension.lowercased())
        }

        if !validURLs.isEmpty {
            await importFiles(validURLs)
        }
    }

    private func loadURL(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: "public.file-url") { data, _ in
                if let data = data as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}

enum SidebarItem: String, CaseIterable, Identifiable, Sendable {
    case allWallpapers = "All Wallpapers"
    case favorites = "Favorites"
    case recent = "Recent"
    case vertical = "Vertical"
    case displays = "Displays"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .allWallpapers: return "photo.on.rectangle.angled"
        case .favorites: return "heart.fill"
        case .recent: return "clock"
        case .vertical: return "rectangle.portrait"
        case .displays: return "display.2"
        }
    }
}

enum WallpaperSortOrder: String, CaseIterable, Sendable {
    case dateAdded = "Date Added"
    case title = "Title"
    case duration = "Duration"
    case resolution = "Resolution"
    case favorites = "Favorites First"
    case mostUsed = "Most Used"

    var localizedName: String {
        switch self {
        case .dateAdded: return L10n.dateAdded
        case .title: return L10n.title
        case .duration: return L10n.duration
        case .resolution: return L10n.resolution
        case .favorites: return L10n.favoritesFirst
        case .mostUsed: return L10n.mostUsed
        }
    }
}
