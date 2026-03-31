import SwiftUI

struct WallpaperGridView: View {
    @Environment(AppState.self) private var appState
    let viewModel: LibraryViewModel
    var showLibraryFilters: Bool = false

    private let columns = [
        GridItem(.adaptive(minimum: 260, maximum: 420), spacing: 14)
    ]

    var body: some View {
        let wallpapers = viewModel.filteredWallpapers

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Editorial header
                headerSection

                if showLibraryFilters {
                    libraryFilterBar
                }

                if wallpapers.isEmpty {
                    EmptyLibraryView {
                        viewModel.isShowingImporter = true
                    }
                } else {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(wallpapers, id: \.id) { wallpaper in
                            WallpaperCard(viewModel: appState.makeCardViewModel(for: wallpaper))
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 28)
                }
            }
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            if viewModel.isImporting {
                ImportProgressOverlay(progress: viewModel.importProgress)
            }
        }
    }

    private var headerSection: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                if viewModel.selectedCategory != nil {
                    Button {
                        viewModel.clearCategory()
                        viewModel.selectedTab = .home
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 10, weight: .semibold))
                            Text(L10n.categories)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 2)
                }

                Text(viewModel.currentTitle)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .tracking(-0.5)

                Text(viewModel.currentSubtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.4))
            }

            Spacer()

            // Sort button
            SortMenuButton(sortOrder: Bindable(viewModel).sortOrder)
        }
        .padding(.horizontal, 28)
        .padding(.top, 28)
        .padding(.bottom, 20)
    }

    @ViewBuilder
    private var libraryFilterBar: some View {
        HStack(spacing: 6) {
            FilterPill(
                title: L10n.allWallpapers,
                isSelected: viewModel.selectedSidebarItem == .allWallpapers
            ) { viewModel.selectedSidebarItem = .allWallpapers }

            FilterPill(
                title: L10n.favorites,
                icon: "heart.fill",
                isSelected: viewModel.selectedSidebarItem == .favorites
            ) { viewModel.selectedSidebarItem = .favorites }

            FilterPill(
                title: L10n.recent,
                icon: "clock",
                isSelected: viewModel.selectedSidebarItem == .recent
            ) { viewModel.selectedSidebarItem = .recent }

            FilterPill(
                title: L10n.vertical,
                icon: "rectangle.portrait",
                isSelected: viewModel.selectedSidebarItem == .vertical
            ) { viewModel.selectedSidebarItem = .vertical }

            Spacer()
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 16)
    }
}

private struct FilterPill: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                }
                Text(title)
                    .font(.system(size: 12, weight: .medium))
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

private struct EmptyLibraryView: View {
    let onImport: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.white.opacity(0.15))

            VStack(spacing: 8) {
                Text(L10n.noWallpapers)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))

                Text(L10n.emptyImportHint)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.35))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            Button(action: onImport) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .semibold))
                    Text(L10n.importWallpapers)
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.white.opacity(0.1), in: Capsule())
                .overlay { Capsule().stroke(.white.opacity(0.1), lineWidth: 1) }
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 60)
    }
}

private struct ImportProgressOverlay: View {
    let progress: Double

    var body: some View {
        VStack(spacing: 12) {
            ProgressView(value: progress)
                .frame(width: 180)
                .tint(.white.opacity(0.7))
            Text(L10n.importing)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(24)
        .glassCard(cornerRadius: 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 28)
    }
}
