import SwiftUI
import AppKit

@main
struct SonyRemoteMacApp: App {
    @NSApplicationDelegateAdaptor(RemoteAppDelegate.self) private var delegate

    init() { TVConnectionSettings.prepare(in: .standard) }

    var body: some Scene {
        Settings { EmptyView() }
            .commands {
                CommandGroup(after: .windowArrangement) {
                    Button("Sony Remote") { RemoteWindowController.shared.show() }
                        .keyboardShortcut("0", modifiers: .command)
                }
            }
    }
}

@MainActor
final class RemoteAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        RemoteWindowController.shared.show()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        RemoteWindowController.shared.show()
        return false
    }
}

/// Keep a single reusable window so the Control Center action also works after closing it.
@MainActor
final class RemoteWindowController: NSObject, NSWindowDelegate {
    static let shared = RemoteWindowController()
    private let vm = RemoteViewModel()
    private var window: NSWindow?

    func show() {
        if window == nil {
            let content = MacRemoteView(vm: vm)
                .foregroundStyle(.primary).tint(.primary)
            let controller = NSHostingController(rootView: content)
            let window = NSWindow(contentViewController: controller)
            window.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
            window.title = "Sony Remote"
            window.identifier = NSUserInterfaceItemIdentifier("remote")
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.backgroundColor = NSColor(named: "RemoteBackground") ?? .windowBackgroundColor
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.setContentSize(NSSize(width: 340, height: 590))
            window.center()
            self.window = window
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.deminiaturize(nil)
        window?.makeKeyAndOrderFront(nil)
        if !ProcessInfo.processInfo.arguments.contains("--ui-testing") { vm.startPolling() }
    }

    func windowWillClose(_ notification: Notification) {
        vm.stopPolling()
    }
}

enum TVConnectionSettings {
    nonisolated static let defaultIP = "192.0.2.1"
    nonisolated static func prepare(in defaults: UserDefaults) {
        if (defaults.string(forKey: "tv_ip") ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            defaults.set(defaultIP, forKey: "tv_ip")
        }
    }
}
