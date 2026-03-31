import SwiftUI

struct ExploreView: View {
    @Environment(AppState.self) private var appState
    let downloader: WallpaperDownloader
    let onDownloadComplete: ([URL]) async -> Void

    @State private var repoInput: String = "javiermmdev/livewallpapers-pro"
    @State private var selectedCategory: WallpaperCategory?

    private let columns = [
        GridItem(.adaptive(minimum: 240, maximum: 380), spacing: 14)
    ]

    private var filteredWallpapers: [RemoteWallpaper] {
        if let category = selectedCategory {
            return downloader.remoteWallpapers.filter { $0.category == category }
        }
        return downloader.remoteWallpapers
    }

    private var availableCategories: [WallpaperCategory] {
        let cats = Set(downloader.remoteWallpapers.compactMap(\.category))
        return WallpaperCategory.allCases.filter { cats.contains($0) }
    }

    /// Wallpapers grouped by category, preserving WallpaperCategory.allCases order
    private var groupedWallpapers: [(category: WallpaperCategory, wallpapers: [RemoteWallpaper])] {
        let source = filteredWallpapers
        let grouped = Dictionary(grouping: source) { $0.category }
        // Maintain allCases order, skip categories with 0 wallpapers
        var result: [(category: WallpaperCategory, wallpapers: [RemoteWallpaper])] = []
        for cat in WallpaperCategory.allCases {
            if let wallpapers = grouped[cat], !wallpapers.isEmpty {
                result.append((cat, wallpapers))
            }
        }
        // Uncategorized at the end
        if let uncategorized = grouped[nil], !uncategorized.isEmpty {
            // Skip — shouldn't happen with a well-structured repo
        }
        return result
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.exploreTitle)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .tracking(-0.5)

                    Text(L10n.exploreSubtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.horizontal, 28)
                .padding(.top, 28)
                .padding(.bottom, 20)

                // Repo input
                repoInputSection

                // Category filter
                if !availableCategories.isEmpty {
                    categoryFilter
                }

                // Content
                if downloader.isLoading {
                    loadingView
                } else if let error = downloader.errorMessage {
                    errorView(error)
                } else if downloader.remoteWallpapers.isEmpty {
                    emptyView
                } else {
                    wallpaperGrid
                }
            }
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Sections

    private var repoInputSection: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "link")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.3))

                TextField("owner/repo", text: $repoInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(.white)

                if !repoInput.isEmpty {
                    Button {
                        repoInput = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            }

            Button {
                Task { await downloader.fetchListing(repo: repoInput) }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 11, weight: .semibold))
                    Text(L10n.fetch)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.white.opacity(0.1), in: Capsule())
                .overlay { Capsule().stroke(.white.opacity(0.1), lineWidth: 1) }
            }
            .buttonStyle(.plain)
            .disabled(repoInput.isEmpty || downloader.isLoading)
            .opacity(repoInput.isEmpty ? 0.4 : 1)

            Button {
                Task { await downloadAll() }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "square.and.arrow.down.on.square")
                        .font(.system(size: 11, weight: .semibold))
                    Text(L10n.downloadAll)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.white.opacity(0.06), in: Capsule())
                .overlay { Capsule().stroke(.white.opacity(0.08), lineWidth: 1) }
            }
            .buttonStyle(.plain)
            .disabled(filteredWallpapers.isEmpty)
            .opacity(filteredWallpapers.isEmpty ? 0.3 : 1)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                CategoryFilterPill(title: L10n.allWallpapers, count: downloader.remoteWallpapers.count, isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }

                ForEach(availableCategories) { cat in
                    let count = downloader.remoteWallpapers.count { $0.category == cat }
                    CategoryFilterPill(title: cat.rawValue, count: count, isSelected: selectedCategory == cat) {
                        selectedCategory = cat
                    }
                }
            }
            .padding(.horizontal, 28)
        }
        .padding(.bottom, 16)
    }

    private var wallpaperGrid: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Total count
            Text("\(L10n.wallpaperCount(filteredWallpapers.count)) \(L10n.wallpapersAvailable)")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.35))
                .padding(.horizontal, 28)
                .padding(.bottom, 20)

            // Grouped by category with section headers
            ForEach(groupedWallpapers, id: \.category) { group in
                categorySectionHeader(group.category, count: group.wallpapers.count)

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(group.wallpapers) { wallpaper in
                        RemoteWallpaperCard(
                            wallpaper: wallpaper,
                            thumbnail: downloader.thumbnails[wallpaper.id],
                            progress: downloader.downloads[wallpaper.id],
                            isDownloaded: downloader.isDownloaded(wallpaper)
                        ) {
                            Task { await downloadSingle(wallpaper) }
                        }
                        .onAppear {
                            downloader.loadThumbnail(for: wallpaper)
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
            }
        }
    }

    private func categorySectionHeader(_ category: WallpaperCategory, count: Int) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: 10) {
            Image(systemName: category.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))

            Text(category.rawValue)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .tracking(-0.3)

            Text("\(count)")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.3))

            Spacer()
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 14)
        .padding(.top, 4)
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.small)
                .tint(.white.opacity(0.5))
            Text(L10n.fetchingRepo)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.white.opacity(0.2))
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(.white.opacity(0.12))

            VStack(spacing: 6) {
                Text(L10n.enterGitHubRepo)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))

                Text(L10n.repoFormatHint)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.3))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    // MARK: - Actions

    private func downloadSingle(_ wallpaper: RemoteWallpaper) async {
        if let url = await downloader.download(wallpaper) {
            await onDownloadComplete([url])
        }
    }

    private func downloadAll() async {
        var urls: [URL] = []
        for wallpaper in filteredWallpapers where !downloader.isDownloaded(wallpaper) {
            if let url = await downloader.download(wallpaper) {
                urls.append(url)
            }
        }
        if !urls.isEmpty {
            await onDownloadComplete(urls)
        }
    }
}

