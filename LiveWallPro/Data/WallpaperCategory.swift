import SwiftUI

/// All supported wallpaper categories.
/// The raw value is used both as the display name and as the folder name in GitHub repos.
enum WallpaperCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case nature     = "Nature"
    case space      = "Space"
    case anime      = "Anime"
    case cars       = "Cars"
    case city       = "City"
    case videoGames = "Video Games"
    case sciFi      = "Sci-fi"
    case fantasy    = "Fantasy"
    case animals    = "Animals"

    var id: String { rawValue }

    /// Asset catalog image name for the category card background.
    var imageName: String {
        switch self {
        case .nature:     return "category_nature"
        case .space:      return "category_space"
        case .anime:      return "category_anime"
        case .cars:       return "category_cars"
        case .city:       return "category_city"
        case .videoGames: return "category_videogames"
        case .sciFi:      return "category_scifi"
        case .fantasy:    return "category_fantasy"
        case .animals:    return "category_animals"
        }
    }

    /// SF Symbol name used in category headers and sidebar items.
    var icon: String {
        switch self {
        case .nature:     return "leaf.fill"
        case .space:      return "sparkles"
        case .anime:      return "star.fill"
        case .cars:       return "car.fill"
        case .city:       return "building.2.fill"
        case .videoGames: return "gamecontroller.fill"
        case .sciFi:      return "cpu.fill"
        case .fantasy:    return "wand.and.stars"
        case .animals:    return "pawprint.fill"
        }
    }

    /// Cinematic gradient fallback when no thumbnail is available.
    var cardGradient: LinearGradient {
        switch self {
        case .nature:
            return LinearGradient(
                colors: [Color(red: 0.05, green: 0.15, blue: 0.08), Color(red: 0.02, green: 0.25, blue: 0.12)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .space:
            return LinearGradient(
                colors: [Color(red: 0.02, green: 0.02, blue: 0.12), Color(red: 0.08, green: 0.04, blue: 0.22)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .anime:
            return LinearGradient(
                colors: [Color(red: 0.18, green: 0.04, blue: 0.15), Color(red: 0.25, green: 0.08, blue: 0.2)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .cars:
            return LinearGradient(
                colors: [Color(red: 0.15, green: 0.05, blue: 0.02), Color(red: 0.22, green: 0.08, blue: 0.05)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .city:
            return LinearGradient(
                colors: [Color(red: 0.06, green: 0.08, blue: 0.14), Color(red: 0.1, green: 0.12, blue: 0.2)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .videoGames:
            return LinearGradient(
                colors: [Color(red: 0.04, green: 0.08, blue: 0.18), Color(red: 0.1, green: 0.05, blue: 0.25)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .sciFi:
            return LinearGradient(
                colors: [Color(red: 0.02, green: 0.1, blue: 0.15), Color(red: 0.05, green: 0.15, blue: 0.22)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .fantasy:
            return LinearGradient(
                colors: [Color(red: 0.12, green: 0.05, blue: 0.18), Color(red: 0.18, green: 0.08, blue: 0.25)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .animals:
            return LinearGradient(
                colors: [Color(red: 0.14, green: 0.08, blue: 0.04), Color(red: 0.2, green: 0.12, blue: 0.06)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }
}
