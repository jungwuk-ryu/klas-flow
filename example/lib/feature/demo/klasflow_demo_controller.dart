import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:klasflow/klasflow.dart';

/// 버튼 하나 실행 결과를 화면에 남기기 위한 모델이다.
///
/// 데모 앱은 "어떤 API가 실제로 성공했는지"를 눈으로 확인하는 것이 목적이므로
/// 성공/실패 여부, 요약 메시지, 실행 시간, 응답 미리보기를 함께 보관한다.
class DemoActionResult {
  final String id;
  final String title;
  final bool success;
  final String summary;
  final Object? payload;
  final String payloadPreview;
  final DateTime executedAt;
  final Duration elapsed;

  const DemoActionResult({
    required this.id,
    required this.title,
    required this.success,
    required this.summary,
    required this.payload,
    required this.payloadPreview,
    required this.executedAt,
    required this.elapsed,
  });
}

/// 데모 화면의 상태와 KLAS 호출 흐름을 관리한다.
///
/// UI 코드는 가능한 한 "표시"에만 집중하고,
/// API 호출/예외 처리/결과 변환은 이 컨트롤러에 몰아 넣는다.
class KlasflowDemoController extends ChangeNotifier {
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final Uri apiBaseUri;
  late final KlasClientConfig _clientConfig = KlasClientConfig(
    baseUri: apiBaseUri,
  );
  late final KlasClient _client = KlasClient(config: _clientConfig);

  bool _isLoading = false;
  String? _activeOperation;
  String? _errorMessage;

  KlasUser? _user;
  KlasUserProfile? _profile;
  KlasPersonalInfo? _personalInfo;
  KlasSessionStatus? _sessionStatus;

  List<KlasCourse> _courses = const <KlasCourse>[];
  KlasCourse? _currentCourse;
  List<KlasTask> _tasks = const <KlasTask>[];

  KlasCourseOverview? _courseOverview;
  String? _courseScheduleText;
  KlasBoardList? _noticeBoard;
  KlasBoardList? _materialBoard;
  KlasTimetable? _semesterTimetable;
  KlasHealthReport? _healthReport;

  final Map<String, DemoActionResult> _actionResultById =
      <String, DemoActionResult>{};
  String? _runningActionId;

  bool _disposed = false;

  KlasflowDemoController({required this.apiBaseUri});

  bool get isLoading => _isLoading;
  String? get activeOperation => _activeOperation;
  String? get errorMessage => _errorMessage;
  KlasUser? get user => _user;
  KlasUserProfile? get profile => _profile;
  KlasPersonalInfo? get personalInfo => _personalInfo;
  KlasSessionStatus? get sessionStatus => _sessionStatus;
  List<KlasCourse> get courses => _courses;
  KlasCourse? get currentCourse => _currentCourse;
  List<KlasTask> get tasks => _tasks;
  KlasCourseOverview? get courseOverview => _courseOverview;
  String? get courseScheduleText => _courseScheduleText;
  KlasBoardList? get noticeBoard => _noticeBoard;
  KlasBoardList? get materialBoard => _materialBoard;
  KlasTimetable? get semesterTimetable => _semesterTimetable;
  KlasHealthReport? get healthReport => _healthReport;
  String? get runningActionId => _runningActionId;

  /// 최근 실행 순서(최신 -> 과거)로 정렬한 결과 목록이다.
  List<DemoActionResult> get actionResults {
    final results = _actionResultById.values.toList(growable: false);
    results.sort((a, b) => b.executedAt.compareTo(a.executedAt));
    return results;
  }

  /// Flutter Web 환경에서 cross-origin 쿠키 제약으로 로그인 실패가 예상되는지 판단한다.
  bool get isLikelyBrowserCrossOriginLogin {
    if (!kIsWeb) {
      return false;
    }
    final appOrigin = Uri.base;
    return appOrigin.scheme != apiBaseUri.scheme ||
        appOrigin.host != apiBaseUri.host ||
        _effectivePort(appOrigin) != _effectivePort(apiBaseUri);
  }

