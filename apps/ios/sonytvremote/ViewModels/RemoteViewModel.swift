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
    @Published var isOn: Bool = false
    @Published var volume: Int = 0
    @Published var maxVolume: Int = 100
    @Published var isMuted: Bool = false
    @Published var apps: [TVApp] = []
    @Published var inputs: [TVInput] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var systemInfo: String = ""
    @Published var currentContent: String = ""

    private let service = SonyTVService.shared
    private var statusTimer: Timer?

    // MARK: - Configuration

    func loadSettings() async {
        logger.info("Loading settings from UserDefaults")
        let defaults = UserDefaults.standard
        let ip = defaults.string(forKey: "tv_ip") ?? ""
        let psk = defaults.string(forKey: "tv_psk") ?? ""
        logger.debug("Configuring service with IP: \(ip, privacy: .public)")
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
            isOn = try await service.getPowerStatus()
            connectionState = isOn ? .connected : .standby
            logger.info("Power status: \(self.isOn ? "ON" : "OFF", privacy: .public)")
            if isOn {
                let volInfos = (try? await service.getVolumeInfo()) ?? []
                if let speaker = volInfos.first(where: { $0.target == "speaker" }) ?? volInfos.first {
                    volume = speaker.volume
                    maxVolume = speaker.maxVolume
                    isMuted = speaker.mute
                    logger.debug("Volume: \(speaker.volume), Muted: \(speaker.mute)")
                }
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

    func powerOn() async {
        logger.info("Power ON requested")
        do {
            try await service.setPowerStatus(on: true)
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await refreshStatus()
        } catch {
            logger.error("Power ON failed: \(error.localizedDescription, privacy: .public)")
            showError(error)
        }
    }

    func powerOff() async {
        logger.info("Power OFF requested")
        do {
            try await service.setPowerStatus(on: false)
            isOn = false
        } catch {
            logger.warning("Power OFF via API failed, trying IRCC command")
            await sendCommand(.powerOff)
        }
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

    func setVolume(_ value: Int) async {
        logger.info("Setting volume to: \(value, privacy: .public)")
        do {
            try await service.setVolume(volume: value)
            volume = value
        } catch {
            logger.error("Set volume failed: \(error.localizedDescription, privacy: .public)")
            showError(error)
        }
    }

    func toggleMute() async {
        // IRCC toggle remains usable on models that cannot report volume state.
        do {
            try await service.sendIRCC(.mute)
            isMuted.toggle()
            await refreshStatus()
        } catch { showError(error) }
    }

    // MARK: - Apps

    func loadApps() async {
        logger.info("Loading apps list")
        isLoading = true
        do {
            apps = try await service.getAppList()
            logger.info("Loaded \(self.apps.count, privacy: .public) apps")
        } catch {
            logger.error("Failed to load apps: \(error.localizedDescription, privacy: .public)")
            showError(error)
        }
        isLoading = false
    }

    func launchApp(_ app: TVApp) async {
        logger.info("Launching app: \(app.title, privacy: .public)")
        do {
            try await service.launchApp(uri: app.uri, title: app.title)
            logger.info("App launched successfully")
        } catch {
            logger.error("Failed to launch app: \(error.localizedDescription, privacy: .public)")
            showError(error)
        }
    }

    // MARK: - Inputs

    func loadInputs() async {
        logger.info("Loading inputs list")
        isLoading = true
        do {
            inputs = try await service.getInputs()
            logger.info("Loaded \(self.inputs.count, privacy: .public) inputs")
        } catch {
            logger.error("Failed to load inputs: \(error.localizedDescription, privacy: .public)")
            showError(error)
        }
        isLoading = false
    }

    func selectInput(_ input: TVInput) async {
        logger.info("Selecting input: \(input.title, privacy: .public)")
        do {
            try await service.setInput(uri: input.uri)
            logger.info("Input selected successfully")
        } catch {
            logger.error("Failed to select input: \(error.localizedDescription, privacy: .public)")
            showError(error)
        }
    }

    // MARK: - System Info

    func loadSystemInfo() async {
        logger.info("Loading system info")
        do {
            let info = try await service.getSystemInfo()
            let name = info["product"] as? String ?? "Sony TV"
            let model = info["model"] as? String ?? ""
            let serial = info["serial"] as? String ?? ""
            systemInfo = "\(name) \(model)\nSerial: \(serial)"
            logger.info("System info loaded: \(name, privacy: .public) \(model, privacy: .public)")
        } catch {
            logger.error("Failed to load system info: \(error.localizedDescription, privacy: .public)")
            systemInfo = "Could not load system info"
        }
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
