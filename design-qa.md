# iPhone 遙控器設計驗證

日期：2026-10-30。範圍為原生 SwiftUI iPhone App，依使用者選定參考圖調整；不是網頁原型。

## 視覺依據與證據

- 來源：`docs/references/dm-tv-remote/remote-original.webp`，889 × 1771 px。
- 初版實作（已存歷史）：`docs/screenshots/iphone-remote-pre-glass-simulator.png`，1398 × 2034 px。
- 原生模擬器：iPhone Duo / iOS 27.1，視窗 466 × 678 pt，3x 密度；沒有 CSS viewport。
- 狀態：深色、尚未設定電視。參考圖為已連線狀態，播放卡片依使用者要求移除；不比較兩者的連線指示顏色。
- 完整並排：`docs/screenshots/full-comparison.png`。兩側維持原比例各縮至最大 430 × 900 px，展示來源桌面視窗與手機實作的整體差異，不將作業系統視窗邊框或狀態區當作 App 差異。
- 控制區並排：`docs/screenshots/controls-comparison.png`。來源裁出 (120, 600, 650, 1010)，實作裁出 (0, 255, 1080, 1520)，各自保持比例縮至最大 430 × 680 px，明確檢查導航盤、按鍵與音量控制。這是適配後的構圖比較，不聲稱跨平台像素一比一相同。
- 已實際開啟來源圖、最終並排圖、設定與更多面板截圖，據此完成比較。

## 必查項目

- 字體：原生系統字體與 SF Symbols；裝置名稱、次要狀態與面板標題層級清楚。主畫面沒有意外換行或截斷。
- 間距／布局：保留來源大圓導航盤、下方兩欄及右側直向音量膠囊。主畫面截圖中底部三個入口均可見；不同可用高度會調整導航盤和按鍵尺寸，極小高度仍可捲動。
- 顏色：深紫黑底、低對比控制表面、較亮的中央確認區及紅色電源，與來源語言一致。狀態不只靠顏色，另有文字。
- 圖片／資產：App 不嵌入參考畫面，也沒有播放封面；原生形狀承載可互動按鍵，圖示使用 SF Symbols。參考素材只放文件。
- 文案：主要流程採繁體中文；未配置顯示連線入口，網路失敗不被誤標成待機。Sony 沒有驗證過的文字輸入不顯示鍵盤按鈕，以靜音取代。

## 比較與修正歷史

1. 初次驗證：[P1] 更多面板捲動後原生導覽列的「完成」按鈕消失，UI 測試無法關閉面板。修正前證據：`docs/screenshots/qa-before-more.png`。
2. 修正：使用固定的面板頂部標題與完成按鈕，獨立於可捲動內容；保留原生 sheet 和拖曳關閉能力。
3. 修正後：`docs/screenshots/iphone-more.png` 顯示捲動至數字鍵時完成按鈕仍在；完整 UI 測試確認按下後返回主畫面。`iphone-settings.png` 也使用相同固定入口。
4. 最終主畫面及控制區並排檢查：沒有剩餘可處理的 P0/P1/P2 視覺問題。

## 驗證結果

- 編譯與測試結果：`/tmp/sony-remote-verified.xcresult`，`TEST SUCCEEDED`。
- 3 個通訊測試通過：混合格式按鍵碼解析、PSK 與 Sony REST／IRCC SOAP 指令、認證失敗處理。
- 1 個 UI 流程測試通過：主按鍵、無底部分頁、音量未設定提示、提示關閉、設定開關、播放選單、更多面板捲動、數字鍵及返回主畫面。
- 已檢查 Xcode 編譯／測試日誌，沒有 Swift 程式編譯錯誤；此為原生 App，不適用瀏覽器 console 檢查。
- 殘留驗證缺口：未連接實體 Sony 電視；尚未實測 iOS 17、橫向／大型字級、真實長按與滑動延遲、待機喚醒或每款機型的指令支援。這些不在本次視覺通過結論內。

## 後續

使用者提供電視型號後，安裝 iPhone 真機測試；依電視回報能力校正指令與認證方式。


## 精簡個人設定（後續更新）

