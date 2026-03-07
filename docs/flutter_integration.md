# Flutter Integration Guide

`klasflow`는 Flutter에서 그대로 주입해 사용할 수 있는 Dart 패키지입니다.

## 0) 실행 가능한 데모 앱

```bash
cd example
flutter pub get
flutter run
```

## 1) Riverpod 예시

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:klasflow/klasflow.dart';

final klasClientProvider = Provider<KlasClient>((ref) {
  final client = KlasClient(
    config: KlasClientConfig(
      maxSessionRenewRetries: 2,
      cacheCredentialsForAutoRenewal: true,
    ),
  );
  ref.onDispose(client.close);
  return client;
});

final klasUserProvider = FutureProvider.family<KlasUser, ({String id, String pw})>((
  ref,
  credentials,
) async {
  final client = ref.watch(klasClientProvider);
  return client.login(credentials.id, credentials.pw);
});
```

## 2) Repository 예시

```dart
import 'package:klasflow/klasflow.dart';

final class KlasRepository {
  final KlasClient _client;

  KlasRepository(this._client);

  Future<KlasUser> login(String id, String password) {
    return _client.login(id, password);
  }

  Future<List<KlasTask>> loadTasks(KlasUser user) async {
    final course = await user.defaultCourse();
    if (course == null) {
      return const <KlasTask>[];
    }
    return course.listTasks(page: 0);
  }

  Future<KlasTimetable> loadTimetable(KlasUser user) {
    return user.timetable();
  }

  Future<KlasCourse?> findCourse(KlasUser user, String courseId) {
    return user.findCourseById(courseId);
  }
}
```

## 3) 운영 팁

- 앱 시작 시 로그인 후 `user.courses(refresh: true)`를 호출해 초기 상태를 확정합니다.
- 특정 과목 화면으로 바로 진입할 때는 `findCourseById(...)`를 먼저 써두면 UI 코드가 단순해집니다.
- 장시간 화면에서는 `startSessionHeartbeat()`를 사용합니다.
- 실계정 테스트는 반드시 읽기 전용 API만 사용합니다.
- `QR 출석`은 상태 변경 기능이므로 일반 demo flow나 실계정 smoke test에 포함하지 않습니다.
