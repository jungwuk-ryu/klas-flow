# 11. 출석/월간 일정 기능

`user.attendance`는 출석과 일정 화면을 구현할 때 사용합니다.

## 1) 출석 과목 목록 (typed)

```dart
final subjects = await user.attendance.listSubjectItems();
for (final s in subjects) {
  print('${s.displayName} / ${s.professorName ?? '-'}');
}
```

## 2) 월간 일정 목록 (typed)

```dart
final now = DateTime.now();
final monthItems = await user.attendance.listMonthlySchedules(
  year: now.year,
  month: now.month,
);
for (final item in monthItems) {
  print('${item.date ?? '-'} / ${item.displayTitle}');
}
```

`year`, `month`를 생략하면 현재 연/월이 자동으로 들어갑니다.

## 3) QR 출석 (typed)

KW출첵 QR 출석은 일반 `KlasClient()`로 사용합니다. SDK가 출석 과목 조회,
추가 인증, QR 제출 요청에 필요한 모바일 앱 식별을 자동으로 적용합니다.
SDK는 디코딩된 QR 문자열과 인증 답변을 받습니다. CLI에서는 표준 입력이나
인자로, 앱에서는 입력 폼이나 스캐너로 값을 얻을 수 있습니다.

이미 QR 문자열이 있다면 `qrCheckIn()`으로 인증과 제출을 한 번에 진행합니다.

```dart
final result = await course.qrCheckIn(
  qrText,
  onVerification: handleQrVerification,
);
print(result.accepted);
```

인증을 먼저 마치고 QR 입력을 받으려면 `prepareQrCheckIn()`을 사용합니다.
아래의 `readVerificationCode()`와 `readQrText()`는 호출하는 프로그램이 제공하는
입력 함수입니다. 예를 들어 Dart CLI에서는 `stdin.readLineSync()`를 연결할 수 있습니다.

```dart
final client = KlasClient();
final user = await client.login(id, password);
final course = await user.findCourseById(selectedCourseId);
if (course == null) return;

final prepared = await course.prepareQrCheckIn(
  onVerification: (challenge) async {
    // 사용자가 이메일 인증을 선택했을 때만 발송합니다.
    await challenge.requestEmailCode();
    final code = await readVerificationCode();
    if (code == null) return null;
    return KlasQrVerificationAnswer(
      method: KlasQrVerificationMethod.email,
      code: code,
    );
  },
);

try {
  final qrText = await readQrText();
  if (qrText == null) return;
  final result = await prepared.submit(qrText);
  if (result.accepted) {
    print('출석 처리 완료');
  } else {
    print('출석 실패: ${result.message ?? '사유 없음'}');
  }
} finally {
  prepared.cancel();
}
```

