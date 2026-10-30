import SwiftUI

struct RemoteView: View {
    @EnvironmentObject var vm: RemoteViewModel
    @AppStorage("tv_name") private var tvName = "Sony BRAVIA"
    @State private var showSettings = false
    @State private var settingsDetent: PresentationDetent = .height(320)

    var body: some View {
        GeometryReader { geometry in
            let keySize = min(76.0, max(56, geometry.size.height * 0.095))
            let padSize = min(300.0, geometry.size.width - 64, max(200, geometry.size.height - 3 * keySize - 236))
            ScrollView {
                VStack(spacing: 0) {
                    header
                    Spacer(minLength: 16)
                    DPadView(size: padSize) { await vm.sendCommand($0) }
                    RemoteGlassGroup { controls(keySize: keySize) }
                        .padding(.top, 28)
                    Spacer(minLength: 16)
                }
                .frame(maxWidth: 380)
                .padding(.horizontal, 28)
                .padding(.top, 16)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity)
                .frame(minHeight: geometry.size.height)
            }
            .scrollIndicators(.hidden)
        }
        .background(RemoteTheme.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let message = vm.errorMessage {
                HStack(spacing: 12) {
                    Image(systemName: "wifi.exclamationmark")
                    Text(message).font(.footnote).frame(maxWidth: .infinity, alignment: .leading)
                    Button { vm.errorMessage = nil } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("關閉提示")
                }
                .padding(16)
                .background(RemoteTheme.surface, in: RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
        }
        .onChange(of: vm.pairingRequired) { _, needed in
            if needed {
                settingsDetent = .large
                showSettings = true
            }
        }
        .sheet(isPresented: $showSettings, onDismiss: {
            vm.pairingRequired = false
            settingsDetent = .height(320)
            Task { await vm.loadSettings(); await vm.refreshStatus() }
        }) {
            NavigationStack {
                SettingsView()
                    .toolbar(.hidden, for: .navigationBar)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack {
                    Text("Connection").font(.headline)
                    Spacer()
                    Button("Done") { showSettings = false }
                        .font(.body.weight(.semibold))
                        .frame(minWidth: 44, minHeight: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .background(RemoteTheme.background)
            }
            .environmentObject(vm)
            .preferredColorScheme(.dark)
            .tint(.white)
            .presentationDetents([.height(320), .large], selection: $settingsDetent)
            .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button { showSettings = true } label: {
                HStack(spacing: 7) {
                    Text(tvName.isEmpty ? "Sony BRAVIA" : tvName)
                        .font(.system(size: 21, weight: .semibold))
                        .lineLimit(1).minimumScaleFactor(0.7)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(RemoteTheme.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("電視連線設定")

            Button {
                RemoteTheme.feedback()
                Task { await vm.togglePower() }
            } label: {
                ZStack {
                    if vm.connectionState == .connecting {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "power")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(powerColor)
                    }
                }
                .frame(width: 46, height: 46)
                .remoteGlass(in: Circle())
                .contentShape(Circle())
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("電源")
            .accessibilityIdentifier("電源")
            .accessibilityValue(vm.connectionLabel)
            .accessibilityHint("開機為綠色，待機為橙色，未連線為灰色")
        }
    }

    private var powerColor: Color {
        switch vm.connectionState {
        case .connected: return .green
        case .standby: return .orange
        case .connecting: return .white
        case .disconnected: return RemoteTheme.secondary
        }
    }

    private func controls(keySize: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 30) {
            VStack(spacing: 16) {
                RemoteKey(icon: "chevron.left", label: "返回", size: keySize) { await vm.sendCommand(.back) }
                Menu {
                    Button("播放", systemImage: "play.fill") { Task { await vm.sendCommand(.play) } }
                    Button("暫停", systemImage: "pause.fill") { Task { await vm.sendCommand(.pause) } }
                } label: {
                    Image(systemName: "playpause.fill")
                        .font(.system(size: 27, weight: .medium))
                        .frame(width: keySize, height: keySize)
                        .remoteGlass(in: Circle())
                }
                .accessibilityLabel("播放控制")
                RemoteKey(icon: vm.isMuted ? "speaker.slash.fill" : "speaker.wave.2",
                          label: "靜音", size: keySize, tint: vm.isMuted ? .orange : .white) {
                    await vm.toggleMute()
                }
            }
            VStack(spacing: 16) {
                RemoteKey(icon: "tv", label: "首頁", size: keySize) { await vm.sendCommand(.home) }
                VStack(spacing: 0) {
                    HoldRemoteKey(icon: "plus", label: "提高電視音量", size: keySize + 8, showsBackground: false) {
                        await vm.volumeUp()
                    }
                    Rectangle().fill(.white.opacity(0.10)).frame(width: 28, height: 1)
                    HoldRemoteKey(icon: "minus", label: "降低電視音量", size: keySize + 8, showsBackground: false) {
                        await vm.volumeDown()
                    }
                }
                .remoteGlass(in: Capsule())
                .accessibilityElement(children: .contain)
                .accessibilityLabel("電視音量")
            }
        }
    }

}

#Preview { RemoteView().environmentObject(RemoteViewModel()) }
