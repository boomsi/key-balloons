# <img src="assets/KeyBalloons.svg" alt="Key Balloons 앱 아이콘" width="36"> Key Balloons

[English](README.md) · [简体中文](README.zh.md) · [繁體中文](README.zh-TW.md) · [Français](README.fr.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md)

Key Balloons는 macOS와 Windows용 데스크톱 오버레이입니다. 어떤 앱에서든 글을 입력하면 윤곽선이 있는 키 이름이 떠 있는 상자에서 올라와 약 2초 후 사라집니다. 같은 키를 반복해서 눌러도 누를 때마다 별도 애니메이션이 표시됩니다.

**[다운로드](https://github.com/boomsi/key-balloons/releases)** · [설치](#설치) · [사용](#사용) · [소스에서 빌드](#소스에서-빌드) · [연동 가이드](docs/mouse-feedback.ko.md)

![Key Balloons 데모. kissmenow를 입력하면 상자에서 키가 떠오릅니다](assets/key-balloons-demo.gif)

> 키 입력은 기기에서 애니메이션을 표시하는 데만 사용됩니다. 키 입력 기록을 보관하거나 네트워크로 보내지 않습니다.

## 설치

[GitHub Releases](https://github.com/boomsi/key-balloons/releases)에서 운영체제에 맞는 설치 파일을 다운로드합니다.

| 플랫폼 | 설치 단계 |
| --- | --- |
| macOS | 유니버설 `.dmg`를 열고 **KeyBalloons.app**을 응용 프로그램 폴더로 드래그한 다음 그곳에서 실행합니다. |
| Windows | x64 `.exe` 설치 프로그램을 실행한 뒤 시작 메뉴에서 **Key Balloons**를 엽니다. |

### macOS에서 입력 모니터링 허용

1. 앱을 시작할 때 권한을 묻는 메시지가 표시되면 **입력 모니터링 열기**를 선택합니다. 메뉴 막대의 **모니터링 켜기…**로도 열 수 있습니다.
2. 시스템 설정 → 개인정보 보호 및 보안 → 입력 모니터링에서 안내 카드의 Key Balloons 아이콘을 목록으로 드래그합니다.
3. 스위치를 켭니다. 앱이 권한을 확인하면 카드가 닫힙니다. macOS에서 앱을 종료하고 다시 열라는 메시지를 표시하면 안내를 따릅니다.

업데이트 후 이전 항목이 남아 있으면 **−**로 제거하고 현재 버전을 추가해 허용합니다.

## 사용

평소 사용하는 앱에서 입력하면 상자가 맨 위에 유지되며 입력 한 번당 키 이름 하나를 표시합니다.

왼쪽 클릭, 오른쪽 클릭, 휠을 스크롤하거나 누르기는 각각 왼쪽, 오른쪽, 가운데를 밝힙니다. **고급**에서 [로컬 마우스 연동](docs/mouse-feedback.ko.md)을 켤 수 있습니다.

### 설정

상자를 오른쪽 클릭하거나 메뉴 막대 또는 알림 영역에서 **Settings…(설정…)**를 선택하면 같은 패널이 열립니다.

- **모양**의 **크기**(50%–150%)와 **불투명도**(20%–100%)는 상자와 키 이름에 함께 적용됩니다.
- **위치**에서 **드래그 허용**을 켜면 왼쪽 버튼으로 상자를 움직일 수 있습니다. **화면 하단에 붙이기**를 켜면 놓을 때 가장 가까운 화면의 사용 가능 영역 하단에 붙습니다.
- **언어**를 변경하면 즉시 적용되고 선택이 저장됩니다. 기본 언어는 영어입니다.
- 메뉴에는 앱의 메모리 사용량과 모니터링 상태가 표시됩니다. 모니터링을 일시 정지하거나 다시 켜고 앱을 종료할 수도 있습니다.

Xcode 26 이상으로 빌드하면 macOS 26에서 네이티브 Liquid Glass 설정 패널이 사용됩니다. macOS에서 Spaces를 전환해도 상자와 애니메이션은 선택한 위치에 함께 유지됩니다.

## 소스에서 빌드

CMake 3.21 이상, Qt Quick과 Qt Quick Test 및 Qt Linguist 도구가 포함된 Qt 6.10 데스크톱 SDK, Xcode 또는 Visual Studio 2022 C++ 도구 체인이 필요합니다. 예제는 Qt 6.10.3을 사용합니다.

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

### Windows(PowerShell)

```powershell
$qt = "$env:USERPROFILE/Qt/6.10.3/msvc2022_64"
$env:Path = "$qt/bin;$env:Path"
cmake -S . -B build -A x64 "-DCMAKE_PREFIX_PATH=$qt"
cmake --build build --config Release --parallel
ctest --test-dir build --build-config Release --output-on-failure
& "./build/Release/KeyBalloons.exe"
```

## 릴리스 설치 프로그램

GitHub 릴리스를 게시하면 **Release installers**가 시작됩니다. 워크플로는 릴리스 태그에서 빌드하고 테스트합니다. 검증이 끝나면 macOS 유니버설 `.dmg`와 Windows x64 `.exe`를 첨부합니다.

**Actions → Release installers → Run workflow**에서 패키징을 테스트할 수 있습니다. 두 설치 프로그램은 실행 결과의 **Artifacts**에 표시됩니다. macOS 번들은 ad hoc 서명을 사용합니다. Apple 공증과 Windows 릴리스 서명에는 각 플랫폼의 인증 정보가 필요합니다.

## 프로젝트 구조 및 테스트

- [`examples/basic-box/`](examples/basic-box/)에는 내장 상자 예제와 애니메이션, 마우스 피드백 구독 코드가 있습니다.
- `src/macos/`와 `src/windows/`는 플랫폼별 입력을 처리합니다. macOS 모듈은 네이티브 설정과 입력 모니터링 안내도 제공합니다.
- `tests/tst_balloons.qml`은 빠른 입력, 개별 사라짐, 드래그, 마우스 피드백, 설정을 테스트합니다. `tests/tst_overlay_core.cpp`는 화면 배치, 로컬 연동, 번역, 메모리 조회를 테스트합니다.
- `tests/tst_stress.qml`은 30초 동안 초당 20회 입력을 시뮬레이션합니다. 프레임 간격과 키 이름 생성부터 다음 Qt 프레임까지 걸리는 시간의 95번째 백분위수를 보여 줍니다. 실제 키 입력부터 화면에 표시되기까지의 지연은 별도로 측정해야 합니다.

데스크톱 세션에서 연속 애니메이션 테스트를 실행합니다.

```sh
./build/key_balloons_tests -input tests/tst_stress.qml
```

Windows에서는 `./build/Release/key_balloons_tests.exe`를 사용합니다. 빠른 동작 확인은 텍스트 편집기나 메모장에서 `A A B`를 입력해 보세요. 편집기 포커스가 유지되고 키 이름 세 개가 각각 올라갔다 사라져야 합니다. [테스트 체크리스트](TODO.ko.md)를 참조하세요.
