import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: RemoteViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("tv_ip") private var tvIP = TVConnectionSettings.defaultIP
    @AppStorage("tv_psk") private var tvPSK = ""
    @State private var connecting = false
    @State private var errorMessage: String?
    @FocusState private var editingAddress: Bool

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("電視 IP")
                    TextField(TVConnectionSettings.defaultIP, text: $tvIP)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($editingAddress)
                        .accessibilityLabel("電視 IP 位址")
                        .accessibilityIdentifier("tv-ip")
                }
                Button {
                    editingAddress = false
                    Task { await connect() }
                } label: {
                    HStack {
                        Text(connecting ? "連接中…" : "連接")
                        Spacer()
                        if connecting { ProgressView() }
                        else { Image(systemName: "arrow.right") }
                    }
                }
                .disabled(tvIP.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || connecting)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage).font(.footnote).foregroundStyle(.orange)
                }
            }

            Section {
                DisclosureGroup("進階設定") {
                    SecureField("連線金鑰（PSK）", text: $tvPSK)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityLabel("電視連線金鑰")
                        .accessibilityIdentifier("tv-psk")
                }
            }
        }
        .safeAreaPadding(.top, 16)
        .scrollContentBackground(.hidden)
        .background(RemoteTheme.background)
        .navigationTitle("連線設定")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func connect() async {
        connecting = true
        errorMessage = nil
        defer { connecting = false }
        tvIP = tvIP.trimmingCharacters(in: .whitespacesAndNewlines)
        await vm.loadSettings()
        do {
            _ = try await SonyTVService.shared.getPowerStatus()
            await SonyTVService.shared.syncRemoteCodes()
            await vm.refreshStatus()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
