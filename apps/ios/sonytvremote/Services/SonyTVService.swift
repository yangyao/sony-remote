import Foundation
import OSLog

enum TVError: LocalizedError {
    case notConfigured
    case networkError(String)
    case httpError(Int, String)
    case invalidResponse(String)
    case authorizationRequired
    case invalidPIN
    case pairingUnavailable
    case credentialStorage

    var requiresAuthorization: Bool {
        switch self {
        case .authorizationRequired, .httpError(401, _), .httpError(403, _): return true
        default: return false
        }
    }

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "尚未設定電視 IP，請先開啟連線設定。"
        case .networkError(let msg):
            return "無法連接電視：\(msg)"
        case .httpError(let code, let body):
            switch code {
            case 401: return "連線金鑰不正確，請檢查電視的 PSK 與認證設定。"
            case 403: return "電視拒絕控制，請確認已啟用 IP 遠端控制。"
            case 404: return "找不到遙控介面，請確認電視 IP 與機型支援。"
            case 500: return "HTTP 500 – TV internal error. \(body.prefix(80))"
            default:  return "HTTP \(code). \(body.prefix(80))"
            }
        case .authorizationRequired:
            return "Pair this app with the TV to enable remote control."
        case .invalidPIN:
            return "Incorrect PIN. Enter the code currently shown on the TV."
        case .pairingUnavailable:
            return "Pairing is unavailable. Turn on the TV and allow remote device registration."
        case .credentialStorage:
            return "Could not save TV pairing. Please try again."
        case .invalidResponse(let detail):
            return "Invalid response: \(detail)"
        }
    }
}

