# klasflow

`klasflow`는 Flutter/Dart 앱에서 KLAS를 도메인 객체 중심으로 다루기 위한 고수준 SDK입니다.

핵심 목표:
- endpoint ID와 `payload Map`을 앱 코드에서 제거
- `login -> user -> course` 객체 흐름으로 사용성 단순화
- 세션/컨텍스트/재로그인을 내부로 캡슐화

## Installation

```bash
dart pub add klasflow
```

## Quick Start

```dart
import 'package:klasflow/klasflow.dart';

Future<void> main() async {
  final client = KlasClient();

  try {
    final user = await client.login('학번', '비밀번호');
    final profile = await user.profile(refresh: true);
    print('authenticated: ${profile.authenticated}');

    final course = await user.defaultCourse();
    if (course == null) {
      print('no course context');
      return;
    }

    final tasks = await course.listTasks(page: 0);
    print('tasks: ${tasks.length}');
  } on KlasException catch (error) {
    print('klas error: $error');
  } finally {
    client.close();
  }
}
```

## Main API

- `KlasClient.login(...) -> KlasUser`
- `KlasUser.profile(...)`
- `KlasUser.courses(...)`
- `KlasUser.defaultCourse(...)`
- `KlasCourse.listTasks(...)`
- `KlasCourse.noticeBoard.listPosts(...)`
- `KlasClient.startSessionHeartbeat(...)`
- `KlasClient.runHealthCheck(...)`

## Migration

- [Breaking migration guide](docs/migration_breaking_1x.md)

## Flutter Demo App

```bash
cd example
flutter pub get
flutter run
```

## Live Read-Only Validation

```bash
$env:KLAS_ID="<id>"
$env:KLAS_PASSWORD="<password>"
dart run tool/live_account_scenarios.dart
dart run tool/live_smoke.dart
```

## Quality / Safety Commands

```bash
dart run tool/check_all.dart
dart run tool/prepublish_check.dart
```

## Security Notes

- 실계정 테스트는 읽기 전용 API만 사용하세요.
- 학번/비밀번호/토큰/쿠키를 로그에 남기지 마세요.
- 비공개 명세 문서는 커밋하지 마세요.
