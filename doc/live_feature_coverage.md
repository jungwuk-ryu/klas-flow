# Live Feature Coverage

`klasflow`의 공개 고수준 API를 기능 단위로 정리한 실 테스트 커버리지 문서입니다.

- 기준일: 2026-10-03
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
| 팀 프로젝트 | `teamProjects.listProjects`, `getDetail`, `listMembers` | [16. 팀 프로젝트 조회](../wiki/16-team-projects.md) | 읽기 전용 | Yes | Yes | No | 현재 계정은 프로젝트가 없어 빈 목록 조회 검증. 본문·제출 결과·점수·팀원·세 종류의 첨부파일 다운로드, 과목·팀 격리와 응답 오류는 합성 HTTP 테스트 |
| 강의계획서 | `KlasCourse.syllabus`, `KlasSyllabus` | [15. 강의계획서 조회](../wiki/15-course-syllabus.md) | 읽기 전용 | Yes | Yes | No | 학부 수강 과목의 본문·평가·교재·주차·연락처·시간표 조회. 일반형과 공통형, 미등록·폐강·조회 제한·응답 오류는 mock 검증. 대학원 및 별도 실험·설계 상세표는 범위 밖 |
| 공지 / 자료실 | `noticeBoard.*`, `materialBoard.*`, `KlasBoardPostSummary.getPost` | [05. 공지사항/자료실 조회](../wiki/05-board-list-and-detail.md) | 읽기 전용 | Yes | Yes | Yes | 목록/상세/원문 페이지 |
| 첨부파일 | `files.listByAttachId`, `KlasAttachedFile.download`, `files.download` | [06. 첨부파일 다운로드](../wiki/06-attachments-download.md) | 읽기 전용 | Yes | Yes | Yes | 다운로드는 mock binary 테스트 존재 |
| 온라인 학습 | `learning.listOnlineContentItems`, `listOnlineTestItems`, `listAnytimeQuizItems`, `listDiscussionItems` | [07. 온라인 학습 기능](../wiki/07-learning-features.md) | 읽기 전용 | Yes | Yes | No | typed 모델 매핑 테스트 존재 |
| 온라인 영상 재생 정보 | `learning.listVideoLectures`, `learning.openVideo`, `KlasVideoMedia` | [07. 온라인 학습 기능](../wiki/07-learning-features.md) | 조회 / 재생 준비 | Yes | Yes | No | 공식 뷰어와 미디어 설명, 실제 MP4 메타데이터는 읽기 확인. 추가 인증과 재생 준비 실패는 mock 검증 |
| 실제 시청 진도 저장 | `KlasVideoPlaybackSession.recordPlayback`, `checkStatus`, `close` | [07. 온라인 학습 기능](../wiki/07-learning-features.md) | 상태 변경 | Yes | No | No | 실제 플레이어 이벤트, 60초 저장 주기, 정지·버퍼링·탐색·이벤트 공백, 학습 기간 외 복습, 세션 교체, 모호한 저장 실패와 재전송 방지를 mock 검증. 실계정 진도 쓰기 금지 |
| E-class 녹화 복습 | `eclass.listRecordings`, `eclass.openVideo` | [08. 설문과 e-Class](../wiki/08-survey-and-eclass.md) | 조회 / 재생 준비 | Yes | Yes | No | 온라인 학습과 별도 재생 경로. 최근 녹화와 구형 녹화, 직접 재생 정보, 쿠키 격리와 온라인 진도 요청이 없음을 mock 검증 |
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

2026-10-03 팀 프로젝트 작업에서는 공식 화면의 목록·상세·팀원 조회 동작을
확인한 뒤 `course.teamProjects`를 추가했습니다. 합성 HTTP 응답으로 목록,
출제 본문, 현재 팀의 제출 결과·점수·첨삭, 팀원과 세 종류의 첨부파일 다운로드를
검증했습니다. 과목·팀 격리, 삭제된 프로젝트, 미배정 팀, 잘못된 날짜와 응답도
테스트했습니다. 팀 프로젝트 관련 사례 39개를 포함한 전체 227개 테스트와
`dart run tool/check_all.dart`가 통과했습니다.

저장된 CLI 인증을 메모리에서 사용한 읽기 전용 SDK 검사에서는 현재 학기
6과목 모두 프로젝트가 없었으며, 목록 요청 6건이 HTTP 200과 빈 목록을
반환했습니다. 검증 클라이언트는 총 14건을 요청했고 차단 대상 요청은 0건입니다.
프로젝트가 등록된 경우의 상세·팀원·첨부파일은 실계정으로 확인하지 않았습니다.
응답 원본과 계정·팀원 식별자를 저장소에 남기지 않았습니다. 이 검사는 아래
표의 사람 수동 테스트 완료 상태와 구분합니다.

2026-10-03에는 요청된 6개 브랜치를 `develop` 기준 통합 브랜치에 병합한 뒤
SDK 전체 검사와 188개 테스트를 통과했습니다. CLI의 임시 복사본에 통합 SDK를
연결해 분석·전체 테스트·스키마·dry-run·설치 스크립트·패키지 dry-run 검사를
수행했고 Windows 실행 파일도 빌드했습니다. CLI 저장소의 의존성이나 브랜치는
이 SDK 통합 작업에서 변경하지 않았습니다.

