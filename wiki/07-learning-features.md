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

## 4) 온라인 동영상 강의 재생

개발 버전 `1.3.0`부터 `course.learning.listVideoLectures()`로 온라인 영상만
조회합니다. `KlasVideoLecture`에는 제목, 주차, 학습 기간, 현재 진도,
시청 가능 여부가 있습니다. 학습 기간이 종료된 영상도 복습할 수 있지만
`playback.canRecordProgress`가 false이면 학습 인정 진도를 저장하지 않습니다.

```dart
import 'package:klasflow/klasflow.dart';

final lectures = await course.learning.listVideoLectures();
if (lectures.isEmpty) return;

final playback = await course.learning.openVideo(lectures.first);
final media = playback.media;
final source = media.sources.first;
// 사용하는 플레이어에 source.uri와 source.format을 전달합니다.
// media.duration은 영상 길이이고, embedUri는 제공되는 경우 공식 임베드입니다.
```

SDK는 UI를 열거나 영상을 자동 재생하지 않습니다. Flutter, 데스크톱 앱,
CLI 등 호출자가 선택한 플레이어를 사용하며 MP4 또는 HLS 주소를 반환합니다.
`openVideo`는 재생 정보를 준비하고, 진도 저장은 실제 플레이어 이벤트가
`recordPlayback`에 전달될 때 시작됩니다.

## 5) 실제 플레이어 이벤트와 진도 저장

재생 중에는 1~5초마다 현재 위치와 상태를 전달하고, 일시정지·버퍼링·탐색·종료
이벤트는 즉시 전달하세요. 동시에 호출할 수 없으므로 앱에서 순서대로 await하거나
이벤트 큐를 사용합니다. 아래 함수는 플레이어 연동 지점을 보여줍니다.

```dart
Future<KlasVideoProgress> onPlayerEvent(
  Duration position,
  KlasVideoPlaybackState state,
) async {
  return playback.recordPlayback(position: position, state: state);
}

await onPlayerEvent(Duration.zero, KlasVideoPlaybackState.playing);
// 이후 실제 플레이어 이벤트에서 현재 위치와 상태를 전달합니다.
// paused, buffering, seeking, ended도 같은 함수로 전달합니다.

// 화면이나 플레이어가 종료되면 대기 중인 이벤트 처리를 마친 뒤 호출합니다.
final finalProgress = await playback.close();
```

저장은 공식 재생 흐름에 맞춰 60초 간격으로 수행하고, 반환된 진도와 인정 시간만
`playback.progress`에 반영합니다. 일시정지·버퍼링·탐색 후 재개하면 새 재생 구간을
시작합니다. 10초보다 긴 이벤트 공백도 새 구간으로 처리하며, 60초보다 짧은
미저장 구간은 인정되지 않을 수 있습니다. 앱이 시청하지 않는 동안 타이머로
`playing` 이벤트를 만들지 마세요.

`progress.watchedDuration`은 학습 인정 시간이고 영상의 마지막 위치가 아닙니다.
이어보기 위치는 앱에서 저장한 뒤 플레이어에 적용하세요. `ended`와 `close()`는
진도를 강제로 100%로 바꾸지 않습니다. 출석 인정은 별도 조건이 있을 수 있습니다.

로그인이 바뀌거나 다른 온라인 영상을 준비하면 기존 세션이 무효화됩니다.
`checkStatus()`로 서버의 재생 세션 상태도 확인할 수 있습니다. 네트워크 오류나
세션 중단이 발생하면 플레이어를 멈추고 목록과 진도를 다시 조회한 후 새로
`openVideo`를 호출하세요. 저장 성공 여부가 불확실한 요청은 자동 재전송하지 않습니다.

## 6) 강의의 추가 인증

일부 강의는 이메일 또는 이미 등록된 OTP를 요구합니다. `onVerification`
콜백은 UI에 의존하지 않으며 입력 방식은 앱에서 정합니다.

```dart
final playback = await course.learning.openVideo(
  lecture,
  maxVerificationAttempts: 3,
  onVerification: (challenge) async {
    // 앱에서 이메일 인증을 선택했을 때만 발송합니다.
    await challenge.requestEmailCode();
    final code = await promptForCode(challenge.emailHint);
    if (code == null) return null;
    return KlasVideoVerificationAnswer(
      method: KlasVideoVerificationMethod.email,
      code: code, // 앞의 0을 포함한 문자열을 유지합니다.
    );
  },
);
```

기존 OTP를 입력받으려면 `challenge.otpAvailable`을 확인하고
`KlasVideoVerificationMethod.otp`를 반환합니다. 입력 취소는 null입니다.
인증 콜백이 없으면 `VideoVerificationRequiredException`으로 요청을 알립니다.
인증 실패나 입력 취소는 `VideoVerificationException`입니다. OTP 신규 등록은
공식 앱에서 진행합니다.

미디어 주소와 재생 세션은 현재 재생에만 사용하고 로그에 기록하지 마세요.
SDK는 외부 미디어 메타데이터에 KLAS 세션 쿠키를 전달하지 않습니다.

E-class 녹화 강의의 복습은 별도 API를 사용합니다.
다음: [08. 설문과 e-Class](08-survey-and-eclass.md)

