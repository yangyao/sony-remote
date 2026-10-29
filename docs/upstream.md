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
- 上游最低 iOS 版本是 26.2；若手機較舊，需先評估相容性再下調。
- iPhone UX 尚未改版；macOS 與共用套件尚未實作。
