# 12. 학적/프레임/헬스체크

이 페이지는 "운영 보조 기능"을 다룹니다.

## 1) 학적 기능: `user.studentRecord`

```dart
final hakjuk = await user.studentRecord.temporaryLeaveHakjuk();
final status = await user.studentRecord.temporaryLeaveStatus();

print(hakjuk.raw);
print(status.raw);
```

학적 화면의 일부 영역은 학교별 필드 차이가 크므로,  
초기에는 `raw`를 앱 DTO로 매핑해서 사용하세요.

## 2) 프레임 기능: `user.frame`

```dart
final home = await user.frame.homeOverview();
final now = DateTime.now();
final schdul = await user.frame.scheduleSummary(
  year: now.year,
  month: now.month,
);
final examCheck = await user.frame.gyojikExamCheck();
```

- 메인 대시보드 요약 카드
- 일정 요약 영역
- 교직 관련 확인 영역

같은 용도로 활용할 수 있습니다.

## 3) 헬스체크: `client.runHealthCheck`

```dart
final report = await client.runHealthCheck(
  includeCourseEndpoints: true,
  includeFrameEndpoint: true,
  taskPage: 0,
);

print('전체 통과: ${report.allPassed}');
print('실패 수: ${report.failedCount}');
```

배포 전/운영 중 점검 자동화에 유용합니다.

## 4) 캡차 이미지 조회: `requestCaptchaImage`

```dart
final captcha = await client.requestCaptchaImage();
print(captcha.bytes.length);
```

로그인 UX를 직접 제어해야 하는 앱에서 활용합니다.

다음: [13. 오류 처리와 운영 패턴](13-error-handling-patterns.md)
