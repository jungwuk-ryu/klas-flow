# Live Feature Coverage

`klasflow`의 공개 고수준 API를 기능 단위로 정리한 실 테스트 커버리지 문서입니다.

- 기준일: 2026-10-02
- `자동 테스트`는 mock HTTP 기반 단위 테스트 존재 여부를 뜻합니다.
- `실계정 수동 테스트 허용`은 저장소 정책상 사람 손으로 실계정에 대해 테스트해도 되는지 여부를 뜻합니다.
- `수동 테스트 완료`는 사람이 직접 실제 환경에서 확인한 기록이 문서화되어 있는지 여부를 뜻합니다.

| 영역 | 대표 공개 API | 대표 시나리오 | 성격 | 자동 테스트 | 실계정 수동 테스트 허용 | 수동 테스트 완료 | 정책 / 제약 |
|---|---|---|---|---|---|---|---|
| 로그인 / 세션 | `KlasClient.login`, `requestCaptchaImage`, `startSessionHeartbeat`, `runHealthCheck` | [02. 로그인과 세션 관리](../wiki/02-login-and-session.md) | 읽기 전용 | Yes | Yes | Yes | 캡차/세션 만료/헬스체크는 mock 테스트 존재 |
| 캡차 입력 후 로그인 계속 | `KlasClient.login(onCaptcha: ..., maxCaptchaAttempts: ...)`, `KlasCaptchaChallenge` | [02. 로그인과 세션 관리](../wiki/02-login-and-session.md) | 인증 | Yes | Yes | No | 공개 로그인 페이지의 동작 확인. PEM/legacy, 쿠키 유지, 재입력/취소/한도, 자동 갱신은 mock 검증. 실계정에 캡차를 강제로 유발하지 않음 |
| 사용자 프로필 | `KlasUser.profile`, `sessionStatus`, `personalInfo`, `keepAlive` | [03. 사용자 정보와 수강 과목 컨텍스트](../wiki/03-user-profile-and-courses.md) | 읽기 전용 | Yes | Yes | Yes | 기본 사용자 식별/세션 조회 |
| 수강 과목 컨텍스트 | `KlasUser.courses`, `defaultCourse`, `findCourseById`, `findCourseByTitle` | [03. 사용자 정보와 수강 과목 컨텍스트](../wiki/03-user-profile-and-courses.md) | 읽기 전용 | Yes | Yes | Yes | 과목 컨텍스트 바인딩 및 course lookup helper 포함 |
| 과제 / 강의 개요 | `KlasCourse.overview`, `scheduleText`, `listTasks`, `learning.getTaskDetail` | [04. 과목 개요와 과제 조회](../wiki/04-course-overview-and-tasks.md) | 읽기 전용 | Yes | Yes | Yes | course context 주입 테스트 존재 |
| 공지 / 자료실 | `noticeBoard.*`, `materialBoard.*`, `KlasBoardPostSummary.getPost` | [05. 공지사항/자료실 조회](../wiki/05-board-list-and-detail.md) | 읽기 전용 | Yes | Yes | Yes | 목록/상세/원문 페이지 |
| 첨부파일 | `files.listByAttachId`, `KlasAttachedFile.download`, `files.download` | [06. 첨부파일 다운로드](../wiki/06-attachments-download.md) | 읽기 전용 | Yes | Yes | Yes | 다운로드는 mock binary 테스트 존재 |
| 온라인 학습 | `learning.listOnlineContentItems`, `listOnlineTestItems`, `listAnytimeQuizItems`, `listDiscussionItems` | [07. 온라인 학습 기능](../wiki/07-learning-features.md) | 읽기 전용 | Yes | Yes | No | typed 모델 매핑 테스트 존재 |
| 설문 / e-Class | `surveys.listSurveyItems`, `surveys.openPage`, `eclass.listEClassItems` | [08. 설문과 e-Class](../wiki/08-survey-and-eclass.md) | 읽기 전용 | Yes | Yes | No | 조회 중심 |
| 시간표 / 수강 | `enrollment.listTimetableEntries`, `enrollment.timetable`, `user.timetable` | [09. 학기 시간표](../wiki/09-timetable.md) | 읽기 전용 | Yes | Yes | No | typed timetable 테스트 존재 |
| 출석 / 월간 일정 | `attendance.listSubjectItems`, `findSubjectItemById`, `findSubjectItemByTitle`, `listMonthlySchedules`, `listMonthlyScheduleTableItems` | [11. 출석/월간 일정 기능](../wiki/11-attendance-features.md) | 읽기 전용 | Yes | Yes | No | 출석 과목 조회, lookup helper, 월 조회 범위와 전체 시작·종료 일시, 월 경계/윤년/잘못된 날짜 mock 검증 |
| QR 출석 | `attendance.qrCheckIn`, `qrCheckInRaw`, `prepareQrCheckIn`, `course.qrCheckIn`, `course.prepareQrCheckIn`, `KlasQrCheckInSession.submit` | [11. 출석/월간 일정 기능](../wiki/11-attendance-features.md) | 상태 변경 | Yes | No | No | 기본 클라이언트의 모바일 식별 자동 처리와 요청 격리, 과목 마감, 이메일/기존 OTP, 외부 QR 문자열 입력, 준비/취소/일회 제출, 세션 변경 시 무효화, 실패 판정, 자동 재전송 방지를 mock 검증. 실계정 출석 제출 금지 |
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
- 증빙 문서가 필요하면 `doc/live_test_evidence_template.md`를 시작점으로 사용합니다.

## Latest Validation Snapshot

2026-10-02 월별 일정 확인에서는 로그인된 Chrome의 2026년 10월 목록과
읽기 전용 월 범위 조회의 일정 10건이 일치했습니다. 기존 요청은 500을
반환했고, 월의 시작일부터 다음 월의 시작일까지 지정한 요청은 200을
반환했습니다. 계정 식별자와 응답 원본은 저장소에 기록하지 않았습니다.
이 기록은 자동화된 읽기 검증이며 아래의 사람 수동 테스트 완료 상태와
구분합니다.

2026-10-02의 모바일 QR 작업에서는 로그인한 Chrome에서 KW출첵 과목 선택과
QR 출석 버튼이 표시되는 것까지 읽기 전용으로 확인했습니다. 추가 인증 발송,
기기 등록, QR 스캔/출석 제출은 실행하지 않았습니다. 이 확인은 실제 출석
접수가 성공했다는 검증을 뜻하지 않습니다.

| 항목 | 명령 | 결과 | 실행일 |
|---|---|---|---|
| Scoped analyze | `dart analyze lib test tool` | Passed | 2026-10-02 |
| Full unit test suite | `dart test` | Passed (128 tests, 월간 일정 모델 회귀 10개와 CI 커밋 범위 회귀 3개 포함) | 2026-10-02 |
| Mobile QR attendance | `dart test test/mobile_qr_attendance_test.dart` (full suite에 포함) | Passed (34 tests) | 2026-10-02 |
| High-level coverage | `dart test test/high_level_feature_coverage_test.dart` (full suite에 포함) | Passed | 2026-10-02 |
| Captcha login and parser | `dart test test/captcha_login_test.dart test/login_parser_test.dart` | Passed (21 tests) | 2026-10-02 |
| Integrated check | `dart run tool/check_all.dart` | Passed | 2026-10-02 |
| CLI compatibility | 로컬 SDK를 사용하는 `klas-cli`의 `dart analyze`, `dart test`, `dart compile exe bin/klas.dart -o build/klas.exe` | Passed (87 tests), executable built | 2026-10-02 |