actor SonyTVService {
    static let shared = SonyTVService()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app", category: "SonyTVService")

    private var tvIP: String = ""
    private var psk: String = ""
    private var session: URLSession
    private let defaults: UserDefaults
    private let credentialStore: any TVCredentialStoring
    private var authCookie: String?
    private var irccPath: String? = nil              // cached once discovered
    private var tvRemoteCodes: [String: String] = [:] // codes fetched from TV via getRemoteControllerInfo

    private func alternativeName(for command: IRCCCommand) -> String? {
        switch command {
        case .up:       return "CursorUp"
        case .down:     return "CursorDown"
        case .left:     return "CursorLeft"
        case .right:    return "CursorRight"
        case .confirm:  return "Enter"
        case .back:     return "Back"
        default:        return nil
        }
    }

    init(session: URLSession? = nil, defaults: UserDefaults = .standard,
         credentialStore: any TVCredentialStoring = KeychainTVCredentialStore()) {
        self.defaults = defaults
        self.credentialStore = credentialStore
        let config = URLSessionConfiguration.default
        config.httpShouldSetCookies = false
        config.httpCookieStorage = nil
        config.urlCredentialStorage = nil
        config.timeoutIntervalForRequest = 8
        config.timeoutIntervalForResource = 15
        self.session = session ?? URLSession(configuration: config)
        // Load saved settings immediately
        self.tvIP = (defaults.string(forKey: "tv_ip") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        self.psk  = (defaults.string(forKey: "tv_psk") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        self.authCookie = credentialStore.load(for: self.tvIP)
    }

    func configure(ip: String, psk: String) {
        let nextIP = ip.trimmingCharacters(in: .whitespacesAndNewlines)
        let nextPSK = psk.trimmingCharacters(in: .whitespacesAndNewlines)
        guard nextIP != tvIP || nextPSK != self.psk else { return }
        if nextIP != tvIP { self.authCookie = credentialStore.load(for: nextIP) }
        self.tvIP = nextIP
        self.psk = nextPSK
        self.irccPath = nil
        self.tvRemoteCodes = [:]
    }

    private func reloadFromUserDefaults() {
        configure(ip: defaults.string(forKey: "tv_ip") ?? "", psk: defaults.string(forKey: "tv_psk") ?? "")
    }

    // MARK: - TV authorization

    enum PairingResult: Equatable, Sendable { case pinRequired, paired }

    private func authorize(_ request: inout URLRequest) {
        request.httpShouldHandleCookies = false
        if !psk.isEmpty {
            request.setValue(psk, forHTTPHeaderField: "X-Auth-PSK")
        } else if let authCookie {
            request.setValue(authCookie, forHTTPHeaderField: "Cookie")
        }
    }

    /// Match the generic access needed by remote buttons; power status is public.
    func verifyControlAuthorization() async throws {
        do {
            _ = try await restRequest(service: "system", method: "getLEDIndicatorStatus")
        } catch let error as TVError where !error.requiresAuthorization {
            // Older models may not expose this protected, read-only method.
            _ = try await restRequest(service: "system", method: "getSystemInformation")
        }
    }

    func requestPairing(pin: String? = nil) async throws -> PairingResult {
        reloadFromUserDefaults()
        guard !tvIP.isEmpty else { throw TVError.notConfigured }
        if let pin {
            guard pin.count == 4, pin.allSatisfy({ $0.isASCII && $0.isNumber }) else {
                throw TVError.invalidPIN
            }
        }
        let clientID: String
        if let saved = defaults.string(forKey: "sony_client_id") { clientID = saved }
        else {
            clientID = "SonyRemote:" + UUID().uuidString
            defaults.set(clientID, forKey: "sony_client_id")
        }
        let url = try tvURL(path: "/sony/accessControl")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpShouldHandleCookies = false
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("SonyRemote/1.0", forHTTPHeaderField: "User-Agent")
        // Sony requires this capability entry to show the device-registration PIN dialog.
        // This is a registration request, not a change to the TV's authentication settings.
        #if os(macOS)
        let nickname = "Sony Remote Mac"
        #else
        let nickname = "Sony Remote"
        #endif
        let body: [String: Any] = ["method": "actRegister", "id": 1, "version": "1.0",
            "params": [["clientid": clientID, "nickname": nickname, "level": "private"],
                       [["value": "yes", "function": "WOL"]]] as [Any]]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        if let pin {
            request.setValue("Basic " + Data(":\(pin)".utf8).base64EncodedString(),
                             forHTTPHeaderField: "Authorization")
        }
        let delegate = TVAuthenticationDelegate()
        let pairingSession = URLSession(configuration: session.configuration, delegate: delegate, delegateQueue: nil)
        defer { pairingSession.finishTasksAndInvalidate() }
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await pairingSession.data(for: request)
        } catch {
            // Cancelling this specific Basic challenge preserves the TV's PIN dialog.
            // Ordinary task cancellation and network errors must still propagate.
            guard delegate.receivedBasicChallenge else { throw error }
            if pin == nil { return .pinRequired }
            throw TVError.invalidPIN
        }
        guard let http = response as? HTTPURLResponse else {
            throw TVError.invalidResponse("No pairing response")
        }
        if http.statusCode == 401 {
            if pin == nil { return .pinRequired }
            throw TVError.invalidPIN
        }
        if http.statusCode == 403 { throw TVError.pairingUnavailable }
        guard (200...299).contains(http.statusCode) else {
            throw TVError.httpError(http.statusCode, "Pairing failed")
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw TVError.invalidResponse("Invalid pairing response")
        }
        if let error = json["error"] as? [Any] {
            if let code = error.first as? Int, code == 401 || code == 403 {
                if pin != nil { throw TVError.invalidPIN }
                throw TVError.pairingUnavailable
            }
            throw TVError.invalidResponse("TV could not register this app")
        }
        guard json["result"] != nil else { throw TVError.invalidResponse("Missing pairing result") }
        let headers = http.allHeaderFields.reduce(into: [String: String]()) {
            if let key = $1.key as? String { $0[key] = String(describing: $1.value) }
        }
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: headers, for: url)
        guard let cookie = HTTPCookie.requestHeaderFields(with: cookies)["Cookie"], !cookie.isEmpty else {
            throw TVError.invalidResponse("TV did not return a pairing credential")
        }
        try credentialStore.save(cookie, for: tvIP)
        authCookie = cookie
        return .paired
    }

    // MARK: - IRCC Command

    func syncRemoteCodes() async {
        logger.info("Syncing remote codes from TV")
        guard let codes = try? await getRemoteControllerInfo() else {
            logger.warning("Failed to fetch remote codes from TV")
            return
        }
        tvRemoteCodes = Dictionary(codes.map { ($0.name, $0.code) }, uniquingKeysWith: { _, latest in latest })
    }

    func sendIRCC(_ command: IRCCCommand) async throws {
        // Prefer the code the TV itself reported — try the canonical name, then a known alias, else fallback to baked-in constant
        let alias = alternativeName(for: command)
        let tvCodeFromCanonical = tvRemoteCodes[command.tvName]
        let tvCodeFromAlias = alias.flatMap { tvRemoteCodes[$0] }
        let tvCode = tvCodeFromCanonical ?? tvCodeFromAlias
        let chosen = tvCode ?? command.rawValue

        let source = tvCodeFromCanonical != nil ? "canonical(\(command.tvName))" :
                     tvCodeFromAlias != nil ? "alias(\(alias ?? ""))" : "hardcoded"
        logger.debug("Sending IRCC for '\(command.tvName)' - source: \(source), code: \(chosen)")

        do {
            try await sendIRCCCode(chosen)
        } catch {
            logger.warning("IRCC code failed, error: \(error.localizedDescription)")
            // If the TV-provided code caused a 500, retry once with the baked-in constant
            if case TVError.httpError(500, _) = error {
                if tvCode != nil && tvCode != command.rawValue {
                    logger.info("Retrying '\(command.tvName)' with hardcoded fallback: \(command.rawValue)")
                    try await sendIRCCCode(command.rawValue)
                    return
                }
            }
            throw error
        }
    }

    private func sendIRCCCode(_ code: String) async throws {
        reloadFromUserDefaults()
        guard !tvIP.isEmpty else { throw TVError.notConfigured }

        // If we already found the working path, use it directly
        if let path = irccPath {
            try await sendIRCCToPath(path, code: code)
            return
        }

        // Auto-discover: try each known IRCC endpoint path in order
        let candidates = ["/sony/IRCC", "/sony/ircc", "/IRCC"]
        var lastError: Error = TVError.invalidResponse("No IRCC endpoint found")

        for path in candidates {
            do {
                try await sendIRCCToPath(path, code: code)
                irccPath = path  // cache the working path
                return
            } catch TVError.httpError(404, _) {
                continue  // try next path
            } catch {
                lastError = error
                break  // real error (401, 403, network), stop trying
            }
        }

        throw lastError
    }

    private func sendIRCCToPath(_ path: String, code: String) async throws {
        let soapBody = """
<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
<s:Body>
<u:X_SendIRCC xmlns:u="urn:schemas-sony-com:service:IRCC:1">
<IRCCCode>\(code)</IRCCCode>
</u:X_SendIRCC>
</s:Body>
</s:Envelope>
"""

        var request = URLRequest(url: try tvURL(path: path))
        request.httpMethod = "POST"
        request.setValue("text/xml; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.setValue("\"urn:schemas-sony-com:service:IRCC:1#X_SendIRCC\"", forHTTPHeaderField: "SOAPACTION")
        authorize(&request)
        request.httpBody = soapBody.data(using: .utf8)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw TVError.invalidResponse("No HTTP response")
        }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw TVError.httpError(http.statusCode, body)
        }
    }

    // MARK: - REST API

    private func restRequest(service: String, method: String, params: [[String: Any]] = []) async throws -> [String: Any] {
        reloadFromUserDefaults()
        guard !tvIP.isEmpty else { throw TVError.notConfigured }

        let body: [String: Any] = [
            "method": method,
            "params": params,
            "id": Int.random(in: 1...999),
            "version": "1.0"
        ]

        var request = URLRequest(url: try tvURL(path: "/sony/\(service)"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw TVError.invalidResponse("No HTTP response")
        }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw TVError.httpError(http.statusCode, body)
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            let raw = String(data: data, encoding: .utf8) ?? "empty"
            throw TVError.invalidResponse("JSON parse failed: \(raw.prefix(100))")
        }
        // Check for API-level error in response body e.g. {"error":[7,"Illegal Argument"]}
        if let errArray = json["error"] as? [Any] {
            if let code = errArray.first as? Int, code == 401 || code == 403 {
                throw TVError.authorizationRequired
            }
            let code = errArray.first.map { "\($0)" } ?? "?"
            let msg  = errArray.last  as? String ?? "unknown"
            throw TVError.invalidResponse("TV error \(code): \(msg)")
        }
        return json
    }

    // MARK: - Power

    func getPowerStatus() async throws -> Bool {
        let result = try await restRequest(service: "system", method: "getPowerStatus")
        if let results = result["result"] as? [[String: Any]],
           let status = results.first?["status"] as? String {
            return status == "active"
        }
        throw TVError.invalidResponse("Missing power status")
    }

    // MARK: - Volume

    func getMuteStatus() async throws -> Bool? {
        let result = try await restRequest(service: "audio", method: "getVolumeInformation")
        guard let results = result["result"] as? [[[String: Any]]] else { return nil }
        let outputs = results.flatMap { $0 }
        let speaker = outputs.first(where: { $0["target"] as? String == "speaker" }) ?? outputs.first
        return speaker?["mute"] as? Bool
    }

    private func getRemoteControllerInfo() async throws -> [(name: String, code: String)] {
        let result = try await restRequest(service: "system", method: "getRemoteControllerInfo")
        return Self.remoteCodes(from: result)
    }

    // Sony returns [metadataObject, commandArray], not an array of command arrays.
    nonisolated static func remoteCodes(from response: [String: Any]) -> [(name: String, code: String)] {
        guard let results = response["result"] as? [Any] else { return [] }
        return results.compactMap { $0 as? [[String: Any]] }.flatMap { $0 }.compactMap { item in
            guard let name = item["name"] as? String,
                  let value = item["value"] as? String else { return nil }
            return (name: name, code: value)
        }
    }

    // MARK: - Helpers

    private func tvURL(path: String) throws -> URL {
        guard let url = URL(string: "http://\(tvIP)\(path)") else {
            throw TVError.networkError("Invalid URL: \(tvIP)\(path)")
        }
        return url
    }
}

/// Sony uses the initial HTTP 401 to display a PIN. CFNetwork must not silently
/// retry that challenge: another registration request can dismiss the TV dialog.
private final class TVAuthenticationDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private var challenged = false
    var receivedBasicChallenge: Bool {
        lock.lock()
        defer { lock.unlock() }
        return challenged
    }
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic {
            lock.lock()
            challenged = true
            lock.unlock()
            completionHandler(.cancelAuthenticationChallenge, nil)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
