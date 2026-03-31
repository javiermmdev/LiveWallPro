import Foundation

/// Lightweight performance monitoring for debugging and validation.
/// Not used in release builds' hot paths — only for diagnostics.
actor PerformanceMonitor {
    struct Snapshot: Sendable {
        let timestamp: Date
        let cpuUsage: Double
        let memoryUsageMB: Double
        let activeDisplayCount: Int
    }

    private var snapshots: [Snapshot] = []
    private let maxSnapshots = 60

    func recordSnapshot(activeDisplayCount: Int) {
        let snapshot = Snapshot(
            timestamp: Date(),
            cpuUsage: currentCPUUsage(),
            memoryUsageMB: currentMemoryMB(),
            activeDisplayCount: activeDisplayCount
        )

        snapshots.append(snapshot)
        if snapshots.count > maxSnapshots {
            snapshots.removeFirst(snapshots.count - maxSnapshots)
        }
    }

    func latestSnapshot() -> Snapshot? {
        snapshots.last
    }

    func averageCPU() -> Double {
        guard !snapshots.isEmpty else { return 0 }
        return snapshots.map(\.cpuUsage).reduce(0, +) / Double(snapshots.count)
    }

    func averageMemory() -> Double {
        guard !snapshots.isEmpty else { return 0 }
        return snapshots.map(\.memoryUsageMB).reduce(0, +) / Double(snapshots.count)
    }

    private func currentCPUUsage() -> Double {
        var threadList: thread_act_array_t?
        var threadCount: mach_msg_type_number_t = 0

        let result = task_threads(mach_task_self_, &threadList, &threadCount)
        guard result == KERN_SUCCESS, let threads = threadList else { return 0 }

        var totalUsage: Double = 0

        for i in 0..<Int(threadCount) {
            var info = thread_basic_info()
            var infoCount = mach_msg_type_number_t(MemoryLayout<thread_basic_info>.size / MemoryLayout<integer_t>.size)

            let kr = withUnsafeMutablePointer(to: &info) { infoPtr in
                infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(infoCount)) { ptr in
                    thread_info(threads[i], thread_flavor_t(THREAD_BASIC_INFO), ptr, &infoCount)
                }
            }

            if kr == KERN_SUCCESS && info.flags & TH_FLAGS_IDLE == 0 {
                totalUsage += Double(info.cpu_usage) / Double(TH_USAGE_SCALE) * 100
            }
        }

        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threads), vm_size_t(threadCount) * vm_size_t(MemoryLayout<thread_act_t>.size))

        return totalUsage
    }

    private func currentMemoryMB() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size)

        let kr = withUnsafeMutablePointer(to: &info) { infoPtr in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { ptr in
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), ptr, &count)
            }
        }

        guard kr == KERN_SUCCESS else { return 0 }
        return Double(info.resident_size) / (1024 * 1024)
    }
}
