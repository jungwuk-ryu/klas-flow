# Quick Tutorial

이 문서는 `klasflow`의 고수준 객체 API를 빠르게 사용하는 최소 경로를 제공합니다.

## Step 1. Client 생성

```dart
final client = KlasClient(
  config: KlasClientConfig(
    maxSessionRenewRetries: 1,
    timeout: const Duration(seconds: 20),
  ),
);
```

## Step 2. 로그인 후 User 객체 확보

```dart
final user = await client.login(id, password);
final profile = await user.profile(refresh: true);
print(profile.authenticated);
```

## Step 3. Course 객체 기반 호출

```dart
final course = await user.defaultCourse();
if (course != null) {
  final tasks = await course.listTasks(page: 0);
  final notices = await course.noticeBoard.listPosts(page: 0);
  print(tasks.length);
  print(notices.posts.length);
}
```

## Step 4. 앱 라이프사이클 대응

```dart
client.startSessionHeartbeat(
  interval: const Duration(minutes: 5),
  onError: (error, stackTrace) {
    // logger/crashlytics
  },
);
```

종료 시:

```dart
client.stopSessionHeartbeat();
client.close();
```

## Step 5. API 변경/장애 진단

```dart
final report = await client.runHealthCheck();
if (!report.allPassed) {
  for (final item in report.items.where((it) => !it.success)) {
    print('${item.id} failed: ${item.detail}');
  }
}
```

## Step 6. 실계정 검증

```bash
$env:KLAS_ID="<id>"
$env:KLAS_PASSWORD="<password>"
dart run tool/live_account_scenarios.dart
```
