import Foundation
import IOKit.ps

/// Polls CPU, RAM and battery usage for this process every 3 seconds.
/// Uses Mach kernel APIs for CPU/memory and IOKit for battery.
@Observable
@MainActor
final class ResourceMonitor {

    // MARK: - Published State

    private(set) var cpuUsage: Double = 0    // percentage, 0–100+
    private(set) var memoryMB: Double = 0    // resident memory in MB
    private(set) var batteryLevel: Int = -1  // 0–100, or -1 if not available
    private(set) var isOnBattery: Bool = false

    private var timer: Timer?

    // MARK: - Lifecycle

    func startMonitoring() {
        update()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.update() }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func update() {
        cpuUsage = Self.appCPUUsage()
        memoryMB = Self.appMemoryMB()
        (batteryLevel, isOnBattery) = Self.batteryInfo()
    }

    // MARK: - CPU

    /// Sums cpu_usage across all threads via Mach thread_info().
    private static func appCPUUsage() -> Double {
        var threadList: thread_act_array_t?
        var threadCount: mach_msg_type_number_t = 0

        let result = task_threads(mach_task_self_, &threadList, &threadCount)
        guard result == KERN_SUCCESS, let threads = threadList else { return 0 }

        var totalUsage: Double = 0
        for i in 0..<Int(threadCount) {
            var info = thread_basic_info_data_t()
            var infoCount = mach_msg_type_number_t(
                MemoryLayout<thread_basic_info_data_t>.size / MemoryLayout<natural_t>.size
            )
            let kr = withUnsafeMutablePointer(to: &info) { ptr in
                ptr.withMemoryRebound(to: integer_t.self, capacity: Int(infoCount)) { intPtr in
                    thread_info(threads[i], thread_flavor_t(THREAD_BASIC_INFO), intPtr, &infoCount)
                }
            }
            if kr == KERN_SUCCESS && (info.flags & TH_FLAGS_IDLE) == 0 {
                totalUsage += Double(info.cpu_usage) / Double(TH_USAGE_SCALE) * 100
            }
        }

        let size = vm_size_t(MemoryLayout<thread_t>.size) * vm_size_t(threadCount)
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threads), size)

        return totalUsage
    }

    // MARK: - Memory

    /// Returns resident memory in MB via mach_task_basic_info.
    private static func appMemoryMB() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size
        )
        let result = withUnsafeMutablePointer(to: &info) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), intPtr, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        return Double(info.resident_size) / (1024 * 1024)
    }

    // MARK: - Battery

    /// Returns battery percentage and whether the Mac is running on battery power.
    private static func batteryInfo() -> (level: Int, onBattery: Bool) {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as [CFTypeRef]

        guard let source = sources.first,
              let desc = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any]
        else { return (-1, false) }

        let isAC = desc[kIOPSPowerSourceStateKey as String] as? String == kIOPSACPowerValue as String
        let level = desc[kIOPSCurrentCapacityKey as String] as? Int ?? -1
        return (level, !isAC)
    }
}
