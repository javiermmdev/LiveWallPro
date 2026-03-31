import Foundation
import SwiftUI

enum BatteryOptimizationMode: String, CaseIterable, Sendable {
    case off = "Off"
    case balanced = "Balanced"
    case aggressive = "Aggressive"
}

enum PlaybackMode: String, CaseIterable, Sendable {
    case loop = "Loop"
    case singlePlay = "Single Play"
    case shuffle = "Shuffle"
}

enum FrameRatePolicy: String, CaseIterable, Sendable {
    case native = "Native"
    case thirtyFPS = "30 FPS"
    case twentyFourFPS = "24 FPS"
    case fifteenFPS = "15 FPS"

    var maxRate: Float {
        switch self {
        case .native: return 60
        case .thirtyFPS: return 30
        case .twentyFourFPS: return 24
        case .fifteenFPS: return 15
        }
    }
}

enum QualityPolicy: String, CaseIterable, Sendable {
    case original = "Original"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

@Observable
final class SettingsStore: @unchecked Sendable {
    static let shared = SettingsStore()

    // Appearance
    var gradientTheme: GradientThemePreset {
        didSet { UserDefaults.standard.set(gradientTheme.rawValue, forKey: "gradientTheme") }
    }
    var appLanguage: AppLanguage {
        didSet { UserDefaults.standard.set(appLanguage.rawValue, forKey: "appLanguage") }
    }

    // General
    var launchAtLogin: Bool {
        didSet { UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin") }
    }
    var showInMenuBar: Bool {
        didSet { UserDefaults.standard.set(showInMenuBar, forKey: "showInMenuBar") }
    }
    var showInDock: Bool {
        didSet { UserDefaults.standard.set(showInDock, forKey: "showInDock") }
    }

    // Library
    var wallpaperFolderPath: String {
        didSet { UserDefaults.standard.set(wallpaperFolderPath, forKey: "wallpaperFolderPath") }
    }
    var watchFolderForChanges: Bool {
        didSet { UserDefaults.standard.set(watchFolderForChanges, forKey: "watchFolderForChanges") }
    }
    var autoGenerateThumbnails: Bool {
        didSet { UserDefaults.standard.set(autoGenerateThumbnails, forKey: "autoGenerateThumbnails") }
    }

    // Playback
    var playbackMode: PlaybackMode {
        didSet { UserDefaults.standard.set(playbackMode.rawValue, forKey: "playbackMode") }
    }
    var defaultVolume: Float {
        didSet { UserDefaults.standard.set(defaultVolume, forKey: "defaultVolume") }
    }

    // Performance
    var batteryOptimizationMode: BatteryOptimizationMode {
        didSet { UserDefaults.standard.set(batteryOptimizationMode.rawValue, forKey: "batteryOptimizationMode") }
    }
    var frameRatePolicy: FrameRatePolicy {
        didSet { UserDefaults.standard.set(frameRatePolicy.rawValue, forKey: "frameRatePolicy") }
    }
    var qualityPolicy: QualityPolicy {
        didSet { UserDefaults.standard.set(qualityPolicy.rawValue, forKey: "qualityPolicy") }
    }
    var pauseOnBattery: Bool {
        didSet { UserDefaults.standard.set(pauseOnBattery, forKey: "pauseOnBattery") }
    }
    var pauseWhenInactive: Bool {
        didSet { UserDefaults.standard.set(pauseWhenInactive, forKey: "pauseWhenInactive") }
    }
    var thumbnailCacheSizeMB: Int {
        didSet { UserDefaults.standard.set(thumbnailCacheSizeMB, forKey: "thumbnailCacheSizeMB") }
    }
    var useHardwareAcceleration: Bool {
        didSet { UserDefaults.standard.set(useHardwareAcceleration, forKey: "useHardwareAcceleration") }
    }

    private init() {
        let defaults = UserDefaults.standard

        self.gradientTheme = GradientThemePreset(rawValue: defaults.string(forKey: "gradientTheme") ?? "") ?? .aurora
        self.appLanguage = AppLanguage(rawValue: defaults.string(forKey: "appLanguage") ?? "") ?? .english
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        self.showInMenuBar = defaults.object(forKey: "showInMenuBar") as? Bool ?? true
        self.showInDock = defaults.object(forKey: "showInDock") as? Bool ?? false
        self.wallpaperFolderPath = defaults.string(forKey: "wallpaperFolderPath")
            ?? NSSearchPathForDirectoriesInDomains(.moviesDirectory, .userDomainMask, true).first
                .map { $0 + "/LiveWallPro" } ?? ""
        self.watchFolderForChanges = defaults.object(forKey: "watchFolderForChanges") as? Bool ?? true
        self.autoGenerateThumbnails = defaults.object(forKey: "autoGenerateThumbnails") as? Bool ?? true
        self.playbackMode = PlaybackMode(rawValue: defaults.string(forKey: "playbackMode") ?? "") ?? .loop
        self.defaultVolume = defaults.object(forKey: "defaultVolume") as? Float ?? 0
        self.batteryOptimizationMode = BatteryOptimizationMode(rawValue: defaults.string(forKey: "batteryOptimizationMode") ?? "") ?? .balanced
        self.frameRatePolicy = FrameRatePolicy(rawValue: defaults.string(forKey: "frameRatePolicy") ?? "") ?? .native
        self.qualityPolicy = QualityPolicy(rawValue: defaults.string(forKey: "qualityPolicy") ?? "") ?? .original
        self.pauseOnBattery = defaults.object(forKey: "pauseOnBattery") as? Bool ?? false
        self.pauseWhenInactive = defaults.object(forKey: "pauseWhenInactive") as? Bool ?? true
        self.thumbnailCacheSizeMB = defaults.object(forKey: "thumbnailCacheSizeMB") as? Int ?? 500
        self.useHardwareAcceleration = defaults.object(forKey: "useHardwareAcceleration") as? Bool ?? true
    }
}
