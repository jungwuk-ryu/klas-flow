# 04. 과목 개요와 과제 조회

이 페이지에서는 과목 단위 화면에서 가장 먼저 필요한 기능을 다룹니다.

## 1) 과목 홈 개요: `course.overview`

```dart
final overview = await course.overview();
print(overview.raw.data.keys);
```

- 반환 타입: `KlasCourseOverview`
- 내부에 `KlasRecord`를 담고 있어 화면 요구에 맞게 안전하게 꺼내 쓸 수 있습니다.

## 2) 과목 시간표 텍스트: `course.scheduleText`

```dart
final text = await course.scheduleText();
print(text ?? '시간표 정보 없음');
```

과목 카드의 요약 UI(예: "월 3-4교시")에 가볍게 사용하기 좋습니다.

## 3) 과제 목록: `course.listTasks`

```dart
final tasks = await course.listTasks(page: 0);
for (final t in tasks) {
  print('${t.title} / 제출=${t.submitted} / 마감=${t.endAt}');
}
```

- 반환 타입: `List<KlasTask>`
- 과제 화면 기본 리스트 구성에 바로 사용 가능합니다.

## 4) 초급자 추천 패턴

1. `defaultCourse()`로 진입 과목 결정
2. `overview()`로 상단 요약 카드 구성
3. `listTasks(page: 0)`로 본문 목록 구성
4. 페이지네이션 필요 시 `page` 증가

다음: [05. 공지사항/자료실 조회](05-board-list-and-detail.md)