  /// 로그인 후 데모의 기본 데이터(프로필/강의/과제)를 모두 불러온다.
  ///
  /// 사용자가 "일단 들어가서 화면을 탐색"할 수 있도록
  /// 자주 보는 데이터는 로그인 단계에서 선로딩한다.
  Future<void> loginAndLoad() async {
    if (isLikelyBrowserCrossOriginLogin) {
      _errorMessage =
          '브라우저의 cross-origin 쿠키 정책 때문에 Web 환경에서는 로그인에 '
          '실패할 수 있습니다. 앱/데스크톱 실행 또는 same-origin 프록시를 사용하세요.';
      _notify();
      return;
    }

    final id = idController.text.trim();
    final password = passwordController.text;
    if (id.isEmpty || password.isEmpty) {
      _errorMessage = '학번(또는 ID)과 비밀번호를 모두 입력해 주세요.';
      _notify();
      return;
    }

    _setLoading(loading: true, operation: '로그인 및 기본 데이터 로딩');
    _errorMessage = null;
    _clearSessionViewState();
    _notify();

    try {
      final user = await _client.login(id, password);

      // 아래 호출은 앱 사용 시 가장 체감이 큰 핵심 정보들이라 로그인 직후에 준비한다.
      final profile = await user.profile(refresh: true);
      final personalInfo = await user.personalInfo(refresh: true);
      final sessionStatus = await user.sessionStatus();
      final courses = await user.courses(refresh: true);
      final current = await user.defaultCourse();
      final tasks = current == null
          ? const <KlasTask>[]
          : await current.listTasks(page: 0);

      _user = user;
      _profile = profile;
      _personalInfo = personalInfo;
      _sessionStatus = sessionStatus;
      _courses = List<KlasCourse>.unmodifiable(courses);
      _currentCourse = current;
      _tasks = List<KlasTask>.unmodifiable(tasks);

      final payload = <String, Object?>{
        'profile': _normalizePayload(profile),
        'personalInfo': _normalizePayload(personalInfo),
        'sessionStatus': _normalizePayload(sessionStatus),
        'courses': courses.length,
        'tasks': tasks.length,
      };
      _recordActionResult(
        DemoActionResult(
          id: 'auth.login',
          title: '로그인 및 기본 데이터 로딩',
          success: true,
          summary: '로그인 성공, 기본 데이터 로딩 완료',
          payload: payload,
          payloadPreview: _toPrettyPreviewFromNormalized(payload),
          executedAt: DateTime.now(),
          elapsed: Duration.zero,
        ),
      );
    } on KlasException catch (error) {
      _errorMessage = _friendlyError(error);
    } catch (_) {
      _errorMessage = '예상하지 못한 오류가 발생했습니다. 다시 시도해 주세요.';
    } finally {
      _setLoading(loading: false);
      _notify();
    }
  }

  /// 현재 선택된 과목의 과제 목록만 다시 불러온다.
  Future<void> reloadTasks() async {
    await _runAction(
      id: 'course.tasks',
      title: '과제 목록 조회',
      action: () async {
        final course = _requireCourse();
        final tasks = await course.listTasks(page: 0);
        _tasks = List<KlasTask>.unmodifiable(tasks);
        return <String, Object?>{
          'courseId': course.courseId,
          'count': tasks.length,
          'items': tasks
              .take(5)
              .map((task) => task.raw)
              .toList(growable: false),
        };
      },
    );
  }

