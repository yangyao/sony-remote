# Sony Remote

無廣告的 Sony BRAVIA 區網遙控器，使用 SwiftUI，支援 iPhone；Mac 版待開發。

## iPhone 第一版

- 黑灰單頁遙控器，保留圓形方向盤與既有布局，按鍵使用原生 Liquid Glass。
- 圓形導航區：滑動方向、點按確認、按住方向圓點連續移動。
- 返回、首頁、播放／暫停入口、靜音。
- 直向電視音量加減，按住可連續調整；控制電視，不控制手機音量。
- 電源鍵直接以顏色顯示狀態：綠色開機、橙色待機、灰色未連線；連線中顯示轉圈。
- 預設電視 IP 為 `192.0.2.1`，開啟即自動連線；設定頁直接使用英文，只保留 TV IP 與 Connect，PSK 收進 Advanced。
- 無底部功能入口、重複標題、狀態文字或「正在播放」卡片；無廣告或分析 SDK。

Sony 部分機型沒有通用的播放／暫停切換指令，因此主畫面的播放按鍵開啟選單，明確選擇播放或暫停。

## 畫面

[主畫面](docs/screenshots/iphone-remote.png) · [設定](docs/screenshots/iphone-settings.png) · [玻璃效果更新前後](docs/screenshots/glass-before-after.png)

視覺檢查與驗證範圍見 [design-qa.md](design-qa.md)。

iOS 26+ 使用 SwiftUI 原生 Liquid Glass；iOS 17–18 使用系統半透明材質。開啟「降低透明度」時改用清晰的不透明按鍵。

## 執行

1. 使用 Xcode 26 或更新版開啟 `apps/ios/sonytvremote.xcodeproj`。
2. 選 `sonytvremote` scheme；App 最低支援 iOS 17。
3. 若安裝到 iPhone，在 Signing & Capabilities 選自己的 Team，必要時調整 Bundle Identifier。
4. iPhone 與電視連到同一區網，App 預設連接 `192.0.2.1`。
5. 若要更改地址，點上方電視名稱，修改 IP 並點「Connect」；需要 PSK 時再展開「Advanced」。

首次連接需要授權的電視時，App 會自動進入配對：先開啟電視，在手機填入電視顯示的四位 PIN，再點 Pair TV。之後使用儲存在 Keychain 的憑據自動連接，不保存 PIN。若電視使用固定 PSK，可在 Advanced 填入原有金鑰。

已在實體 BRAVIA 完成 PIN 配對，使用者確認音量按鍵可控制。待機喚醒與其他機型仍需另行驗證；目前沒有實作 UDP Wake-on-LAN。

文字輸入不會自動喚起 iPhone 鍵盤；偶爾輸入時可用方向鍵操作電視的螢幕鍵盤，或使用實體遙控器。

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

通訊測試使用 URLProtocol 模擬 Sony 回應，驗證 PSK、REST／SOAP 格式、電視回報按鍵碼、PIN 配對、錯誤 PIN、憑據重載及不同電視間的憑據隔離。
UI 測試涵蓋主畫面、設定面板與播放選單；另驗證底部三個入口／重複標題／狀態文字已移除，以及預設 IP 和精簡設定。

上游程式依 Apache-2.0 授權，詳見 `apps/ios/LICENSE`；來源與修改見 `docs/upstream.md`。
