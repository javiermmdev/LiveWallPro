import Foundation
import SwiftData

@Model
final class DisplayAssignment {
    @Attribute(.unique) var displayID: String
    var wallpaperID: UUID?
    var scalingMode: ScalingMode
    var volume: Float
    var playbackSpeed: Float

    init(displayID: String, wallpaperID: UUID? = nil) {
        self.displayID = displayID
        self.wallpaperID = wallpaperID
        self.scalingMode = .fill
        self.volume = 0
        self.playbackSpeed = 1.0
    }
}

enum ScalingMode: String, Codable, CaseIterable, Sendable {
    case fill = "Fill"
    case fit = "Fit"
    case crop = "Crop"
    case stretch = "Stretch"
}
