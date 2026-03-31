import SwiftUI

struct WallpaperCard: View {
    let viewModel: WallpaperCardViewModel
    @State private var isHovered = false
    @State private var showDeleteAlert = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Full-bleed image or placeholder
            thumbnailBackground

            // Cinematic gradient overlay
            LinearGradient(
                colors: [.clear, .clear, .black.opacity(0.2), .black.opacity(0.65)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Top badges
            VStack {
                HStack(spacing: 6) {
                    if viewModel.isActive {
                        BadgeView(text: L10n.active, color: .green)
                    }
                    if viewModel.wallpaper.isVertical {
                        BadgeView(text: L10n.vertical, color: .purple)
                    }
                    Spacer()
                    Text(viewModel.wallpaper.formattedDuration)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 5))
                }
                .padding(10)
                Spacer()
            }

            // Bottom info
            VStack(alignment: .leading, spacing: 3) {
                Text(viewModel.wallpaper.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(viewModel.wallpaper.resolution)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.45))
                    if !viewModel.wallpaper.creator.isEmpty {
                        Circle().fill(.white.opacity(0.2)).frame(width: 3, height: 3)
                        Text(viewModel.wallpaper.creator)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.45))
                            .lineLimit(1)
                    }
                }
            }
            .padding(12)

            // Hover overlay with Set Wallpaper button
            if isHovered {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.04))
                    .overlay {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button {
                                    viewModel.setAsWallpaper()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 10))
                                        Text(L10n.setWallpaper)
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.white.opacity(0.15), in: Capsule())
                                    .overlay { Capsule().stroke(.white.opacity(0.1), lineWidth: 1) }
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(10)
                        }
                    }
                    .transition(.opacity)
                    .allowsHitTesting(true)
            }
        }
        .aspectRatio(16.0 / 10.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(isHovered ? 0.15 : 0.06), lineWidth: 1)
        }
        .shadow(color: .black.opacity(isHovered ? 0.5 : 0.25), radius: isHovered ? 18 : 8, y: isHovered ? 6 : 3)
        .scaleEffect(isHovered ? 1.025 : 1.0)
        .animation(.easeOut(duration: 0.2), value: isHovered)
        .onHover { isHovered = $0 }
        .contextMenu { contextMenu }
        .alert(L10n.deleteWallpaper, isPresented: $showDeleteAlert) {
            Button(L10n.cancel, role: .cancel) { }
            Button(L10n.delete, role: .destructive) {
                viewModel.delete()
            }
        } message: {
            Text(L10n.deleteConfirmation)
        }
    }

    @ViewBuilder
    private var thumbnailBackground: some View {
        if let thumbnailURL = viewModel.wallpaper.thumbnailURL,
           let nsImage = NSImage(contentsOf: thumbnailURL) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
        } else {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.1), Color(white: 0.06)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    Image(systemName: "film")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(.white.opacity(0.08))
                }
        }
    }

    @ViewBuilder
    private var contextMenu: some View {
        Button(L10n.setAllDisplays) { viewModel.setOnAllDisplays() }

        ForEach(viewModel.displays) { display in
            Button(L10n.setOnDisplay(display.name)) { viewModel.setOnDisplay(display.id) }
        }

        Divider()

        Button(viewModel.wallpaper.isFavorite ? L10n.removeFromFavorites : L10n.addToFavorites) {
            viewModel.toggleFavorite()
        }

        Divider()

        Menu(L10n.category) {
            Button(L10n.none) { viewModel.setCategory(nil) }
            Divider()
            ForEach(WallpaperCategory.allCases) { cat in
                Button {
                    viewModel.setCategory(cat)
                } label: {
                    HStack {
                        Image(systemName: cat.icon)
                        Text(cat.rawValue)
                        if viewModel.wallpaper.wallpaperCategory == cat {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }

        Menu(L10n.scaling) {
            ForEach(ScalingMode.allCases, id: \.self) { mode in
                Button(mode.rawValue) { viewModel.setScaling(mode) }
            }
        }

        Divider()

        Button(L10n.showInFinder) { viewModel.showInFinder() }
        Button(L10n.delete) { showDeleteAlert = true }
    }
}

struct BadgeView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.75), in: RoundedRectangle(cornerRadius: 5))
            .overlay {
                RoundedRectangle(cornerRadius: 5)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            }
    }
}
