import Foundation
import Testing
@testable import sonytvremote

@MainActor
struct SonyServiceTests {
    @Test func defaultAddressMigratesEmptySettingsAndPreservesCustomAddress() {
        let defaults = UserDefaults(suiteName: "sony-settings-tests-\(UUID())")!
        TVConnectionSettings.prepare(in: defaults)
        #expect(defaults.string(forKey: "tv_ip") == "192.0.2.1")
        defaults.set("", forKey: "tv_ip")
        TVConnectionSettings.prepare(in: defaults)
        #expect(defaults.string(forKey: "tv_ip") == "192.0.2.1")
        defaults.set("192.0.2.10", forKey: "tv_ip")
        TVConnectionSettings.prepare(in: defaults)
        #expect(defaults.string(forKey: "tv_ip") == "192.0.2.10")
    }

    @Test func decodesMixedRemoteControllerResponse() {
        let response: [String: Any] = ["result": [
            ["bundled": true, "type": "IR_REMOTE_BUNDLE_TYPE_A"],
            [["name": "VolumeUp", "value": "tv-volume-code"], ["name": "Home", "value": "tv-home-code"]]
        ]]
        let codes = SonyTVService.remoteCodes(from: response)
        #expect(codes.map(\.name) == ["VolumeUp", "Home"])
        #expect(codes.map(\.code) == ["tv-volume-code", "tv-home-code"])
        #expect(SonyTVService.remoteCodes(from: ["result": []]).isEmpty)
    }

    @Test func sendsAuthenticatedSonyCommandsAndUsesAdvertisedCode() async throws {
        let defaults = UserDefaults(suiteName: "sony-remote-tests-\(UUID())")!
        defaults.set("192.0.2.1", forKey: "tv_ip")
        defaults.set("test-only-psk", forKey: "tv_psk")
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [SonyStubProtocol.self]
        let service = SonyTVService(session: URLSession(configuration: config), defaults: defaults)
        // The stub rejects wrong endpoints, headers, SOAPAction, or hardcoded IRCC fallback.
        await service.syncRemoteCodes()
        try await service.sendIRCC(.volumeUp)
        #expect(try await service.getPowerStatus())
        try await service.verifyControlAuthorization()
    }

    @Test func authenticationFailureIsSurfaced() async throws {
        let defaults = UserDefaults(suiteName: "sony-remote-tests-\(UUID())")!
        defaults.set("192.0.2.1", forKey: "tv_ip")
        defaults.set("incorrect", forKey: "tv_psk")
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [SonyStubProtocol.self]
        let service = SonyTVService(session: URLSession(configuration: config), defaults: defaults)
        do {
            _ = try await service.getPowerStatus()
            Issue.record("Expected HTTP 401")
        } catch TVError.httpError(let code, _) {
            #expect(code == 401)
        }
    }
}

private final class SonyStubProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        var status = 200
        var body = "{}"
        if request.value(forHTTPHeaderField: "X-Auth-PSK") != "test-only-psk" {
            status = 401
        } else if request.httpMethod != "POST" {
            status = 405
        } else if request.url?.path == "/sony/system" {
            // URLProtocol may deliver the body as a stream rather than httpBody.
            let data = request.httpBody ?? readStream(request.httpBodyStream)
            let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            if json?["method"] as? String == "getRemoteControllerInfo" {
                body = #"{"result":[{"bundled":true},[{"name":"VolumeUp","value":"advertised-volume-code"}]]}"#
            } else if json?["method"] as? String == "getPowerStatus" {
                body = #"{"result":[{"status":"active"}]}"#
            } else if json?["method"] as? String == "getLEDIndicatorStatus" {
                body = #"{"result":[{"mode":"on"}]}"#
            } else { status = 400 }
        } else if request.url?.path == "/sony/IRCC" {
            let data = request.httpBody ?? readStream(request.httpBodyStream)
            let soap = String(data: data, encoding: .utf8) ?? ""
            if !soap.contains("<IRCCCode>advertised-volume-code</IRCCCode>") ||
                request.value(forHTTPHeaderField: "SOAPACTION") != "\"urn:schemas-sony-com:service:IRCC:1#X_SendIRCC\"" {
                status = 400
            }
        } else { status = 404 }
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    private func readStream(_ stream: InputStream?) -> Data {
        guard let stream else { return Data() }
        stream.open()
        defer { stream.close() }
        var result = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            result.append(contentsOf: buffer.prefix(count))
        }
        return result
    }
    override func stopLoading() {}
}