  /// 과목 선택을 변경하고 선택한 과목 기준으로 과제를 다시 조회한다.
  Future<void> changeCourse(KlasCourse? course) async {
    if (course == null) {
      return;
    }

    await _runAction(
      id: 'course.change',
      title: '현재 과목 변경',
      action: () async {
        final tasks = await course.listTasks(page: 0);
        _currentCourse = course;
        _tasks = List<KlasTask>.unmodifiable(tasks);

        // 과목이 바뀌면 과목 종속 캐시(개요/게시판 등)는 무효화해 혼동을 막는다.
        _courseOverview = null;
        _courseScheduleText = null;
        _noticeBoard = null;
        _materialBoard = null;

        return <String, Object?>{
          'courseId': course.courseId,
          'termId': course.termId,
          'title': course.title,
          'taskCount': tasks.length,
        };
      },
    );
  }

  /// `user.profile(refresh:true)`를 실행한다.
  Future<void> refreshProfile() async {
    await _runAction(
      id: 'user.profile',
      title: '사용자 프로필 새로고침',
      action: () async {
        final profile = await _requireUser().profile(refresh: true);
        _profile = profile;
        return profile;
      },
    );
  }

  /// `user.personalInfo(refresh:true)`를 실행한다.
  Future<void> loadPersonalInfo() async {
    await _runAction(
      id: 'user.personalInfo',
      title: '개인정보 상세 조회',
      action: () async {
        final info = await _requireUser().personalInfo(refresh: true);
        _personalInfo = info;
        return info;
      },
    );
  }

  /// `user.sessionStatus()`를 실행한다.
  Future<void> refreshSessionStatus() async {
    await _runAction(
      id: 'user.sessionStatus',
      title: '세션 상태 조회',
      action: () async {
        final status = await _requireUser().sessionStatus();
        _sessionStatus = status;
        return status;
      },
    );
  }

  /// `user.keepAlive()`를 실행하고 곧바로 세션 상태를 다시 확인한다.
  Future<void> keepAliveSession() async {
    await _runAction(
      id: 'user.keepAlive',
      title: '세션 연장',
      action: () async {
        final user = _requireUser();
        await user.keepAlive();
        final status = await user.sessionStatus();
        _sessionStatus = status;
        return <String, Object?>{
          'message': '세션 연장 요청 완료',
          'session': _normalizePayload(status),
        };
      },
    );
  }

  /// `user.frame.homeOverview()`를 실행한다.
  Future<void> loadFrameHomeOverview() async {
    await _runAction(
      id: 'user.frame.homeOverview',
      title: '홈 개요 조회',
      action: () async {
        final record = await _requireUser().frame.homeOverview();
        return record;
      },
    );
  }

  /// `user.frame.scheduleSummary()`를 실행한다.
  Future<void> loadFrameScheduleSummary() async {
    await _runAction(
      id: 'user.frame.scheduleSummary',
      title: '일정 요약 조회',
      action: () async {
        final query = _currentMonthScheduleQuery();
        final record = await _requireUser().frame.scheduleSummary(query: query);
        return <String, Object?>{
          'schdulYear': query['schdulYear'],
          'schdulMonth': query['schdulMonth'],
          ...record.raw,
        };
      },
    );
  }

  /// `user.timetable()`를 실행한다.
  Future<void> loadEnrollmentTimetable() async {
    await _runAction(
      id: 'user.enrollment.timetable',
      title: '학기 시간표 조회',
      action: () async {
        final timetable = await _requireUser().timetable(
          termId: _currentCourse?.termId,
        );
        _semesterTimetable = timetable;
        return timetable;
      },
    );
  }

  /// `user.attendance.listSubjects()`를 실행한다.
  Future<void> loadAttendanceSubjects() async {
    await _runAction(
      id: 'user.attendance.listSubjects',
      title: '출석 과목 목록 조회',
      action: () async {
        final rows = await _requireUser().attendance.listSubjects();
        return _summarizeRecords(rows);
      },
    );
  }

