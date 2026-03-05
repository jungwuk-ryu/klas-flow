# 08. 설문과 e-Class

이 페이지는 강의 운영 보조 기능(설문, e-Class)을 간단하고 안정적으로 붙이는 방법을 다룹니다.

## 1) 설문 목록: `course.surveys.listSurveyItems`

```dart
final surveys = await course.surveys.listSurveyItems();
for (final s in surveys) {
  print('${s.displayTitle} / 상태=${s.status ?? '-'}');
}
```

필요 시 설문 페이지 원문도 열 수 있습니다.

```dart
final html = await course.surveys.openPage();
print('html length: ${html.length}');
```

## 2) e-Class 목록: `course.eclass.listEClassItems`

```dart
final items = await course.eclass.listEClassItems(page: 0);
for (final item in items) {
  print('${item.displayTitle} / ${item.startAt} ~ ${item.endAt}');
}
```

## 3) 언제 `list(...)`/`listItems(...)`를 쓰나요?

- `listSurveyItems`, `listEClassItems`: UI 중심, 타입 안정성 우선
- `list`, `listItems`: 아직 모델이 없는 추가 필드가 필요할 때

실무에서는 보통 화면용 코드는 typed API를 기본으로 두고,  
예외 케이스만 `raw` 접근을 혼합합니다.

다음: [09. 학기 시간표](09-timetable.md)

