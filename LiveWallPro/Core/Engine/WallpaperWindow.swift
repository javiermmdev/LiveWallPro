import AppKit
import AVFoundation

/// A borderless, transparent window that sits at the desktop level behind icons.
/// Uses AVPlayerLayer for hardware-accelerated, power-efficient video playback.
final class WallpaperWindow: NSWindow {
    private let playerView: WallpaperPlayerView
    private(set) var displayID: CGDirectDisplayID

    init(display: DisplayInfo) {
        self.displayID = display.id
        self.playerView = WallpaperPlayerView()

        super.init(
            contentRect: display.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        // Place below desktop icons
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        isOpaque = true
        hasShadow = false
        backgroundColor = .black
        ignoresMouseEvents = true
        isReleasedWhenClosed = false
        animationBehavior = .none

        contentView = playerView
    }

    func updateFrame(for display: DisplayInfo) {
        self.displayID = display.id
        setFrame(display.frame, display: false, animate: false)
    }

    func setPlayer(_ player: AVPlayer?) {
        playerView.setPlayer(player)
    }

    func setScalingMode(_ mode: ScalingMode) {
        playerView.setScalingMode(mode)
    }

    func showOnDesktop() {
        orderFront(nil)
    }

    func hideFromDesktop() {
        orderOut(nil)
    }
}

/// The view that hosts AVPlayerLayer for efficient video rendering.
final class WallpaperPlayerView: NSView {
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer = AVPlayerLayer()
        (layer as? AVPlayerLayer)?.videoGravity = .resizeAspectFill
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    private var playerLayer: AVPlayerLayer? {
        layer as? AVPlayerLayer
    }

    func setPlayer(_ player: AVPlayer?) {
        playerLayer?.player = player
    }

    func setScalingMode(_ mode: ScalingMode) {
        switch mode {
        case .fill:
            playerLayer?.videoGravity = .resizeAspectFill
        case .fit:
            playerLayer?.videoGravity = .resizeAspect
        case .crop:
            playerLayer?.videoGravity = .resizeAspectFill
        case .stretch:
            playerLayer?.videoGravity = .resize
        }
    }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer?.frame = bounds
        CATransaction.commit()
    }
}
