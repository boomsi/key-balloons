# Key Balloons

[English](TODO.en.md) · [简体中文](TODO.md) · [繁體中文](TODO.zh-TW.md) · [Français](TODO.fr.md) · [日本語](TODO.ja.md) · [한국어](TODO.ko.md) · [Español](TODO.es.md)

## 第一版

- [x] 採用共用的 C++ 和 Qt Quick，平台程式碼只處理系統事件和視窗行為。
- [x] 為重複按鍵、獨立消失和快速輸入撰寫自動化測試。
- [x] 實作半透明置頂盒子及在三秒內逐一上升、淡出的按鍵標籤。
- [x] 在 macOS 與 Windows 接入全域鍵盤監聽、暫停和結束。
- [x] 在 macOS 建置、執行動畫自動化測試及靜態檢查 QML。
- [x] 在 macOS 實機確認懸浮視窗置頂、原視窗保有焦點，且點擊會送到下層視窗。
- [x] 在 macOS 模擬每秒 20 次輸入，持續 30 秒。600 次都成功產生並回收，最多同時顯示 59 個。標籤產生到下一個 Qt 畫面的第 95 百分位是 12 毫秒。
- [x] 在 macOS 抽樣閒置 CPU 用量，兩次皆為 0.0%。
- [x] 在 macOS 和 Windows 執行 CI 建置與動畫自動化測試。 [建置紀錄](https://github.com/boomsi/key-balloons/actions/runs/45830723721)
- [ ] 在兩個平台以實體鍵盤確認跨 App 輸入，並在 Windows 實機確認置頂、焦點和點擊穿透。
- [ ] 量測實際按鍵到顯示的延遲，以及 Windows 持續動畫的畫面間隔。
- [ ] 確認按住按鍵自動重複與「跟隨系統」的行為。初版顯示實際按鍵，盒子位於主要螢幕。
- [x] 提交第一版並推送至新建的公開儲存庫。
