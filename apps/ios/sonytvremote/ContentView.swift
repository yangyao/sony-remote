import SwiftUI

struct ContentView: View {
    @StateObject private var vm = RemoteViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        RemoteView()
            .environmentObject(vm)
            .foregroundStyle(.primary)
            .tint(.primary)
            .task {
                guard !ProcessInfo.processInfo.arguments.contains("--ui-testing") else { return }
                await vm.loadSettings()
                vm.startPolling()
                await vm.checkAuthorization()
            }
            .onChange(of: scenePhase) { _, phase in
                guard !ProcessInfo.processInfo.arguments.contains("--ui-testing") else { return }
                if phase == .active { vm.startPolling() }
                else { vm.stopPolling() }
            }
    }
}

#Preview { ContentView() }
