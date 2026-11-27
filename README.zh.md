# <img src="assets/KeyBalloons.svg" alt="Key Balloons 应用图标" width="36"> Key Balloons

[English](README.md) · [简体中文](README.zh.md) · [繁體中文](README.zh-TW.md) · [Français](README.fr.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md)

Key Balloons 是一个 macOS 和 Windows 的桌面小工具。在任何应用里打字时，带细描边的按键字符会从悬浮盒口弹出，约 2 秒后淡出。每次按键都会产生独立动画，连续按同一个键也会逐个显示。

**[下载安装包](https://github.com/boomsi/key-balloons/releases)** · [安装](#安装) · [使用](#使用) · [从源码构建](#从源码构建) · [接入指南](docs/mouse-feedback.zh.md)

![Key Balloons 演示：输入 kissmenow 时，按键从盒子里浮起](assets/key-balloons-demo.gif)

> 键盘输入只在本机用来显示动画。应用不会保存按键记录或把按键发送到网络。

## 安装

从 [GitHub Releases](https://github.com/boomsi/key-balloons/releases) 下载对应的安装包。

| 平台 | 安装步骤 |
| --- | --- |
| macOS | 打开通用版 `.dmg`，把 **KeyBalloons.app** 拖进「应用程序」，再从那里启动。 |
| Windows | 运行 x64 `.exe` 安装程序，从开始菜单打开 **Key Balloons**。 |

### 在 macOS 上开启输入监控

1. 如果启动时提示需要权限，点 **Open Input Monitoring**。也可以稍后从菜单栏选择 **Enable monitoring…**。
2. 系统会打开「隐私与安全性 → 输入监控」。把窗口下方卡片里的 **Key Balloons** 图标拖进列表。
3. 在系统设置里打开开关。应用检测到权限生效后会收起卡片。如果 macOS 提示退出并重新打开应用，按系统提示操作。

更新后，系统列表可能仍显示旧版的授权。先选中旧条目，点 **−** 移除，再拖入并开启新版。

## 使用

切到常用应用直接打字。盒子保持置顶，每次实际按键都显示一个字符。

左键、右键、滚动或按下滚轮对应点亮左侧、右侧和中间。在 **高级** 开启本机鼠标接入，即可[发送或订阅鼠标反馈事件](docs/mouse-feedback.zh.md)。

### 设置

右键盒子，或从菜单栏、通知区域选择 **Settings…（设置…）**，都会打开同一个面板。

- 在 **外观** 调整 **大小**（50%–150%）和 **不透明度**（20%–100%），同时作用于盒子和浮动字符。
- 在 **位置** 开启 **允许拖动** 后，可以按住左键移动盒子。勾选 **自动贴底**，松手时会吸附到最近屏幕的可用区域底边。
- **语言** 可以即时切换，选择会保存。首次使用默认为英文。
- 菜单栏或通知区域显示应用当前内存占用和监听状态，也可以暂停、恢复监听或退出。

使用 Xcode 26 或更新版本构建时，macOS 26 上的设置使用系统 Liquid Glass 弹出面板和原生控件。
在 macOS 上切换桌面时，盒子会留在原位置，动画跟着盒子一起显示。

## 从源码构建

需要 CMake 3.21 或更新版本、含 Qt Quick、Qt Quick Test 和 Qt Linguist 工具的 Qt 6.10 桌面 SDK，以及 Xcode 或 Visual Studio 2022 的 C++ 工具链。以下示例使用 Qt 6.10.3。

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

## 发布安装包

发布 GitHub Release 会启动 **Release installers**。工作流从该 Release 的标签构建并运行测试。两端都验证通过后，macOS 通用版 `.dmg` 和 Windows x64 `.exe` 会附到同一个 Release。

在 **Actions → Release installers → Run workflow** 可以手动演练打包。两个安装包会出现在该次运行的 **Artifacts** 中。

macOS 包内的应用使用临时签名。Apple 公证和 Windows 发行签名需要各平台的发行凭据。

## 项目结构和测试

- [`examples/basic-box/`](examples/basic-box/) 包含内置盒子示例、动画和鼠标反馈订阅代码。
- `src/macos/` 和 `src/windows/` 分别处理各平台的键盘事件。macOS 模块还负责原生设置菜单和输入监控引导。
- `tests/tst_balloons.qml` 覆盖快速连敲、独立到期、拖动、鼠标反馈和设置。`tests/tst_overlay_core.cpp` 覆盖屏幕定位、本机接入、翻译和内存读取。
- `tests/tst_stress.qml` 模拟每秒 20 次输入、持续 30 秒，输出帧间隔与字符创建到下一 Qt 帧的第 95 百分位。真实按键到显示的总延迟需要另行实测。

在桌面上可以运行持续动画测试。

```sh
./build/key_balloons_tests -input tests/tst_stress.qml
```

Windows 使用 `./build/Release/key_balloons_tests.exe`。也可以在 TextEdit 或记事本里敲 `A A B`，确认编辑器仍然有焦点，三个字符先后上升并独立消失。验证清单见 [TODO.md](TODO.md)。
