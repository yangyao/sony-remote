import Foundation
import Security

protocol TVCredentialStoring: Sendable {
    nonisolated func load(for host: String) -> String?
    nonisolated func save(_ cookie: String, for host: String) throws
}

/// Pairing cookies stay in this app's Keychain; the temporary TV PIN is never saved.
struct KeychainTVCredentialStore: TVCredentialStoring {
    nonisolated init() {}
    nonisolated private func query(for host: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: "com.yangyao.sonyremote.tv-pairing",
         kSecAttrAccount as String: host.lowercased()]
    }

    nonisolated func load(for host: String) -> String? {
        var query = query(for: host)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    nonisolated func save(_ cookie: String, for host: String) throws {
        let attributes: [String: Any] = [kSecValueData as String: Data(cookie.utf8)]
        let status = SecItemUpdate(query(for: host) as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var item = query(for: host)
            item.merge(attributes) { _, new in new }
            item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else {
                throw TVError.credentialStorage
            }
        } else if status != errSecSuccess {
            throw TVError.credentialStorage
        }
    }
}
