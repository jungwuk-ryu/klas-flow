# 14. 고수준 API 전체 인덱스

이 페이지는 현재 공개된 고수준 API를 한눈에 찾기 위한 인덱스입니다.  
저수준 엔드포인트/필드 상세는 의도적으로 최소화하고, 사용 목적 중심으로 정리했습니다.

## 읽는 방법

- **권장 시나리오**: 처음 보는 API라면 해당 튜토리얼 페이지를 먼저 읽으세요.
- **반환 타입**: typed 모델이면 바로 UI 구성, `KlasRecord`면 앱 DTO 매핑을 권장합니다.

---

## KlasClient

| API | 설명 | 권장 시나리오 |
|---|---|---|
| `currentUser` | 현재 로그인 사용자 참조 | [02](02-login-and-session.md) |
| `isSessionHeartbeatRunning` | 하트비트 동작 여부 | [02](02-login-and-session.md) |
| `login(id, password)` | 로그인 후 `KlasUser` 반환 | [02](02-login-and-session.md) |
| `requestCaptchaImage()` | 캡차 이미지 조회 | [12](12-student-record-frame-healthcheck.md) |
| `startSessionHeartbeat(...)` | 세션 자동 연장 시작 | [02](02-login-and-session.md) |
| `stopSessionHeartbeat()` | 세션 자동 연장 중지 | [02](02-login-and-session.md) |
| `runHealthCheck(...)` | 주요 기능 상태 점검 | [12](12-student-record-frame-healthcheck.md) |
| `clearLocalState()` | 로컬 세션/캐시 초기화 | [02](02-login-and-session.md) |
| `close()` | 리소스 해제 | [02](02-login-and-session.md) |

---

## KlasUser

| API | 설명 | 권장 시나리오 |
|---|---|---|
| `id`, `name`, `authenticated` | 로그인 사용자 기본 정보 | [03](03-user-profile-and-courses.md) |
| `profile(refresh: ...)` | 사용자 프로필 조회 | [03](03-user-profile-and-courses.md) |
| `sessionStatus()` | 세션 상태 조회 | [02](02-login-and-session.md) |
| `personalInfo(refresh: ...)` | 개인정보 수정 화면 기준 상세 정보 | [03](03-user-profile-and-courses.md) |
| `keepAlive()` | 세션 즉시 연장 | [02](02-login-and-session.md) |
| `courses(refresh: ...)` | 수강 과목 목록 조회 | [03](03-user-profile-and-courses.md) |
| `defaultCourse(refresh: ...)` | 기본 과목 선택 | [03](03-user-profile-and-courses.md) |
| `findCourseById(...)` | 과목 ID로 수강 과목 찾기 | [03](03-user-profile-and-courses.md) |
| `findCourseByTitle(...)` | 표시 과목명으로 수강 과목 찾기 | [03](03-user-profile-and-courses.md) |
| `timetable(query: ...)` | 학기 시간표 조회 | [09](09-timetable.md) |
| `clearCache()` | 사용자 캐시 초기화 | [13](13-error-handling-patterns.md) |
| `academic` | 학사/성적 기능 진입점 | [10](10-academic-features.md) |
| `enrollment` | 수강/시간표 기능 진입점 | [09](09-timetable.md) |
| `attendance` | 출석/일정 기능 진입점 | [11](11-attendance-features.md) |
| `studentRecord` | 학적 기능 진입점 | [12](12-student-record-frame-healthcheck.md) |
| `files` | 첨부파일 기능 진입점 | [06](06-attachments-download.md) |
| `frame` | 프레임/홈 요약 기능 진입점 | [12](12-student-record-frame-healthcheck.md) |

---

## KlasCourse

| API | 설명 | 권장 시나리오 |
|---|---|---|
| `courseId`, `termId`, `title`, `professorName`, `isDefault` | 과목 메타 정보 | [03](03-user-profile-and-courses.md) |
| `rawContext` | 원본 과목 컨텍스트 | [03](03-user-profile-and-courses.md) |
| `owner` | 소유 사용자 객체 | [03](03-user-profile-and-courses.md) |
| `overview()` | 과목 홈 개요 조회 | [04](04-course-overview-and-tasks.md) |
| `scheduleText()` | 과목 시간표 텍스트 조회 | [04](04-course-overview-and-tasks.md) |
| `listTasks(page: ...)` | 과제 목록 조회 (`List<KlasTask>`) | [04](04-course-overview-and-tasks.md) |
| `qrCheckIn(qrCode)` | 현재 과목에 대해 QR 출석 처리 | [11](11-attendance-features.md) |
| `learning` | 학습 기능 진입점 | [07](07-learning-features.md) |
| `noticeBoard` | 공지사항 보드 기능 | [05](05-board-list-and-detail.md) |
| `materialBoard` | 강의자료실 보드 기능 | [05](05-board-list-and-detail.md) |
| `surveys` | 설문 기능 | [08](08-survey-and-eclass.md) |
| `eclass` | e-Class 기능 | [08](08-survey-and-eclass.md) |

