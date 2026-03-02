# klasflow

`klasflow`는 Flutter/Dart 앱에서 KLAS 연동을 빠르게 끝내기 위한 클라이언트 SDK입니다.

핵심 목표:
- 로그인/세션/컨텍스트를 앱 코드에서 분리
- 읽기 전용 API 호출을 안전하게 표준화
- KLAS API 변화가 생겨도 빠르게 진단 가능하게 만들기

## Why This Package

KLAS 연동에서 반복되는 문제를 줄입니다.
- 로그인 프로토콜 변경 대응(구형/신형 플로우 지원)
- 세션 만료 감지 및 자동 재로그인 재시도
- 과목 컨텍스트 자동 주입
- `client.api`(카탈로그) + `client.endpoints`(자동완성) 이중 접근
- 런타임 헬스체크(`runHealthCheck`)로 API 호환성 점검

## Installation

```bash
dart pub add klasflow
```

## 3-Minute Quick Start

```dart
import 'package:klasflow/klasflow.dart';

Future<void> main() async {
  final client = KlasClient();

  try {
    final bootstrap = await client.loginAndBootstrap('학번', '비밀번호');
    print('authenticated: ${bootstrap.session.authenticated}');
    print('contexts: ${bootstrap.contexts.length}');

    final tasks = await client.endpoints.learning.taskStdList(
      payload: {'currentPage': 0},
    );
    print('tasks: ${tasks.length}');
  } on KlasException catch (error) {
    print('klas error: $error');
  } finally {
    client.close();
  }
}
```

## Flutter Demo App

실행 가능한 Flutter 데모 앱은 `example/`에 있습니다.

```bash
cd example
flutter pub get
flutter run
```

주의:
- Flutter Web에서 `localhost`로 실행하면 `https://klas.kw.ac.kr`와 교차 출처가 되어
  브라우저 세션 쿠키 정책 때문에 로그인(`LoginCaptcha`/`LoginConfirm`)이 실패할 수 있습니다.
- 이 경우 Android/iOS/desktop 타깃으로 실행하거나 same-origin reverse proxy를 사용하세요.
- 데모 앱 base URI는 `--dart-define=KLAS_BASE_URI=<url>`로 오버라이드할 수 있습니다.

데모 구성:
- 로그인(학번/비밀번호)
- 세션 정보 UI 표시
- 컨텍스트 목록 UI 표시 및 전환
- `learning.taskStdList` 데이터 UI 표시

## Pick Your Usage Path

1. Simple Path
- `loginAndBootstrap()`
- `endpoints.learning.taskStdList()` 같은 typed endpoint 사용

2. Flexible Path
- `api.callObject/callArray/callText/callBinary`
- 카탈로그 ID 기반 공통 호출

3. Advanced Path
- `startSessionHeartbeat()` / `stopSessionHeartbeat()`
- `runHealthCheck()`로 운영 진단
- `KlasClientConfig`로 timeout, retry 정책 조정

## Public API Highlights

- `KlasClient.login(...)`
- `KlasClient.loginAndBootstrap(...)`
- `KlasClient.getSessionInfo()`
- `KlasClient.refreshContexts()`
- `KlasClient.setContext(...)`
- `KlasClient.runHealthCheck(...)`
- `KlasClient.startSessionHeartbeat(...)`
- `KlasClient.stopSessionHeartbeat()`
- `KlasClient.api.*`
- `KlasClient.endpoints.*`

주요 설정:
- `KlasClientConfig.maxSessionRenewRetries`
- `KlasClientConfig.cacheCredentialsForAutoRenewal` (보안 민감 앱에서 `false` 권장)

## Tutorial & Docs

- [Quick Tutorial](docs/tutorial_quickstart.md)
- [FAQ](docs/faq.md)
- [Adoption Questions](docs/adoption_questions.md)
- [Roadmap](docs/roadmap.md)
- [Security Guidelines](docs/security_guidelines.md)
- [API Change Playbook](docs/api_change_playbook.md)
- [Login Flow](docs/login_flow.md)
- [Architecture](docs/architecture.md)
- [Architecture Critique](docs/architecture_critique.md)
- [Flutter Integration](docs/flutter_integration.md)
- [Release Checklist](docs/release_checklist.md)
- [Example Guide](example/README.md)

## Live Read-Only Validation (10 Scenarios)

실계정으로 읽기 전용 시나리오를 자동 점검합니다.

```bash
$env:KLAS_ID="<id>"
$env:KLAS_PASSWORD="<password>"
dart run tool/live_account_scenarios.dart
```

## Quality / Safety Commands

전체 품질 점검:
```bash
dart run tool/check_all.dart
```

민감 문자열 포함 점검:
```bash
dart run tool/check_all.dart --block="value1,value2"
```

비공개 문서/민감정보 점검:
```bash
dart run tool/prepublish_check.dart
dart run tool/prepublish_check.dart --block="value1,value2"
```

## API Drift Strategy

KLAS 응답이 바뀌면 아래 순서로 대응하세요.
1. `runHealthCheck()` 또는 `tool/live_account_scenarios.dart` 실행
2. 실패 endpoint 식별
3. `ApiPaths` override 또는 parser 보강
4. 테스트 추가 후 릴리스

## Security Notes

- 실계정 테스트는 읽기 전용 API만 사용하세요.
- 학번/비밀번호/토큰/쿠키를 로그에 남기지 마세요.
- 비공개 명세 문서(`klas-api-spec.md`, `klasflow_LLM_RFP_with_API_Spec.md`)는 커밋하지 마세요.
