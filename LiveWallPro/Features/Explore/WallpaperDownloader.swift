import AVFoundation
import AppKit
import Foundation

/// A wallpaper available for download from a GitHub repository.
struct RemoteWallpaper: Identifiable, Sendable {
    let id: String
    let name: String
    let downloadURL: URL
    let category: WallpaperCategory?
    let fileSizeBytes: Int64

    /// Human-readable name with underscores/hyphens removed and extension stripped.
    var displayName: String {
        name.replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .components(separatedBy: ".").dropLast().joined(separator: ".")
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSizeBytes, countStyle: .file)
    }
}

/// Fetches and downloads wallpapers from a GitHub repository.
///
/// Expected repo structure: `<Category>/<filename>.mp4`
/// e.g. `Nature/forest.mp4`, `Space/nebula.mp4`
@Observable
@MainActor
final class WallpaperDownloader {

    // MARK: - State

    private(set) var remoteWallpapers: [RemoteWallpaper] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var downloads: [String: DownloadProgress] = [:]

    struct DownloadProgress: Sendable {
        let wallpaperID: String
        var progress: Double
        var isComplete: Bool
        var error: String?
    }

    /// In-memory thumbnail cache: wallpaper ID → NSImage.
    private(set) var thumbnails: [String: NSImage] = [:]
    private var thumbnailTasks: Set<String> = []

    private let settings: SettingsStore
    private let supportedExtensions: Set<String> = ["mp4", "m4v", "mov"]

