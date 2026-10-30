# Sony Remote

無廣告的原生 Sony BRAVIA 區網遙控器，支援 iPhone 和 Mac，使用 SwiftUI 與原生 Liquid Glass。

## 畫面

| iPhone · Light | iPhone · Dark |
| :---: | :---: |
| <img src="docs/screenshots/iphone-light.png" alt="iPhone 遙控器淺色模式" width="270"> | <img src="docs/screenshots/iphone-dark.png" alt="iPhone 遙控器深色模式" width="270"> |

| Mac · Light | Mac · Dark |
| :---: | :---: |
| <img src="docs/screenshots/mac-light.png" alt="Mac 遙控器淺色模式" width="240"> | <img src="docs/screenshots/mac-dark.png" alt="Mac 遙控器深色模式" width="240"> |

## 功能

- 圓形方向盤：方向、確認、滑動導航與按住連發。
- 返回、首頁、播放／暫停、靜音、電視音量加減及電源。
- 自動跟隨系統 Light / Dark Mode，沒有額外的主題切換設定。
- 首次使用四位 PIN 配對，授權保存在本機 Keychain；也支援電視的 PSK 模式。
- Mac 控制中心提供一個 Sony Remote 入口，點擊開啟完整遙控器窗口。
- 沒有廣告、分析 SDK、帳號或雲端服務。

應用程式啟動、輸入源清單、數字鍵、頻道鍵及「正在播放」資訊不在本專案的範圍內。

## 連接設定與圖標

| Connection · Light | Connection · Dark | App Icon |
| :---: | :---: | :---: |
| <img src="docs/screenshots/iphone-connection-light.png" alt="Connection 淺色模式" width="200"> | <img src="docs/screenshots/iphone-connection-dark.png" alt="Connection 深色模式" width="200"> | <img src="docs/screenshots/icon-preview.png" alt="Sony Remote 應用程式圖標" width="128"> |

[設計參考](docs/design-references.md)

## 使用與編譯

### iPhone

1. Xcode 開啟 `apps/ios/sonytvremote.xcodeproj`，選 `sonytvremote` scheme。
2. 安裝到實機前，在 Signing & Capabilities 選自己的 Team；公開工程不包含開發者簽名設定。
3. 手機與電視連到同一區網，首次在 Connection 填入電視 IP，點 Connect。
4. 若電視需要授權，輸入電視顯示的四位 PIN，點 Pair TV。配對碼過期可點 Show code again。

最低 iOS 17；iOS 26+ 使用原生 Liquid Glass，較早版本使用系統材質。降低透明度時使用不透明表面。

### Mac

Xcode 開啟 `apps/macos/SonyRemote.xcodeproj`，選 `SonyRemote` scheme 和自己的 Team，執行到 My Mac。最低 macOS 26。

完成連接後，在控制中心的 Edit Controls 搜尋 Sony Remote 並加入。日後直接點入口即可開啟遙控器。詳見 [Mac 說明](apps/macos/README.md)。

首次安裝不預填私人 IP。已安裝版本保留裝置內儲存的地址與配對；更改地址請點上方電視名稱。設定頁直接使用英文，PSK 收在 Advanced。

Sony 的播放與暫停是分開指令，因此播放按鈕提供 Play / Pause 選單。文字輸入使用電視螢幕鍵盤；深度待機喚醒未實作或驗證。

## 專案結構

- `apps/ios/`：iPhone 工程，以及兩端共用的通訊、按鍵模型、ViewModel 和元件。
- `apps/macos/`：Mac 窗口、連接設定、控制中心擴展與 UI 測試；直接引用共用 Swift 檔案。
- `packages/Appearance/`：兩端共用的深淺色色彩資源。
- `tools/render-app-icons.swift`：原創圖標的可重現向量繪製腳本。
- `docs/`：來源、隱私、設計和演示截圖。

## 測試

```sh
xcodebuild -project apps/ios/sonytvremote.xcodeproj -scheme sonytvremote \
  -destination 'platform=iOS Simulator,name=<已安裝的模擬器>' \
  -parallel-testing-enabled NO -collect-test-diagnostics never \
  -only-testing:sonytvremoteTests -only-testing:sonytvremoteUITests/RemoteUITests test
```

Mac 測試見 [Mac 說明](apps/macos/README.md)。通訊測試使用模擬 Sony 回應，涵蓋 PIN／PSK、授權保存與隔離、IRCC 按鍵碼、靜音狀態和未設定地址；UI 測試不連接真實電視。

## 來源與授權

本專案基於 [ug2454/sonytvremote](https://github.com/ug2454/sonytvremote) 修改，使用 Apache-2.0。見 [LICENSE](LICENSE)、[NOTICE](NOTICE) 和 [修改說明](docs/upstream.md)。

隱私與儲存範圍見 [docs/privacy.md](docs/privacy.md)；驗證範圍見 [design-qa.md](design-qa.md)。
