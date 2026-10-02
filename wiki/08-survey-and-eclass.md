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

## 3) E-class 녹화 강의 복습

E-class는 강의실에서 녹화한 영상을 복습하는 기능입니다. 온라인 콘텐츠와
목록과 재생 경로가 다르며, 온라인 강의의 학습 진도 저장은 제공하지 않습니다.
개발 버전 `1.3.0`의 `listRecordings`와 `openVideo`를 사용하세요.

```dart
final recordings = await course.eclass.listRecordings();
if (recordings.isEmpty) return;

final recording = recordings.first;
print('${recording.displayTitle} / ${recording.recordedAt}');
final media = await course.eclass.openVideo(recording);
final source = media.sources.first;
// 앱의 플레이어에 source.uri를 전달하여 복습합니다.
```

`KlasEClassRecording`은 영상 식별자, 과목·학기, 제목, 녹화 일시와 영상 길이를
제공합니다. `openVideo`는 과목의 최신 목록에서 영상을 확인한 후
`KlasVideoMedia`를 반환합니다. 최근 녹화와 구형 녹화의 재생 방식을 SDK가
구분해서 처리합니다. 구형 녹화는 `media.embedUri`가 null일 수 있으며
`media.sources`의 직접 재생 주소를 사용합니다.

SDK가 플레이어를 띄우지 않으므로 Flutter, 데스크톱, CLI에서 각자 플레이어를
연결할 수 있습니다. 복습의 이어보기 위치는 앱에서 저장하세요. E-class에는
`KlasVideoPlaybackSession`이나 온라인 학습 진도 쓰기를 연결하지 않습니다.
반환된 미디어 주소는 현재 재생에만 사용하고 로그나 공개 저장소에 기록하지 마세요.

## 4) 언제 `list(...)`/`listItems(...)`를 쓰나요?

- `listSurveyItems`, `listEClassItems`: UI 중심, 타입 안정성 우선
- `list`, `listItems`: 아직 모델이 없는 추가 필드가 필요할 때

실무에서는 보통 화면용 코드는 typed API를 기본으로 두고,  
예외 케이스만 `raw` 접근을 혼합합니다.

다음: [09. 학기 시간표](09-timetable.md)