  /// `user.attendance.monthList()`를 실행한다.
  Future<void> loadAttendanceMonthList() async {
    await _runAction(
      id: 'user.attendance.monthList',
      title: '월간 일정 목록 조회',
      action: () async {
        final query = _currentMonthScheduleQuery();
        final rows = await _requireUser().attendance.listMonthlySchedules(
          query: query,
        );
        return <String, Object?>{
          'schdulYear': query['schdulYear'],
          'schdulMonth': query['schdulMonth'],
          'count': rows.length,
          'sample': rows
              .take(8)
              .map(
                (item) => <String, Object?>{
                  'title': item.title,
                  'date': item.date,
                  'status': item.status,
                  'scheduleId': item.scheduleId,
                  'raw': item.raw,
                },
              )
              .toList(growable: false),
        };
      },
    );
  }

  /// `user.attendance.monthTable()`를 실행한다.
  Future<void> loadAttendanceMonthTable() async {
    await _runAction(
      id: 'user.attendance.monthTable',
      title: '월간 일정 테이블 조회',
      action: () async {
        final query = _currentMonthScheduleQuery();
        final rows = await _requireUser().attendance
            .listMonthlyScheduleTableItems(query: query);
        return <String, Object?>{
          'schdulYear': query['schdulYear'],
          'schdulMonth': query['schdulMonth'],
          'count': rows.length,
          'sample': rows
              .take(8)
              .map(
                (item) => <String, Object?>{
                  'dayOfMonth': item.dayOfMonth,
                  'weekday': item.weekday,
                  'title': item.title,
                  'status': item.status,
                  'raw': item.raw,
                },
              )
              .toList(growable: false),
        };
      },
    );
  }

  /// `course.overview()`를 실행한다.
  Future<void> loadCourseOverview() async {
    await _runAction(
      id: 'course.overview',
      title: '강의 개요 조회',
      action: () async {
        final overview = await _requireCourse().overview();
        _courseOverview = overview;
        return overview;
      },
    );
  }

  /// `course.scheduleText()`를 실행한다.
  Future<void> loadCourseScheduleText() async {
    await _runAction(
      id: 'course.scheduleText',
      title: '강의 시간표 문자열 조회',
      action: () async {
        final text = await _requireCourse().scheduleText();
        _courseScheduleText = text;
        return <String, Object?>{'scheduleText': text ?? '(null)'};
      },
    );
  }

  /// `course.noticeBoard.listPosts(page:0)`를 실행한다.
  Future<void> loadNoticeBoardPosts() async {
    await _runAction(
      id: 'course.noticeBoard.listPosts',
      title: '공지사항 게시판 조회',
      action: () async {
        final board = await _requireCourse().noticeBoard.listPosts(page: 0);
        _noticeBoard = board;
        return <String, Object?>{
          'count': board.posts.length,
          'page': _normalizePayload(board.page?.raw),
          'sample': board.posts
              .take(5)
              .map((post) => post.raw)
              .toList(growable: false),
        };
      },
    );
  }

  /// `course.materialBoard.listPosts(page:0)`를 실행한다.
  Future<void> loadMaterialBoardPosts() async {
    await _runAction(
      id: 'course.materialBoard.listPosts',
      title: '강의자료실 조회',
      action: () async {
        final board = await _requireCourse().materialBoard.listPosts(page: 0);
        _materialBoard = board;
        return <String, Object?>{
          'count': board.posts.length,
          'page': _normalizePayload(board.page?.raw),
          'sample': board.posts
              .take(5)
              .map((post) => post.raw)
              .toList(growable: false),
        };
      },
    );
  }

  /// `course.learning.listAnytimeQuizzes(page:0)`를 실행한다.
  Future<void> loadAnytimeQuizzes() async {
    await _runAction(
      id: 'course.learning.anytimeQuizzes',
      title: '수시퀴즈 목록 조회',
      action: () async {
        final rows = await _requireCourse().learning.listAnytimeQuizzes(
          page: 0,
        );
        return _summarizeRecords(rows);
      },
    );
  }

