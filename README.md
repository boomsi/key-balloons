# Key Balloons

<img src="assets/KeyBalloons.svg" alt="Key Balloons 应用图标" width="112">

一个 macOS 和 Windows 的桌面小工具。盒子浮在当前应用上方，每次敲键都会从盒口弹出一颗带按键标签的玻璃气球。每颗独立上升和淡出，约 2.8 秒消失。快速输入和重复按下同一个键都会追加气球。

键盘监听只为当前动画提供按键标签。应用在本机运行，按键不写入文件，也不会发送到网络。菜单栏或系统托盘提供暂停和退出。

## 安装

从 [GitHub Releases](https://github.com/boomsi/key-balloons/releases) 下载对应的安装包。

- **macOS** 打开通用版 `.dmg`，把 **KeyBalloons.app** 拖进「应用程序」，再从那里启动。首次使用时，从菜单栏图标选择 **Enable monitoring…**，在「系统设置 → 隐私与安全性 → 输入监控」里开启 Key Balloons，必要时重新打开应用。
- **Windows** 运行 x64 `.exe` 安装程序，从开始菜单启动 **Key Balloons**。应用图标会显示在任务栏的通知区域。

## 使用

- 切到常用应用直接打字。盒子保持置顶，每次实际按键都生成一颗独立气球。
- 左键按住盒子拖到想要的位置。右键打开设置，勾选 **Allow dragging** 可以拖动，取消勾选可以锁定位置。
- 右键菜单里的 **Opacity** 滑块在 **20%–100%** 之间实时调节盒子和气球。百分比越低，画面越透明。
- 从 macOS 菜单栏或 Windows 通知区域图标打开菜单，可以暂停监听或退出。

## 构建

需要 CMake 3.21+、Qt 6.10.x 的桌面 SDK（包含 Qt Quick 和 Qt Quick Test），以及 Xcode 或 Visual Studio 2022 的 C++ 工具链。下例使用 Qt 6.10.3。

**macOS**

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$HOME/Qt/6.10.3/macos"
cmake --build build --parallel
ctest --test-dir build --output-on-failure
open build/KeyBalloons.app
```

**Windows（PowerShell）**

```powershell
$qt = "$env:USERPROFILE/Qt/6.10.3/msvc2022_64"
$env:Path = "$qt/bin;$env:Path"
cmake -S . -B build -A x64 "-DCMAKE_PREFIX_PATH=$qt"
cmake --build build --config Release --parallel
ctest --test-dir build --build-config Release --output-on-failure
& "./build/Release/KeyBalloons.exe"
```

## 发布安装包

在 GitHub 发布 Release 后，**Release installers** 会从该 Release 的标签构建两端安装包。两端都通过测试后，工作流会把 macOS 通用版 `.dmg` 和 Windows x64 安装程序 `.exe` 附到同一 Release。

也可以在 **Actions → Release installers → Run workflow** 手动演练，从该次运行的 **Artifacts** 下载两个安装包。

macOS 包内的 App 使用临时签名。Apple 公证和 Windows 发行签名需要各平台的发行凭据。

## 结构和验证

- `qml/` 包含共用的置顶窗口、盒子和动画。每颗气球结束后只回收自己的元素。
- `src/macos/` 和 `src/windows/` 分别将系统键盘事件转换成按键标签。
- `tests/tst_balloons.qml` 覆盖快速连敲、独立到期、拖动锁定、动画跟随和透明度调节。
- `tests/tst_stress.qml` 在可见窗口里模拟每秒 20 次输入，持续 30 秒。测试输出帧间隔及气球创建到下一帧的第 95 百分位。系统键盘事件到画面的总延迟需要另行实测。

在桌面上可以运行持续动画测试。

```sh
./build/key_balloons_tests -input tests/tst_stress.qml
```

Windows 使用 `./build/Release/key_balloons_tests.exe`。用 TextEdit 或记事本验证真实输入时，快速敲两次 `A` 再敲 `B`，检查编辑器仍有焦点、盒子保持置顶、点击能穿过透明层，三个气球先后升起并独立消失。验证清单见 [TODO.md](TODO.md)。