---

## KlasLearningFeature

| API | 설명 | 반환 |
|---|---|---|
| `listAnytimeQuizzes(...)` | 수시퀴즈 목록(원형) | `List<KlasRecord>` |
| `listAnytimeQuizItems(...)` | 수시퀴즈 목록(typed) | `List<KlasAnytimeQuiz>` |
| `listDiscussions(...)` | 토론 목록(원형) | `List<KlasRecord>` |
| `listDiscussionItems(...)` | 토론 목록(typed) | `List<KlasDiscussionTopic>` |
| `homeInfo(...)` | 학습 홈 정보 | `KlasRecord` |
| `attendanceStatus(...)` | 출석 상태 목록 | `List<KlasRecord>` |
| `attendanceStatusDetail(...)` | 출석 상태 상세 | `List<KlasRecord>` |
| `discussionStatus(...)` | 토론 상태 목록 | `List<KlasRecord>` |
| `summary(...)` | 학습 요약 | `KlasRecord` |
| `realtimeProgress(...)` | 실시간 진도 | `List<KlasRecord>` |
| `taskStatus(...)` | 과제 상태 | `List<KlasRecord>` |
| `teamProjects(...)` | 팀프로젝트 상태 | `List<KlasRecord>` |
| `testAndQuizStatus(...)` | 시험/퀴즈 상태 | `List<KlasRecord>` |
| `onlineTests(...)` | 온라인 시험 목록(원형) | `List<KlasRecord>` |
| `listOnlineTestItems(...)` | 온라인 시험 목록(typed) | `List<KlasOnlineTest>` |
| `onlineContents(...)` | 온라인 콘텐츠 목록(원형) | `List<KlasRecord>` |
| `listOnlineContentItems(...)` | 온라인 콘텐츠 목록(typed) | `List<KlasOnlineContent>` |

시나리오: [07](07-learning-features.md)

---

## 보드 기능 (`noticeBoard`, `materialBoard`)

`KlasNoticeBoard`, `KlasMaterialBoard`는 동일한 API를 제공합니다.

| API | 설명 | 반환 |
|---|---|---|
| `listPosts(...)` | 게시글 목록 | `KlasBoardList` |
| `getPost(boardNo: ..., ...)` | 게시글 상세 | `KlasBoardPostDetail` |
| `openPostPage(boardNo: ..., ...)` | 게시글 페이지 원문 | `String` |

시나리오: [05](05-board-list-and-detail.md)

---

## KlasSurveyFeature / KlasEClassFeature

| API | 설명 | 반환 |
|---|---|---|
| `surveys.openPage(...)` | 설문 페이지 원문 | `String` |
| `surveys.list(...)` | 설문 목록(원형) | `List<KlasRecord>` |
| `surveys.listSurveyItems(...)` | 설문 목록(typed) | `List<KlasSurveyEntry>` |
| `eclass.listItems(...)` | e-Class 목록(원형) | `List<KlasRecord>` |
| `eclass.listEClassItems(...)` | e-Class 목록(typed) | `List<KlasEClassItem>` |

시나리오: [08](08-survey-and-eclass.md)

---

## KlasAcademicFeature

| API | 설명 | 반환 |
|---|---|---|
| `checkTerm(...)` | 학기 점검 정보 | `KlasRecord` |
| `hakjukInfo(...)` | 학적 정보 | `KlasRecord` |
| `programCategory(...)` | 프로그램 구분 정보 | `KlasRecord` |
| `sugangOption(...)` | 수강 옵션 값 | `Object?` |
| `listGrades(...)` | 성적 목록(원형) | `List<KlasRecord>` |
| `listGradeEntries(...)` | 성적 목록(typed) | `List<KlasGradeEntry>` |
| `gradeSummary(...)` | 성적 요약 | `KlasRecord` |
| `listDeletedApplications(...)` | 취득학점포기 신청 목록 | `List<KlasRecord>` |
| `deletedHakjukInfo(...)` | 취득학점포기 학적 정보 | `KlasRecord` |
| `listDeletedGrades(...)` | 취득학점포기 성적 목록 | `List<KlasRecord>` |
| `gyoyangInfo(...)` | 교양 이수 정보 | `KlasRecord` |
| `listPortfolio(...)` | 포트폴리오 목록 | `List<KlasRecord>` |
| `listScholarshipHistory(...)` | 장학 이력 | `List<KlasRecord>` |
| `listScholarships(...)` | 장학 목록 | `List<KlasRecord>` |
| `listLectureEvalCourses(...)` | 강의평가 과목 목록 | `List<KlasRecord>` |
| `listLectureEvalDepartments(...)` | 강의평가 학과 목록 | `List<KlasRecord>` |
| `listStanding(...)` | 석차 목록 | `List<KlasRecord>` |
| `listToeicInfo(...)` | 어학 정보 | `List<KlasRecord>` |
| `toeicLevelText(...)` | 어학 레벨 텍스트 | `String` |
| `listToeicRecords(...)` | 어학 기록 목록 | `List<KlasRecord>` |

