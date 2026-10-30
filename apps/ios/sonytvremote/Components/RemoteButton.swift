import SwiftUI
import UIKit

enum RemoteTheme {
    static let background = Color(red: 0.15, green: 0.12, blue: 0.18)
    static let surface = Color(red: 0.21, green: 0.18, blue: 0.24)
    static let center = Color(red: 0.29, green: 0.25, blue: 0.32)
    static let secondary = Color(red: 0.65, green: 0.61, blue: 0.68)

    @MainActor static func feedback() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
}

struct RemoteKey: View {
    let icon: String
    let label: String
    var size: CGFloat = 76
    var tint: Color = .white
    let action: () async -> Void

    var body: some View {
        Button {
            RemoteTheme.feedback()
            Task { await action() }
        } label: {
            Image(systemName: icon)
                .font(.system(size: size * 0.35, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .background(RemoteTheme.surface, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(label)
        .accessibilityIdentifier(label)
    }
}

/// Standard button semantics, with serial, cancellable repeat while held.
struct HoldRemoteKey: View {
    let icon: String
    let label: String
    var size: CGFloat = 76
    var showsBackground = true
    var fontSize: CGFloat = 28
    let action: () async -> Void
    @State private var repeatTask: Task<Void, Never>?
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Button {} label: {
            Image(systemName: icon)
                .font(.system(size: fontSize, weight: .medium))
                .frame(width: size, height: size)
                .background(showsBackground ? RemoteTheme.surface : .clear, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(HoldPressStyle { pressed in
            repeatTask?.cancel()
            guard pressed else { return }
            RemoteTheme.feedback()
            repeatTask = Task { @MainActor in
                await action()
                do {
                    try await Task.sleep(for: .milliseconds(450))
                    while !Task.isCancelled {
                        await action()
                        try await Task.sleep(for: .milliseconds(160))
                    }
                } catch { /* Finger lifted, view dismissed, or app backgrounded. */ }
            }
        })
        .accessibilityLabel(label)
        .accessibilityIdentifier(label)
        .accessibilityHint("按住連續調整")
        .accessibilityAction { Task { await action() } }
        .onDisappear { repeatTask?.cancel() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { repeatTask?.cancel() }
        }
    }
}

private struct HoldPressStyle: ButtonStyle {
    let changed: (Bool) -> Void
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.55 : 1)
            .onChange(of: configuration.isPressed) { _, pressed in changed(pressed) }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.65 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
