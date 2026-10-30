# DM TV Remote — UX 參考

來源：[Dependent Media 官方介紹](https://dependentmedia.com/dm-tv-remote/)。保存日期：2026-10-30。

這組資料是使用者選定的 Mac 遙控器 UX 參考；iPhone 版仍以控制中心的 Apple TV Remote 為主要參考。
圖片為第三方介面參考資料，權利屬原作者，不適用於本專案程式碼授權，不作為產品內素材使用。

## 1. 完整遙控器畫面

![完整遙控器](remote-original.webp)

官網原始圖片：<https://dependentmedia.com/wp-content/uploads/2026/09/dm-tv-remote-mac.png.webp>

可觀察的布局：

- 頂部裝置名稱與綠色連線狀態，右側手勢模式、電源。
- 播放資訊為獨立卡片，與導航區分開。
- 中央大尺寸圓形導航盤，四方向圓點與中心確認區。
- 下方返回／首頁兩欄；左側播放與鍵盤，右側直向音量膠囊。
- App 選單放在最底部，不占用主導航區。
- 深色背景、低對比按鍵底色、統一圓形按鍵與留白。

## 2. 播放狀態與整體比例

![播放狀態](now-playing-original.webp)

官網原始圖片：<https://dependentmedia.com/wp-content/uploads/2026/09/dm-tv-remote-now-playing-2048x1280.png.webp>

用來對照播放卡片、進度條、跳轉控制與整體視覺比例；此圖是官網宣傳圖，與上一張顯示相同播放狀態。

## 3. 配對流程影片截圖

![配對對話框](pairing-demo-010s.png)

擷取自[官網示範影片](https://dependentmedia.com/wp-content/uploads/2026/09/dm-tv-remote-demo.mp4) 00:10。
影片是實拍畫面，適合參考模態對話框與主視窗關係，不適合量測精確尺寸。
此處 Apple TV PIN 配對僅作流程參考；Sony 的 IP／PSK 設定依其自身協定實作。

## 後續實作取捨

- Mac 版採用這組畫面的緊湊縱向布局與控制分組，支援鍵盤和觸控板。
- iPhone 保留 Apple TV Remote 的大面積滑動區，不必照搬 Mac 圓形導航盤。
- Sony 的播放進度、文字輸入等能力先驗證再顯示；畫面參考不代表功能已支援。
- 圖示與介面使用 SwiftUI／SF Symbols 自行實作，不直接使用參考圖片。