  /// `course.learning.listDiscussions(page:0)`를 실행한다.
  Future<void> loadDiscussions() async {
    await _runAction(
      id: 'course.learning.discussions',
      title: '토론 목록 조회',
      action: () async {
        final rows = await _requireCourse().learning.listDiscussions(page: 0);
        return _summarizeRecords(rows);
      },
    );
  }

  /// `course.learning.onlineContents(page:0)`를 실행한다.
  Future<void> loadOnlineContents() async {
    await _runAction(
      id: 'course.learning.onlineContents',
      title: '온라인 콘텐츠 목록 조회',
      action: () async {
        final rows = await _requireCourse().learning.onlineContents(page: 0);
        return _summarizeRecords(rows);
      },
    );
  }

  /// `course.learning.onlineTests(page:0)`를 실행한다.
  Future<void> loadOnlineTests() async {
    await _runAction(
      id: 'course.learning.onlineTests',
      title: '온라인 시험 목록 조회',
      action: () async {
        final rows = await _requireCourse().learning.onlineTests(page: 0);
        return _summarizeRecords(rows);
      },
    );
  }

  /// `course.surveys.list()`를 실행한다.
  Future<void> loadSurveys() async {
    await _runAction(
      id: 'course.surveys.list',
      title: '설문 목록 조회',
      action: () async {
        final rows = await _requireCourse().surveys.list();
        return _summarizeRecords(rows);
      },
    );
  }

  /// `course.eclass.listItems(page:0)`를 실행한다.
  Future<void> loadEclassItems() async {
    await _runAction(
      id: 'course.eclass.listItems',
      title: 'e-Class 목록 조회',
      action: () async {
        final rows = await _requireCourse().eclass.listItems(page: 0);
        return _summarizeRecords(rows);
      },
    );
  }

  /// 클라이언트 내장 진단 함수를 실행한다.
  Future<void> runHealthCheck() async {
    await _runAction(
      id: 'client.healthCheck',
      title: '헬스체크 실행',
      action: () async {
        final report = await _client.runHealthCheck();
        _healthReport = report;
        return <String, Object?>{
          'checkedAt': report.checkedAt.toIso8601String(),
          'allPassed': report.allPassed,
          'failedCount': report.failedCount,
          'items': report.items
              .map(
                (item) => <String, Object?>{
                  'id': item.id,
                  'success': item.success,
                  'elapsedMs': item.elapsed.inMilliseconds,
                  'detail': item.detail,
                },
              )
              .toList(growable: false),
        };
      },
    );
  }

  /// 드롭다운에 표시할 강의 라벨을 만든다.
  String courseLabel(KlasCourse course) {
    final title = course.title ?? '(이름 없음)';
    final professor = course.professorName;
    if (professor == null || professor.isEmpty) {
      return '$title [${course.termId}]';
    }
    return '$title - $professor [${course.termId}]';
  }

  @override
  void dispose() {
    // dispose 이후 비동기 응답에서 notify가 호출되지 않도록 플래그를 먼저 켠다.
    _disposed = true;
    idController.dispose();
    passwordController.dispose();
    _client.close();
    super.dispose();
  }

