import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: RemoteViewModel
    @AppStorage("tv_name") private var tvName = "Sony BRAVIA"
    @AppStorage("tv_ip") private var tvIP = ""
    @AppStorage("tv_psk") private var tvPSK = ""
    @State private var testing = false
    @State private var result: String?
    @State private var succeeded = false

    var body: some View {
        Form {
            Section {
                TextField("電視名稱", text: $tvName)
                    .accessibilityLabel("電視名稱")
                HStack {
                    Text("IP 位址")
                    TextField("192.168.1.100", text: $tvIP)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityLabel("電視 IP 位址")
                        .accessibilityIdentifier("tv-ip")
                }
                HStack {
                    Text("連線金鑰")
                    SecureField("PSK（依機型填寫）", text: $tvPSK)
                        .multilineTextAlignment(.trailing)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityLabel("電視連線金鑰")
                        .accessibilityIdentifier("tv-psk")
                }
            } header: {
                Text("我的電視")
            } footer: {
                Text("iPhone 與電視需連接同一個區域網路。設定會自動儲存。")
            }

            Section {
                Button {
                    Task { await testConnection(sendHome: false) }
                } label: {
                    HStack {
                        Text("測試連線")
                        Spacer()
                        if testing { ProgressView() }
                        else { Image(systemName: "wifi") }
                    }
                }
                .disabled(tvIP.trimmingCharacters(in: .whitespaces).isEmpty || testing)
                if let result {
                    Label(result, systemImage: succeeded ? "checkmark.circle" : "exclamationmark.circle")
                        .font(.footnote)
                        .foregroundStyle(succeeded ? Color.green : Color.orange)
                        .textSelection(.enabled)
                }
            }

            Section("如何連接") {
                guide("1", "查看電視 IP", "在電視的網路設定中，找到目前的 IP 位址。")
                guide("2", "啟用遠端控制", "在家用網路或 IP 控制設定中允許遠端裝置控制。選單名稱依型號而異。")
                guide("3", "設定連線金鑰", "若電視提供預先共用金鑰（PSK），請在這裡填入相同金鑰。部分機型使用其他認證方式，需另外適配。")
            }

            Section {
                Button("測試首頁按鍵", systemImage: "tv") {
                    Task { await testConnection(sendHome: true) }
                }
                .disabled(tvIP.trimmingCharacters(in: .whitespaces).isEmpty || testing)
            } footer: {
                Text("會傳送一次首頁指令，讓你確認電視是否有反應。待機喚醒能力依電視型號與遠端啟動設定而異。")
            }
        }
        .scrollContentBackground(.hidden)
        .background(RemoteTheme.background)
        .navigationTitle("連線設定")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func testConnection(sendHome: Bool) async {
        testing = true
        result = nil
        defer { testing = false }
        await vm.loadSettings()
        do {
            if sendHome {
                await SonyTVService.shared.syncRemoteCodes()
                try await SonyTVService.shared.sendIRCC(.home)
                result = "首頁指令已傳送，請確認電視是否有反應。"
            } else {
                let on = try await SonyTVService.shared.getPowerStatus()
                result = on ? "已連接電視，可以開始使用。" : "已連接，電視目前在待機中。"
            }
            succeeded = true
            await vm.refreshStatus()
        } catch {
            succeeded = false
            result = error.localizedDescription
        }
    }

    private func guide(_ number: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.footnote.weight(.medium))
                .frame(width: 24, height: 24)
                .background(RemoteTheme.surface, in: Circle())
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.subheadline.weight(.medium))
                Text(detail).font(.footnote).foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}
