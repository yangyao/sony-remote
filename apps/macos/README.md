# Sony Remote for Mac

原生 SwiftUI 遙控器，最低 macOS 26。安裝一個 App，內含一個控制中心擴展：點 **Sony Remote** 即開啟完整遙控器，沒有獨立的電視電源控件。

## 使用

1. 使用 Xcode 開啟 `SonyRemote.xcodeproj`，選 `SonyRemote` scheme，Signing 選自己的 Team，執行到 My Mac。
2. App 預設連接 `192.0.2.1`。首次連接時輸入電視顯示的四位配對碼；若已過期，點 **Show code again**。
3. 控制中心 → **Edit Controls** → 搜尋 **Sony Remote** → **Add to Control Center**。只需添加這一個入口。
4. 此後從控制中心開啟遙控器。退出 App、關閉窗口或最小化後，入口仍可重新喚出同一個窗口。

點電視名稱可修改 IP，PSK 位於 Advanced。Mac 與 iPhone 分別配對，Mac 的授權保存在本機 Keychain，不保存 PIN。

## 操作

- 圓形方向鍵、確認、返回、首頁、播放／暫停、靜音及直向音量加減，沿用 iPhone 的原生 Liquid Glass 視覺。
- 按住方向圓點或音量鍵可連續發送指令。
- 方向鍵和 Return 對應導航及確認，Escape 返回；配對頁內不攔截這些遙控快捷鍵。
- 播放按鈕開啟 Play / Pause 小面板，以適配 Sony 分離的播放／暫停指令。
- 遙控器內保留電源鍵；未增加獨立的控制中心電源按鈕。深度待機的網路喚醒尚未驗證。

## 結構

- `SonyRemote/`：Mac 窗口、遙控器與英文連接設定。
- `RemoteControl/`：WidgetKit 控制中心入口。
- `Shared/OpenRemoteIntent.swift`：App 與擴展共同編譯的 App Intent；在 App 進程開啟窗口。
- `Config/`：網路使用說明、sandbox 與 network client entitlement。
- `SonyRemoteUITests/`：基本按鈕、播放面板、設定頁、關閉後重新開啟窗口的 UI 測試；測試時不連接電視。

通訊服務、Keychain、按鍵定義、ViewModel、方向盤與玻璃按鍵直接引用 `../ios/sonytvremote/` 的共用 Swift 檔案，維持一份實作。

```sh
xcodebuild -project apps/macos/SonyRemote.xcodeproj -scheme SonyRemote \
  -destination 'platform=macOS' -parallel-testing-enabled NO \
  -collect-test-diagnostics never test
```

## 控制中心接口

ControlWidget 的公開接口提供單個按鈕或開關模板，不能在一個控件內自由排列完整遙控器，因此這裡使用單個按鈕開啟 App。參考 [Controls](https://developer.apple.com/documentation/widgetkit/controls-collection)、[Creating controls](https://developer.apple.com/documentation/widgetkit/creating-controls-to-perform-actions-across-the-system)。

Sony 的首次註冊回傳 HTTP 401 以顯示 PIN。配對 session 明確取消 Basic 認證 challenge，避免 CFNetwork 隱式重送註冊、導致電視上的配對碼立即關閉；這項修正同時用於 iPhone 通訊原始碼。
