import AVFoundation
import Foundation
import SwiftData
import UniformTypeIdentifiers

@Observable
@MainActor
final class ImportPipeline {
    private let modelContext: ModelContext
    private let thumbnailPipeline: ThumbnailPipeline

    private(set) var isImporting: Bool = false
    private(set) var importProgress: Double = 0
    private(set) var importErrors: [ImportError] = []

    static let supportedTypes: [UTType] = [.mpeg4Movie, .quickTimeMovie, .movie]
    static let supportedExtensions: Set<String> = ["mp4", "m4v", "mov"]

    init(modelContext: ModelContext, thumbnailPipeline: ThumbnailPipeline) {
        self.modelContext = modelContext
        self.thumbnailPipeline = thumbnailPipeline
    }

    func importFiles(_ urls: [URL]) async {
        guard !isImporting else { return }
        isImporting = true
        importProgress = 0
        importErrors = []

        let total = Double(urls.count)

        for (index, url) in urls.enumerated() {
            do {
                try await importSingleFile(url)
            } catch {
                importErrors.append(ImportError(url: url, error: error))
            }
            importProgress = Double(index + 1) / total
        }

        isImporting = false
    }

    func importFromFolder(_ folderURL: URL) async {
        guard !isImporting else { return }

        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: folderURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        var videoURLs: [URL] = []
        while let fileURL = enumerator.nextObject() as? URL {
            if Self.supportedExtensions.contains(fileURL.pathExtension.lowercased()) {
                videoURLs.append(fileURL)
            }
        }

        await importFiles(videoURLs)
    }

    private func importSingleFile(_ url: URL) async throws {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }

        // Check if already imported
        let path = url.path
        let existingDescriptor = FetchDescriptor<Wallpaper>(
            predicate: #Predicate { $0.filePath == path }
        )
        let existing = try modelContext.fetchCount(existingDescriptor)
        if existing > 0 { return }

        // Extract video metadata
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let tracks = try await asset.loadTracks(withMediaType: .video)

        var width = 0
        var height = 0
        var codec: String?

        if let videoTrack = tracks.first {
            let size = try await videoTrack.load(.naturalSize)
            let transform = try await videoTrack.load(.preferredTransform)
            let transformedSize = size.applying(transform)
            width = Int(abs(transformedSize.width))
            height = Int(abs(transformedSize.height))

            let descriptions = try await videoTrack.load(.formatDescriptions)
            if let desc = descriptions.first {
                let mediaSubType = CMFormatDescriptionGetMediaSubType(desc)
                codec = fourCCToString(mediaSubType)
            }
        }

        let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = fileAttributes[.size] as? Int64 ?? 0

        let title = url.deletingPathExtension().lastPathComponent

        let wallpaper = Wallpaper(
            filePath: url.path,
            title: title,
            resolutionWidth: width,
            resolutionHeight: height,
            duration: duration.seconds.isNaN ? 0 : duration.seconds,
            fileSize: fileSize,
            codec: codec
        )

        modelContext.insert(wallpaper)

        // Generate thumbnail
        if let thumbnailPath = try? await thumbnailPipeline.generateThumbnail(for: url, wallpaperID: wallpaper.id) {
            wallpaper.thumbnailPath = thumbnailPath
        }

        try modelContext.save()
    }

    private func fourCCToString(_ code: FourCharCode) -> String {
        let bytes = [
            UInt8((code >> 24) & 0xFF),
            UInt8((code >> 16) & 0xFF),
            UInt8((code >> 8) & 0xFF),
            UInt8(code & 0xFF)
        ]
        return String(bytes: bytes, encoding: .ascii) ?? "unknown"
    }
}

struct ImportError: Identifiable {
    let id = UUID()
    let url: URL
    let error: Error
}
