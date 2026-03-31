import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView {
            AppearanceSettingsTab()
                .environment(appState)
                .tabItem { Label(L10n.appearance, systemImage: "paintpalette") }

            GeneralSettingsTab()
                .environment(appState)
                .tabItem { Label(L10n.general, systemImage: "gear") }

            LibrarySettingsTab()
                .environment(appState)
                .tabItem { Label(L10n.library, systemImage: "folder") }

            PlaybackSettingsTab()
                .environment(appState)
                .tabItem { Label(L10n.playback, systemImage: "play.circle") }

            PerformanceSettingsTab()
                .environment(appState)
                .tabItem { Label(L10n.performance, systemImage: "gauge.with.dots.needle.33percent") }

            DisplaySettingsTab()
                .environment(appState)
                .tabItem { Label(L10n.displays, systemImage: "display.2") }
        }
        .frame(width: 520)
    }
}

// MARK: - Appearance

struct AppearanceSettingsTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var settings = appState.settings

        Form {
            Section(L10n.language) {
                Picker(L10n.language, selection: $settings.appLanguage) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.rawValue).tag(lang)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section(L10n.theme) {
                Text(L10n.chooseTheme)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 140), spacing: 12)], spacing: 12) {
                    ForEach(GradientThemePreset.allCases) { preset in
                        ThemePresetButton(
                            preset: preset,
                            isSelected: settings.gradientTheme == preset
                        ) {
                            settings.gradientTheme = preset
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Preview") {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.clear)
                    .frame(height: 80)
                    .background {
                        settings.gradientTheme.meshGradient
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .overlay {
                        HStack(spacing: 16) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.ultraThinMaterial)
                                .frame(width: 100, height: 60)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(.white.opacity(0.12), lineWidth: 1)
                                }
                                .overlay {
                                    Text("Card")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.7))
                                }

                            RoundedRectangle(cornerRadius: 8)
                                .fill(.ultraThinMaterial)
                                .frame(width: 100, height: 60)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(.white.opacity(0.12), lineWidth: 1)
                                }
                                .overlay {
                                    Text("Card")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                        }
                    }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

private struct ThemePresetButton: View {
    let preset: GradientThemePreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(preset.gradient)
                    .frame(height: 56)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? preset.accentColor : .white.opacity(0.1), lineWidth: isSelected ? 2.5 : 1)
                    }
                    .shadow(color: isSelected ? preset.accentColor.opacity(0.4) : .clear, radius: 8)

                Text(preset.rawValue)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - General

