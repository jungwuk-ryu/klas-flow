# Quick Tutorial

이 문서는 Flutter 개발자가 `KlasClient`를 빠르게 이해하고 실제 앱에 붙이기 위한 최소 경로를 제공합니다.

## Step 1. Client 생성

```dart
final client = KlasClient(
  config: KlasClientConfig(
    maxSessionRenewRetries: 1,
    timeout: const Duration(seconds: 20),
    cacheCredentialsForAutoRenewal: true,
  ),
);
```

## Step 2. 로그인 + 초기 상태 확보

```dart
final bootstrap = await client.loginAndBootstrap(id, password);
print(bootstrap.session.authenticated);
print(bootstrap.contexts.length);
```

`loginAndBootstrap()`은 아래를 한 번에 처리합니다.
- 로그인
- 세션 확인
- 컨텍스트 로드

## Step 3. 읽기 전용 API 호출

typed endpoint 사용(권장):

```dart
final tasks = await client.endpoints.learning.taskStdList(
  payload: {'currentPage': 0},
);
```

catalog 호출:

```dart
final tasks = await client.api.callArray(
  'learning.taskStdList',
  payload: {'currentPage': 0},
);
```

## Step 4. 앱 라이프사이클 대응

장시간 화면에서 세션 유지가 필요하면 heartbeat를 사용합니다.

```dart
client.startSessionHeartbeat(
  interval: const Duration(minutes: 5),
  onError: (error, stackTrace) {
    // logger/crashlytics 전송
  },
);
```

화면 종료/앱 종료 시:

```dart
client.stopSessionHeartbeat();
client.close();
```

## Step 5. API 변경/장애 진단

런타임 점검:

```dart
final report = await client.runHealthCheck();
if (!report.allPassed) {
  for (final item in report.items.where((it) => !it.success)) {
    print('${item.id} failed: ${item.detail}');
  }
}
```

CI/로컬 점검:

```bash
dart run tool/check_all.dart
```

## Step 6. 실계정 검증

읽기 전용 10개 시나리오:

```bash
$env:KLAS_ID="<id>"
$env:KLAS_PASSWORD="<password>"
dart run tool/live_account_scenarios.dart
```

## Common Mistakes

- 컨텍스트가 필요한 endpoint를 로그인 없이 호출
- 계정 정보/쿠키를 로그에 남김
- 비공개 명세 문서를 git tracked 상태로 둠
- API 변경 신호(파싱 실패, 404/405 증가)를 무시함
