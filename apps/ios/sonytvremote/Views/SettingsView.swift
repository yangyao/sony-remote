import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: RemoteViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("tv_ip") private var tvIP = ""
    @AppStorage("tv_psk") private var tvPSK = ""
    @State private var connecting = false
    @State private var message: String?
    @State private var failed = false
    @State private var pin = ""
    @State private var step: Step = .connect
    @FocusState private var editingAddress: Bool
    @FocusState private var editingPIN: Bool

    private enum Step { case connect, turnOnTV, enterPIN }

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("TV IP")
                    TextField(TVConnectionSettings.exampleIP, text: $tvIP)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($editingAddress)
                        .accessibilityLabel("TV IP address")
                        .accessibilityIdentifier("tv-ip")
                }
                if step == .enterPIN {
                    SecureField("TV pairing code", text: $pin)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .focused($editingPIN)
                        .accessibilityLabel("TV pairing code")
                        .accessibilityIdentifier("tv-pin")
                        .onChange(of: pin) { _, value in
                            pin = String(value.filter { $0.isASCII && $0.isNumber }.prefix(4))
                        }
                }
                Button {
                    editingAddress = false
                    editingPIN = false
                    Task { await connect() }
                } label: {
                    HStack {
                        Text(connecting ? "Connecting…" : (step == .connect ? "Connect" : "Pair TV"))
                        Spacer()
                        if connecting { ProgressView() }
                        else { Image(systemName: "arrow.right") }
                    }
                }
                .disabled(tvIP.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || connecting ||
                          (step == .enterPIN && pin.count != 4))
                if step == .enterPIN {
                    Button("Show code again") {
                        pin = ""
                        step = .connect
                        editingPIN = false
                        Task { await connect() }
                    }
                    .disabled(connecting)
                }
            }

            if let message {
                Section {
                    Text(message).font(.footnote).foregroundStyle(failed ? Color.orange : .secondary)
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
        .onChange(of: tvIP) { _, _ in resetPairing() }
        .onChange(of: tvPSK) { _, _ in resetPairing() }
        .task {
            if vm.pairingRequired { await connect() }
        }
    }

    private func resetPairing() {
        step = .connect
        pin = ""
        message = nil
    }

    private func connect() async {
        connecting = true
        message = nil
        failed = false
        defer { connecting = false }
        let address = tvIP.trimmingCharacters(in: .whitespacesAndNewlines)
        if address != tvIP {
            tvIP = address
            step = .connect
        }
        await vm.loadSettings()
        let service = SonyTVService.shared
        do {
            if step == .enterPIN {
                _ = try await service.requestPairing(pin: pin)
                try await service.verifyControlAuthorization()
                await finishConnection()
                return
            }
            do {
                try await service.verifyControlAuthorization()
                await finishConnection()
                return
            } catch let error as TVError where error.requiresAuthorization && tvPSK.isEmpty {
                // Access to the public power status does not imply control authorization.
                vm.pairingRequired = true
            }
            step = .turnOnTV
            guard try await service.getPowerStatus() else {
                message = "Turn on the TV with your remote, then tap Pair TV."
                return
            }
            switch try await service.requestPairing() {
            case .pinRequired:
                step = .enterPIN
                message = "Enter the 4-digit code shown on your TV. You only need to pair once."
                editingPIN = true
            case .paired:
                try await service.verifyControlAuthorization()
                await finishConnection()
            }
        } catch {
            failed = true
            if let error = error as? TVError {
                if error.requiresAuthorization && !tvPSK.isEmpty {
                    message = "Incorrect pre-shared key. Check Advanced settings."
                } else { message = error.localizedDescription }
            } else {
                message = "Unable to connect. Check the IP address and TV network settings."
            }
        }
    }

    private func finishConnection() async {
        await SonyTVService.shared.syncRemoteCodes()
        await vm.refreshStatus()
        vm.pairingRequired = false
        pin = ""
        dismiss()
    }
}
