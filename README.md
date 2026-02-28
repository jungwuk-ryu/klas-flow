# klasflow

`klasflow`는 Flutter/Dart에서 KLAS를 안전하게 호출하기 위한 고수준 SDK이다.

복잡한 로그인 절차, 쿠키 세션, 과목 컨텍스트 주입, JSON/HTML/파일 응답 분리를 내부에서 처리하고,
외부에는 단순한 `KlasClient` API를 제공한다.

## 설치

```bash
dart pub add klasflow
```

## 빠른 시작

```dart
import 'package:klasflow/klasflow.dart';

Future<void> main() async {
  final client = KlasClient();

  try {
    await client.login('학번', '비밀번호');
    final session = await client.getSessionInfo();
    print('세션 유효: ${session.authenticated}');
  } on KlasException catch (error) {
    print('오류: $error');
  } finally {
    client.close();
  }
}
```

## 핵심 기능

- 다단계 로그인 오케스트레이션(`login`) 자동 처리
- 세션 쿠키 자동 유지, 만료 감지, 자동 세션 연장(재로그인 1회 재시도)
- 과목 컨텍스트(`selectYearhakgi`, `selectSubj`, `selectChangeYn`) 자동 주입
- JSON/HTML/파일 응답 타입 분리
- 명세 기반 65개 읽기 전용 엔드포인트 카탈로그(`client.api`) 제공
- IDE 자동완성 친화적인 그룹형 엔드포인트 API(`client.endpoints`) 제공
- 명확한 예외 타입 제공

## 공개 API

- `KlasClient.login(String id, String password)`
- `KlasClient.getSessionInfo()`
- `KlasClient.refreshContexts()`
- `KlasClient.setContext(...)`
- `KlasClient.initializeFrame()`
- `KlasClient.downloadFile(...)`
- `KlasClient.api.call(...)`
- `KlasClient.api.callObject(...)`
- `KlasClient.api.callArray(...)`
- `KlasClient.api.callText(...)`
- `KlasClient.api.callBinary(...)`
- `KlasClient.endpoints.learning.*`
- `KlasClient.endpoints.academic.*`
- `KlasClient.endpoints.file.*`
- `KlasClient.startSessionHeartbeat(...)`
- `KlasClient.stopSessionHeartbeat()`
- `KlasClient.isSessionHeartbeatRunning`

설정 옵션:

- `KlasClientConfig.maxSessionRenewRetries` (기본 `1`)

## 데모 예제

- [Example Guide](example/README.md)
- `example/basic_login_demo.dart`: 기본 로그인 + 세션/컨텍스트 출력
- `example/error_handling_demo.dart`: 타입별 예외 처리 패턴
- `example/context_workflow_demo.dart`: 컨텍스트 로드/전환 + 컨텍스트 주입 API 호출
- `example/file_download_demo.dart`: 파일 다운로드 후 임시 경로 저장
- `example/auto_session_renewal_demo.dart`: 세션 만료 자동 연장 동작 흐름
- `example/api_catalog_demo.dart`: 카탈로그 기반 전체 API 호출 패턴
- `example/heartbeat_demo.dart`: 장시간 실행 앱에서 세션 heartbeat 사용 패턴
- `tool/live_account_scenarios.dart`: 실계정 기준 읽기 전용 10개 시나리오 검증 스크립트

실행 예시:

```bash
dart run example/basic_login_demo.dart -DKLAS_ID=<id> -DKLAS_PASSWORD=<password>
```

실계정 10개 시나리오 검증:

```bash
$env:KLAS_ID="<id>"
$env:KLAS_PASSWORD="<password>"
dart run tool/live_account_scenarios.dart
```

카탈로그 호출 예시:

```dart
final result = await client.api.callArray(
  'learning.taskStdList',
  payload: {'currentPage': 0},
);
```

그룹형 호출 예시:

```dart
final result = await client.endpoints.learning.taskStdList(
  payload: {'currentPage': 0},
);
```

카탈로그 변경 후 자동완성 래퍼를 다시 생성하려면:

```bash
dart run tool/generate_typed_endpoints.dart
```

## 예외 타입

- `InvalidCredentialsException`
- `OtpRequiredException`
- `CaptchaRequiredException`
- `SessionExpiredException`
- `ServiceUnavailableException`
- `NetworkException`
- `ParsingException`

## 아키텍처

- `Client Layer` -> 외부 공개 API
- `Auth Flow Layer` -> 로그인 단계 오케스트레이션
- `Context Layer` -> 과목 컨텍스트 상태/주입
- `API Layer` -> 엔드포인트 단위 캡슐화
- `Transport Layer` -> HTTP/쿠키/응답 분리
- `Parsing Layer` -> JSON/HTML 파싱
- `Models Layer` -> 강한 타입 모델

상세 문서:

- [로그인 흐름](docs/login_flow.md)
- [설계 문서](docs/architecture.md)
- [Flutter 연동 가이드](docs/flutter_integration.md)
- [공개 배포 체크리스트](docs/release_checklist.md)

## 테스트

```bash
dart analyze
dart test
dart test --coverage=coverage
dart run coverage:format_coverage --package=. --in=coverage --lcov --report-on=lib --out=coverage/lcov.info
```

라인 커버리지는 변경 시점에 따라 달라질 수 있으므로, 위 커맨드로 최신 수치를 확인하세요.

한 번에 전체 품질 검증을 실행하려면:

```bash
dart run tool/check_all.dart
```

민감 문자열까지 함께 검사하려면:

```bash
dart run tool/check_all.dart --block="value1,value2"
```

## 배포 전 안전 점검

아래 점검 스크립트는 공개되면 안 되는 명세 파일과 차단 문자열(민감정보)이
현재 파일/이력에 남아있는지 확인한다.

```bash
dart run tool/prepublish_check.dart
```

차단 문자열을 같이 검사하려면:

```bash
dart run tool/prepublish_check.dart --block="your_student_id,your_password"
```

점검 항목:

- `klas-api-spec.md`, `klasflow_LLM_RFP_with_API_Spec.md`가 추적/이력에 존재하는지
- 차단 문자열이 tracked file, git history, working tree에 존재하는지
