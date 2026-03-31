import Foundation
import SwiftData

@Model
final class Wallpaper {
    @Attribute(.unique) var id: UUID
    var filePath: String
    var title: String
    var tags: [String]
    var creator: String
    var resolutionWidth: Int
    var resolutionHeight: Int
    var duration: Double
    var addedDate: Date
    var isFavorite: Bool
    var thumbnailPath: String?
    var fileSize: Int64
    var codec: String?
    var isVertical: Bool
    var category: String?

    var timesUsed: Int
    var lastUsedDate: Date?
    var totalPlaybackSeconds: Double

    var resolution: String {
        "\(resolutionWidth)x\(resolutionHeight)"
    }

    var aspectRatio: Double {
        guard resolutionHeight > 0 else { return 16.0 / 9.0 }
        return Double(resolutionWidth) / Double(resolutionHeight)
    }

    var fileURL: URL {
        URL(fileURLWithPath: filePath)
    }

    var thumbnailURL: URL? {
        thumbnailPath.map { URL(fileURLWithPath: $0) }
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var wallpaperCategory: WallpaperCategory? {
        get { category.flatMap { WallpaperCategory(rawValue: $0) } }
        set { category = newValue?.rawValue }
    }

    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    init(
        filePath: String,
        title: String,
        tags: [String] = [],
        creator: String = "",
        resolutionWidth: Int = 0,
        resolutionHeight: Int = 0,
        duration: Double = 0,
        fileSize: Int64 = 0,
        codec: String? = nil
    ) {
        self.id = UUID()
        self.filePath = filePath
        self.title = title
        self.tags = tags
        self.creator = creator
        self.resolutionWidth = resolutionWidth
        self.resolutionHeight = resolutionHeight
        self.duration = duration
        self.addedDate = Date()
        self.isFavorite = false
        self.thumbnailPath = nil
        self.fileSize = fileSize
        self.codec = codec
        self.isVertical = resolutionHeight > resolutionWidth
        self.timesUsed = 0
        self.lastUsedDate = nil
        self.totalPlaybackSeconds = 0
    }
}
