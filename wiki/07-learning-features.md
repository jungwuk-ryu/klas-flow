# 07. 온라인 학습 기능(콘텐츠/시험/퀴즈/토론)

학습 탭을 구현할 때 가장 자주 쓰는 `course.learning` 기능을 정리합니다.

## 1) typed 목록 API (초급자 추천)

```dart
final contents = await course.learning.listOnlineContentItems(page: 0);
final tests = await course.learning.listOnlineTestItems(page: 0);
final quizzes = await course.learning.listAnytimeQuizItems(page: 0);
final discussions = await course.learning.listDiscussionItems(page: 0);
```

각 모델의 대표 필드:

- 온라인 콘텐츠: `displayTitle`, `status`, `startAt`, `endAt`
- 온라인 시험: `displayTitle`, `status`, `startAt`, `endAt`
- 수시 퀴즈: `displayTitle`, `status`, `startAt`, `endAt`
- 토론: `displayTitle`, `status`, `startAt`, `endAt`

## 2) 상태/진도 보조 API

`KlasLearningFeature`에는 대시보드용 보조 조회도 있습니다.

- `homeInfo()`
- `attendanceStatus()`
- `attendanceStatusDetail()`
- `discussionStatus()`
- `summary()`
- `realtimeProgress()`
- `taskStatus()`
- `teamProjects()`
- `testAndQuizStatus()`

이 메서드들은 공통적으로 `KlasRecord` 또는 `List<KlasRecord>`를 반환합니다.  
즉, 화면 요구에 맞는 필드만 안전하게 선택해서 쓰는 방식입니다.

## 3) raw 스타일 메서드를 함께 써야 하는 경우

아직 typed 모델이 없는 영역은 아래 메서드로 접근합니다.

- `onlineContents(page: ...)`
- `onlineTests(page: ...)`
- `listAnytimeQuizzes(page: ...)`
- `listDiscussions(page: ...)`

권장 전략:

1. 먼저 typed 메서드 사용
2. 부족한 필드가 있으면 `raw`를 함께 확인
3. 필요성이 반복되면 SDK에 typed 모델을 추가

다음: [08. 설문과 e-Class](08-survey-and-eclass.md)

