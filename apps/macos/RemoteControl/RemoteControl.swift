import SwiftUI
import WidgetKit

@main
struct RemoteControls: WidgetBundle {
    var body: some Widget { SonyRemoteControl() }
}

struct SonyRemoteControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.yangyao.sonyremote.mac.open") {
            ControlWidgetButton(action: OpenRemoteIntent()) {
                Label("Sony Remote", systemImage: "appletvremote.gen4")
            }
        }
        .displayName("Sony Remote")
        .description("Open your Sony TV remote.")
    }
}
