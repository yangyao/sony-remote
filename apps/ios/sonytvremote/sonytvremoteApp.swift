import SwiftUI

@main
struct SonyRemoteApp: App {
    init() {
        TVConnectionSettings.prepare(in: .standard)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// Seed once, including upgrades from the old empty address; preserve custom addresses.
enum TVConnectionSettings {
    nonisolated static let defaultIP = "192.0.2.1"

    nonisolated static func prepare(in defaults: UserDefaults) {
        if (defaults.string(forKey: "tv_ip") ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            defaults.set(defaultIP, forKey: "tv_ip")
        }
    }
}
