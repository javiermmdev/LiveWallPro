import SwiftUI

/// Root view. Lays out the navigation bar and tab-driven content over a
/// full-window theme gradient background.
struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: LibraryViewModel?

    /// Lazily creates the view model on first access.
    private var vm: LibraryViewModel {
        if let viewModel { return viewModel }
        let created = appState.makeLibraryViewModel()
        Task { @MainActor in self.viewModel = created }
        return created
    }

    private var theme: GradientThemePreset {
        appState.settings.gradientTheme
    }

    var body: some View {
        @Bindable var library = vm

        ZStack {
            // Full-window gradient — sits behind the nav bar too
            theme.meshGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                NavigationBar(
                    selectedTab: $library.selectedTab,
                    searchText: $library.searchText,
                    onImport: { vm.isShowingImporter = true }
                )

                // MARK: Tab Content
                switch vm.selectedTab {
                case .home:
                    CategoryGridView { category in
                        vm.selectCategory(category)
                    }

                case .explore:
                    if vm.selectedCategory != nil {
                        // Browsing a specific category from the home grid
                        WallpaperGridView(viewModel: vm)
                    } else {
                        ExploreView(downloader: appState.wallpaperDownloader) { urls in
                            await vm.importFiles(urls)
                        }
                    }

                case .library:
                    WallpaperGridView(viewModel: vm, showLibraryFilters: true)
                }
            }
        }
        .fileImporter(
            isPresented: $library.isShowingImporter,
            allowedContentTypes: ImportPipeline.supportedTypes,
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                Task { await vm.importFiles(urls) }
            }
        }
        .onDrop(of: ImportPipeline.supportedTypes, isTargeted: nil) { providers in
            Task { await vm.handleDrop(providers) }
            return true
        }
    }
}
