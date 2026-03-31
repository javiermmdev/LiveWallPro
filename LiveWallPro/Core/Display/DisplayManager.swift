import AppKit
import Foundation

struct DisplayInfo: Identifiable, Sendable {
    let id: CGDirectDisplayID
    let frame: CGRect
    let visibleFrame: CGRect
    let scaleFactor: CGFloat
    let isMain: Bool
    let isBuiltIn: Bool
    let name: String

    var stringID: String { String(id) }

    var nativeResolution: CGSize {
        CGSize(
            width: frame.width * scaleFactor,
            height: frame.height * scaleFactor
        )
    }
}

@Observable
@MainActor
final class DisplayManager {
    private(set) var displays: [DisplayInfo] = []
    private var registeredCallback: CGDisplayReconfigurationCallBack?

    init() {
        refreshDisplays()
        registerForDisplayChanges()
    }

    deinit {
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        CGDisplayRemoveReconfigurationCallback({ _, _, _ in }, pointer)
    }

    func refreshDisplays() {
        var displayCount: UInt32 = 0
        CGGetActiveDisplayList(0, nil, &displayCount)

        var displayIDs = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
        CGGetActiveDisplayList(displayCount, &displayIDs, &displayCount)

        let mainDisplay = CGMainDisplayID()

        displays = displayIDs.compactMap { displayID in
            let screen = NSScreen.screens.first { screen in
                let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
                return screenNumber == displayID
            }

            // Use NSScreen.frame (AppKit coordinates, includes menu bar area)
            let frame = screen?.frame ?? CGDisplayBounds(displayID)
            let visibleFrame = screen?.visibleFrame ?? frame
            let scaleFactor = screen?.backingScaleFactor ?? 2.0
            let isBuiltIn = CGDisplayIsBuiltin(displayID) != 0

            let name: String
            if let screen = screen {
                name = screen.localizedName
            } else if isBuiltIn {
                name = "Built-in Display"
            } else {
                name = "Display \(displayID)"
            }

            return DisplayInfo(
                id: displayID,
                frame: frame,
                visibleFrame: visibleFrame,
                scaleFactor: scaleFactor,
                isMain: displayID == mainDisplay,
                isBuiltIn: isBuiltIn,
                name: name
            )
        }
    }

    private func registerForDisplayChanges() {
        let callback: CGDisplayReconfigurationCallBack = { displayID, flags, userInfo in
            guard let userInfo = userInfo else { return }
            let manager = Unmanaged<DisplayManager>.fromOpaque(userInfo).takeUnretainedValue()
            if flags.contains(.addFlag) || flags.contains(.removeFlag) || flags.contains(.movedFlag) {
                Task { @MainActor in
                    manager.refreshDisplays()
                }
            }
        }

        let pointer = Unmanaged.passUnretained(self).toOpaque()
        CGDisplayRegisterReconfigurationCallback(callback, pointer)
    }

    private func unregisterDisplayChanges() {
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        CGDisplayRemoveReconfigurationCallback({ _, _, _ in }, pointer)
    }

    func display(for id: CGDirectDisplayID) -> DisplayInfo? {
        displays.first { $0.id == id }
    }

    func display(forStringID stringID: String) -> DisplayInfo? {
        guard let numericID = UInt32(stringID) else { return nil }
        return displays.first { $0.id == numericID }
    }
}
