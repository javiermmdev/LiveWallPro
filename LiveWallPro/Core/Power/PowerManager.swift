import AppKit
import Foundation
import IOKit.ps

enum PowerSource: Sendable {
    case battery(level: Int)
    case ac
    case unknown
}

enum PowerPolicy: Sendable {
    case fullQuality
    case balanced
    case lowPower
    case paused
}

private final class NotificationObserverBag: @unchecked Sendable {
    var observers: [any NSObjectProtocol] = []

    func removeAll() {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        observers.removeAll()
    }

    deinit {
        removeAll()
    }
}

@Observable
@MainActor
final class PowerManager {
    private(set) var powerSource: PowerSource = .unknown
    private(set) var isLowPowerMode: Bool = false
    private(set) var currentPolicy: PowerPolicy = .fullQuality
    private(set) var isScreenAsleep: Bool = false
    private(set) var isScreensaverActive: Bool = false

    /// Called when the screen/system wakes up — use this to resume playback.
    var onWake: (() -> Void)?
    /// Called when the screen/system goes to sleep — use this to pause playback.
    var onSleep: (() -> Void)?

    @ObservationIgnored
    private let observerBag = NotificationObserverBag()

    init() {
        updatePowerSource()
        registerNotifications()
    }

    func evaluatePolicy(settings: SettingsStore) -> PowerPolicy {
        if isScreenAsleep || isScreensaverActive {
            currentPolicy = .paused
            return .paused
        }

        switch powerSource {
        case .battery(let level):
            if level < 10 || isLowPowerMode {
                currentPolicy = .paused
            } else if level < 20 || settings.batteryOptimizationMode == .aggressive {
                currentPolicy = .lowPower
            } else if settings.batteryOptimizationMode == .balanced {
                currentPolicy = .balanced
            } else {
                currentPolicy = .fullQuality
            }
        case .ac:
            currentPolicy = .fullQuality
        case .unknown:
            currentPolicy = .balanced
        }

        return currentPolicy
    }

    private func updatePowerSource() {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as [CFTypeRef]

        guard let source = sources.first,
              let description = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any] else {
            powerSource = .unknown
            return
        }

        let isCharging = description[kIOPSPowerSourceStateKey as String] as? String == kIOPSACPowerValue as String
        if isCharging {
            powerSource = .ac
        } else {
            let level = description[kIOPSCurrentCapacityKey as String] as? Int ?? 100
            powerSource = .battery(level: level)
        }
    }

    private func registerNotifications() {
        let nc = NSWorkspace.shared.notificationCenter
        let dnc = DistributedNotificationCenter.default()

        // Screen sleep
        observerBag.observers.append(nc.addObserver(
            forName: NSWorkspace.screensDidSleepNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isScreenAsleep = true
                self?.onSleep?()
            }
        })

        // Screen wake — wait briefly for displays to come fully online before resuming
        observerBag.observers.append(nc.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isScreenAsleep = false
                self?.updatePowerSource()
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s
                self?.onWake?()
            }
        })

        // System sleep (lid close / full hibernation)
        observerBag.observers.append(nc.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isScreenAsleep = true
                self?.onSleep?()
            }
        })

        // System wake
        observerBag.observers.append(nc.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isScreenAsleep = false
                self?.updatePowerSource()
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2s — give displays time
                self?.onWake?()
            }
        })

        // Screensaver start
        observerBag.observers.append(dnc.addObserver(
            forName: NSNotification.Name("com.apple.screensaver.didstart"),
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.isScreensaverActive = true }
        })

        // Screensaver stop
        observerBag.observers.append(dnc.addObserver(
            forName: NSNotification.Name("com.apple.screensaver.didstop"),
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isScreensaverActive = false
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                self?.onWake?()
            }
        })

        let powerNC = NotificationCenter.default
        observerBag.observers.append(powerNC.addObserver(
            forName: NSNotification.Name("NSProcessInfoPowerStateDidChange"),
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
                self?.updatePowerSource()
            }
        })

        isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
    }
}
