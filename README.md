# Sony Remote

無廣告的 Sony BRAVIA 區網遙控器，使用 SwiftUI，支援 iPhone；Mac 版待開發。

## iPhone 第一版

- 深色單頁遙控器，參考 Apple TV Remote 與 DM TV Remote。
- 圓形導航區：滑動方向、點按確認、按住方向圓點連續移動。
- 返回、首頁、播放／暫停入口、靜音。
- 直向電視音量加減，按住可連續調整；控制電視，不控制手機音量。
- 電源、App 清單、輸入源與更多按鍵面板。
- 預設電視 IP 為 `192.0.2.1`，開啟即自動連線；設定只保留 IP 與「連接」，PSK 收進進階設定。
- 無「正在播放」卡片，無廣告或分析 SDK。

Sony 部分機型沒有通用的播放／暫停切換指令，因此主畫面的播放按鍵開啟選單，明確選擇播放或暫停。

## 畫面

[主畫面](docs/screenshots/iphone-remote.png) · [設定](docs/screenshots/iphone-settings.png) · [更多控制](docs/screenshots/iphone-more.png) · [與參考圖比較](docs/screenshots/controls-comparison.png)

視覺檢查與驗證範圍見 [design-qa.md](design-qa.md)。

## 執行

1. 使用 Xcode 26 或更新版開啟 `apps/ios/sonytvremote.xcodeproj`。
2. 選 `sonytvremote` scheme；App 最低支援 iOS 17。
3. 若安裝到 iPhone，在 Signing & Capabilities 選自己的 Team，必要時調整 Bundle Identifier。
4. iPhone 與電視連到同一區網，App 預設連接 `192.0.2.1`。
5. 若要更改地址，點上方電視名稱，修改 IP 並點「連接」；需要 PSK 時再展開「進階設定」。

已從預設地址讀到電視待機狀態；實體遙控按鍵尚待驗證。PSK 認證及各按鍵支援程度依型號而異；需要 PIN 配對的機型尚未實作配對流程。待機喚醒亦需依機型另行驗證，現階段沒有實作 Wake-on-LAN。

## 目錄

- `apps/ios/`：iPhone 工程、通訊服務及測試。
- `apps/macos/`：Mac 版開發入口，目前尚未實作。
- `packages/`：預留共用 Swift Package，目前尚未抽取。
- `docs/references/dm-tv-remote/`：原始視覺參考與來源。
- `docs/ux.md`：介面方向與已實作行為。
- `docs/apple-tv-on-mac.md`：Mac 控制 Apple TV 的現成工具。
- `docs/upstream.md`：來源、授權及已知限制。

## 測試

```sh
xcodebuild -project apps/ios/sonytvremote.xcodeproj \
  -scheme sonytvremote -destination 'platform=iOS Simulator,name=<你的模擬器>' \
  -parallel-testing-enabled NO -collect-test-diagnostics never \
  -only-testing:sonytvremoteTests -only-testing:sonytvremoteUITests/RemoteUITests test
```

通訊測試使用 URLProtocol 模擬 Sony 回應，驗證 PSK、REST／SOAP 格式及電視回報按鍵碼。
UI 測試涵蓋主畫面、設定面板、播放選單與更多控制；另驗證預設 IP、簡化設定及移除教學／測試按鈕。

上游程式依 Apache-2.0 授權，詳見 `apps/ios/LICENSE`；來源與修改見 `docs/upstream.md`。
