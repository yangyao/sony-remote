# 來源與修改

- 上游：[ug2454/sonytvremote](https://github.com/ug2454/sonytvremote)
- 匯入版本：`c9c30ce353aeee4851de77caffa090282cff126c`
- 作者：Uday Garg
- 原始授權：[Apache-2.0](../LICENSE)，來源標示保留於 [NOTICE](../NOTICE)。

保留並修改了 Sony REST／IRCC 通訊基礎與部分按鍵模型。重寫 iPhone 主畫面和設定流程，加入序列化按鍵傳送、連發、電視回報按鍵碼、PIN 配對與 Keychain 授權保存；新增原生 Mac App、控制中心入口、系統深淺色、原創圖標及測試。

已移除未使用的應用列表、輸入源頁面與模型、數字／頻道／彩色／串流快捷鍵、播放內容資訊、畫質設定、SwiftData 範例、範本啟動測試和沒有實際 UDP 發送功能的 Wake-on-LAN stub。

PIN 註冊所需的 WOL capability 是 Sony 註冊協定參數，仍須保留；它不代表本專案實作了網路喚醒。首次 HTTP 401 不可隱式重送，否則部分電視會關閉配對碼。

公開工程不包含個人簽名 Team、私人地址或實際配對資料。測試中的 PIN、PSK 和 cookie 是虛構資料；IRCC 字串是公開協定常數。
