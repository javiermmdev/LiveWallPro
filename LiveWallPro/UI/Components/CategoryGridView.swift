import SwiftUI

struct CategoryGridView: View {
    @Environment(AppState.self) private var appState
    var onSelectCategory: (WallpaperCategory) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Editorial header
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.categories)
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundStyle(.white)
                        .tracking(-0.5)

                    Text(L10n.browseByCategory)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.horizontal, 28)
                .padding(.top, 28)
                .padding(.bottom, 24)

                // 3x3 category grid
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(WallpaperCategory.allCases) { category in
                        CategoryCard(
                            category: category,
                            thumbnailURL: appState.libraryManager.firstThumbnail(for: category),
                            count: appState.libraryManager.wallpaperCount(for: category),
                            onTap: { onSelectCategory(category) }
                        )
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
            }
        }
        .scrollIndicators(.hidden)
    }
}

private struct CategoryCard: View {
    let category: WallpaperCategory
    let thumbnailURL: URL?
    let count: Int
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                // Background: category image from asset catalog
                Image(category.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .clipped()

                // Dark gradient overlay for text readability
                LinearGradient(
                    colors: [.clear, .clear, .black.opacity(0.3), .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Category label
                VStack(alignment: .leading, spacing: 3) {
                    Text(category.rawValue)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .tracking(-0.2)

                    if count > 0 {
                        Text("\(count) wallpaper\(count == 1 ? "" : "s")")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(16)
            }
            .aspectRatio(16.0 / 10.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.white.opacity(isHovered ? 0.12 : 0.06), lineWidth: 1)
            }
            .shadow(color: .black.opacity(isHovered ? 0.5 : 0.3), radius: isHovered ? 20 : 10, y: isHovered ? 8 : 4)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
