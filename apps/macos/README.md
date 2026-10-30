# Sony Remote for Mac

macOS 26+ 原生 SwiftUI 遙控器。一個 App 內含一個控制中心入口；點 Sony Remote 開啟完整遙控器，不提供獨立的控制中心電源按鈕。

## 使用

1. Xcode 開啟 `SonyRemote.xcodeproj`，選 `SonyRemote` scheme 和自己的 Signing Team。
2. 首次在 Connection 輸入電視 IP，點 Connect，依電視提示輸入四位 PIN；或在 Advanced 填入 PSK。
3. 控制中心 → Edit Controls → 搜尋 Sony Remote → Add to Control Center。
4. 日後從控制中心開啟遙控器。關閉窗口、最小化或退出 App 後均可重新喚出。

Mac 與 iPhone 分別配對。裝置內既有地址與授權會保留，原始碼不預填私人地址。

## 操作

按鍵與 iPhone 版本相同，使用 Liquid Glass，自動跟隨系統深淺色。按住方向或音量可連續發送指令；方向鍵、Return、Escape 對應導航、確認和返回。配對頁不攔截遙控快捷鍵。

## 結構

- `SonyRemote/`：SwiftUI 遙控器、英文連接頁與可重用的 AppKit 窗口。
- `RemoteControl/`：WidgetKit 控制中心入口。
- `Shared/OpenRemoteIntent.swift`：App 與擴展共用的開啟動作。
- `Config/`：區網使用說明、sandbox 和 network-client entitlement。
- `Assets.xcassets/`：AppIcon。
- `SonyRemoteUITests/`：控制、設定、播放面板及關閉後重新開啟的 UI 測試。

共用 Swift 檔案直接引用 `../ios/sonytvremote/`，色彩引用 `../../packages/Appearance/`。

選好自己的 Signing Team 後，可在 Xcode 執行測試；命令列也可明確傳入自己的 Team：

```sh
xcodebuild -project apps/macos/SonyRemote.xcodeproj -scheme SonyRemote \
  -destination 'platform=macOS' DEVELOPMENT_TEAM=YOUR_TEAM_ID \
  -parallel-testing-enabled NO -collect-test-diagnostics never test
```

控制中心使用單個公開的 ControlWidgetButton 開啟 App。參考 [Apple Controls](https://developer.apple.com/documentation/widgetkit/controls-collection)。
