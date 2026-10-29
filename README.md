# Sony Remote

無廣告的 Sony BRAVIA 區網遙控器，使用 SwiftUI，規劃支援 iPhone 與 Mac。

## 目錄

- `apps/ios/`：由 ug2454/sonytvremote 匯入的 iPhone 起始專案。
- `apps/macos/`：Mac 版開發入口，目前尚未實作。
- `packages/`：預留共用 Swift Package，目前尚未抽取。
- `docs/ux.md`：Apple TV Remote 操作體驗方向。
- `docs/apple-tv-on-mac.md`：Mac 控制 Apple TV 的現成工具。
- `docs/upstream.md`：來源、授權、匯入修改及已知限制。

## 執行 iPhone 專案

1. 使用 Xcode 開啟 `apps/ios/sonytvremote.xcodeproj`。
2. 選擇 `sonytvremote` scheme；上游最低部署版本為 iOS 26.2。
3. 若安裝到 iPhone，在 Signing & Capabilities 選自己的 Team，必要時調整 Bundle Identifier。
4. iPhone 與電視連到同一區網，於 App 設定填寫電視 IP 與該機型需要的 PSK。
5. 使用設定中的 REST / IRCC 測試確認連線。

尚未以實體 Sony 電視驗證。功能與認證方式須依電視型號確認。
目前介面沿用上游，Apple TV Remote 風格改版尚未實作。

## 下一步

1. 確認電視型號及 IRCC / REST 連線。
2. 依 `docs/ux.md` 改造 iPhone 遙控器。
3. 將通訊與裝置設定抽成 `packages/SonyRemoteCore`，供兩端使用。
4. 開發 macOS 選單列 App，加入鍵盤操作。

上游程式依 Apache-2.0 授權，詳見 `apps/ios/LICENSE`；來源與修改見 `docs/upstream.md`。
