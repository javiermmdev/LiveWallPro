import Foundation

/// Watches a designated wallpaper folder for new MP4 files using DispatchSource.
/// Power-efficient: uses kqueue-based file system events, no polling.
@MainActor
final class FolderWatcher {
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private let onChanged: () -> Void

    init(onChanged: @escaping () -> Void) {
        self.onChanged = onChanged
    }

    func startWatching(directory: URL) {
        stopWatching()

        let path = directory.path
        fileDescriptor = open(path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename],
            queue: .main
        )

        source.setEventHandler { [weak self] in
            self?.onChanged()
        }

        source.setCancelHandler { [weak self] in
            guard let self else { return }
            if self.fileDescriptor >= 0 {
                close(self.fileDescriptor)
                self.fileDescriptor = -1
            }
        }

        source.resume()
        self.source = source
    }

    func stopWatching() {
        source?.cancel()
        source = nil
    }

    deinit {
        source?.cancel()
    }
}
