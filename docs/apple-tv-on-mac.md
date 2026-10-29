# 在 Mac 控制 Apple TV

可使用開源原生 macOS 選單列 App [Itsytv](https://github.com/nickustinov/itsytv-macos)。
它控制的是 Apple TV 裝置，與 Sony BRAVIA 的 IRCC / REST 協定不同。

## 安裝與使用

```sh
brew install --cask itsytv
```

也可以從專案 GitHub Releases 下載 DMG。
安裝後點擊選單列 TV 圖示，在與 Apple TV 相同區網下選擇裝置，輸入電視畫面顯示的四位數配對碼。

依專案文件：需要 macOS 14+，Apple TV 第四代或更新、tvOS 15+。
提供方向鍵、鍵盤導航、文字輸入、播放控制與 App 啟動。
音量控制需要 Apple TV 透過 HDMI-CEC 控制電視；實體遙控器學習的紅外線音量指令不能直接由 Mac 發送。

來源：https://github.com/nickustinov/itsytv-macos （查閱日期：2026-10-30）。
本次只記錄使用方式，沒有安裝工具或整合其程式碼。
