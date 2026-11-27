# 滑鼠回饋整合

[English](mouse-feedback.md) · [简体中文](mouse-feedback.zh.md) · [繁體中文](mouse-feedback.zh-TW.md) · [Français](mouse-feedback.fr.md) · [日本語](mouse-feedback.ja.md) · [한국어](mouse-feedback.ko.md) · [Español](mouse-feedback.es.md)

在盒子上按右鍵，或從選單列／通知區域選擇 **設定…**。在 **進階** 開啟 **允許本機滑鼠整合**。每次啟動時預設關閉。關閉時會中斷第三方連線，內建盒子仍透過私有連線使用相同協定。

## 建立連線

開啟整合後，讀取下列位置的 `mouse-feedback-v1.json`。重新連線前請重新讀取檔案，因為每個執行個體都有自己的端點。同一使用者同時只能有一個執行個體開放第三方端點。

| 平台 | 描述檔路徑 | 傳輸方式 |
| --- | --- | --- |
| macOS | `~/Library/Application Support/Key Balloons/mouse-feedback-v1.json` | Unix 網域通訊端 |
| Windows | `%LOCALAPPDATA%\Key Balloons\mouse-feedback-v1.json` | 具名管道 |

描述檔含數字 `version` 與字串 `endpoint`。使用 `endpoint` 作為通訊端或管道路徑。端點提供給同一使用者執行的本機程式。

## 傳送與接收事件

每則訊息是一個 UTF-8 JSON 物件，以換行字元（`\n`）結束。每則上限 512 位元組，包含換行字元，並且帶有 `"version":1`。訊息過長會中斷連線。

| 事件 | 原生輸入 | 盒子效果 |
| --- | --- | --- |
| `mouse.left` | 按下左鍵 | 左半部亮起 |
| `mouse.right` | 按下右鍵 | 右半部亮起 |
| `mouse.wheel` | 垂直或水平捲動，或按下滾輪 | 中央亮起 |

在連線上傳送一次 `subscribe`。服務端確認後，用 `event` 傳送新事件。訂閱不會重播舊事件。同一連線可同時發布與訂閱，訂閱者也會收到自己發布的事件。

```jsonl
{"version":1,"op":"subscribe"}
{"version":1,"op":"ok","request":"subscribe"}
{"version":1,"op":"event","event":"mouse.left"}
```

傳送 `publish` 和上表的事件名稱即可點亮相應區域，訂閱者也會收到事件。發布只觸發視覺效果。第三方可以在原生監聽暫停時發布。macOS 的原生事件需要輸入監控權限。

```jsonl
{"version":1,"op":"publish","event":"mouse.right"}
{"version":1,"op":"ok","request":"publish"}
```

無效請求會回傳 `{"version":1,"op":"error","code":"…"}`。錯誤碼為 `invalid_message`、`unsupported_version`、`unsupported_operation` 和 `unsupported_event`。確認代表已接受請求。事件只含動作名稱。讀取太慢的程式可能被中斷，重新連線並訂閱後可繼續接收。

## 執行範例

裝好 Node.js 並開啟本機整合後，在專案根目錄用兩個終端機執行。監看程式會顯示訂閱確認和後續事件。

```sh
node examples/mouse-feedback.mjs watch
```

```sh
node examples/mouse-feedback.mjs mouse.left
node examples/mouse-feedback.mjs mouse.right
node examples/mouse-feedback.mjs mouse.wheel
```

圖形介面可參考[內建盒子的訂閱實作](../examples/basic-box/overlay_mouse_client.cpp)。
