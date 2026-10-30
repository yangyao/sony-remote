import SwiftUI

struct ContentView: View {
    @StateObject private var vm = RemoteViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        RemoteView()
            .environmentObject(vm)
            .preferredColorScheme(.dark)
            .tint(.white)
            .task {
                await vm.loadSettings()
                vm.startPolling()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { vm.startPolling() }
                else { vm.stopPolling() }
            }
    }
}

#Preview { ContentView() }