struct GeneralSettingsTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var settings = appState.settings

        Form {
            Section(L10n.startup) {
                Toggle(L10n.launchAtLogin, isOn: $settings.launchAtLogin)
                Toggle(L10n.showInMenuBar, isOn: $settings.showInMenuBar)
                Toggle(L10n.showInDock, isOn: $settings.showInDock)
            }

            Section(L10n.engine) {
                HStack {
                    Text(L10n.status)
                    Spacer()
                    Image(systemName: "circle.fill")
                        .foregroundStyle(appState.wallpaperEngine.isRunning ? .green : .gray)
                        .font(.caption2)
                    Text(appState.wallpaperEngine.isRunning ? L10n.running : L10n.stopped)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Button(L10n.startEngine) { appState.startEngine() }
                        .disabled(appState.wallpaperEngine.isRunning)
                    Button(L10n.stopEngine) { appState.stopEngine() }
                        .disabled(!appState.wallpaperEngine.isRunning)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Library

struct LibrarySettingsTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var settings = appState.settings

        Form {
            Section("Wallpaper Folder") {
                HStack {
                    TextField("Path", text: $settings.wallpaperFolderPath)
                        .textFieldStyle(.roundedBorder)
                    Button("Browse...") {
                        let panel = NSOpenPanel()
                        panel.canChooseDirectories = true
                        panel.canChooseFiles = false
                        panel.allowsMultipleSelection = false
                        if panel.runModal() == .OK, let url = panel.url {
                            settings.wallpaperFolderPath = url.path
                        }
                    }
                }
                Toggle("Watch folder for new files", isOn: $settings.watchFolderForChanges)
            }

            Section("Import") {
                Toggle("Auto-generate thumbnails", isOn: $settings.autoGenerateThumbnails)

                Button("Import from Wallpaper Folder") {
                    let url = URL(fileURLWithPath: settings.wallpaperFolderPath)
                    Task {
                        await appState.importPipeline.importFromFolder(url)
                        try? appState.libraryManager.loadWallpapers()
                    }
                }
            }

            Section("Cache") {
                HStack {
                    Text("Thumbnail Cache Size")
                    Spacer()
                    Picker("", selection: $settings.thumbnailCacheSizeMB) {
                        Text("100 MB").tag(100)
                        Text("250 MB").tag(250)
                        Text("500 MB").tag(500)
                        Text("1 GB").tag(1024)
                    }
                    .frame(width: 120)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Playback

struct PlaybackSettingsTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var settings = appState.settings

        Form {
            Section("Playback") {
                Picker("Mode", selection: $settings.playbackMode) {
                    ForEach(PlaybackMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }

                HStack {
                    Text("Default Volume")
                    Slider(value: $settings.defaultVolume, in: 0...1)
                    Text("\(Int(settings.defaultVolume * 100))%")
                        .foregroundStyle(.secondary)
                        .frame(width: 40)
                }
            }

            Section("Auto-Pause") {
                Toggle("Pause when no apps visible (battery saving)", isOn: $settings.pauseWhenInactive)
                Toggle("Pause on battery power", isOn: $settings.pauseOnBattery)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Performance

struct PerformanceSettingsTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var settings = appState.settings

        Form {
            Section("Battery Optimization") {
                Picker("Mode", selection: $settings.batteryOptimizationMode) {
                    ForEach(BatteryOptimizationMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                Text("Balanced reduces quality on battery. Aggressive pauses below 20%.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Frame Rate") {
                Picker("Max Frame Rate", selection: $settings.frameRatePolicy) {
                    ForEach(FrameRatePolicy.allCases, id: \.self) { policy in
                        Text(policy.rawValue).tag(policy)
                    }
                }
                Text("Lower frame rates significantly reduce power consumption.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Quality") {
                Picker("Quality", selection: $settings.qualityPolicy) {
                    ForEach(QualityPolicy.allCases, id: \.self) { policy in
                        Text(policy.rawValue).tag(policy)
                    }
                }
                Toggle("Hardware Acceleration", isOn: $settings.useHardwareAcceleration)
            }

            Section("Current Status") {
                LabeledContent("Power Source") { Text(powerSourceText) }
                LabeledContent("Active Policy") { Text(policyText) }
                LabeledContent("Low Power Mode") {
                    Text(appState.powerManager.isLowPowerMode ? "On" : "Off")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var powerSourceText: String {
        switch appState.powerManager.powerSource {
        case .battery(let level): return "Battery (\(level)%)"
        case .ac: return "AC Power"
        case .unknown: return "Unknown"
        }
    }

    private var policyText: String {
        switch appState.powerManager.currentPolicy {
        case .fullQuality: return "Full Quality"
        case .balanced: return "Balanced"
        case .lowPower: return "Low Power"
        case .paused: return "Paused"
        }
    }
}

// MARK: - Displays

struct DisplaySettingsTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Form {
            Section("Connected Displays") {
                ForEach(appState.displayManager.displays) { display in
                    DisplayRow(
                        display: display,
                        activeWallpaper: activeWallpaper(for: display),
                        onRemove: { appState.wallpaperEngine.removeWallpaper(for: display.id) }
                    )
                }
            }

            Section {
                Button("Refresh Displays") {
                    appState.displayManager.refreshDisplays()
                    appState.wallpaperEngine.handleDisplaysChanged()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func activeWallpaper(for display: DisplayInfo) -> Wallpaper? {
        guard let wallpaperID = appState.wallpaperEngine.activeWallpapers[display.id] else { return nil }
        return appState.libraryManager.wallpaper(for: wallpaperID)
    }
}

private struct DisplayRow: View {
    let display: DisplayInfo
    let activeWallpaper: Wallpaper?
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: display.isBuiltIn ? "laptopcomputer" : "display")
                Text(display.name).font(.headline)
                if display.isMain {
                    Text("Main")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.2), in: Capsule())
                }
                Spacer()
            }

            HStack(spacing: 16) {
                Text("Resolution: \(Int(display.nativeResolution.width))x\(Int(display.nativeResolution.height))")
                Text("Scale: \(String(format: "%.0f", display.scaleFactor))x")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if let wallpaper = activeWallpaper {
                HStack {
                    Text("Active: \(wallpaper.title)")
                        .font(.caption)
                        .foregroundStyle(.green)
                    Spacer()
                    Button("Remove", action: onRemove)
                        .controlSize(.small)
                }
            } else {
                Text("No wallpaper assigned")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
