import Foundation

/// Keep personal addresses in device settings, never in the source tree.
enum TVConnectionSettings {
    nonisolated static let exampleIP = "192.0.2.1"

    nonisolated static func prepare(in defaults: UserDefaults) {
        defaults.register(defaults: ["tv_ip": ""])
    }
}
