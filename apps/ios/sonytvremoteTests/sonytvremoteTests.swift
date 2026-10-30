import Foundation
import Testing
@testable import sonytvremote

@MainActor
struct SonyServiceTests {
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