    /// Persistent thumbnail cache directory under ~/Library/Caches/LiveWallPro/Thumbnails.
    private var thumbnailCacheDirectory: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("LiveWallPro/Thumbnails", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // MARK: - Init

    init(settings: SettingsStore) {
        self.settings = settings
    }

    // MARK: - Listing

    /// Fetches the file listing from a GitHub repo via the Trees API.
    /// Accepts `owner/repo` or `owner/repo/branch` format.
    func fetchListing(repo: String) async {
        isLoading = true
        errorMessage = nil
        remoteWallpapers = []

        let parts = repo.split(separator: "/")
        guard parts.count >= 2 else {
            errorMessage = "Invalid repo format. Use owner/repo"
            isLoading = false
            return
        }

        let owner = String(parts[0])
        let repoName = String(parts[1])
        let branch = parts.count >= 3 ? String(parts[2]) : "main"
        let apiURL = URL(string: "https://api.github.com/repos/\(owner)/\(repoName)/git/trees/\(branch)?recursive=1")!

        do {
            var request = URLRequest(url: apiURL)
            request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
            request.timeoutInterval = 15

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                errorMessage = "GitHub API error (HTTP \(code)). Check the repo name."
                isLoading = false
                return
            }

            let tree = try JSONDecoder().decode(GitHubTreeResponse.self, from: data)

            var wallpapers: [RemoteWallpaper] = []
            for item in tree.tree where item.type == "blob" {
                let ext = URL(string: item.path)?.pathExtension.lowercased() ?? ""
                guard supportedExtensions.contains(ext) else { continue }

                let pathComponents = item.path.split(separator: "/")
                let fileName = String(pathComponents.last ?? "")
                let folderName = pathComponents.count >= 2 ? String(pathComponents[pathComponents.count - 2]) : nil
                let category = folderName.flatMap { WallpaperCategory(rawValue: $0) }
                let downloadURL = URL(string: "https://raw.githubusercontent.com/\(owner)/\(repoName)/\(branch)/\(item.path)")!

                wallpapers.append(RemoteWallpaper(
                    id: item.path,
                    name: fileName,
                    downloadURL: downloadURL,
                    category: category,
                    fileSizeBytes: Int64(item.size ?? 0)
                ))
            }

            remoteWallpapers = wallpapers
            if wallpapers.isEmpty {
                errorMessage = "No video files found in this repository."
            }
        } catch {
            errorMessage = "Failed to connect: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Download

    /// Downloads a wallpaper to the local folder, reporting progress via `downloads`.
    func download(_ wallpaper: RemoteWallpaper) async -> URL? {
        downloads[wallpaper.id] = DownloadProgress(wallpaperID: wallpaper.id, progress: 0, isComplete: false)

        let folderURL = URL(fileURLWithPath: settings.wallpaperFolderPath)
        try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)

        let destURL = folderURL.appendingPathComponent(wallpaper.name)

        // Already downloaded — skip
        if FileManager.default.fileExists(atPath: destURL.path) {
            downloads[wallpaper.id] = DownloadProgress(wallpaperID: wallpaper.id, progress: 1, isComplete: true)
            return destURL
        }

        do {
            let (asyncBytes, response) = try await URLSession.shared.bytes(from: wallpaper.downloadURL)
            let totalSize = response.expectedContentLength
            var receivedBytes: Int64 = 0
            var data = Data()
            data.reserveCapacity(totalSize > 0 ? Int(totalSize) : 10_000_000)

            for try await byte in asyncBytes {
                data.append(byte)
                receivedBytes += 1
                // Update progress every 64 KB to avoid spamming the main actor
                if totalSize > 0, receivedBytes % 65536 == 0 {
                    downloads[wallpaper.id] = DownloadProgress(
                        wallpaperID: wallpaper.id,
                        progress: Double(receivedBytes) / Double(totalSize),
                        isComplete: false
                    )
                }
            }

            try data.write(to: destURL)
            downloads[wallpaper.id] = DownloadProgress(wallpaperID: wallpaper.id, progress: 1, isComplete: true)
            return destURL
        } catch {
            downloads[wallpaper.id] = DownloadProgress(
                wallpaperID: wallpaper.id, progress: 0, isComplete: false,
                error: error.localizedDescription
            )
            return nil
        }
    }

    func isDownloaded(_ wallpaper: RemoteWallpaper) -> Bool {
        let path = URL(fileURLWithPath: settings.wallpaperFolderPath)
            .appendingPathComponent(wallpaper.name).path
        return FileManager.default.fileExists(atPath: path)
    }

    // MARK: - Thumbnails

    /// Generates a thumbnail for a remote wallpaper from its video URL.
    /// Checks disk cache first; generates via AVAssetImageGenerator if missing.
    func loadThumbnail(for wallpaper: RemoteWallpaper) {
        let id = wallpaper.id
        guard thumbnails[id] == nil, !thumbnailTasks.contains(id) else { return }
        thumbnailTasks.insert(id)

        let cacheFile = thumbnailCacheFile(for: wallpaper)

        // Serve from disk cache if available
        if let cached = NSImage(contentsOf: cacheFile) {
            thumbnails[id] = cached
            thumbnailTasks.remove(id)
            return
        }

        Task.detached(priority: .utility) { [downloadURL = wallpaper.downloadURL] in
            let image = await Self.generateThumbnail(from: downloadURL)
            if let image,
               let tiff = image.tiffRepresentation,
               let rep = NSBitmapImageRep(data: tiff),
               let png = rep.representation(using: .png, properties: [:]) {
                try? png.write(to: cacheFile)
            }
            await MainActor.run {
                self.thumbnails[id] = image
                self.thumbnailTasks.remove(id)
            }
        }
    }

    func loadAllThumbnails() {
        for wallpaper in remoteWallpapers { loadThumbnail(for: wallpaper) }
    }

    private func thumbnailCacheFile(for wallpaper: RemoteWallpaper) -> URL {
        let safeName = wallpaper.id
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        return thumbnailCacheDirectory.appendingPathComponent(safeName + ".png")
    }

    /// Extracts a frame from a remote video URL using AVAssetImageGenerator.
    /// Tries 1 second in, falls back to time zero on failure.
    private static func generateThumbnail(from url: URL) async -> NSImage? {
        let asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: false])
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 480, height: 270)
        generator.requestedTimeToleranceBefore = CMTime(seconds: 2, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter  = CMTime(seconds: 2, preferredTimescale: 600)

        let time = CMTime(seconds: 1, preferredTimescale: 600)
        do {
            let (cg, _) = try await generator.image(at: time)
            return NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
        } catch {
            do {
                let (cg, _) = try await generator.image(at: .zero)
                return NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
            } catch {
                return nil
            }
        }
    }
}

// MARK: - GitHub API Types

private struct GitHubTreeResponse: Decodable {
    let tree: [GitHubTreeItem]
}

private struct GitHubTreeItem: Decodable {
    let path: String
    let type: String
    let size: Int?
}
