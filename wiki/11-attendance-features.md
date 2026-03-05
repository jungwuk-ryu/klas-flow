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

## 3) 월간 일정 테이블 (typed)

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

## 4) attendance feature 전체 API

- `listSubjects()`
- `listSubjectItems()`
- `monthList()`
- `listMonthlySchedules()`
- `monthTable()`
- `listMonthlyScheduleTableItems()`

## 5) UI 구성 추천

1. 상단 과목 탭: `listSubjectItems()`
2. 월 캘린더 점 목록: `listMonthlyScheduleTableItems()`
3. 하단 상세 리스트: `listMonthlySchedules()`

다음: [12. 학적/프레임/헬스체크](12-student-record-frame-healthcheck.md)
