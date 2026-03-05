# 09. 학기 시간표

학기 시간표는 사용자 체감 가치가 큰 기능입니다.  
`klasflow`에서는 typed 모델로 바로 화면을 만들 수 있도록 제공합니다.

## 1) 사용자 단위 조회: `user.timetable`

```dart
final timetable = await user.timetable();
if (timetable.isEmpty) {
  print('시간표 없음');
}
```

## 2) 엔트리 목록 조회

```dart
final entries = await user.enrollment.listTimetableEntries();
for (final e in entries) {
  print('${e.title} / ${e.scheduleText ?? '-'} / ${e.classroom ?? '-'}');
}
```

## 3) 요일별 그룹화

```dart
final grouped = timetable.groupedByWeekday;
for (final day in grouped.entries) {
  print('[${day.key}] ${day.value.length}개');
}
```

UI 구현 팁:

- 탭: `월/화/수/목/금` 기준
- 카드 제목: `entry.title`
- 보조 라벨: `entry.professorName`, `entry.classroom`
- 시간 라벨: `entry.scheduleText`

## 4) enrollment feature 직접 사용

```dart
final t = await user.enrollment.timetable();
```

`user.timetable()`와 동일한 목적이며, 팀 스타일에 맞게 하나로 통일하면 됩니다.

## 5) 관련 메서드

- `listTimetableEntries()`: 화면용 리스트
- `timetable()`: 그룹화/정렬 포함 구조
- `listTimetable()`: `KlasRecord` 기반 원형 데이터

다음: [10. 학사/성적 기능](10-academic-features.md)