- 新視覺依據：使用者要求只保留地址、預設 `192.0.2.1`，移除教學與兩個測試入口。
- 改前：`docs/screenshots/qa-before-settings.png`；改後：`docs/screenshots/iphone-settings.png`。已開啟最終截圖確認 IP 完整可讀、「連接」可用、進階設定預設收合。
- 設定改為 320 pt 小面板，可展開；保留固定「完成」入口，表單頂部預留安全間距，避免首列被標題覆蓋。
- 預設地址用於新安裝及舊空白設定的升級，保留已有的自訂地址與 PSK。新增單元測試驗證此遷移行為。
- `/tmp/sony-simple-settings.xcresult`：4 個服務／設定單元測試及設定 UI 測試通過。
- `/tmp/sony-simple-settings-final.xcresult`：最終小面板 UI 測試通過，確認 IP 顯示、「連接」啟用、教學／測試入口移除及關閉面板。
- 真機版簽名編譯通過，已更新並成功啟動於使用者的 iPhone 15。
- 讀取電視 `getPowerStatus` 成功回傳 HTTP 200 / standby；這項查詢無需 PSK。尚未驗證實體遙控按鍵或待機喚醒。
- 字體、深色配色與主畫面保持一致；最終小面板沒有可處理的 P0/P1/P2 視覺問題。


## Liquid Glass 材質更新

- 本次約束：布局與按鍵完全延續；只移除紫色並加入原生 Liquid Glass。沒有採用 Apple TV 的大觸控板。
- 材質來源：`docs/references/apple-tv-liquid-glass/iphone-reference.png`，iPhone 15 / iOS 27.0.1，1179 × 2556 px，3x。
- 同一手機改前／改後：`docs/screenshots/iphone-before-glass.png`、`docs/screenshots/iphone-remote-glass.png`，均為 1179 × 2556 px；待機狀態相同。
- 已開啟並排證據：`docs/screenshots/glass-before-after.png`，各側等比例縮至 393 × 852 px。圓形方向盤與確認鍵的直徑、按鍵分組位置、音量膠囊與底部入口一致。
- 已開啟材質局部對照：`docs/screenshots/glass-material-comparison.png`，上方 Apple TV 按鍵，下方 Sony 按鍵。檢查邊緣高光、中性灰材質與白色 SF Symbols；不將兩者不同按鍵尺寸／排列視為差異。
- 字體與文案：延續既有大小、字重、繁體中文與連線狀態。
- 布局與間距：沒有新增 padding 或改動尺寸計算，只有功能鍵增加不改變布局的 GlassEffectContainer。
- 顏色與材質：純黑底、中性灰方向盤；原生 `.regular.interactive()` 用於確認與功能按鍵／音量膠囊。方向盤外圈不再加玻璃，避免雙層玻璃。
- 圖片資產：App 仍使用 SF Symbols 與原生材質，沒有嵌入參考圖或用點陣圖假裝玻璃。
- 無障礙：保留標籤與觸控尺寸；降低透明度時使用清晰的不透明表面。iOS 17–18 使用系統半透明材質 fallback；尚未在舊系統實機驗證。
- 真機簽名編譯通過，已安裝並成功啟動於使用者 iPhone 15；本次真機截圖已確認實際渲染，沒有可處理的 P0/P1/P2 視覺差異。
- `/tmp/sony-remote-glass.xcresult`：兩個 UI 測試通過，涵蓋遙控器／播放選單／更多面板，以及預設 IP／精簡設定／完成按鈕。日誌沒有 Swift 程式編譯錯誤。
- 本次沒有修改 Sony 通訊、認證或預設 IP；沒有以真機發送按鍵來驗證電視功能。靜態截圖能確認材質外觀，不作互動動畫效能量測。


## 基本控制精簡更新

- 使用者要求移除底部三個入口、SONY REMOTE 重複標題與狀態文字，不開發手機鍵盤。
- 新截圖：`docs/screenshots/iphone-remote.png`，使用者 iPhone 15，1179 × 2556 px，3x；待機狀態。
- 改前：`docs/screenshots/iphone-remote-glass.png`；已開啟同手機新舊截圖，確認圓形方向盤、基本控制與原生玻璃材質保留。
- 並排證據：`docs/screenshots/minimal-before-after.png`，兩側等比例縮至 393 × 852 px。舊版文字與底部入口移除後，主控制仍全部可見、無溢出。
- 電源鍵橙色對應實際待機；綠色為開機、灰色為未連線，連線中使用 ProgressView。VoiceOver 仍提供完整狀態文字與提示，不在畫面上增加文案。
- 電視名稱仍可開啟原有精簡設定，沒有底部功能面板的替代入口。
- 字體大小、黑灰配色、SF Symbols、玻璃材質保持；可用留白由既有 Spacer 分配。
- `/tmp/sony-minimal-ui.xcresult`：兩個 UI 測試通過，包含確認底部三入口／重複標題／待機文字不存在、主要控制存在、設定進出與播放選單。
- 真機簽名編譯通過，已更新並成功啟動；已開啟手機實際截圖確認最終畫面。
- 無剩餘可處理的 P0/P1/P2 視覺問題；通訊協定未變更，沒有測試實體電視按鍵或新增文字輸入功能。


## IP 設定頁直接使用英文

