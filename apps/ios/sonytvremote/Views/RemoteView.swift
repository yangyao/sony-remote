import SwiftUI

struct RemoteView: View {
    @EnvironmentObject var vm: RemoteViewModel
    @AppStorage("tv_name") private var tvName = "Sony BRAVIA"
    @AppStorage("tv_ip") private var tvIP = ""
    @State private var sheet: RemoteSheet?

    private enum RemoteSheet: String, Identifiable {
        case settings, apps, inputs, more
        var id: String { rawValue }
    }

    var body: some View {
        GeometryReader { geometry in
            let keySize = min(76.0, max(56, geometry.size.height * 0.095))
            let padSize = min(300.0, geometry.size.width - 64, max(200, geometry.size.height - 3 * keySize - 236))
            ScrollView {
                VStack(spacing: 0) {
                    header
                    Spacer(minLength: 16)
                    DPadView(size: padSize) { await vm.sendCommand($0) }
                    controls(keySize: keySize)
                        .padding(.top, 28)
                    Spacer(minLength: 16)
                    footer
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
        .sheet(item: $sheet, onDismiss: {
            Task { await vm.loadSettings(); await vm.refreshStatus() }
        }) { destination in
            NavigationStack {
                Group {
                    switch destination {
                    case .settings: SettingsView()
                    case .apps: AppsView()
                    case .inputs: InputsView()
                    case .more: moreControls
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack {
                    Text(sheetTitle(destination)).font(.headline)
                    Spacer()
                    Button("完成") { sheet = nil }
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
            .presentationDragIndicator(.visible)
        }
    }

    private func sheetTitle(_ destination: RemoteSheet) -> String {
        switch destination {
        case .settings: return "連線設定"
        case .apps: return "應用程式"
        case .inputs: return "輸入源"
        case .more: return "更多控制"
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button { sheet = .settings } label: {
                VStack(alignment: .leading, spacing: 7) {
                    Text("SONY REMOTE")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2.3)
                        .foregroundStyle(RemoteTheme.secondary)
                    HStack(spacing: 7) {
                        Text(tvName.isEmpty ? "Sony BRAVIA" : tvName)
                            .font(.system(size: 21, weight: .semibold))
                            .lineLimit(1).minimumScaleFactor(0.7)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(RemoteTheme.secondary)
                    }
                    HStack(spacing: 5) {
                        Circle().fill(statusColor).frame(width: 5, height: 5)
                        Text(tvIP.isEmpty ? "點此連接電視" : vm.connectionLabel)
                            .font(.system(size: 11))
                            .foregroundStyle(RemoteTheme.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("電視連線設定")
            RemoteKey(icon: "power", label: "電源", size: 46,
                      tint: Color(red: 0.91, green: 0.43, blue: 0.40)) {
                await vm.togglePower()
            }
        }
    }

    private var statusColor: Color {
        if tvIP.isEmpty { return RemoteTheme.secondary }
        switch vm.connectionState {
        case .connected: return .green
        case .standby: return .orange
        case .connecting: return .yellow
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
                        .background(RemoteTheme.surface, in: Circle())
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
                .background(RemoteTheme.surface, in: Capsule())
                .accessibilityElement(children: .contain)
                .accessibilityLabel("電視音量")
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 0) {
            footerButton("square.grid.2x2", "應用程式", .apps)
            Spacer()
            footerButton("rectangle.on.rectangle", "輸入源", .inputs)
            Spacer()
            footerButton("ellipsis", "更多", .more)
        }
        .padding(.horizontal, 6)
    }

    private func footerButton(_ icon: String, _ label: String, _ destination: RemoteSheet) -> some View {
        Button { sheet = destination } label: {
            Label(label, systemImage: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(RemoteTheme.secondary)
                .frame(minHeight: 44)
        }
        .accessibilityIdentifier(label)
    }

    private var moreControls: some View {
        List {
            Section("電視") {
                commandRow("選單", "line.3.horizontal", .options)
                commandRow("節目資訊", "info.circle", .info)
                commandRow("切換輸入源", "rectangle.on.rectangle", .input)
                commandRow("頻道 +", "chevron.up", .channelUp)
                commandRow("頻道 −", "chevron.down", .channelDown)
            }
            Section("播放") {
                commandRow("倒轉", "backward.fill", .rewind)
                commandRow("快轉", "forward.fill", .fastForward)
                commandRow("停止", "stop.fill", .stop)
                commandRow("字幕", "captions.bubble", .subtitle)
            }
            Section("數字鍵") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(1...9, id: \.self) { number in numberKey(number) }
                    Color.clear.frame(height: 44)
                    numberKey(0)
                }
                .padding(.vertical, 8)
            }
            Section { Button("連線設定", systemImage: "gearshape") { sheet = .settings } }
        }
        .navigationTitle("更多控制")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func commandRow(_ title: String, _ icon: String, _ command: IRCCCommand) -> some View {
        Button(title, systemImage: icon) { Task { await vm.sendCommand(command) } }
    }

    private func numberKey(_ number: Int) -> some View {
        Button {
            let commands: [IRCCCommand] = [.num0, .num1, .num2, .num3, .num4, .num5, .num6, .num7, .num8, .num9]
            Task { await vm.sendCommand(commands[number]) }
        } label: {
            Text(String(number)).font(.title2).frame(maxWidth: .infinity, minHeight: 48)
                .background(RemoteTheme.surface, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview { RemoteView().environmentObject(RemoteViewModel()) }