- `prepareQrCheckIn()`은 과목 선택 → 마감 여부 확인 → 추가 인증까지 진행하고 `KlasQrCheckInSession`을 반환합니다. 출석 요청은 호출자가 `submit(qrText)`를 실행할 때 전송합니다. 입력 함수 실행, 카메라 권한, QR 이미지 디코딩은 호출하는 프로그램이 담당합니다.
- `onVerification`은 서버가 추가 인증을 요구할 때 호출됩니다. 이메일은 `requestEmailCode()`를 명시적으로 호출해야 발송하며, 같은 challenge에서 중복 호출해도 한 번만 발송합니다. 이 Future를 기다린 다음 입력 UI를 여세요.
- 이미 등록한 OTP가 있으면 `challenge.otpAvailable`을 확인하고 `KlasQrVerificationMethod.otp`와 사용자가 입력한 코드를 반환할 수 있습니다. OTP나 스마트 기기 신규 등록은 SDK에서 수행하지 않습니다.
- 인증 코드는 문자열로 전달하므로 앞자리 `0`이 보존됩니다. 코드가 거절되면 새 challenge를 받고, 기본 3회 이후에는 중단합니다. `maxVerificationAttempts`는 1~10으로 지정할 수 있습니다.
- 인증 callback이 `null`을 반환하면 `QrAttendanceCancelledException`으로 종료하며 출석을 제출하지 않습니다. callback을 생략했는데 인증이 필요하면 `QrAttendanceVerificationRequiredException`이 발생합니다.
- QR 입력을 취소하면 `prepared.cancel()`로 준비를 로컬에서 해제합니다. `isPending`은 제출 가능한 준비인지 나타냅니다. 인증 키는 SDK 내부에서 관리합니다.
- QR 문자열은 원래 값 그대로 전송합니다. 빈 문자열은 `ArgumentError`이며 아직 제출하지 않은 준비를 소비하지 않습니다. 한 번 제출을 시작한 준비는 성공·거절·오류에 관계없이 재사용할 수 없으며, 재사용 또는 취소 후 제출은 `StateError`입니다. `cancel()`은 이미 시작한 서버 요청을 중단하지 않습니다.
- 준비 후 재로그인, 자동 세션 갱신, `clearLocalState()`가 발생하면 기존 준비는 만료됩니다. 제출하면 `SessionExpiredException`이 발생하며, 다시 `prepareQrCheckIn()`으로 인증을 준비해야 합니다. 서버의 인증 키나 QR 코드 자체가 만료될 수도 있으므로 입력을 얻은 뒤 바로 제출하세요.
- 상태 변경 기능이므로 실계정 smoke test나 기본 demo 흐름에는 넣지 않습니다. 인증 코드 확인·이메일 발송·출석 제출은 세션 만료나 네트워크 오류 때 자동 재전송하지 않습니다. 결과가 불명확하면 KW출첵에서 출석 상태를 확인한 뒤 사용자가 다시 시작하도록 안내하세요.
- 서버가 실패를 반환하면 `accepted == false`와 `message`로 표시합니다. 판정할 수 없는 응답은 `ParsingException`이며 성공으로 처리하지 않습니다.

출석 과목 항목을 먼저 찾고 싶다면 helper를 사용할 수 있습니다.

```dart
final subject = await user.attendance.findSubjectItemById('CSE101');
final same = await user.attendance.findSubjectItemByTitle('자료구조');
```

출석 과목 항목으로도 같은 절차를 사용할 수 있습니다.

```dart
final prepared = await user.attendance.prepareQrCheckIn(
  subject: subject,
  onVerification: handleQrVerification,
);
final result = await prepared.submit(qrText);
```

`user.attendance.qrCheckIn(subject: ..., qrCode: ..., onVerification: ...)`와
`prepareQrCheckIn(subject: ..., onVerification: ...)`도 같은 절차를 사용합니다.
원본 응답이 필요하면 `qrCheckInRaw(...)`를 사용합니다. 모바일 앱용 설정을 별도로
지정할 필요는 없습니다.

## 4) 월간 일정 테이블 (typed)

```dart
final now = DateTime.now();
final table = await user.attendance.listMonthlyScheduleTableItems(
  year: now.year,
  month: now.month,
);
for (final row in table) {
  print('${row.weekday ?? '-'} ${row.dayOfMonth ?? '-'} / ${row.displayTitle}');
}
```

## 5) attendance feature 전체 API

- `listSubjects()`
- `listSubjectItems()`
- `findSubjectItemById()`
- `findSubjectItemByTitle()`
- `qrCheckIn()`
- `prepareQrCheckIn()`
- `qrCheckInRaw()`
- `monthList()`
- `listMonthlySchedules()`
- `monthTable()`
- `listMonthlyScheduleTableItems()`

## 6) UI 구성 추천

1. 상단 과목 탭: `listSubjectItems()`
2. QR 출석 버튼: `prepareQrCheckIn()`으로 인증 후 앱이 QR 입력을 얻어 `submit()` 호출
3. 월 캘린더 점 목록: `listMonthlyScheduleTableItems()`
4. 하단 상세 리스트: `listMonthlySchedules()`

다음: [12. 학적/프레임/헬스체크](12-student-record-frame-healthcheck.md)
