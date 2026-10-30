import SwiftUI

struct DPadView: View {
    let size: CGFloat
    let send: (IRCCCommand) async -> Void
    @State private var lastTranslation: CGSize = .zero
    @State private var swipeTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Circle()
                .fill(RemoteTheme.dpad)
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.07), lineWidth: 1))
            ForEach(0..<4) { index in
                let command: IRCCCommand = [.up, .right, .down, .left][index]
                let label = ["向上", "向右", "向下", "向左"][index]
                HoldRemoteKey(icon: "circle.fill", label: label, size: 56,
                              showsBackground: false, fontSize: 5) { await send(command) }
                    .foregroundStyle(RemoteTheme.secondary)
                    .offset(x: offset(index).width, y: offset(index).height)
            }
            Button {
                RemoteTheme.feedback()
                Task { await send(.confirm) }
            } label: {
                Circle().fill(.clear)
                    .frame(width: size * 0.40, height: size * 0.40)
                    .remoteGlass(in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("確認")
            .accessibilityIdentifier("確認")
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 24)
                .onChanged { value in
                    let dx = value.translation.width - lastTranslation.width
                    let dy = value.translation.height - lastTranslation.height
                    guard max(abs(dx), abs(dy)) >= 32 else { return }
                    lastTranslation = value.translation
                    let command: IRCCCommand = abs(dx) > abs(dy)
                        ? (dx > 0 ? .right : .left) : (dy > 0 ? .down : .up)
                    // Keep swipe commands ordered instead of opening parallel HTTP requests.
                    let previous = swipeTask
                    swipeTask = Task {
                        await previous?.value
                        guard !Task.isCancelled else { return }
                        await send(command)
                    }
                    RemoteTheme.feedback()
                }
                .onEnded { _ in lastTranslation = .zero }
        )
        .onDisappear { swipeTask?.cancel() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("導航觸控區")
        .accessibilityHint("滑動導覽，點按中央確認；按住方向圓點可連續移動")
    }

    private func offset(_ index: Int) -> CGSize {
        let distance = size * 0.39
        return [CGSize(width: 0, height: -distance), CGSize(width: distance, height: 0),
                CGSize(width: 0, height: distance), CGSize(width: -distance, height: 0)][index]
    }
}
