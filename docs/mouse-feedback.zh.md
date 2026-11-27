# 鼠标反馈接入协议

[English](mouse-feedback.md) · [简体中文](mouse-feedback.zh.md) · [繁體中文](mouse-feedback.zh-TW.md) · [Français](mouse-feedback.fr.md) · [日本語](mouse-feedback.ja.md) · [한국어](mouse-feedback.ko.md) · [Español](mouse-feedback.es.md)

右键盒子，或从菜单栏、通知区域选择 **设置…**。在 **高级** 开启 **允许本机鼠标接入**。每次启动 Key Balloons 时，第三方接入默认关闭。取消勾选会断开第三方客户端。内置盒子通过私有连接订阅同一协议，继续显示鼠标反馈。

## 建立连接

开启接入后，从下面的位置读取 `mouse-feedback-v1.json`。每个运行实例有自己的端点，重连前请重新读取文件。同一用户同一时间只能有一个实例开放第三方端点。

| 平台 | 描述文件路径 | 传输方式 |
| --- | --- | --- |
| macOS | `~/Library/Application Support/Key Balloons/mouse-feedback-v1.json` | Unix 域套接字 |
| Windows | `%LOCALAPPDATA%\Key Balloons\mouse-feedback-v1.json` | 命名管道 |

描述文件包含数字 `version` 和字符串 `endpoint`。用 `endpoint` 作为套接字或命名管道路径建立本机连接。端点提供给同一用户运行的本机进程使用。

## 发送和接收事件

每条消息是一个 UTF-8 JSON 对象，末尾带换行符（`\n`）。单条消息上限为 512 字节，包含换行符。每条消息带 `"version":1`。消息超长时，服务端会断开连接。

| 事件 | 原生输入 | 内置盒子反馈 |
| --- | --- | --- |
| `mouse.left` | 按下左键 | 左半边亮 |
| `mouse.right` | 按下右键 | 右半边亮 |
| `mouse.wheel` | 纵向或横向滚动，或按下滚轮 | 中间亮 |

要接收事件，在连接上发送一次 `subscribe`。服务端确认订阅后，新事件会通过 `event` 消息送达。每次订阅只接收之后的事件。同一个连接也可以发布，发布者自己订阅时也会收到该事件。

```jsonl
{"version":1,"op":"subscribe"}
{"version":1,"op":"ok","request":"subscribe"}
{"version":1,"op":"event","event":"mouse.left"}
```

要触发反馈，发送 `publish`，并填写上表中的一个事件名。内置盒子对应区域会亮起，订阅者也会收到事件。`publish` 只触发显示反馈。暂停原生监听后，第三方仍可以发布事件。macOS 上的原生鼠标事件需要输入监控权限。

```jsonl
{"version":1,"op":"publish","event":"mouse.right"}
{"version":1,"op":"ok","request":"publish"}
```

无效请求会收到 `{"version":1,"op":"error","code":"…"}`。错误码包括 `invalid_message`、`unsupported_version`、`unsupported_operation` 和 `unsupported_event`。确认消息表示请求已被接收。事件消息只包含动作名。读取过慢的客户端可能被断开，重新连接并订阅即可继续接收。

## 运行示例

安装 Node.js 并开启本机接入后，在仓库根目录的两个终端分别运行。订阅端会输出订阅确认和后续事件。

```sh
node examples/mouse-feedback.mjs watch
```

```sh
node examples/mouse-feedback.mjs mouse.left
node examples/mouse-feedback.mjs mouse.right
node examples/mouse-feedback.mjs mouse.wheel
```

图形界面接入可以参考 [内置盒子的订阅实现](../examples/basic-box/overlay_mouse_client.cpp)。