저장된 CLI 인증으로 현재 학기 6과목의 강의계획서와 모바일 출석 과목 6개를
조회했습니다. 모바일 식별값은 SDK가 자동으로 적용했습니다. 2026년 10월 일정
10건 모두 시작·종료 일시가 있었고, 월 경계를 넘는 5건의 전체 기간도
유지됐습니다. 컴파일된 CLI의 `calendar month --year 2026 --month 10`도
같은 건수와 기간을 반환했습니다. 온라인 동영상 목록 67개와 E-class 녹화
목록 3개를 조회하고 E-class 미디어의 양수 길이와 MP4 HEAD 응답 200을
확인했습니다. 검증 클라이언트는 읽기 요청 62건을 수행했습니다. 출석 제출,
학습 진도 저장, 인증번호 발송·확인은 수행하지 않았고 차단 대상 요청도
없었습니다. 캡차 계속 로그인과 상태 변경 기능은 합성 HTTP 테스트로
검증합니다. 이 기록은 자동화된 조회 검사이며 사람 수동 테스트 완료 표와
구분합니다.

2026-10-03 강의계획서 작업에서는 로그인된 Chrome에서 조회 목록과 본문을
읽고, 수정된 SDK의 `course.syllabus()`로 현재 학기 6과목을 확인했습니다.
6과목 모두 개요·학습목표·15주차 계획이 반환됐고, 평가 반영 비율 합계는
각각 100%였습니다. 시간표와 교재도 반환됐습니다. 공통형 계획서는 공식 화면의
조회 방식을 확인하고 합성 응답으로 테스트했습니다. 실계정에는 읽기 요청만
수행했으며 계정 식별자, 응답 원본과 담당자 연락처를 저장소에 남기지 않았습니다.

2026-10-03 동영상 작업에서는 로그인된 Chrome의 온라인 학습과 E-class 복습
목록을 각각 확인하고, 뷰어를 실행하지 않은 상태에서 재생 정보와 미디어 설명을
읽었습니다. 두 종류의 실제 MP4 HEAD 응답은 200, `video/mp4`, 바이트 범위
탐색 지원을 반환했습니다. E-class 복습에는 온라인 진도 저장 연결이 없습니다.
인증번호 발송, 영상 재생, 학습 진도 저장은 실계정에서 실행하지 않았습니다.
진도 저장과 인증은 합성 HTTP 데이터로 검증합니다. 응답 원본과 미디어 주소,
개인 식별자와 재생 키는 저장소에 기록하지 않았습니다.

같은 날 수정된 SDK의 공개 API도 저장된 CLI 인증 세션으로 확인했습니다.
`learning.openVideo`와 `eclass.openVideo`가 각각 미디어를 반환하고 직접 재생
주소의 HEAD 응답이 `200 / video/mp4`임을 확인했습니다. 검증 클라이언트에서
인증번호 발송·확인과 진도 저장 요청을 차단했고, 차단 대상 요청은 0건입니다.
실제 재생이나 출석·학습 인정 진도의 변경을 검증한 기록은 아닙니다.

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
| Scoped analyze | `dart analyze lib test tool` | Passed | 2026-10-03 |
| Full unit test suite | `dart test` | Passed (227 tests, 팀 프로젝트·강의계획서·동영상·QR·로그인 및 고수준 API 회귀 포함) | 2026-10-03 |
| Team project reads | `dart test test/team_project_test.dart` (full suite에 포함) | Passed (37 tests, 목록·본문·제출 결과·팀원·다운로드·과목/팀 격리·응답 오류) | 2026-10-03 |
| Live empty team project lists | 저장된 CLI 인증을 사용한 읽기 전용 SDK 검사 | Passed (현재 학기 6과목, HTTP 200 빈 목록 6건) | 2026-10-03 |
| Course syllabus | `dart test test/syllabus_test.dart` (full suite에 포함) | Passed (26 tests, 일반형·공통형·과목 격리·미등록·제한·응답 오류) | 2026-10-03 |
| Video playback / E-class review | `dart test test/video_playback_test.dart` (full suite에 포함) | Passed (30 tests) | 2026-10-03 |
| Mobile QR attendance | `dart test test/mobile_qr_attendance_test.dart` (full suite에 포함) | Passed (34 tests) | 2026-10-02 |
| High-level coverage | `dart test test/high_level_feature_coverage_test.dart` (full suite에 포함) | Passed | 2026-10-03 |
| Captcha login and parser | `dart test test/captcha_login_test.dart test/login_parser_test.dart` | Passed (21 tests) | 2026-10-02 |
| Integrated check | `dart run tool/check_all.dart` | Passed (develop 통합 코드 및 팀 프로젝트 추가) | 2026-10-03 |
| CLI compatibility | 통합 SDK를 연결한 CLI 임시 복사본의 `dart run tool/check_all.dart`, `dart compile exe bin/klas.dart -o build/klas.exe` | Passed (전체 CLI 검사), executable built | 2026-10-03 |
| Compiled CLI monthly calendar | `klas --format json calendar month --year 2026 --month 10` | Passed (10건, 전체 기간 10건, 월 경계 일정 5건) | 2026-10-03 |
