import SwiftUI

struct MacRemoteView: View {
    @ObservedObject var vm: RemoteViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var showConnection = false
    @State private var showPlayback = false

    private var isUITesting: Bool { ProcessInfo.processInfo.arguments.contains("--ui-testing") }

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Button { showConnection = true } label: {
                    HStack(spacing: 7) {
                        Text("Sony BRAVIA").font(.system(size: 19, weight: .semibold))
                        Image(systemName: "chevron.down").font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Connection settings")
                Spacer()
                RemoteKey(icon: "power", label: "Power", size: 38, tint: powerColor) { await vm.togglePower() }
            }
            DPadView(size: 240) { await vm.sendCommand($0) }
            RemoteGlassGroup {
                HStack(alignment: .top, spacing: 28) {
                    VStack(spacing: 12) {
                        RemoteKey(icon: "chevron.left", label: "Back", size: 58) { await vm.sendCommand(.back) }
                        RemoteKey(icon: "playpause.fill", label: "Playback", size: 58) { showPlayback = true }
                            .popover(isPresented: $showPlayback) {
                                HStack(spacing: 16) {
                                    Button("Play", systemImage: "play.fill") {
                                        showPlayback = false
                                        Task { await vm.sendCommand(.play) }
                                    }
                                    Button("Pause", systemImage: "pause.fill") {
                                        showPlayback = false
                                        Task { await vm.sendCommand(.pause) }
                                    }
                                }.padding(16)
                            }
                        RemoteKey(icon: vm.isMuted ? "speaker.slash.fill" : "speaker.wave.2", label: "Mute",
                                  size: 58, tint: vm.isMuted ? .orange : .white) { await vm.toggleMute() }
                    }
                    VStack(spacing: 12) {
                        RemoteKey(icon: "tv", label: "Home", size: 58) { await vm.sendCommand(.home) }
                        VStack(spacing: 0) {
                            HoldRemoteKey(icon: "plus", label: "Volume up", size: 64, showsBackground: false, fontSize: 23) { await vm.volumeUp() }
                            Rectangle().fill(.white.opacity(0.1)).frame(width: 24, height: 1)
                            HoldRemoteKey(icon: "minus", label: "Volume down", size: 64, showsBackground: false, fontSize: 23) { await vm.volumeDown() }
                        }.remoteGlass(in: Capsule())
                    }
                }
            }
            if let message = vm.errorMessage {
                Text(message).font(.caption).foregroundStyle(.orange).fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 30).padding(.top, 28).padding(.bottom, 26)
        .frame(width: 340)
        .background(Color.black)
        .focusable().focusEffectDisabled()
        .onKeyPress(.upArrow) { send(.up) }
        .onKeyPress(.downArrow) { send(.down) }
        .onKeyPress(.leftArrow) { send(.left) }
        .onKeyPress(.rightArrow) { send(.right) }
        .onKeyPress(.return) { send(.confirm) }
        .onKeyPress(.escape) { send(.back) }
        .sheet(isPresented: $showConnection, onDismiss: {
            vm.pairingRequired = false
            if !isUITesting { Task { await vm.loadSettings(); await vm.refreshStatus() } }
        }) {
            MacConnectionView().environmentObject(vm).preferredColorScheme(.dark)
        }
        .onChange(of: vm.pairingRequired) { _, needed in if needed { showConnection = true } }
        .task {
            guard !isUITesting else { return }
            await vm.loadSettings()
            vm.startPolling()
            await vm.checkAuthorization()
        }
        .onDisappear { vm.stopPolling() }
        .onChange(of: scenePhase) { _, phase in
            guard !isUITesting else { return }
            if phase == .active { vm.startPolling() } else { vm.stopPolling() }
        }
    }

    private func send(_ command: IRCCCommand) -> KeyPress.Result {
        guard !showConnection else { return .ignored }
        Task { await vm.sendCommand(command) }
        return .handled
    }

    private var powerColor: Color {
        switch vm.connectionState {
        case .connected: .green
        case .standby: .orange
        case .connecting: .white
        case .disconnected: .gray
        }
    }
}