  /// 공통 실행 래퍼.
  ///
  /// 모든 버튼 액션이 동일한 예외 처리/결과 기록 방식을 사용하도록 통일한다.
  Future<void> _runAction({
    required String id,
    required String title,
    required Future<Object?> Function() action,
  }) async {
    if (_isLoading) {
      return;
    }

    final startedAt = DateTime.now();
    final stopwatch = Stopwatch()..start();

    _runningActionId = id;
    _setLoading(loading: true, operation: title);
    _errorMessage = null;
    _notify();

    try {
      final payload = await action();
      final normalizedPayload = _normalizePayload(payload);
      stopwatch.stop();
      _recordActionResult(
        DemoActionResult(
          id: id,
          title: title,
          success: true,
          summary: '요청 성공',
          payload: normalizedPayload,
          payloadPreview: _toPrettyPreviewFromNormalized(normalizedPayload),
          executedAt: startedAt,
          elapsed: stopwatch.elapsed,
        ),
      );
    } on KlasException catch (error) {
      stopwatch.stop();
      final message = _friendlyError(error);
      _errorMessage = message;
      _recordActionResult(
        DemoActionResult(
          id: id,
          title: title,
          success: false,
          summary: message,
          payload: null,
          payloadPreview: '',
          executedAt: startedAt,
          elapsed: stopwatch.elapsed,
        ),
      );
    } on StateError catch (error) {
      stopwatch.stop();
      final message = error.message;
      _errorMessage = message;
      _recordActionResult(
        DemoActionResult(
          id: id,
          title: title,
          success: false,
          summary: message,
          payload: null,
          payloadPreview: '',
          executedAt: startedAt,
          elapsed: stopwatch.elapsed,
        ),
      );
    } catch (error) {
      stopwatch.stop();
      const message = '요청 처리 중 알 수 없는 오류가 발생했습니다.';
      _errorMessage = message;
      _recordActionResult(
        DemoActionResult(
          id: id,
          title: title,
          success: false,
          summary: '$message\n$error',
          payload: null,
          payloadPreview: '',
          executedAt: startedAt,
          elapsed: stopwatch.elapsed,
        ),
      );
    } finally {
      _runningActionId = null;
      _setLoading(loading: false);
      _notify();
    }
  }

  /// 결과 기록 시에는 같은 id의 이전 결과를 덮어써서 화면을 단순하게 유지한다.
  void _recordActionResult(DemoActionResult result) {
    _actionResultById[result.id] = result;
  }

  KlasUser _requireUser() {
    final user = _user;
    if (user == null) {
      throw StateError('먼저 로그인해 주세요.');
    }
    return user;
  }

  KlasCourse _requireCourse() {
    final course = _currentCourse;
    if (course == null) {
      throw StateError('먼저 과목을 선택해 주세요.');
    }
    return course;
  }

  Map<String, Object?> _summarizeRecords(List<KlasRecord> rows) {
    return <String, Object?>{
      'count': rows.length,
      'sample': rows.take(5).map((row) => row.raw).toList(growable: false),
    };
  }

  String _friendlyError(KlasException error) {
    if (error is InvalidCredentialsException) {
      return '로그인 정보가 올바르지 않습니다. 학번/비밀번호를 확인해 주세요.';
    }
    if (error is OtpRequiredException) {
      return 'OTP 인증이 필요한 계정입니다.';
    }
    if (error is CaptchaRequiredException) {
      return '캡차 입력이 필요한 계정입니다.';
    }
    if (error is SessionExpiredException) {
      return '세션이 만료되었습니다. 다시 로그인해 주세요.';
    }
    if (error is NetworkException) {
      return '네트워크 요청에 실패했습니다. 인터넷 연결을 확인해 주세요.';
    }
    if (error is ServiceUnavailableException) {
      return 'KLAS 서비스가 일시적으로 불안정합니다. 잠시 후 다시 시도해 주세요.';
    }
    return 'KLAS 요청 실패: ${error.message}';
  }

  int _effectivePort(Uri uri) {
    if (uri.hasPort && uri.port != 0) {
      return uri.port;
    }
    return switch (uri.scheme) {
      'https' => 443,
      'http' => 80,
      _ => 0,
    };
  }

  Map<String, int> _currentMonthScheduleQuery() {
    final now = DateTime.now();
    return <String, int>{'schdulYear': now.year, 'schdulMonth': now.month};
  }

  void _setLoading({required bool loading, String? operation}) {
    _isLoading = loading;
    _activeOperation = loading ? operation : null;
  }

  void _clearSessionViewState() {
    _user = null;
    _profile = null;
    _personalInfo = null;
    _sessionStatus = null;
    _courses = const <KlasCourse>[];
    _currentCourse = null;
    _tasks = const <KlasTask>[];
    _courseOverview = null;
    _courseScheduleText = null;
    _noticeBoard = null;
    _materialBoard = null;
    _semesterTimetable = null;
    _healthReport = null;
    _actionResultById.clear();
    _runningActionId = null;
  }