// MARK: - Subviews

private struct CategoryFilterPill: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                Text("\(count)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.45))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background {
                Capsule()
                    .fill(isSelected ? .white.opacity(0.1) : (isHovered ? .white.opacity(0.05) : .clear))
                    .overlay {
                        Capsule().stroke(.white.opacity(isSelected ? 0.1 : 0.06), lineWidth: 1)
                    }
            }
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

private struct RemoteWallpaperCard: View {
    let wallpaper: RemoteWallpaper
    let thumbnail: NSImage?
    let progress: WallpaperDownloader.DownloadProgress?
    let isDownloaded: Bool
    let onDownload: () -> Void

    @State private var isHovered = false

    private var isDownloading: Bool {
        guard let progress else { return false }
        return !progress.isComplete && progress.error == nil
    }

    private var isThumbnailLoading: Bool {
        thumbnail == nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Visual area
            ZStack {
                if let thumbnail {
                    // Real video thumbnail
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .clipped()
                        .transition(.opacity.animation(.easeIn(duration: 0.3)))
                } else {
                    // Skeleton shimmer while loading
                    SkeletonShimmer()
                }

                // Dark gradient overlay for status indicators
                if thumbnail != nil {
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.25)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

                // Download progress / status overlay
                if isDownloading, let progress {
                    Color.black.opacity(0.4)
                    VStack(spacing: 6) {
                        ProgressView(value: progress.progress)
                            .frame(width: 100)
                            .tint(.white.opacity(0.7))
                        Text("\(Int(progress.progress * 100))%")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                } else if isDownloaded {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.green.opacity(0.8))
                        .shadow(color: .black.opacity(0.5), radius: 4)
                } else if let progress, let error = progress.error {
                    VStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: 20))
                            .foregroundStyle(.red.opacity(0.7))
                        Text(error)
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.4))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 12)
                }

                // Video play badge (only when thumbnail loaded)
                if thumbnail != nil {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "play.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(5)
                                .background(.black.opacity(0.5), in: Circle())
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }
            .aspectRatio(16.0 / 10.0, contentMode: .fit)
            .clipShape(UnevenRoundedRectangle(
                topLeadingRadius: 12, bottomLeadingRadius: 0,
                bottomTrailingRadius: 0, topTrailingRadius: 12
            ))

            // Info bar
            HStack {
                if isThumbnailLoading {
                    // Skeleton for text too
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(.white.opacity(0.06))
                            .frame(width: 120, height: 10)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(.white.opacity(0.04))
                            .frame(width: 70, height: 8)
                    }
                    Spacer()
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(wallpaper.displayName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            if let category = wallpaper.category {
                                Text(category.rawValue)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.35))
                            }
                            Text(wallpaper.formattedSize)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white.opacity(0.25))
                        }
                    }

                    Spacer()

                    if isDownloaded {
                        Text(L10n.downloaded)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.green.opacity(0.6))
                    } else if !isDownloading {
                        Button(action: onDownload) {
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 16))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(isHovered ? 0.12 : 0.06), lineWidth: 1)
        }
        .shadow(color: .black.opacity(isHovered ? 0.4 : 0.2), radius: isHovered ? 14 : 6, y: isHovered ? 4 : 2)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeOut(duration: 0.2), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Skeleton Shimmer

private struct SkeletonShimmer: View {
    @State private var shimmerOffset: CGFloat = -1

    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(Color(white: 0.08))
                .overlay {
                    // Animated shimmer sweep
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .white.opacity(0.04), location: 0.4),
                            .init(color: .white.opacity(0.08), location: 0.5),
                            .init(color: .white.opacity(0.04), location: 0.6),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: UnitPoint(x: shimmerOffset - 0.3, y: 0.5),
                        endPoint: UnitPoint(x: shimmerOffset + 0.3, y: 0.5)
                    )
                }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: false)) {
                shimmerOffset = 2
            }
        }
    }
}
