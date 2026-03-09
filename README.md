# klasflow

`klasflow`는 Flutter/Dart 앱에서 KLAS를 도메인 객체 중심으로 다루기 위한 고수준 SDK입니다.

## 프로젝트 상태

- 현재 **개발 단계(Work in Progress)** 입니다.
- 아직 **pub.dev에 배포하지 않았습니다**.
- API/모델/동작은 다음 버전에서 변경될 수 있습니다.

## 이 SDK가 해결하는 문제

앱 코드에서 다음과 같은 저수준 호출을 직접 다루지 않도록 하는 것이 목표입니다.

- endpoint ID 문자열
- `payload` 맵 키 조합
- 세션 만료/재로그인 처리
- 과목 컨텍스트(`selectYearhakgi`, `selectSubj`) 주입

고수준 흐름:

1. `login`
2. `user`
3. `courses`
4. `course.feature.*`

## 설치

아직 pub.dev 미배포 상태이므로 `path` 또는 `git` 의존성으로 사용해 주세요.

`pubspec.yaml` 예시 (`path`):

```yaml
dependencies:
  klasflow:
    path: ../klasflow
```

`pubspec.yaml` 예시 (`git`):

```yaml
dependencies:
  klasflow:
    git:
      url: https://github.com/jungwuk-ryu/klas-flow.git
      ref: master
```

## 빠른 시작

```dart
import 'package:klasflow/klasflow.dart';

Future<void> main() async {
  final client = KlasClient();

  try {
    final user = await client.login('학번', '비밀번호');
    final profile = await user.profile(refresh: true);
    final courses = await user.courses(refresh: true);

    print('로그인 사용자: ${profile.userName} (${profile.userId})');
    print('수강 과목 수: ${courses.length}');
  } on KlasException catch (error) {
    print('KLAS 요청 실패: $error');
  } finally {
    client.close();
  }
}
```

## 사용 예제

### 1) 기본 과목에서 과제 조회

```dart
final user = await client.login(id, password);
final course = await user.defaultCourse();
if (course == null) return;

final tasks = await course.listTasks(page: 0);
for (final task in tasks) {
  print('[과제] ${task.title} / 제출=${task.submitted}');
}
```

### 2) 공지사항 목록 + 상세 조회

```dart
final notices = await course.noticeBoard.listPosts(page: 0);
if (notices.posts.isEmpty) return;

final first = notices.posts.first;
final detail = await first.getPost();

print('공지 제목: ${first.title}');
print('상세 keys: ${detail.board?.raw.keys.toList()}');
```

### 3) 첨부파일 목록 조회 + 다운로드

```dart
final post = notices.posts.firstWhere((p) => (p.fileCount ?? 0) > 0);
final attachId = post.attachId;
if (attachId == null || attachId.isEmpty) return;

final files = await user.files.listByAttachId(attachId: attachId);
if (files.isEmpty) return;

final file = files.first;
final payload = await file.download();

print('다운로드 파일명: ${file.fileName}');
print('바이트 수: ${payload.bytes.length}');
```

### 4) 학습 항목 조회 (온라인 콘텐츠/시험/퀴즈/토론)

```dart
final contents = await course.learning.onlineContents(page: 0);
final tests = await course.learning.onlineTests(page: 0);
final quizzes = await course.learning.listAnytimeQuizzes(page: 0);
final discussions = await course.learning.listDiscussions(page: 0);

print('온라인콘텐츠=${contents.length}');
print('온라인시험=${tests.length}');
print('수시퀴즈=${quizzes.length}');
print('토론=${discussions.length}');
```

### 5) 학기 시간표 조회 (고수준)

```dart
final timetable = await user.timetable();

for (final entry in timetable.entries) {
  print('${entry.title} | ${entry.scheduleText ?? '-'} | ${entry.classroom ?? '-'}');
}

for (final day in timetable.groupedByWeekday.entries) {
  print('[${day.key}] ${day.value.length}개 수업');
}
```

### 6) 클라이언트 헬스체크/하트비트

```dart
client.startSessionHeartbeat(
  interval: const Duration(minutes: 5),
  onError: (error, stackTrace) {
    print('heartbeat error: $error');
  },
);

final report = await client.runHealthCheck();
print('health passed=${report.allPassed} failed=${report.failedCount}');
```

## 주요 API

- `KlasClient.login(...) -> KlasUser`
- `KlasUser.profile(...)`
- `KlasUser.personalInfo(...)`
- `KlasUser.courses(...)`
- `KlasUser.defaultCourse(...)`
- `KlasCourse.listTasks(...)`
- `KlasCourse.noticeBoard.listPosts(...)`
- `KlasCourse.noticeBoard.getPost(...)`
- `KlasBoardPostSummary.getPost(...)`
- `KlasCourse.materialBoard.*`
- `KlasCourse.learning.*`
- `KlasUser.timetable(...)`
- `KlasEnrollmentFeature.listTimetableEntries(...)`
- `KlasEnrollmentFeature.timetable(...)`
- `KlasFileFeature.listByAttachId(...)`
- `KlasFileFeature.download(...)`
- `KlasAttachedFile.download(...)`
- `KlasClient.startSessionHeartbeat(...)`
- `KlasClient.runHealthCheck(...)`

## 문서

- [AGENTS.md](AGENTS.md)
- [CONTRIBUTING.md](CONTRIBUTING.md)
- [PLANS.md](PLANS.md)
- [wiki/14-high-level-api-index.md](wiki/14-high-level-api-index.md)
- [docs/live_feature_coverage.md](docs/live_feature_coverage.md)

## Flutter 데모 앱

```bash
cd example
flutter pub get
flutter run
```

## 라이브 읽기 전용 검증

```bash
$env:KLAS_ID="<id>"
$env:KLAS_PASSWORD="<password>"
dart run tool/live_account_scenarios.dart
dart run tool/live_smoke.dart
```

## 품질 점검 명령어

```bash
dart run tool/check_all.dart
dart run tool/prepublish_check.dart
```

## 커밋 메시지 컨벤션

- 형식: `type(scope): subject`
- 예시: `feat(timetable): add typed semester timetable API`
- 허용 타입: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `ci`, `build`, `perf`, `revert`

로컬 훅 활성화:

```bash
git config core.hooksPath .githooks
```

CI에서도 동일한 규칙으로 커밋 메시지를 검증합니다.

## 운영 주의사항

- 실계정 테스트는 읽기 전용 API만 사용해 주세요.
- 학번/비밀번호/토큰/쿠키를 로그/스크린샷에 남기지 마세요.
- 내부 문서나 비공개 명세는 공개 저장소에 커밋하지 마세요.

## 문서

- [아키텍처](docs/architecture.md)
- [에이전트 작업 가이드](AGENTS.md)
- [작업 계획 가이드](PLANS.md)
- [실 테스트 커버리지](docs/live_feature_coverage.md)
- [Flutter 연동](docs/flutter_integration.md)
- [위키 홈 (튜토리얼)](wiki/Home.md)
- [고수준 API 전체 인덱스](wiki/14-high-level-api-index.md)
