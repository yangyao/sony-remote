# Sony Remote for Mac

macOS 26+ 原生 SwiftUI 遥控器。一个 App 内含一个控制中心入口；点 Sony Remote 开启完整遥控器，不提供独立的控制中心电源按钮。

## 使用

1. Xcode 开启 `SonyRemote.xcodeproj`，选 `SonyRemote` scheme 和自己的 Signing Team。
2. 首次在 Connection 输入电视 IP，点 Connect，依电视提示输入四位 PIN；或在 Advanced 填入 PSK。
3. 控制中心 → Edit Controls → 搜寻 Sony Remote → Add to Control Center。
4. 日后从控制中心开启遥控器。关闭窗口、最小化或退出 App 后均可重新唤出。

Mac 与 iPhone 分别配对。装置内既有地址与授权会保留，原始码不预填私人地址。

## 操作

按键与 iPhone 版本相同，使用 Liquid Glass，自动跟随系统深浅色。按住方向或音量可连续发送指令；方向键、Return、Escape 对应导航、确认和返回。配对页不拦截遥控快捷键。

## 结构

- `SonyRemote/`：SwiftUI 遥控器、英文连接页与可重用的 AppKit 窗口。
- `RemoteControl/`：WidgetKit 控制中心入口。
- `Shared/OpenRemoteIntent.swift`：App 与扩展共用的开启动作。
- `Config/`：局域网使用说明、sandbox 和 network-client entitlement。
- `Assets.xcassets/`：AppIcon。
- `SonyRemoteUITests/`：控制、设置、播放面板及关闭后重新开启的 UI 测试。

共用 Swift 文件直接引用 `../ios/sonytvremote/`，色彩引用 `../../packages/Appearance/`。

选好自己的 Signing Team 后，可在 Xcode 执行测试；命令列也可明确传入自己的 Team：

```sh
xcodebuild -project apps/macos/SonyRemote.xcodeproj -scheme SonyRemote \
  -destination 'platform=macOS' DEVELOPMENT_TEAM=YOUR_TEAM_ID \
  -parallel-testing-enabled NO -collect-test-diagnostics never test
```

控制中心使用单个公开的 ControlWidgetButton 开启 App。参考 [Apple Controls](https://developer.apple.com/documentation/widgetkit/controls-collection)。
