# Key Balloons

一个 macOS 和 Windows 的桌面小工具。盒子浮在当前应用上方，每次敲键都会从盒口弹出一颗带按键标签的玻璃气球。每颗独立上升和淡出，约 2.8 秒消失。快速输入和重复按下同一个键都会追加气球。

键盘监听只为当前动画提供按键标签。应用在本机运行，按键不写入文件，也不会发送到网络。菜单栏或系统托盘提供暂停和退出。

## 构建

需要 CMake 3.21+、Qt 6.10.x 的桌面 SDK（包含 Qt Quick 和 Qt Quick Test），以及 Xcode 或 Visual Studio 2022 的 C++ 工具链。下例使用 Qt 6.10.3。

**macOS**

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$HOME/Qt/6.10.3/macos"
cmake --build build --parallel
ctest --test-dir build --output-on-failure
open build/KeyBalloons.app
```

点击菜单栏图标里的 **Enable monitoring…**，在系统设置的「隐私与安全性 → 输入监控」中开启 Key Balloons，必要时重启应用。

**Windows（PowerShell）**

```powershell
$qt = "$env:USERPROFILE/Qt/6.10.3/msvc2022_64"
$env:Path = "$qt/bin;$env:Path"
cmake -S . -B build -A x64 "-DCMAKE_PREFIX_PATH=$qt"
cmake --build build --config Release --parallel
ctest --test-dir build --build-config Release --output-on-failure
& "./build/Release/KeyBalloons.exe"
```

运行后在任务栏的通知区域找到 Key Balloons。Windows 使用 Raw Input 接收当前桌面会话的键盘事件。

## 结构和验证

- `qml/` 包含共用的置顶窗口、盒子和动画。每颗气球结束后只回收自己的元素。
- `src/macos/` 和 `src/windows/` 分别将系统键盘事件转换成按键标签。
- `tests/tst_balloons.qml` 覆盖相同键重复输入、不同到期时间和 60 个气球的突发输入。
- `tests/tst_stress.qml` 在可见窗口里模拟每秒 20 次输入，持续 30 秒。测试输出帧间隔及气球创建到下一帧的第 95 百分位。系统键盘事件到画面的总延迟需要另行实测。

在桌面上运行持续动画测试：

```sh
./build/key_balloons_tests -input tests/tst_stress.qml
```

Windows 使用 `./build/Release/key_balloons_tests.exe`。用 TextEdit 或记事本验证真实输入时，快速敲两次 `A` 再敲 `B`，检查编辑器仍有焦点、盒子保持置顶、点击能穿过透明层，三个气球先后升起并独立消失。验证清单见 [TODO.md](TODO.md)。
