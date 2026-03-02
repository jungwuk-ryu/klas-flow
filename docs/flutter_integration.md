# Flutter Integration Guide

`klasflow`는 순수 Dart 패키지이므로 Flutter에서 바로 주입해서 사용할 수 있습니다.

## 0) 실행 가능한 데모 앱

저장소의 `example/`은 실제 Flutter 앱 데모입니다.

```bash
cd example
flutter pub get
flutter run
```

주의:
- Flutter Web(`localhost`) + 기본 `baseUri(https://klas.kw.ac.kr)` 조합은
  cross-origin 쿠키 제한으로 로그인 단계에서 실패할 수 있습니다.
- 실사용 로그인 검증은 Android/iOS/desktop 또는 same-origin reverse proxy 환경을 권장합니다.
- 데모 앱은 `--dart-define=KLAS_BASE_URI=<url>`로 base URI를 바꿔 실행할 수 있습니다.

데모 화면은 로그인 후 아래 데이터를 UI에 표시합니다.
- `SessionInfo`
- 과목 컨텍스트 목록(`availableContexts`)
- 과제 목록(`learning.taskStdList`)

## 1) Riverpod 예시

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:klasflow/klasflow.dart';

final klasClientProvider = Provider<KlasClient>((ref) {
  final client = KlasClient(
    config: KlasClientConfig(
      // 세션 만료 시 최대 2회 자동 연장
      maxSessionRenewRetries: 2,
      // 보안 우선 앱이라면 false로 두고 수동 재로그인 UX를 제공
      cacheCredentialsForAutoRenewal: true,
    ),
  );

  ref.onDispose(client.close);
  return client;
});

final sessionProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final client = ref.watch(klasClientProvider);
  return client.api.callObject('session.info');
});
```

## 2) BLoC/Controller 예시

```dart
import 'package:klasflow/klasflow.dart';

final class KlasRepository {
  final KlasClient _client;

  KlasRepository(this._client);

  Future<void> login(String id, String password) {
    return _client.loginAndBootstrap(id, password).then((_) => null);
  }

  Future<List<dynamic>> loadTasks() {
    return _client.endpoints.learning.taskStdList(
      payload: {'currentPage': 0},
    );
  }

  Future<void> runDiagnostics() async {
    final report = await _client.runHealthCheck();
    if (!report.allPassed) {
      for (final item in report.items.where((it) => !it.success)) {
        print('health fail: ${item.id} -> ${item.detail}');
      }
    }
  }

  void startHeartbeat() {
    _client.startSessionHeartbeat(
      interval: const Duration(minutes: 5),
      onError: (error, _) {
        // 운영 환경에서는 logger/crashlytics로 전송
        print('heartbeat error: $error');
      },
    );
  }

  void stopHeartbeat() {
    _client.stopSessionHeartbeat();
  }
}
```

## 3) 운영 팁

- 앱 시작 시에는 로그인 성공 후 `refreshContexts()`로 기본 컨텍스트를 확정해 두는 것을 권장합니다.
- 백그라운드 전환 시 `stopSessionHeartbeat()`, 포그라운드 복귀 시 `startSessionHeartbeat()`를 권장합니다.
- 실계정 테스트에서는 반드시 읽기 전용 엔드포인트만 사용하세요.
- 로그/크래시 리포트에 학번, 토큰, 쿠키가 남지 않도록 마스킹 정책을 두세요.
