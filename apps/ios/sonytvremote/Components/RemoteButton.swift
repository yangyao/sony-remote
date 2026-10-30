import SwiftUI
#if os(iOS)
import UIKit
#endif

enum RemoteTheme {
    static let background = Color.black
    static let surface = Color(white: 0.12)
    static let center = Color(white: 0.19)
    static let secondary = Color(white: 0.65)

    @MainActor static func feedback() {
#if os(iOS)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
#endif
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
                .remoteGlass(in: Circle())
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
                .remoteGlass(in: Circle(), enabled: showsBackground)
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
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in changed(pressed) }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Native Liquid Glass on iOS 26+, with a material fallback for older phones.
/// No layout padding is added, so all existing hit targets and spacing stay intact.
private struct RemoteGlassModifier<S: Shape>: ViewModifier {
    let shape: S
    let interactive: Bool
    let enabled: Bool
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @ViewBuilder func body(content: Content) -> some View {
        if !enabled {
            content
        } else if reduceTransparency {
            content.background(RemoteTheme.surface, in: shape)
                .overlay(shape.stroke(.white.opacity(0.20), lineWidth: 0.5))
        } else if #available(iOS 26.0, *) {
            content.glassEffect(.regular.interactive(interactive), in: shape)
        } else {
            content.background(.ultraThinMaterial, in: shape)
                .overlay(shape.stroke(.white.opacity(0.16), lineWidth: 0.5))
        }
    }
}

extension View {
    func remoteGlass<S: Shape>(in shape: S, interactive: Bool = true, enabled: Bool = true) -> some View {
        modifier(RemoteGlassModifier(shape: shape, interactive: interactive, enabled: enabled))
    }
}

struct RemoteGlassGroup<Content: View>: View {
    @ViewBuilder let content: () -> Content

    @ViewBuilder var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 8) { content() }
        } else {
            content()
        }
    }
}