@MainActor
struct SonyPairingTests {
    @Test func pairsOnceAndRestoresCookieForRESTAndIRCCWithoutLeakingToAnotherTV() async throws {
        let defaults = UserDefaults(suiteName: "sony-pairing-tests-\(UUID())")!
        defaults.set("192.0.2.1", forKey: "tv_ip")
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [PairingStubProtocol.self]
        let session = URLSession(configuration: config)
        let store = MemoryTVCredentialStore()
        let service = SonyTVService(session: session, defaults: defaults, credentialStore: store)

        #expect(try await service.getPowerStatus()) // Public endpoint needs no authentication.
        do {
            try await service.verifyControlAuthorization()
            Issue.record("Public power status must not be accepted as control authorization")
        } catch TVError.authorizationRequired {}

        #expect(try await service.requestPairing() == .pinRequired)
        let clientID = try #require(defaults.string(forKey: "sony_client_id"))
        #expect(store.load(for: "192.0.2.1") == nil)
        do {
            _ = try await service.requestPairing(pin: "0000")
            Issue.record("Expected incorrect PIN to be rejected")
        } catch TVError.invalidPIN {}
        #expect(store.load(for: "192.0.2.1") == nil)

        #expect(try await service.requestPairing(pin: "1234") == .paired)
        #expect(defaults.string(forKey: "sony_client_id") == clientID)
        #expect(store.load(for: "192.0.2.1") == "auth=test-paired-cookie")
        #expect(defaults.string(forKey: "tv_pin") == nil)

        // A fresh service instance must restore authorization without requesting another PIN.
        let restored = SonyTVService(session: session, defaults: defaults, credentialStore: store)
        try await restored.verifyControlAuthorization()
        try await restored.sendIRCC(.confirm)

        defaults.set("192.0.2.2", forKey: "tv_ip")
        do {
            try await restored.verifyControlAuthorization()
            Issue.record("A different TV must require its own pairing")
        } catch TVError.authorizationRequired {}
    }
}

private final class MemoryTVCredentialStore: TVCredentialStoring, @unchecked Sendable {
    nonisolated private let lock = NSLock()
    nonisolated(unsafe) private var cookies: [String: String] = [:]
    nonisolated func load(for host: String) -> String? { lock.withLock { cookies[host] } }
    nonisolated func save(_ cookie: String, for host: String) throws {
        lock.withLock { cookies[host] = cookie }
    }
}

private final class PairingStubProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        var status = 200
        var headers: [String: String] = [:]
        var body = #"{"result":[]}"#
        let data = request.httpBody ?? readStream(request.httpBodyStream)
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        let cookie = request.value(forHTTPHeaderField: "Cookie")
        if request.url?.host != "192.0.2.1", cookie != nil {
            status = 418 // Explicitly fail if a credential is leaked to a different host.
        } else if request.url?.path == "/sony/accessControl" {
            let params = json?["params"] as? [Any]
            let identity = params?.first as? [String: Any]
            let capabilities = params?.last as? [[String: String]]
            if capabilities != [["value": "yes", "function": "WOL"]] {
                status = 400 // Missing capability previously returned 401 but showed no PIN on the actual TV.
            } else if json?["method"] as? String != "actRegister" || identity?["level"] as? String != "private" ||
                !(identity?["clientid"] as? String ?? "").hasPrefix("SonyRemote:") {
                status = 400
            } else if request.value(forHTTPHeaderField: "Authorization") == "Basic " + Data(":1234".utf8).base64EncodedString() {
                headers["Set-Cookie"] = "auth=test-paired-cookie; Path=/sony/; HttpOnly"
            } else {
                status = 401
            }
        } else if json?["method"] as? String == "getPowerStatus" {
            body = #"{"result":[{"status":"active"}]}"#
        } else if cookie != "auth=test-paired-cookie" {
            body = #"{"error":[403,"Forbidden"]}"# // Sony also reports auth failures in HTTP 200 JSON.
        } else if request.url?.path == "/sony/IRCC" {
            body = ""
        } else if json?["method"] as? String == "getLEDIndicatorStatus" {
            body = #"{"result":[{"mode":"on"}]}"#
        } else if json?["method"] as? String == "getSystemInformation" {
            body = #"{"result":[{"product":"TV","model":"Test BRAVIA"}]}"#
        } else { status = 400 }
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: headers)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    private func readStream(_ stream: InputStream?) -> Data {
        guard let stream else { return Data() }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            data.append(contentsOf: buffer.prefix(count))
        }
        return data
    }
    override func stopLoading() {}
}
