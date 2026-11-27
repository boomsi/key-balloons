# <img src="assets/KeyBalloons.svg" alt="Key Balloons App 圖像" width="36"> Key Balloons

[English](README.md) · [简体中文](README.zh.md) · [繁體中文](README.zh-TW.md) · [Français](README.fr.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md)

Key Balloons 是 macOS 和 Windows 的桌面懸浮工具。在任何 App 打字時，帶有輪廓的按鍵標籤會從懸浮盒升起，約兩秒後淡出。每次按鍵都有獨立動畫，重複按同一鍵也是如此。

**[下載安裝程式](https://github.com/boomsi/key-balloons/releases)** · [安裝](#安裝) · [使用](#使用) · [從原始碼建置](#從原始碼建置) · [整合指南](docs/mouse-feedback.zh-TW.md)

![Key Balloons 示範：輸入 star now 時，按鍵從盒子浮起](assets/key-balloons-demo.gif)

> 鍵盤輸入只在本機用於顯示動畫。App 不會保留按鍵記錄，也不會透過網路傳送按鍵。

## 安裝

從 [GitHub Releases](https://github.com/boomsi/key-balloons/releases) 下載對應安裝程式。

| 平台 | 安裝步驟 |
| --- | --- |
| macOS | 開啟通用版 `.dmg`，把 **KeyBalloons.app** 拖到「應用程式」並從那裡開啟。 |
| Windows | 執行 x64 `.exe` 安裝程式，再從「開始」功能表開啟 **Key Balloons**。 |

### macOS 的輸入監控

1. 啟動時若有權限提示，選擇 **開啟輸入監控**。也能從選單列選擇 **啟用監聽…**。
2. 在「系統設定 → 隱私權與安全性 → 輸入監控」中，將提示卡上的 Key Balloons 圖像拖入清單。
3. 開啟開關。App 偵測到權限後會關閉提示卡。如果系統要求結束並重新開啟 App，依畫面指示操作。

更新後若清單仍顯示舊版本，使用 **−** 移除舊項目，再加入目前版本並開啟權限。

## 使用

在一般 App 打字，懸浮盒保持置頂，每次實際按鍵顯示一個標籤。

左鍵、右鍵及滾動或按下滾輪分別點亮左側、右側和中央。在 **進階** 可啟用[滑鼠回饋整合](docs/mouse-feedback.zh-TW.md)。

### 設定

在盒子上按右鍵，或在選單列或通知區域選擇 **Settings…（設定…）**，都會開啟同一個面板。

- 在 **外觀** 調整 **大小**（50%–150%）與 **不透明度**（20%–100%）。盒子和標籤會一起調整。
- 在 **位置** 開啟 **允許拖移** 後可按住左鍵移動盒子。開啟 **自動貼齊螢幕底部** 後，放開時會貼到最近螢幕的可用區域底部。
- **語言** 會立即切換介面並儲存所選語言。預設是英文。
- 選單列或通知區域會顯示 App 的記憶體用量與監聽狀態，也可用來暫停、恢復監聽或結束 App。

以 Xcode 26 或更新版本建置時，macOS 26 上的設定會使用原生 Liquid Glass 彈出面板。切換 macOS 的桌面空間時，盒子與動畫會一同留在所選位置。

## 從原始碼建置

需要 CMake 3.21 或更新版本，內含 Qt Quick、Qt Quick Test 及 Qt Linguist 工具的 Qt 6.10 桌面 SDK，以及 Xcode 或 Visual Studio 2022 的 C++ 工具鏈。以下範例使用 Qt 6.10.3。

### macOS

```sh
cmake -S . -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DKEY_BALLOONS_DEVELOPMENT_BUILD=ON \
  -DCMAKE_PREFIX_PATH="$HOME/Qt/6.10.3/macos"
cmake --build build --parallel
ctest --test-dir build --output-on-failure
open build/KeyBalloonsDev.app
```

### Windows（PowerShell）

```powershell
$qt = "$env:USERPROFILE/Qt/6.10.3/msvc2022_64"
$env:Path = "$qt/bin;$env:Path"
cmake -S . -B build -A x64 "-DCMAKE_PREFIX_PATH=$qt"
cmake --build build --config Release --parallel
ctest --test-dir build --build-config Release --output-on-failure
& "./build/Release/KeyBalloons.exe"
```

## 發布安裝程式

發布 GitHub Release 會啟動 **Release installers**。工作流程從該版本標籤建置並執行測試，驗證後附上 macOS 通用版 `.dmg` 和 Windows x64 `.exe`。

也可透過 **Actions → Release installers → Run workflow** 測試打包。兩個安裝程式會出現在這次執行的 **Artifacts** 中。macOS 套件使用臨時簽章。Apple 公證和 Windows 發布簽章需要各平台的憑證。

## 專案結構與測試

- [`examples/basic-box/`](examples/basic-box/) 包含內建盒子範例、動畫和滑鼠回饋訂閱程式。
- `src/macos/` 與 `src/windows/` 處理平台輸入。macOS 模組也提供原生設定和輸入監控引導。
- `tests/tst_balloons.qml` 測試快速輸入、獨立消失、拖移、滑鼠回饋和設定。`tests/tst_overlay_core.cpp` 測試定位、本機整合、語言和記憶體讀取。
- `tests/tst_stress.qml` 模擬每秒 20 次輸入，持續 30 秒，報告畫面更新間隔和標籤建立到下一個 Qt 畫面的第 95 百分位。實體按鍵到顯示的延遲需要另外量測。

在桌面上執行持續動畫測試。

```sh
./build/key_balloons_tests -input tests/tst_stress.qml
```

Windows 使用 `./build/Release/key_balloons_tests.exe`。也可在「文字編輯」或「記事本」輸入 `A A B`，確認編輯器保持焦點，三個標籤分別升起並消失。
