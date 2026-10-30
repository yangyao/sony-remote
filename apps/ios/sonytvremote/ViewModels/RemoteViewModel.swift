import Foundation
import Combine
import OSLog

@MainActor
class RemoteViewModel: ObservableObject {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app", category: "RemoteViewModel")
    enum ConnectionState { case connecting, connected, standby, disconnected }
    @Published var connectionState: ConnectionState = .disconnected
    var connectionLabel: String {
        switch connectionState {
        case .connecting: return "連線中…"
        case .connected: return "已連線"
        case .standby: return "待機中"
        case .disconnected: return "未連線"
        }
    }
    private var refreshing = false
    private var commandGeneration = 0
    private var commandTask: Task<Void, Never>?
    private var errorTask: Task<Void, Never>?
    @Published var pairingRequired = false
    @Published var isMuted: Bool = false
    @Published var errorMessage: String?

    private let service = SonyTVService.shared
    private var statusTimer: Timer?

    // MARK: - Configuration

    func loadSettings() async {
        logger.info("Loading settings from UserDefaults")
        let defaults = UserDefaults.standard
        let ip = defaults.string(forKey: "tv_ip") ?? ""
        let psk = defaults.string(forKey: "tv_psk") ?? ""
        await service.configure(ip: ip, psk: psk)
    }

    func checkAuthorization() async {
        do {
            try await service.verifyControlAuthorization()
        } catch let error as TVError where error.requiresAuthorization {
            pairingRequired = true
        } catch {
            // Let normal connection status report reachability; don't prompt pairing for network errors.
        }
    }

    func startPolling() {
        logger.info("Starting status polling")
        statusTimer?.invalidate()
        statusTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshStatus()
            }
        }
        Task {
            guard !(UserDefaults.standard.string(forKey: "tv_ip") ?? "").isEmpty else { return }
            await service.syncRemoteCodes()
            await refreshStatus()
        }
    }

    func stopPolling() {
        logger.info("Stopping status polling")
        statusTimer?.invalidate()
        statusTimer = nil
    }

    // MARK: - Status

    func refreshStatus() async {
        guard !refreshing else { return }
        guard !(UserDefaults.standard.string(forKey: "tv_ip") ?? "").isEmpty else {
            connectionState = .disconnected
            return
        }
        refreshing = true
        defer { refreshing = false }
        if connectionState == .disconnected { connectionState = .connecting }
        logger.debug("Refreshing TV status")
        do {
            let isOn = try await service.getPowerStatus()
            connectionState = isOn ? .connected : .standby
            if isOn, let muted = try? await service.getMuteStatus() {
                isMuted = muted
            }
        } catch {
            logger.error("Failed to refresh status: \(error.localizedDescription, privacy: .public)")
            connectionState = .disconnected
            // A network failure is not evidence that the TV is in standby.
        }
    }

    // MARK: - Power

    func togglePower() async {
        logger.info("Toggle power button pressed")
        await sendCommand(.power)
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await refreshStatus()
    }

    // MARK: - IRCC Commands

    func sendCommand(_ command: IRCCCommand) async {
        let previous = commandTask
        let generation = commandGeneration
        let next = Task { @MainActor in
            await previous?.value
            guard !Task.isCancelled, generation == commandGeneration else { return }
            do {
                try await service.sendIRCC(command)
            } catch {
                commandGeneration += 1 // Drop queued gestures after a failed request.
                showError(error)
            }
        }
        commandTask = next
        await next.value
    }

    // MARK: - Volume

    func volumeUp() async {
        logger.info("Volume UP pressed")
        await sendCommand(.volumeUp)
    }

    func volumeDown() async {
        logger.info("Volume DOWN pressed")
        await sendCommand(.volumeDown)
    }

    func toggleMute() async {
        // IRCC toggle remains usable on models that cannot report volume state.
        do {
            try await service.sendIRCC(.mute)
            isMuted.toggle()
            await refreshStatus()
        } catch { showError(error) }
    }

    // MARK: - Error

    private func showError(_ error: Error) {
        if let tvError = error as? TVError, tvError.requiresAuthorization {
            errorTask?.cancel()
            errorMessage = nil
            pairingRequired = true
            return
        }
        logger.error("Showing error to user: \(error.localizedDescription, privacy: .public)")
        errorTask?.cancel()
        if case TVError.notConfigured = error {
            errorMessage = "請點上方電視名稱，設定電視 IP 與連線金鑰。"
        } else {
            errorMessage = error.localizedDescription
        }
        errorTask = Task {
            do { try await Task.sleep(for: .seconds(5)) }
            catch { return }
            self.errorMessage = nil
        }
    }
}
