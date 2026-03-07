# Live Feature Coverage

`klasflow`의 공개 고수준 API를 기능 단위로 정리한 실 테스트 커버리지 문서입니다.

- 기준일: 2026-03-07
- `자동 테스트`는 mock HTTP 기반 단위 테스트 존재 여부를 뜻합니다.
- `실계정 수동 테스트 허용`은 저장소 정책상 사람 손으로 실계정에 대해 테스트해도 되는지 여부를 뜻합니다.
- `수동 테스트 완료`는 사람이 직접 실제 환경에서 확인한 기록이 문서화되어 있는지 여부를 뜻합니다.

| 영역 | 대표 공개 API | 대표 시나리오 | 성격 | 자동 테스트 | 실계정 수동 테스트 허용 | 수동 테스트 완료 | 정책 / 제약 |
|---|---|---|---|---|---|---|---|
| 로그인 / 세션 | `KlasClient.login`, `requestCaptchaImage`, `startSessionHeartbeat`, `runHealthCheck` | [02. 로그인과 세션 관리](../wiki/02-login-and-session.md) | 읽기 전용 | Yes | Yes | No | 캡차/세션 만료/헬스체크는 mock 테스트 존재 |
| 사용자 프로필 | `KlasUser.profile`, `sessionStatus`, `personalInfo`, `keepAlive` | [03. 사용자 정보와 수강 과목 컨텍스트](../wiki/03-user-profile-and-courses.md) | 읽기 전용 | Yes | Yes | No | 기본 사용자 식별/세션 조회 |
| 수강 과목 컨텍스트 | `KlasUser.courses`, `defaultCourse`, `findCourseById`, `findCourseByTitle` | [03. 사용자 정보와 수강 과목 컨텍스트](../wiki/03-user-profile-and-courses.md) | 읽기 전용 | Yes | Yes | No | 과목 컨텍스트 바인딩 및 course lookup helper 포함 |
| 과제 / 강의 개요 | `KlasCourse.overview`, `scheduleText`, `listTasks`, `learning.getTaskDetail` | [04. 과목 개요와 과제 조회](../wiki/04-course-overview-and-tasks.md) | 읽기 전용 | Yes | Yes | No | course context 주입 테스트 존재 |
| 공지 / 자료실 | `noticeBoard.*`, `materialBoard.*`, `KlasBoardPostSummary.getPost` | [05. 공지사항/자료실 조회](../wiki/05-board-list-and-detail.md) | 읽기 전용 | Yes | Yes | No | 목록/상세/원문 페이지 |
| 첨부파일 | `files.listByAttachId`, `KlasAttachedFile.download`, `files.download` | [06. 첨부파일 다운로드](../wiki/06-attachments-download.md) | 읽기 전용 | Yes | Yes | No | 다운로드는 mock binary 테스트 존재 |
| 온라인 학습 | `learning.listOnlineContentItems`, `listOnlineTestItems`, `listAnytimeQuizItems`, `listDiscussionItems` | [07. 온라인 학습 기능](../wiki/07-learning-features.md) | 읽기 전용 | Yes | Yes | No | typed 모델 매핑 테스트 존재 |
| 설문 / e-Class | `surveys.listSurveyItems`, `surveys.openPage`, `eclass.listEClassItems` | [08. 설문과 e-Class](../wiki/08-survey-and-eclass.md) | 읽기 전용 | Yes | Yes | No | 조회 중심 |
| 시간표 / 수강 | `enrollment.listTimetableEntries`, `enrollment.timetable`, `user.timetable` | [09. 학기 시간표](../wiki/09-timetable.md) | 읽기 전용 | Yes | Yes | No | typed timetable 테스트 존재 |
| 출석 / 월간 일정 | `attendance.listSubjectItems`, `listMonthlySchedules`, `listMonthlyScheduleTableItems` | [11. 출석/월간 일정 기능](../wiki/11-attendance-features.md) | 읽기 전용 | Yes | Yes | No | 출석 과목 / 일정 조회 |
| QR 출석 | `attendance.qrCheckIn`, `attendance.qrCheckInRaw`, `course.qrCheckIn` | [11. 출석/월간 일정 기능](../wiki/11-attendance-features.md) | 상태 변경 | Yes | No | No | 실제 출석 상태를 바꾸므로 실계정 수동 테스트 금지 |
| 학사 / 성적 | `academic.*` | [10. 학사/성적 기능](../wiki/10-academic-features.md) | 읽기 전용 | Yes | Yes | No | 성적/장학/어학/강의평가 조회 |
| 학적 | `studentRecord.temporaryLeaveHakjuk`, `temporaryLeaveStatus` | [12. 학적/프레임/헬스체크](../wiki/12-student-record-frame-healthcheck.md) | 읽기 전용 | Yes | Yes | No | 현재는 조회만 포함 |
| 프레임 / 홈 요약 | `frame.homeOverview`, `scheduleSummary`, `gyojikExamCheck` | [12. 학적/프레임/헬스체크](../wiki/12-student-record-frame-healthcheck.md) | 읽기 전용 | Yes | Yes | No | 홈/프레임성 보조 정보 |

## 수동 테스트 상태 해석

| 값 | 의미 |
|---|---|
| `Yes` | 사람이 실제 환경에서 수행했고, 기록이 남아 있음 |
| `No` | 아직 사람이 직접 완료한 기록이 없음 |

## 운영 메모

- 상태 변경 기능은 실계정 수동 테스트를 기본 금지로 유지합니다.
- 새 기능을 추가할 때는 이 표에 반드시 행을 추가하고, `자동 테스트`와 `수동 테스트 완료`를 함께 갱신합니다.
- 수동 테스트를 실제로 완료했다면 날짜, 환경, 계정 범위, 확인 결과를 별도 증빙 문서나 PR 설명에 남긴 뒤 이 표를 `Yes`로 바꿉니다.
- 증빙 문서가 필요하면 `docs/live_test_evidence_template.md`를 시작점으로 사용합니다.

## Latest Validation Snapshot

| 항목 | 명령 | 결과 | 실행일 |
|---|---|---|---|
| Scoped analyze | `dart analyze lib test tool` | Passed | 2026-03-07 |
| Full unit test suite | `dart test` | Passed | 2026-03-07 |
| QR attendance targeted tests | `dart test test/high_level_api_test.dart -n 'attendance QR check-in|course.qrCheckIn'` | Passed | 2026-03-07 |
| High-level coverage | `dart test test/high_level_feature_coverage_test.dart` | Passed | 2026-03-07 |