시나리오: [10](10-academic-features.md)

---

## KlasEnrollmentFeature

| API | 설명 | 반환 |
|---|---|---|
| `listYears(...)` | 학년도 목록 | `List<KlasRecord>` |
| `listColleges(...)` | 단과대 목록 | `List<KlasRecord>` |
| `listDepartments(...)` | 학과 목록 | `List<KlasRecord>` |
| `lecturePlanStopFlag(...)` | 강의계획서 플래그 | `String` |
| `listTimetable(...)` | 시간표 목록(원형) | `List<KlasRecord>` |
| `listTimetableEntries(...)` | 시간표 목록(typed) | `List<KlasTimetableEntry>` |
| `timetable(...)` | 시간표 집계(typed) | `KlasTimetable` |

시나리오: [09](09-timetable.md)

---

## KlasAttendanceFeature

| API | 설명 | 반환 |
|---|---|---|
| `listSubjects(...)` | 출석 과목 목록(원형) | `List<KlasRecord>` |
| `listSubjectItems(...)` | 출석 과목 목록(typed) | `List<KlasAttendanceSubject>` |
| `qrCheckIn(...)` | QR 출석 처리(typed) | `KlasQrAttendanceResult` |
| `qrCheckInRaw(...)` | QR 출석 처리(원형) | `KlasRecord` |
| `monthList(...)` | 월간 일정 목록(원형) | `List<KlasRecord>` |
| `listMonthlySchedules(...)` | 월간 일정 목록(typed) | `List<KlasMonthlyScheduleItem>` |
| `monthTable(...)` | 월간 일정 테이블(원형) | `List<KlasRecord>` |
| `listMonthlyScheduleTableItems(...)` | 월간 일정 테이블(typed) | `List<KlasMonthlyScheduleTableItem>` |

시나리오: [11](11-attendance-features.md)

---

## KlasStudentRecordFeature / KlasFileFeature / KlasFrameFeature

| API | 설명 | 반환 |
|---|---|---|
| `studentRecord.temporaryLeaveHakjuk(...)` | 휴복학 학적 정보 | `KlasRecord` |
| `studentRecord.temporaryLeaveStatus(...)` | 휴복학 상태 정보 | `KlasRecord` |
| `files.listByAttachId(...)` | 첨부파일 목록 조회 | `List<KlasAttachedFile>` |
| `files.download(...)` | 첨부파일 직접 다운로드 | `FilePayload` |
| `frame.homeOverview(...)` | 홈 요약 정보 | `KlasRecord` |
| `frame.scheduleSummary(...)` | 일정 요약 정보 | `KlasRecord` |
| `frame.gyojikExamCheck(...)` | 교직 시험 확인 정보 | `KlasRecord` |

시나리오: [06](06-attachments-download.md), [12](12-student-record-frame-healthcheck.md)

---

## 모델 편의 API

| API | 설명 | 관련 시나리오 |
|---|---|---|
| `KlasBoardPostSummary.getPost(...)` | 목록 항목에서 상세 바로 조회 | [05](05-board-list-and-detail.md) |
| `KlasBoardPostSummary.hasAttachments` | 첨부 존재 여부 | [06](06-attachments-download.md) |
| `KlasAttachedFile.download(...)` | 파일 객체에서 바로 다운로드 | [06](06-attachments-download.md) |
| `KlasTimetable.groupedByWeekday` | 요일별 그룹 | [09](09-timetable.md) |
| `KlasTimetable.isEmpty` | 시간표 비어있음 여부 | [09](09-timetable.md) |

---

필요한 기능을 찾았다면, 해당 튜토리얼 페이지의 예제를 그대로 실행해 보고 화면에 붙이는 순서로 진행하세요.
