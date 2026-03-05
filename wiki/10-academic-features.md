# 10. 학사/성적 기능

`user.academic`은 성적/장학/어학/석차 같은 학사 데이터를 조회할 때 사용합니다.

## 1) 성적 목록(typed): `listGradeEntries`

```dart
final grades = await user.academic.listGradeEntries();
for (final g in grades) {
  print('${g.displaySubjectName} / ${g.grade ?? '-'} / ${g.credit ?? '-'}');
}
```

성적 화면은 이 메서드부터 시작하는 것을 권장합니다.

## 2) 성적 요약: `gradeSummary`

```dart
final summary = await user.academic.gradeSummary();
print(summary.raw);
```

## 3) 학사 feature 전체 조회 API

- `checkTerm()`
- `hakjukInfo()`
- `programCategory()`
- `sugangOption()`
- `listGrades()`
- `listGradeEntries()`
- `gradeSummary()`
- `listDeletedApplications()`
- `deletedHakjukInfo()`
- `listDeletedGrades()`
- `gyoyangInfo()`
- `listPortfolio()`
- `listScholarshipHistory()`
- `listScholarships()`
- `listLectureEvalCourses()`
- `listLectureEvalDepartments()`
- `listStanding()`
- `listToeicInfo()`
- `toeicLevelText()`
- `listToeicRecords()`

## 4) 실전 운영 팁

- 화면 MVP는 `listGradeEntries` + `gradeSummary`만으로 충분합니다.
- 나머지 API는 메뉴 확장 시점에 단계적으로 추가하세요.
- 반환이 `KlasRecord`인 경우, 필드 의존성을 앱 내부 DTO로 한 번 감싸면 유지보수가 쉬워집니다.

다음: [11. 출석/월간 일정 기능](11-attendance-features.md)