  /// 다양한 타입을 JSON 직렬화 가능한 구조로 바꾼다.
  ///
  /// 응답 객체를 그대로 출력하면 `Instance of ...`만 보이기 쉬워서,
  /// 초보자도 이해하기 쉬운 Map/List 중심 구조로 변환한다.
  Object? _normalizePayload(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is KlasRecord) {
      return value.raw;
    }
    if (value is KlasUserProfile) {
      return <String, Object?>{
        'authenticated': value.authenticated,
        'userId': value.userId,
        'userName': value.userName,
        'raw': value.raw,
      };
    }
    if (value is KlasPersonalInfo) {
      return value.raw;
    }
    if (value is KlasSessionStatus) {
      return <String, Object?>{
        'authenticated': value.authenticated,
        'logoutCountDownSec': value.logoutCountDownSec,
        'sessionNotiSec': value.sessionNotiSec,
        'remainingTime': value.remainingTime,
        'raw': value.raw,
      };
    }
    if (value is KlasCourseOverview) {
      return value.record.raw;
    }
    if (value is KlasBoardList) {
      return <String, Object?>{
        'count': value.posts.length,
        'page': value.page?.raw,
        'sample': value.posts
            .take(5)
            .map((post) => post.raw)
            .toList(growable: false),
      };
    }
    if (value is KlasTimetable) {
      return <String, Object?>{
        'count': value.entries.length,
        'items': value.entries
            .map(
              (entry) => <String, Object?>{
                'subjectName': entry.subjectName,
                'professorName': entry.professorName,
                'dayOfWeek': entry.dayOfWeek,
                'startTime': entry.startTime,
                'endTime': entry.endTime,
                'periodText': entry.periodText,
                'classroom': entry.classroom,
              },
            )
            .toList(growable: false),
      };
    }
    if (value is KlasTimetableEntry) {
      return <String, Object?>{
        'subjectName': value.subjectName,
        'professorName': value.professorName,
        'dayOfWeek': value.dayOfWeek,
        'startTime': value.startTime,
        'endTime': value.endTime,
        'periodText': value.periodText,
        'classroom': value.classroom,
      };
    }
    if (value is KlasTask) {
      return value.raw;
    }
    if (value is Map) {
      final mapped = <String, Object?>{};
      value.forEach((key, item) {
        mapped[key.toString()] = _normalizePayload(item);
      });
      return mapped;
    }
    if (value is Iterable) {
      return value.map(_normalizePayload).toList(growable: false);
    }
    if (value is String || value is num || value is bool) {
      return value;
    }
    return value.toString();
  }

  String _toPrettyPreviewFromNormalized(Object? normalized) {
    if (normalized == null) {
      return '(no data)';
    }

    final plain = switch (normalized) {
      String _ => normalized,
      _ => const JsonEncoder.withIndent('  ').convert(normalized),
    };

    const maxLength = 6000;
    if (plain.length <= maxLength) {
      return plain;
    }
    return '${plain.substring(0, maxLength)}\n...(출력 생략: ${plain.length - maxLength}자)';
  }

  void _notify() {
    // 비동기 요청 완료 시점이 화면 dispose 이후일 수 있으므로 안전하게 가드한다.
    if (!_disposed) {
      notifyListeners();
    }
  }
}

/// `--dart-define=KLAS_BASE_URI=...` 값이 있으면 우선 사용한다.
Uri resolveBaseUri() {
  const override = String.fromEnvironment('KLAS_BASE_URI');
  if (override.isEmpty) {
    return Uri(scheme: 'https', host: 'klas.kw.ac.kr');
  }

  final parsed = Uri.tryParse(override);
  if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) {
    return Uri(scheme: 'https', host: 'klas.kw.ac.kr');
  }
  return parsed;
}
