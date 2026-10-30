import AppIntents
#if !REMOTE_EXTENSION
import AppKit
#endif

struct OpenRemoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Sony Remote"
    static var description = IntentDescription("Open the Sony TV remote.")
    static var supportedModes: IntentModes { .foreground }

    @MainActor
    func perform() async throws -> some IntentResult {
        #if !REMOTE_EXTENSION
        RemoteWindowController.shared.show()
        #endif
        return .result()
    }
}

