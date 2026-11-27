# マウスフィードバック連携

[English](mouse-feedback.md) · [简体中文](mouse-feedback.zh.md) · [繁體中文](mouse-feedback.zh-TW.md) · [Français](mouse-feedback.fr.md) · [日本語](mouse-feedback.ja.md) · [한국어](mouse-feedback.ko.md) · [Español](mouse-feedback.es.md)

ボックスを右クリックするか、メニューバーまたは通知領域から **設定…** を開きます。**詳細設定** の **ローカルマウス連携を許可** をオンにします。起動時は毎回オフです。オフにすると外部クライアントが切断されます。内蔵ボックスはプライベート接続で同じプロトコルを使って購読を続けます。

## 接続

連携を有効にしたら、下記の `mouse-feedback-v1.json` を読み込みます。実行中のインスタンスごとに接続先が異なるため、再接続の前にファイルを読み直してください。同じユーザーについて、外部向け接続先を公開できるインスタンスは同時に 1 つです。

| プラットフォーム | 記述ファイルの場所 | 接続方式 |
| --- | --- | --- |
| macOS | `~/Library/Application Support/Key Balloons/mouse-feedback-v1.json` | Unix ドメインソケット |
| Windows | `%LOCALAPPDATA%\Key Balloons\mouse-feedback-v1.json` | 名前付きパイプ |

記述ファイルには数値の `version` と文字列の `endpoint` が含まれます。`endpoint` をローカルソケットまたはパイプのパスに使います。同じユーザーで動くプロセスから接続できます。

## イベントの送受信

各メッセージは UTF-8 の JSON オブジェクト 1 つと、末尾の改行（`\n`）で構成されます。上限は改行を含めて 512 バイトです。すべてのメッセージに `"version":1` が必要です。上限を超えると接続が切断されます。

| イベント | ネイティブ入力 | 内蔵ボックス |
| --- | --- | --- |
| `mouse.left` | 左ボタンを押す | 左半分が光る |
| `mouse.right` | 右ボタンを押す | 右半分が光る |
| `mouse.wheel` | 縦・横スクロール、またはホイールを押す | 中央が光る |

接続ごとに `subscribe` を一度送信します。サーバーの確認後に発生したイベントが `event` として届きます。過去のイベントは再送されません。同じ接続で配信することもでき、購読者は自分の配信も受け取ります。

```jsonl
{"version":1,"op":"subscribe"}
{"version":1,"op":"ok","request":"subscribe"}
{"version":1,"op":"event","event":"mouse.left"}
```

ボックスを光らせるには、表のイベント名とともに `publish` を送ります。購読者にもイベントが届きます。配信が起こすのは表示上の反応だけです。ネイティブ監視の一時停止中も外部から配信できます。macOS のネイティブイベントには入力監視の許可が必要です。

```jsonl
{"version":1,"op":"publish","event":"mouse.right"}
{"version":1,"op":"ok","request":"publish"}
```

無効なリクエストには `{"version":1,"op":"error","code":"…"}` が返ります。コードは `invalid_message`、`unsupported_version`、`unsupported_operation`、`unsupported_event` です。確認メッセージは受付を表します。イベントの内容はアクション名のみです。読み取りが遅いクライアントは切断されることがあります。再接続して購読し直してください。

## サンプルを実行する

Node.js をインストールしてローカル連携を有効にし、リポジトリのルートで端末を 2 つ開いて実行します。監視側は購読確認と後続イベントを出力します。

```sh
node examples/mouse-feedback.mjs watch
```

```sh
node examples/mouse-feedback.mjs mouse.left
node examples/mouse-feedback.mjs mouse.right
node examples/mouse-feedback.mjs mouse.wheel
```

グラフィカルな例は[内蔵ボックスの購読実装](../examples/basic-box/overlay_mouse_client.cpp)を参照してください。
