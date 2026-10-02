# 16. 팀 프로젝트 조회

개발 버전 `1.3.0`은 `course.teamProjects`에서 프로젝트 목록, 출제 본문,
현재 팀의 제출 결과와 팀원을 조회합니다. 일반 `KlasClient()`로 로그인한 뒤
수강 과목 객체를 사용합니다.

## 1) 목록과 제출 기간

```dart
import 'package:klasflow/klasflow.dart';

final user = await client.login(id, password);
final course = await user.defaultCourse();
if (course == null) return;

final projects = await course.teamProjects.listProjects();
for (final project in projects) {
  print('${project.number}. ${project.displayTitle}');
  print('제출 기간: ${project.startsAt} ~ ${project.dueAt}');
  print('추가 제출: ${project.additionalStartsAt} ~ ${project.additionalDueAt}');
  print('팀 번호: ${project.teamNumber}, 제출 여부: ${project.submitted}');
}
```

프로젝트가 없는 과목은 빈 목록을 반환합니다. `submitted`는 현재 팀의 제출
상태이며, 팀원 개인의 제출 여부가 아닙니다. `isWithinSubmissionPeriod`와
`isWithinAdditionalSubmissionPeriod`는 KLAS가 알려준 기간 상태입니다.
서버에 없는 날짜나 상태는 `null`이므로 미제출이나 기간 종료로 단정하지 마세요.

`submissionVisibility`는 교수가 설정한 제출물 공개 범위입니다.
`bestSubmissions`, `allSubmissions`, `private` 중 하나이며, 알 수 없는 설정은
`null`입니다. 이 값은 다른 팀의 제출물을 조회하는 기능을 제공하지 않습니다.

## 2) 본문과 현재 팀의 제출 결과

```dart
if (projects.isEmpty) return;

final project = projects.first;
final detail = await course.teamProjects.getDetail(project);
print(detail.contentHtml);
print('주차: ${detail.week}, 차시: ${detail.session}');
print('기본 점수: ${detail.basicScore}');
print('허용 파일: ${detail.allowedFileTypes}');
print('파일 크기 제한(MB): ${detail.fileSizeLimitMegabytes}');

final submission = detail.submission;
if (submission != null) {
  print(submission.title);
  print(submission.content);
  print('점수: ${submission.score}');
  print('우수 제출물 선정: ${submission.isSelectedAsBest}');
  print(submission.instructorFeedback);
}
```

출제 본문 `contentHtml`은 HTML이고, 제출 본문 `content`와 교수 의견
`instructorFeedback`은 줄바꿈을 보존한 텍스트입니다. 앱이 표시 방식을
선택합니다. 제출 결과가 없으면 `submission`은 `null`이고, 아직 제공되지 않은
점수나 교수 의견도 `null`입니다. `isCurrentUserLeader`는 현재 사용자의 팀장
여부이며, KLAS가 값을 제공하지 않으면 `null`입니다.

목록에서 받은 프로젝트를 같은 과목의 상세·팀원 조회에 전달하세요. SDK는 조회
직전에 목록을 다시 확인해 현재 프로젝트와 팀을 선택합니다. 다른 과목이나
학기의 객체를 전달하면 `ArgumentError`, 삭제되거나 조회할 수 없는 프로젝트는
`TeamProjectUnavailableException`입니다. 잘못된 응답이나 서버 오류는 예외로
전달되어 빈 목록과 구별할 수 있습니다.

## 3) 첨부파일 다운로드

상세 조회는 다음 파일 그룹을 자동으로 준비합니다.

- `detail.files`: 교수의 출제 첨부파일
- `detail.submission?.files`: 현재 팀의 제출 파일
- `detail.submission?.feedbackFiles`: 교수의 첨삭 자료

```dart
for (final file in detail.files) {
  final payload = await file.download();
  print('${file.fileName}: ${payload.bytes.length} bytes');
  // 앱이나 CLI에서 payload.bytes를 저장하거나 표시합니다.
}
```

파일이 없으면 해당 목록은 비어 있습니다. 본문만 필요하면
`getDetail(project, includeFiles: false)`를 호출하세요. 이 경우 파일 메타데이터
조회가 생략되고 파일 목록도 비어 있으므로 실제 첨부 유무를 판단할 수 없습니다.

## 4) 팀원 조회

```dart
final members = await course.teamProjects.listMembers(project);
for (final member in members) {
  print('${member.name} / ${member.department}');
  print('학번: ${member.studentId}, 이메일: ${member.email}');
  print('팀 번호: ${member.teamNumber}, 팀장: ${member.isLeader}');
}
```

팀이 배정되지 않았거나 팀원 목록이 없으면 빈 목록을 반환합니다. 표시되지 않은
이름·학과·학번·이메일·팀장 여부는 `null`입니다.

기존 `course.learning.teamProjects()`는 학습 현황용 조회로 유지됩니다.
프로젝트 본문과 팀원을 읽으려면 이 페이지의 `course.teamProjects`를 사용하세요.
현재 API는 조회와 첨부파일 다운로드를 지원하며 제출·업로드·팀 변경은 포함하지
않습니다.

현재 계정에 프로젝트가 없어 실계정 검증은 빈 목록 조회까지 수행했습니다.
본문·팀원·세 종류의 첨부파일과 오류 처리는 합성 HTTP 응답으로 검증합니다.
