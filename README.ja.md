# <img src="assets/KeyBalloons.svg" alt="Key Balloons のアイコン" width="36"> Key Balloons

[English](README.md) · [简体中文](README.zh.md) · [繁體中文](README.zh-TW.md) · [Français](README.fr.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md)

Key Balloons は macOS と Windows 用のデスクトップオーバーレイです。どのアプリで入力しても、輪郭付きのキーラベルがフローティングボックスから浮かび、約 2 秒で消えます。同じキーを繰り返し押しても、押すたびに個別にアニメーションします。

**[ダウンロード](https://github.com/boomsi/key-balloons/releases)** · [インストール](#インストール) · [使い方](#使い方) · [ソースからビルドする](#ソースからビルドする) · [連携ガイド](docs/mouse-feedback.ja.md)

![Key Balloons のデモ。kissmenow と入力するとキーがボックスから浮かびます](assets/key-balloons-demo.gif)

> キー入力は端末上でアニメーションを表示するために使われます。入力履歴は保存せず、キー入力をネットワークに送信することもありません。

## インストール

[GitHub Releases](https://github.com/boomsi/key-balloons/releases) から対応するインストーラーをダウンロードします。

| プラットフォーム | インストール手順 |
| --- | --- |
| macOS | ユニバーサル版の `.dmg` を開き、**KeyBalloons.app** を「アプリケーション」にドラッグして、そこから起動します。 |
| Windows | x64 の `.exe` インストーラーを実行し、スタートメニューから **Key Balloons** を起動します。 |

### macOS で入力監視を許可する

1. 起動時に許可を求められたら **入力監視を開く** を選択します。メニューバーの **監視を有効にする…** からも開けます。
2. 「システム設定 → プライバシーとセキュリティ → 入力監視」で、案内カードの Key Balloons アイコンを一覧にドラッグします。
3. スイッチをオンにします。許可が反映されると案内カードが閉じます。macOS にアプリを終了して開き直すよう表示された場合は、表示に従ってください。

更新後に古い項目が残っていたら **−** で削除し、現在のアプリを追加して許可します。

## 使い方

普段のアプリで入力すると、最前面のボックスに押したキーごとのラベルが表示されます。

左クリック、右クリック、スクロールまたはホイールの押し込みで、それぞれ左側、右側、中央が光ります。**詳細設定** から[ローカルマウス連携](docs/mouse-feedback.ja.md)を有効にできます。

### 設定

ボックスの右クリックとメニューバーまたは通知領域の **Settings…（設定…）** は、同じ設定パネルを開きます。

- **外観** の **サイズ**（50%～150%）と **不透明度**（20%～100%）は、ボックスとラベルの両方に反映されます。
- **位置** で **ドラッグを許可** をオンにすると左ボタンで移動できます。**画面下端に吸着** は、ボタンを放したときに最も近い画面の使用可能領域の下端に配置します。
- **言語** の変更はすぐに反映され、次回の起動にも引き継がれます。初期設定は英語です。
- メニューにはアプリのメモリ使用量と監視の状態が表示されます。監視の一時停止と再開、アプリの終了もここから行えます。

Xcode 26 以降でビルドした場合、macOS 26 ではネイティブの Liquid Glass パネルが使われます。macOS で操作スペースを切り替えても、ボックスとアニメーションは設定した位置を保ちます。

## ソースからビルドする

CMake 3.21 以降、Qt Quick、Qt Quick Test、Qt Linguist のツールを含む Qt 6.10 デスクトップ SDK、Xcode または Visual Studio 2022 の C++ ツールチェーンが必要です。以下の例では Qt 6.10.3 を使用します。

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

## リリース用インストーラー

GitHub でリリースを公開すると **Release installers** が起動します。ワークフローはリリースタグからビルドしてテストし、検証後に macOS ユニバーサル版 `.dmg` と Windows x64 `.exe` を添付します。

**Actions → Release installers → Run workflow** からパッケージ作成を試せます。両方のインストーラーは実行結果の **Artifacts** に表示されます。macOS 版の署名は ad hoc 方式です。Apple の公証や Windows の配布用署名には、各プラットフォームの資格情報が必要です。

## 構成とテスト

- [`examples/basic-box/`](examples/basic-box/) には内蔵ボックスの例とアニメーション、マウスフィードバックの購読コードがあります。
- `src/macos/` と `src/windows/` は各プラットフォームの入力を扱います。macOS コードはネイティブ設定と入力監視の案内も担当します。
- `tests/tst_balloons.qml` は連続入力、独立した表示終了、ドラッグ、マウス表示、設定をテストします。`tests/tst_overlay_core.cpp` は画面配置、ローカル連携、翻訳、メモリ取得をテストします。
- `tests/tst_stress.qml` は毎秒 20 回の入力を 30 秒間模擬し、フレーム間隔とラベル生成から次の Qt フレームまでの時間の 95 パーセンタイルを報告します。実際のキー入力から表示までの遅延は別途測定が必要です。

デスクトップ環境でアニメーションの連続テストを実行します。

```sh
./build/key_balloons_tests -input tests/tst_stress.qml
```

Windows では `./build/Release/key_balloons_tests.exe` を使用します。簡単な動作確認には、テキストエディットやメモ帳で `A A B` と入力してください。エディターのフォーカスを保ったまま、3 つのラベルが個別に表示されて消えます。[テストチェックリスト](TODO.ja.md)も参照できます。
