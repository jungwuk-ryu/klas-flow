# 02. 로그인과 세션 관리

이 페이지에서는 로그인부터 세션 유지, 종료까지 "앱 생명주기 관점"으로 설명합니다.

## 1) 로그인: `KlasClient.login`

```dart
final client = KlasClient();
final user = await client.login(id, password);
```

- 반환 타입: `KlasUser`
- 로그인 성공 직후부터 `user`를 통해 대부분의 기능에 접근합니다.

### 숫자 캡차가 필요한 로그인

`1.3.0`부터 `onCaptcha`로 이미지 표시와 사용자 입력을 연결할 수 있습니다. 다음 예시의 `showCaptchaDialog`는 앱에서 구현할 이미지/입력 UI입니다.

```dart
final user = await client.login(
  id,
  password,
  onCaptcha: (challenge) async {
    return showCaptchaDialog(
      imageBytes: challenge.image.bytes,
      attempt: challenge.attempt,
      maxAttempts: challenge.maxAttempts,
    ); // Future<String?>: 사용자가 읽은 숫자 또는 취소 시 null
  },
  maxCaptchaAttempts: 3,
);
```

- `KlasCaptchaChallenge.image`는 현재 로그인과 같은 세션에서 받은 `FilePayload`입니다. 콜백 안에서는 이 바이트를 표시하세요. 별도로 `requestCaptchaImage()`를 호출하면 화면에 표시된 문제가 바뀔 수 있습니다.
- 숫자는 문자열로 반환합니다. 예를 들어 `"0037"`의 앞자리 0을 유지해야 합니다. 공백은 제거되며 숫자 이외의 문자는 `FormatException`을 발생시킵니다.
- 잘못된 캡차를 서버가 거절하면 새 이미지로 다시 입력을 요청합니다. 기본 한도는 로그인당 3회이며 `maxCaptchaAttempts`는 1 이상이어야 합니다.
- 콜백을 생략하거나, 입력을 취소하거나, 한도를 초과하면 `CaptchaRequiredException`을 발생시킵니다. 잘못된 비밀번호는 기존 `InvalidCredentialsException`으로 구분됩니다.
- 자동 재로그인을 위한 자격증명 캐시가 활성화되어 있으면 세션 갱신 중에도 같은 콜백을 호출할 수 있습니다. 앱이 입력 UI를 보여줄 수 없을 때는 `null`을 반환하고 나중에 다시 로그인하세요. 이미지와 답은 캐시하지 않습니다.

SDK는 사용자가 입력한 답을 전달합니다. 숫자를 자동으로 판독하지 않습니다. 현재 개발 버전의 기능이며, 배포 전에는 로컬 SDK 의존성을 사용하세요.

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