- 標題／按鈕／欄位為 Connection、Done、TV IP、Connect、Advanced、Pre-shared key (PSK)，包含頁內無障礙標籤與錯誤提示。
- 沒有新增翻譯資源或語言切換，也沒有更動主遙控器介面。
- 已開啟 `docs/screenshots/iphone-settings.png` 確認英文文字完整、無截斷，IP 與 Connect 可用，仍是精簡小面板。
- `/tmp/sony-english-settings.xcresult`：設定頁 UI 測試通過，含開啟／關閉、預設 IP 與 Connect 啟用狀態。
- 真機簽名編譯通過，已更新並成功啟動於使用者 iPhone 15。

final result: passed


## PIN pairing verification — 2026-10-30

- Fixed Sony device registration to include the WOL capability, which made this TV display its pairing dialog.
- Authorization checks use a protected endpoint; public power status no longer counts as proof of control access.
- User completed pairing on test device iPhone 15 and confirmed volume-up changed the TV volume.
- Installed the final build and relaunched it: main remote appeared without another pairing prompt, with active power status. Credentials persist in the iPhone Keychain; PIN is not stored.
- Final simulator run passed: 5 unit tests and 2 UI tests. Covers incorrect PIN, credential persistence, REST/IRCC authorization, host isolation, and canonical registration capabilities. Signed device build passed.
- Main layout unchanged. Updated main screenshot contains no pairing code or TV content.


## macOS implementation — 2026-10-30

- Implemented a signed macOS 26+ SwiftUI app with an embedded WidgetKit ControlWidgetButton. The single Sony Remote control opens the full app; no standalone power control.
- Installed at `~/Applications/SonyRemote.app`; added its button to the user's Control Center through Edit Controls.
- Verified actual Control Center activation both when the app was not running and after its window had been closed. The retained AppKit window hosts SwiftUI content and restores correctly; explicit dark appearance preserves icon/text contrast after reopening.
- Reused Sony service, credentials, command model, ViewModel, D-pad and glass buttons from the iOS source. macOS uses its own stable client ID and local Keychain authorization.
- Found and fixed a real pairing issue: CFNetwork automatically sent a second request after the initial Basic HTTP 401, dismissing this TV's PIN dialog. A dedicated pairing-session delegate cancels that challenge and returns the expected pairing result. Confirmed on the TV, and through a loopback HTTP server that receives exactly one request per action.
- Final UI test passed: basic controls, Play/Pause popover, English settings, closing the window and reopening it. Tests suspend networking rather than changing the saved address. Confirmed saved IP remains `192.0.2.1`.
- All 5 shared iOS service tests passed after the pairing-session change. Signed app and extension build passed; installed bundle passes deep signature verification.
- Actual Mac volume-up changed the TV speaker from 12 to 13; volume-down restored 12. Reopening the app retained authorization without another PIN prompt.
- Final screenshot: `docs/screenshots/mac-remote.png`, captured after closing and reopening through Control Center. No PIN, credentials, desktop content or TV photos are included.
- Not verified: deep-standby network wake, all individual commands on this TV, other TV models, and distribution/notarization. This is a locally signed personal build.


## Automatic appearance and app icons — 2026-10-30

- Removed forced dark schemes, fixed white foregrounds, and the Mac darkAqua override. Both apps inherit system appearance. Shared color assets provide light/dark backgrounds, D-pad surfaces and opaque fallback surfaces; foregrounds and separators use semantic colors. No theme preferences or buttons were added.
- Verified the running Mac app changes between light and dark when system appearance changes. Inspected main and Connection screens in both modes. Restored the Mac's original light appearance and confirmed its automatic-appearance setting remains enabled.
- Verified the running iOS simulator changes between light/dark via system appearance, including Connection and playback controls. Simulator uses the integrated display (display 1); its extra display defaults to a blank framebuffer and is not the app screen.
- Added original vector remote artwork and a reproducible AppKit renderer. iPhone icon files are 1024×1024 opaque RGB, with ordinary, dark and tinted variants. Mac contains all standard icon sizes in AppIcon.appiconset; the built bundle supplies CFBundleIconName/CFBundleIconFile and the compiled icon.
- Refreshed the installed Mac bundle registration and icon cache; NSWorkspace now resolves the custom remote icon instead of the generic placeholder.
- Passed 5 service tests, 2 iOS UI tests in light appearance, and the Mac UI test; additionally reran the iOS main/Connection/playback flow in dark appearance. Both signed builds succeeded.
- Updated test device iPhone 15 and the Mac installation. The physical iPhone screenshot confirms system light appearance and retained pairing (TV currently in standby). No TV power or volume commands were sent for this appearance update.
- Screenshots: iphone-remote-light/dark, iphone-settings-light/dark, mac-remote-light/dark, mac-settings-light/dark in docs/screenshots. Existing layout retained.
