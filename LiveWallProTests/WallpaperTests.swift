import Testing
import Foundation
@testable import LiveWallPro

@Suite("Wallpaper Model Tests")
struct WallpaperTests {
    @Test("Create wallpaper with basic properties")
    func createWallpaper() {
        let wallpaper = Wallpaper(
            filePath: "/tmp/test.mp4",
            title: "Test Wallpaper",
            resolutionWidth: 1920,
            resolutionHeight: 1080,
            duration: 30.0,
            fileSize: 1024 * 1024 * 50
        )

        #expect(wallpaper.title == "Test Wallpaper")
        #expect(wallpaper.resolution == "1920x1080")
        #expect(wallpaper.formattedDuration == "0:30")
        #expect(!wallpaper.isVertical)
        #expect(!wallpaper.isFavorite)
        #expect(wallpaper.timesUsed == 0)
    }

    @Test("Vertical wallpaper detection")
    func verticalDetection() {
        let vertical = Wallpaper(
            filePath: "/tmp/vertical.mp4",
            title: "Vertical",
            resolutionWidth: 1080,
            resolutionHeight: 1920
        )
        #expect(vertical.isVertical)

        let horizontal = Wallpaper(
            filePath: "/tmp/horizontal.mp4",
            title: "Horizontal",
            resolutionWidth: 1920,
            resolutionHeight: 1080
        )
        #expect(!horizontal.isVertical)
    }

    @Test("Aspect ratio calculation")
    func aspectRatio() {
        let wallpaper = Wallpaper(
            filePath: "/tmp/test.mp4",
            title: "Test",
            resolutionWidth: 1920,
            resolutionHeight: 1080
        )

        let ratio = wallpaper.aspectRatio
        #expect(abs(ratio - (16.0 / 9.0)) < 0.01)
    }

    @Test("File size formatting")
    func fileSizeFormatting() {
        let wallpaper = Wallpaper(
            filePath: "/tmp/test.mp4",
            title: "Test",
            fileSize: 52_428_800
        )

        #expect(!wallpaper.formattedFileSize.isEmpty)
    }
}

@Suite("Settings Store Tests")
struct SettingsStoreTests {
    @Test("Default settings values")
    func defaultValues() {
        let settings = SettingsStore.shared

        #expect(settings.showInMenuBar == true)
        #expect(settings.useHardwareAcceleration == true)
        #expect(settings.batteryOptimizationMode == .balanced)
        #expect(settings.frameRatePolicy == .native)
        #expect(settings.playbackMode == .loop)
    }
}

@Suite("Scaling Mode Tests")
struct ScalingModeTests {
    @Test("All scaling modes available")
    func allModes() {
        let modes = ScalingMode.allCases
        #expect(modes.count == 4)
        #expect(modes.contains(.fill))
        #expect(modes.contains(.fit))
        #expect(modes.contains(.crop))
        #expect(modes.contains(.stretch))
    }
}

@Suite("Power Policy Tests")
struct PowerPolicyTests {
    @Test("Frame rate policy values")
    func frameRatePolicies() {
        #expect(FrameRatePolicy.native.maxRate == 60)
        #expect(FrameRatePolicy.thirtyFPS.maxRate == 30)
        #expect(FrameRatePolicy.twentyFourFPS.maxRate == 24)
        #expect(FrameRatePolicy.fifteenFPS.maxRate == 15)
    }
}

@Suite("Import Pipeline Tests")
struct ImportPipelineTests {
    @Test("Supported file extensions")
    func supportedExtensions() {
        #expect(ImportPipeline.supportedExtensions.contains("mp4"))
        #expect(ImportPipeline.supportedExtensions.contains("m4v"))
        #expect(ImportPipeline.supportedExtensions.contains("mov"))
        #expect(!ImportPipeline.supportedExtensions.contains("avi"))
        #expect(!ImportPipeline.supportedExtensions.contains("wmv"))
    }
}
