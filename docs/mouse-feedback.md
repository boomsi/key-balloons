# Mouse feedback integration

[English](mouse-feedback.md) · [简体中文](mouse-feedback.zh.md) · [繁體中文](mouse-feedback.zh-TW.md) · [Français](mouse-feedback.fr.md) · [日本語](mouse-feedback.ja.md) · [한국어](mouse-feedback.ko.md) · [Español](mouse-feedback.es.md)

Right-click the box or choose **Settings…** from the menu bar or system tray. Under **Advanced**, turn on **Allow local mouse integrations**. Local integrations start disabled each time Key Balloons launches. Turning the option off disconnects third-party clients. The built-in box remains subscribed through a private connection and uses the same protocol.

## Connect

Read `mouse-feedback-v1.json` from the following location after enabling integrations. Each running instance has its own endpoint, so read the file again before reconnecting. Only one instance at a time can open the third-party endpoint for the current user.

| Platform | Descriptor path | Transport |
| --- | --- | --- |
| macOS | `~/Library/Application Support/Key Balloons/mouse-feedback-v1.json` | Unix domain socket |
| Windows | `%LOCALAPPDATA%\Key Balloons\mouse-feedback-v1.json` | Named pipe |

The descriptor has a `version` number and an `endpoint` string. Open a local connection using that string as the socket or pipe path. The endpoint is accessible to processes running as the same user.

## Send and receive events

Each message is one UTF-8 JSON object followed by a newline (`\n`). The maximum size is 512 bytes including the newline. Each message includes `"version":1`. Messages that exceed the limit cause the connection to close.

| Event | Native input | Built-in box |
| --- | --- | --- |
| `mouse.left` | Left button down | Left half flashes |
| `mouse.right` | Right button down | Right half flashes |
| `mouse.wheel` | Scroll in either direction or press the wheel | Center flashes |

To receive events on a connection, send `subscribe` once. The server acknowledges the subscription. Events published after that acknowledgement arrive as `event` messages without replay. A client can publish on the same connection, and subscribed publishers also receive their own events.

```jsonl
{"version":1,"op":"subscribe"}
{"version":1,"op":"ok","request":"subscribe"}
{"version":1,"op":"event","event":"mouse.left"}
```

To trigger feedback, send `publish` with one of the three event names. It flashes the built-in box and delivers the event to subscribers. `publish` triggers visual feedback without generating system mouse input. Native monitoring can be paused independently of third-party publishing. On macOS, native events require Input Monitoring permission.

```jsonl
{"version":1,"op":"publish","event":"mouse.right"}
{"version":1,"op":"ok","request":"publish"}
```

Invalid requests return `{"version":1,"op":"error","code":"…"}`. Codes are `invalid_message`, `unsupported_version`, `unsupported_operation`, and `unsupported_event`. An acknowledgement means the request was accepted. Event messages carry only the action name. Slow clients may be disconnected and should reconnect and resubscribe to resume delivery.

## Run the example

With Node.js installed and local integrations enabled, run these commands from the repository root in two terminals. The watcher prints the subscription acknowledgement and subsequent events.

```sh
node examples/mouse-feedback.mjs watch
```

```sh
node examples/mouse-feedback.mjs mouse.left
node examples/mouse-feedback.mjs mouse.right
node examples/mouse-feedback.mjs mouse.wheel
```

For an example of consuming events in a graphical app, see [the built-in box subscriber](../examples/basic-box/overlay_mouse_client.cpp).
