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
