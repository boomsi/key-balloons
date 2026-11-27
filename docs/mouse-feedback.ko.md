# 마우스 피드백 연동

[English](mouse-feedback.md) · [简体中文](mouse-feedback.zh.md) · [繁體中文](mouse-feedback.zh-TW.md) · [Français](mouse-feedback.fr.md) · [日本語](mouse-feedback.ja.md) · [한국어](mouse-feedback.ko.md) · [Español](mouse-feedback.es.md)

상자를 오른쪽 클릭하거나 메뉴 막대 또는 알림 영역에서 **설정…**을 엽니다. **고급**에서 **로컬 마우스 연동 허용**을 켭니다. 앱을 새로 시작할 때는 기본적으로 꺼져 있습니다. 끄면 외부 클라이언트와의 연결이 끊어집니다. 내장 상자는 비공개 연결에서 같은 프로토콜로 구독을 유지합니다.

## 연결

연동을 켠 뒤 아래 경로의 `mouse-feedback-v1.json`을 읽습니다. 실행 인스턴스마다 엔드포인트가 달라 재연결 전에 파일을 다시 읽어야 합니다. 동일한 사용자는 동시에 한 인스턴스에서만 외부 연결을 열 수 있습니다.

| 플랫폼 | 설명 파일 경로 | 전송 방식 |
| --- | --- | --- |
| macOS | `~/Library/Application Support/Key Balloons/mouse-feedback-v1.json` | Unix 도메인 소켓 |
| Windows | `%LOCALAPPDATA%\Key Balloons\mouse-feedback-v1.json` | 명명된 파이프 |

설명 파일에는 숫자 `version`과 문자열 `endpoint`가 있습니다. `endpoint`를 로컬 소켓 또는 파이프 경로로 사용합니다. 동일한 사용자로 실행되는 로컬 프로세스가 연결할 수 있습니다.

## 이벤트 전송 및 수신

메시지 하나는 UTF-8 JSON 객체 하나와 끝의 줄바꿈(`\n`)으로 구성됩니다. 줄바꿈 포함 최대 512바이트이며 `"version":1`이 있어야 합니다. 이 한도를 초과하면 연결이 끊어집니다.

| 이벤트 | 네이티브 입력 | 내장 상자 |
| --- | --- | --- |
| `mouse.left` | 왼쪽 버튼 누름 | 왼쪽 절반이 켜짐 |
| `mouse.right` | 오른쪽 버튼 누름 | 오른쪽 절반이 켜짐 |
| `mouse.wheel` | 수직·수평 스크롤 또는 휠 누름 | 가운데가 켜짐 |

연결에서 `subscribe`를 한 번 보냅니다. 서버가 확인한 뒤 새 이벤트가 `event` 메시지로 도착합니다. 이전 이벤트는 다시 보내지 않습니다. 같은 연결에서 발행과 구독을 할 수 있으며, 발행한 클라이언트도 자신이 구독 중이면 해당 이벤트를 받습니다.

```jsonl
{"version":1,"op":"subscribe"}
{"version":1,"op":"ok","request":"subscribe"}
{"version":1,"op":"event","event":"mouse.left"}
```

표에서 이벤트 하나를 골라 `publish`로 보내면 상자의 해당 영역이 켜지고 구독자에게도 이벤트가 전달됩니다. 발행은 시각적 효과만 일으킵니다. 네이티브 모니터링이 일시 정지되어도 외부에서 발행할 수 있습니다. macOS에서 네이티브 이벤트를 받으려면 입력 모니터링 권한이 필요합니다.

```jsonl
{"version":1,"op":"publish","event":"mouse.right"}
{"version":1,"op":"ok","request":"publish"}
```

유효하지 않은 요청에는 `{"version":1,"op":"error","code":"…"}`가 반환됩니다. 오류 코드는 `invalid_message`, `unsupported_version`, `unsupported_operation`, `unsupported_event`입니다. 확인 응답은 요청이 수락됐음을 뜻합니다. 이벤트에는 동작 이름만 들어 있습니다. 읽기 속도가 너무 느린 클라이언트는 연결이 끊어질 수 있습니다. 다시 연결해 구독을 재개하세요.

## 예제 실행

Node.js를 설치하고 로컬 연동을 켠 뒤 저장소 루트의 터미널 두 곳에서 실행합니다. 감시 명령은 구독 확인과 이후 이벤트를 출력합니다.

```sh
node examples/mouse-feedback.mjs watch
```

```sh
node examples/mouse-feedback.mjs mouse.left
node examples/mouse-feedback.mjs mouse.right
node examples/mouse-feedback.mjs mouse.wheel
```

그래픽 앱 예제로는 [내장 상자 구독 구현](../examples/basic-box/overlay_mouse_client.cpp)을 참고하세요.
