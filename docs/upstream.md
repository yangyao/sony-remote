# 第三方來源與匯入說明

## iOS 起始專案

- 來源：https://github.com/ug2454/sonytvremote
- 匯入 commit：c9c30ce353aeee4851de77caffa090282cff126c
- 授權：Apache-2.0，完整原文保留於 `apps/ios/LICENSE`。
- 上游 README 保留於 `apps/ios/UPSTREAM_README.md`；該文件描述上游，未必代表已驗證功能。

本次修改：將工程置於 apps/ios，移除開發者個人 xcuserdata，清除上游簽名 Team，Bundle Identifier 改為 com.yangyao.sonyremote 系列。新增區網權限說明與本機 HTTP 的 ATS 設定，清理行尾空白。

## 已知限制

- 尚未用實際電視測試連線與按鍵。
- 上游 Wake-on-LAN 只建立封包，沒有發送實作，不能視為可用的喚醒功能。
- PSK 目前沿用上游 UserDefaults 儲存；後續改為 Keychain。
- 上游最低 iOS 版本為 26.2；本專案已下調至 iOS 17，尚未在 iOS 17 實機執行。
- iPhone 主畫面已重寫；macOS 與共用套件尚未實作。

## iPhone 第一版修改

重寫 ContentView、RemoteView、DPadView 與按鍵元件，移除底部分頁及播放資訊卡片，加入直向電視音量膠囊、按住連發、滑動導航、觸覺回饋與 VoiceOver 標籤。設定頁改為繁體中文簡潔表單；App／輸入源移至彈出面板。

修正 getRemoteControllerInfo 混合物件／陣列回應的解析；改用序列化按鍵傳送，失敗後丟棄已排隊的手勢。連線狀態區分待機與連線失敗，關閉背景輪詢。清除不存在的 Wake-on-LAN 設定入口。新增通訊與 UI 測試。
