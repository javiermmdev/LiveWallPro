import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: MenuBarViewModel?

    private var vm: MenuBarViewModel {
        if let viewModel { return viewModel }
        let created = appState.makeMenuBarViewModel()
        Task { @MainActor in self.viewModel = created }
        return created
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: vm.isEngineRunning ? "circle.fill" : "circle")
                    .foregroundStyle(vm.isEngineRunning ? .green : .gray)
                    .font(.caption2)
                Text(vm.isEngineRunning ? L10n.wallpaperActive : L10n.wallpaperPaused)
            }

            Divider()

            ForEach(vm.displays) { display in
                if let title = vm.wallpaperTitle(for: display) {
                    HStack {
                        Image(systemName: display.isBuiltIn ? "laptopcomputer" : "display")
                            .font(.caption)
                        Text("\(display.name): \(title)")
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
            }

            Divider()

            if vm.isEngineRunning {
                Button(L10n.pauseAll) { vm.pauseAll() }
                Button(L10n.resumeAll) { vm.resumeAll() }
            } else {
                Button(L10n.startEngine) { vm.startEngine() }
            }

            Divider()

            Button(L10n.openApp) { vm.openMainWindow() }
            SettingsLink { Text(L10n.settings) }

            Divider()

            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.resourceUsage)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Label(vm.cpuText, systemImage: "cpu")
                    Label(vm.memoryText, systemImage: "memorychip")
                }
                .font(.caption)

                HStack(spacing: 12) {
                    Label(vm.batteryText, systemImage: vm.batteryIcon)
                    Text(vm.powerStatusText)
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }

            Divider()

            Button(L10n.quitApp) { vm.stopAndQuit() }
                .keyboardShortcut("q")
        }
    }
}
