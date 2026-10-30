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
                    Text("TV IP")
                    TextField(TVConnectionSettings.defaultIP, text: $tvIP)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($editingAddress)
                        .accessibilityLabel("TV IP address")
                        .accessibilityIdentifier("tv-ip")
                }
                Button {
                    editingAddress = false
                    Task { await connect() }
                } label: {
                    HStack {
                        Text(connecting ? "Connecting…" : "Connect")
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
                DisclosureGroup("Advanced") {
                    SecureField("Pre-shared key (PSK)", text: $tvPSK)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityLabel("TV pre-shared key")
                        .accessibilityIdentifier("tv-psk")
                }
            }
        }
        .safeAreaPadding(.top, 16)
        .scrollContentBackground(.hidden)
        .background(RemoteTheme.background)
        .navigationTitle("Connection")
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
            switch error {
            case TVError.notConfigured:
                errorMessage = "Enter your TV IP address."
            case TVError.httpError(401, _):
                errorMessage = "Incorrect pre-shared key. Check Advanced settings."
            case TVError.httpError(403, _):
                errorMessage = "Remote control is not allowed by the TV."
            default:
                errorMessage = "Unable to connect. Check the IP address and TV network settings."
            }
        }
    }
}
