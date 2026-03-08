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

> 주의: QR 출석은 상태 변경 기능입니다. 실계정 smoke test나 README 기본 예제 흐름에는 포함하지 마세요.

```dart
final subjects = await user.attendance.listSubjectItems();
if (subjects.isEmpty) return;

final subject = subjects.first;
final result = await user.attendance.qrCheckIn(
  subject: subject,
  qrCode: scannedQrCode,
);

if (result.accepted) {
  print('출석 처리 완료');
} else {
  print('출석 실패: ${result.message ?? '사유 없음'}');
}
```

- `qrCode`는 카메라/스캐너가 읽어낸 문자열입니다.
- `qrCheckIn(...)`은 초보자용 고수준 API입니다.
- 고급 사용자가 서버 원본 응답이 필요하면 `qrCheckInRaw(...)`를 사용합니다.

출석 과목 항목을 먼저 찾고 싶다면 helper를 사용할 수 있습니다.

```dart
final subject = await user.attendance.findSubjectItemById('CSE101');
final same = await user.attendance.findSubjectItemByTitle('자료구조');
```

과목 화면에서 이미 `KlasCourse`를 가지고 있다면 더 짧게 쓸 수 있습니다.

```dart
final result = await course.qrCheckIn(scannedQrCode);
print(result.accepted);
```

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
- `qrCheckInRaw()`
- `monthList()`
- `listMonthlySchedules()`
- `monthTable()`
- `listMonthlyScheduleTableItems()`

## 6) UI 구성 추천

1. 상단 과목 탭: `listSubjectItems()`
2. QR 출석 버튼: `qrCheckIn()`
3. 월 캘린더 점 목록: `listMonthlyScheduleTableItems()`
4. 하단 상세 리스트: `listMonthlySchedules()`

다음: [12. 학적/프레임/헬스체크](12-student-record-frame-healthcheck.md)
