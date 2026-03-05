# 02. 로그인과 세션 관리

이 페이지에서는 로그인부터 세션 유지, 종료까지 "앱 생명주기 관점"으로 설명합니다.

## 1) 로그인: `KlasClient.login`

```dart
final client = KlasClient();
final user = await client.login(id, password);
```

- 반환 타입: `KlasUser`
- 로그인 성공 직후부터 `user`를 통해 대부분의 기능에 접근합니다.

## 2) 현재 사용자 참조: `currentUser`

```dart
final current = client.currentUser;
if (current != null) {
  print(current.id);
}
```

- 로그인 이후에는 `client.currentUser`로 마지막 로그인 사용자를 참조할 수 있습니다.

## 3) 세션 상태 확인: `user.sessionStatus`

```dart
final status = await user.sessionStatus();
print('인증 여부: ${status.authenticated}');
print('남은 시간(초): ${status.remainingTimeSec}');
```

앱이 백그라운드/복귀를 반복하는 경우, 특정 화면 진입 전에 세션 상태를 점검하면 안정적입니다.

## 4) 세션 연장

### 4-1) 즉시 연장: `user.keepAlive`

```dart
await user.keepAlive();
```

### 4-2) 자동 연장: `client.startSessionHeartbeat`

```dart
client.startSessionHeartbeat(
  interval: const Duration(minutes: 5),
  onError: (error, stackTrace) {
    print('하트비트 오류: $error');
  },
);
```

- `interval`은 `Duration.zero`보다 커야 합니다.
- 앱 종료 시점에는 `stopSessionHeartbeat()` 또는 `close()`를 호출하세요.

## 5) 로컬 상태 초기화: `clearLocalState`

```dart
client.clearLocalState();
```

로그아웃 버튼 처리 시 유용합니다.  
(쿠키/컨텍스트/자동 재로그인 캐시/사용자 캐시를 정리)

## 6) 리소스 해제: `close`

```dart
client.close();
```

`dispose` 시점(앱 종료, 테스트 teardown)에서 반드시 호출하세요.

다음: [03. 사용자 정보와 수강 과목 컨텍스트](03-user-profile-and-courses.md)

