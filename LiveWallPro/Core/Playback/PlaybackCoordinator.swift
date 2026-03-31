import AVFoundation
import Foundation

@Observable
@MainActor
final class PlaybackCoordinator {
    struct PlayerState: Sendable {
        let displayID: CGDirectDisplayID
        let wallpaperID: UUID?
        var isPlaying: Bool
    }

    private(set) var playerStates: [CGDirectDisplayID: PlayerState] = [:]
    private var players: [CGDirectDisplayID: AVQueuePlayer] = [:]
    private var loopers: [CGDirectDisplayID: AVPlayerLooper] = [:]
    private var playerItems: [CGDirectDisplayID: AVPlayerItem] = [:]

    func setupPlayer(for displayID: CGDirectDisplayID, videoURL: URL, wallpaperID: UUID) async {
        teardownPlayer(for: displayID)

        // Start security-scoped access if the URL is a security-scoped bookmark
        let accessing = videoURL.startAccessingSecurityScopedResource()

        let asset = AVURLAsset(url: videoURL, options: [
            AVURLAssetPreferPreciseDurationAndTimingKey: false
        ])

        // Verify the asset is playable before creating the player
        let isPlayable: Bool
        do {
            isPlayable = try await asset.load(.isPlayable)
        } catch {
            print("[PlaybackCoordinator] Asset not playable at \(videoURL.path): \(error.localizedDescription)")
            if accessing { videoURL.stopAccessingSecurityScopedResource() }
            return
        }

        guard isPlayable else {
            print("[PlaybackCoordinator] Asset reports not playable: \(videoURL.path)")
            if accessing { videoURL.stopAccessingSecurityScopedResource() }
            return
        }

        let templateItem = AVPlayerItem(asset: asset)
        templateItem.preferredForwardBufferDuration = 2

        let player = AVQueuePlayer()
        player.automaticallyWaitsToMinimizeStalling = false
        player.preventsDisplaySleepDuringVideoPlayback = false
        player.volume = 0
        player.allowsExternalPlayback = false

        let looper = AVPlayerLooper(player: player, templateItem: templateItem)

        players[displayID] = player
        loopers[displayID] = looper
        playerItems[displayID] = templateItem

        playerStates[displayID] = PlayerState(
            displayID: displayID,
            wallpaperID: wallpaperID,
            isPlaying: false
        )
    }

    func player(for displayID: CGDirectDisplayID) -> AVQueuePlayer? {
        players[displayID]
    }

    func play(displayID: CGDirectDisplayID) {
        players[displayID]?.play()
        playerStates[displayID]?.isPlaying = true
    }

    func pause(displayID: CGDirectDisplayID) {
        players[displayID]?.pause()
        playerStates[displayID]?.isPlaying = false
    }

    func pauseAll() {
        for displayID in players.keys {
            pause(displayID: displayID)
        }
    }

    func resumeAll() {
        for displayID in players.keys {
            play(displayID: displayID)
        }
    }

    func setVolume(_ volume: Float, for displayID: CGDirectDisplayID) {
        players[displayID]?.volume = volume
    }

    func setRate(_ rate: Float, for displayID: CGDirectDisplayID) {
        players[displayID]?.rate = rate
    }

    func applyPowerPolicy(_ policy: PowerPolicy) {
        switch policy {
        case .fullQuality:
            resumeAll()
        case .balanced:
            resumeAll()
            for displayID in players.keys {
                setRate(1.0, for: displayID)
            }
        case .lowPower:
            for displayID in players.keys {
                if playerStates[displayID]?.isPlaying == true {
                    setRate(0.5, for: displayID)
                }
            }
        case .paused:
            pauseAll()
        }
    }

    func teardownPlayer(for displayID: CGDirectDisplayID) {
        players[displayID]?.pause()
        players[displayID]?.removeAllItems()
        loopers[displayID]?.disableLooping()

        players.removeValue(forKey: displayID)
        loopers.removeValue(forKey: displayID)
        playerItems.removeValue(forKey: displayID)
        playerStates.removeValue(forKey: displayID)
    }

    func teardownAll() {
        let allDisplays = Array(players.keys)
        for displayID in allDisplays {
            teardownPlayer(for: displayID)
        }
    }
}
