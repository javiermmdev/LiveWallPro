import AVFoundation
import AppKit
import Foundation

actor ThumbnailPipeline {
    private let settings: SettingsStore
    private let thumbnailDirectory: URL
    private let thumbnailSize = CGSize(width: 480, height: 270)

    init(settings: SettingsStore) {
        self.settings = settings

        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.thumbnailDirectory = cacheDir.appendingPathComponent("com.livewallpro.thumbnails", isDirectory: true)

        try? FileManager.default.createDirectory(at: thumbnailDirectory, withIntermediateDirectories: true)
    }

    func generateThumbnail(for videoURL: URL, wallpaperID: UUID) async throws -> String {
        let asset = AVURLAsset(url: videoURL, options: [
            AVURLAssetPreferPreciseDurationAndTimingKey: false
        ])

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = thumbnailSize
        generator.apertureMode = .cleanAperture

        // Generate at 1 second or 25% into the video
        let duration = try await asset.load(.duration)
        let time = CMTime(seconds: min(1.0, duration.seconds * 0.25), preferredTimescale: 600)

        let cgImage = try await generator.image(at: time).image

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) else {
            throw ThumbnailError.encodingFailed
        }

        let filename = "\(wallpaperID.uuidString).jpg"
        let thumbnailURL = thumbnailDirectory.appendingPathComponent(filename)

        try jpegData.write(to: thumbnailURL)

        await enforceCache()

        return thumbnailURL.path
    }

    func thumbnailExists(for wallpaperID: UUID) -> Bool {
        let filename = "\(wallpaperID.uuidString).jpg"
        let thumbnailURL = thumbnailDirectory.appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: thumbnailURL.path)
    }

    func removeThumbnail(for wallpaperID: UUID) {
        let filename = "\(wallpaperID.uuidString).jpg"
        let thumbnailURL = thumbnailDirectory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: thumbnailURL)
    }

    private func enforceCache() async {
        let maxBytes = Int64(settings.thumbnailCacheSizeMB) * 1024 * 1024

        guard let files = try? FileManager.default.contentsOfDirectory(
            at: thumbnailDirectory,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
        ) else { return }

        var totalSize: Int64 = 0
        var fileInfos: [(url: URL, size: Int64, date: Date)] = []

        for file in files {
            guard let values = try? file.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]) else { continue }
            let size = Int64(values.fileSize ?? 0)
            let date = values.contentModificationDate ?? Date.distantPast
            fileInfos.append((url: file, size: size, date: date))
            totalSize += size
        }

        if totalSize <= maxBytes { return }

        // Evict oldest first
        fileInfos.sort { $0.date < $1.date }

        for info in fileInfos {
            guard totalSize > maxBytes else { break }
            try? FileManager.default.removeItem(at: info.url)
            totalSize -= info.size
        }
    }
}

enum ThumbnailError: Error, LocalizedError {
    case encodingFailed
    case generationFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed: return "Failed to encode thumbnail"
        case .generationFailed: return "Failed to generate thumbnail from video"
        }
    }
}
