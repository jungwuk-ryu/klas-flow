import 'domain_executor.dart';
import '../models/course_context.dart';
import '../exceptions/klas_exceptions.dart';
import '../models/file_payload.dart';
import '../models/high_level_models.dart';

/// 로그인된 사용자 도메인 객체입니다.
final class KlasUser {
  final KlasDomainExecutor _executor;
  KlasUserProfile _profile;
  KlasPersonalInfo? _cachedPersonalInfo;
  List<KlasCourse>? _cachedCourses;

  late final KlasAcademicFeature academic = KlasAcademicFeature(_executor);
  late final KlasEnrollmentFeature enrollment = KlasEnrollmentFeature(
    _executor,
  );
  late final KlasAttendanceFeature attendance = KlasAttendanceFeature(
    _executor,
  );
  late final KlasStudentRecordFeature studentRecord = KlasStudentRecordFeature(
    _executor,
  );
  late final KlasFileFeature files = KlasFileFeature(_executor);
  late final KlasFrameFeature frame = KlasFrameFeature(_executor);

  KlasUser({
    required KlasDomainExecutor executor,
    required KlasUserProfile profile,
  }) : _executor = executor,
       _profile = profile;

  /// 사용자 식별자입니다.
  String? get id => _profile.userId;

  /// 사용자 이름입니다.
  String? get name => _profile.userName;

  /// 인증 상태입니다.
  bool get authenticated => _profile.authenticated;

  /// 사용자 프로필을 조회합니다.
  Future<KlasUserProfile> profile({bool refresh = false}) async {
    if (!refresh) {
      return _profile;
    }
    _profile = await _executor.fetchUserProfile();
    return _profile;
  }

  /// 세션 상태를 조회합니다.
  Future<KlasSessionStatus> sessionStatus() async {
    final raw = await _executor.callObject(
      'session.info',
      includeContext: false,
    );
    return KlasSessionStatus.fromJson(raw);
  }

  /// 개인정보 수정 화면 기준 상세 프로필을 조회합니다.
  Future<KlasPersonalInfo> personalInfo({bool refresh = false}) async {
    if (!refresh && _cachedPersonalInfo != null) {
      return _cachedPersonalInfo!;
    }

    final raw = await _executor.callObject(
      'user.personalInfo',
      payload: const <String, dynamic>{},
      includeContext: false,
    );
    final info = KlasPersonalInfo.fromJson(raw);
    _cachedPersonalInfo = info;
    return info;
  }

  /// 서버 세션을 연장합니다.
  Future<void> keepAlive() {
    return _executor.keepAlive();
  }

  /// 수강 과목 목록을 조회합니다.
  Future<List<KlasCourse>> courses({bool refresh = false}) async {
    if (!refresh && _cachedCourses != null) {
      return List<KlasCourse>.unmodifiable(_cachedCourses!);
    }

    final contexts = refresh || _executor.availableContexts.isEmpty
        ? await _executor.refreshContexts()
        : _executor.availableContexts;

    final courses = contexts
        .map(
          (context) =>
              KlasCourse(executor: _executor, owner: this, context: context),
        )
        .toList(growable: false);
    _cachedCourses = courses;
    return List<KlasCourse>.unmodifiable(courses);
  }

  /// 기본 과목 컨텍스트를 반환합니다.
  Future<KlasCourse?> defaultCourse({bool refresh = false}) async {
    final items = await courses(refresh: refresh);
    if (items.isEmpty) {
      return null;
    }

    final defaults = items.where((course) => course.isDefault).toList();
    if (defaults.isNotEmpty) {
      return defaults.first;
    }
    return items.first;
  }

  /// 과목 ID로 수강 과목을 찾습니다.
  Future<KlasCourse?> findCourseById(
    String courseId, {
    bool refresh = false,
  }) async {
    final normalized = courseId.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final items = await courses(refresh: refresh);
    for (final course in items) {
      if (course.courseId.trim() == normalized) {
        return course;
      }
    }
    return null;
  }

  /// 표시 과목명으로 수강 과목을 찾습니다.
  Future<KlasCourse?> findCourseByTitle(
    String title, {
    bool refresh = false,
  }) async {
    final normalized = title.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }

    final items = await courses(refresh: refresh);
    for (final course in items) {
      final courseTitle = course.title?.trim().toLowerCase();
      if (courseTitle == normalized) {
        return course;
      }
    }
    return null;
  }

  /// 학기 시간표를 조회합니다.
  ///
  /// `termId`를 넘기지 않으면 기본 과목의 학기를 사용해
  /// `searchYear/searchHakgi`를 자동으로 채웁니다.
  Future<KlasTimetable> timetable({
    String? termId,
    Map<String, dynamic>? query,
  }) async {
    String? resolvedTermId = _normalizeTermId(termId);
    if (resolvedTermId == null && !_hasTimetableTermQuery(query)) {
      resolvedTermId = _normalizeTermId((await defaultCourse())?.termId);
    }
    return enrollment.timetable(termId: resolvedTermId, query: query);
  }

  /// 내부 캐시를 초기화합니다.
  void clearCache() {
    _cachedPersonalInfo = null;
    _cachedCourses = null;
  }
}

/// 단일 강의 도메인 객체입니다.
final class KlasCourse {
  final KlasDomainExecutor _executor;
  final KlasUser _owner;
  final CourseContext _context;

  late final KlasLearningFeature learning = KlasLearningFeature(
    _executor,
    _context,
  );
  late final KlasNoticeBoard noticeBoard = KlasNoticeBoard(_executor, _context);
  late final KlasMaterialBoard materialBoard = KlasMaterialBoard(
    _executor,
    _context,
  );
  late final KlasSurveyFeature surveys = KlasSurveyFeature(_executor, _context);
  late final KlasEClassFeature eclass = KlasEClassFeature(_executor, _context);

  KlasCourse({
    required KlasDomainExecutor executor,
    required KlasUser owner,
    required CourseContext context,
  }) : _executor = executor,
       _owner = owner,
       _context = context;

  /// 과목 식별자입니다.
  String get courseId => _context.selectSubj;

  /// 학기 식별자입니다.
  String get termId => _context.selectYearhakgi;

  /// 표시 과목명입니다.
  String? get title => _parseCourseLabel(_context.subjectName).$1;

  /// 표시 교수명입니다.
  String? get professorName => _parseCourseLabel(_context.subjectName).$2;

  /// 기본 과목 여부입니다.
  bool get isDefault => _context.isDefault;

  /// 원본 컨텍스트입니다.
  CourseContext get rawContext => _context;

  /// 소유 사용자 객체입니다.
  KlasUser get owner => _owner;

  /// 강의 개요를 조회합니다.
  Future<KlasCourseOverview> overview() async {
    final raw = await _executor.callCourseObject(
      'learning.lctrumHomeStdInfo',
      context: _context,
      payload: const {},
    );
    return KlasCourseOverview(KlasRecord(raw));
  }

  /// 강의 시간표 문자열을 조회합니다.
  Future<String?> scheduleText() async {
    final raw = await _executor.callCourse(
      'frame.lctrumSchdulInfo',
      context: _context,
      payload: const {},
    );
    if (raw == null) {
      return null;
    }
    return raw.toString();
  }

  /// 과제 목록을 조회합니다.
  Future<List<KlasTask>> listTasks({int page = 0}) async {
    final rows = await _executor.callCourseArray(
      'learning.taskStdList',
      context: _context,
      payload: <String, dynamic>{'currentPage': page},
    );

    return rows.map(_recordMap).map(KlasTask.fromJson).toList(growable: false);
  }

  /// 현재 과목에 대해 QR 출석을 처리합니다.
  Future<KlasQrAttendanceResult> qrCheckIn(String qrCode) async {
    final subject = await _owner.attendance.findSubjectItemByCourse(this);
    return _owner.attendance.qrCheckIn(subject: subject, qrCode: qrCode);
  }
}

abstract base class _CourseFeatureBase {
  final KlasDomainExecutor executor;
  final CourseContext context;

  _CourseFeatureBase(this.executor, this.context);

  Future<List<KlasRecord>> array(
    String endpoint, {
    Map<String, dynamic>? payload,
  }) async {
    final rows = await executor.callCourseArray(
      endpoint,
      context: context,
      payload: payload ?? const <String, dynamic>{},
    );
    return rows.map(_recordFromDynamic).toList(growable: false);
  }

  Future<KlasRecord> object(
    String endpoint, {
    Map<String, dynamic>? payload,
  }) async {
    final row = await executor.callCourseObject(
      endpoint,
      context: context,
      payload: payload ?? const <String, dynamic>{},
    );
    return KlasRecord(row);
  }

  Future<Object?> scalar(String endpoint, {Map<String, dynamic>? payload}) {
    return executor.callCourse(
      endpoint,
      context: context,
      payload: payload ?? const <String, dynamic>{},
    );
  }

  Future<String> text(String endpoint, {Map<String, dynamic>? payload}) {
    return executor.callCourseText(
      endpoint,
      context: context,
      payload: payload ?? const <String, dynamic>{},
    );
  }

  Map<String, dynamic> withPage(int page, Map<String, dynamic>? payload) {
    return <String, dynamic>{
      'currentPage': page,
      if (payload != null) ...payload,
    };
  }
}

/// 강의 학습 feature 모음입니다.
final class KlasLearningFeature extends _CourseFeatureBase {
  KlasLearningFeature(super.executor, super.context);

  Future<List<KlasRecord>> listAnytimeQuizzes({
    int page = 0,
    Map<String, dynamic>? query,
  }) {
    return array('learning.anytmQuizStdList', payload: withPage(page, query));
  }

  /// 수시퀴즈 목록을 고수준 모델로 조회합니다.
  Future<List<KlasAnytimeQuiz>> listAnytimeQuizItems({
    int page = 0,
    Map<String, dynamic>? query,
  }) async {
    final rows = await listAnytimeQuizzes(page: page, query: query);
    return List<KlasAnytimeQuiz>.unmodifiable(
      rows.map((row) => KlasAnytimeQuiz.fromJson(row.raw)),
    );
  }

  Future<List<KlasRecord>> listDiscussions({
    int page = 0,
    Map<String, dynamic>? query,
  }) {
    return array('learning.dscsnStdList', payload: withPage(page, query));
  }

  /// 토론 목록을 고수준 모델로 조회합니다.
  Future<List<KlasDiscussionTopic>> listDiscussionItems({
    int page = 0,
    Map<String, dynamic>? query,
  }) async {
    final rows = await listDiscussions(page: page, query: query);
    return List<KlasDiscussionTopic>.unmodifiable(
      rows.map((row) => KlasDiscussionTopic.fromJson(row.raw)),
    );
  }

  Future<KlasRecord> homeInfo({Map<String, dynamic>? query}) {
    return object('learning.lctrumHomeStdInfo', payload: query);
  }

  Future<List<KlasRecord>> attendanceStatus({Map<String, dynamic>? query}) {
    return array('learning.lrnSttusStdAtendList', payload: query);
  }

  Future<List<KlasRecord>> attendanceStatusDetail({
    Map<String, dynamic>? query,
  }) {
    return array('learning.lrnSttusStdAtendListSub', payload: query);
  }

  Future<List<KlasRecord>> discussionStatus({Map<String, dynamic>? query}) {
    return array('learning.lrnSttusStdDscsnList', payload: query);
  }

  Future<KlasRecord> summary({Map<String, dynamic>? query}) {
    return object('learning.lrnSttusStdOne', payload: query);
  }

  Future<List<KlasRecord>> realtimeProgress({Map<String, dynamic>? query}) {
    return array('learning.lrnSttusStdRtprgsList', payload: query);
  }

  Future<List<KlasRecord>> taskStatus({Map<String, dynamic>? query}) {
    return array('learning.lrnSttusStdTaskList', payload: query);
  }

  /// 과제 상세 정보를 조회합니다.
  Future<KlasTaskDetail> getTaskDetail({
    required int ordseq,
    int? seq,
    Map<String, dynamic>? query,
  }) async {
    final payload = <String, dynamic>{
      'pageInit': true,
      'rpt': const <Object>[],
      'smt': const <Object>[],
      'selectChangeYn': context.selectChangeYn,
      'ordseq': ordseq.toString(),
      'seq': seq,
      'contents': '',
      'selectYearhakgi': context.selectYearhakgi,
      'selectSubj': context.selectSubj,
      if (query != null) ...query,
    };
    final raw = await executor.callCourseObject(
      'learning.taskStdView',
      context: context,
      payload: payload,
    );
    return KlasTaskDetail.fromJson(raw);
  }

  Future<List<KlasRecord>> teamProjects({Map<String, dynamic>? query}) {
    return array('learning.lrnSttusStdTeamPrjctList', payload: query);
  }

  Future<List<KlasRecord>> testAndQuizStatus({Map<String, dynamic>? query}) {
    return array('learning.lrnSttusStdTestAnQuizList', payload: query);
  }

  Future<List<KlasRecord>> onlineTests({
    int page = 0,
    Map<String, dynamic>? query,
  }) {
    return array('learning.onlineTestStdList', payload: withPage(page, query));
  }

  /// 온라인 시험 목록을 고수준 모델로 조회합니다.
  Future<List<KlasOnlineTest>> listOnlineTestItems({
    int page = 0,
    Map<String, dynamic>? query,
  }) async {
    final rows = await onlineTests(page: page, query: query);
    return List<KlasOnlineTest>.unmodifiable(
      rows.map((row) => KlasOnlineTest.fromJson(row.raw)),
    );
  }

  Future<List<KlasRecord>> onlineContents({
    int page = 0,
    Map<String, dynamic>? query,
  }) {
    return array(
      'learning.selectOnlineCntntsStdList',
      payload: withPage(page, query),
    );
  }

  /// 온라인 콘텐츠 목록을 고수준 모델로 조회합니다.
  Future<List<KlasOnlineContent>> listOnlineContentItems({
    int page = 0,
    Map<String, dynamic>? query,
  }) async {
    final rows = await onlineContents(page: page, query: query);
    return List<KlasOnlineContent>.unmodifiable(
      rows.map((row) => KlasOnlineContent.fromJson(row.raw)),
    );
  }
}

abstract base class _BaseBoardFeature extends _CourseFeatureBase {
  final String listEndpoint;
  final String viewEndpoint;
  final String pageEndpoint;
  final String searchMasterNo;

  _BaseBoardFeature({
    required KlasDomainExecutor executor,
    required CourseContext context,
    required this.listEndpoint,
    required this.viewEndpoint,
    required this.pageEndpoint,
    required this.searchMasterNo,
  }) : super(executor, context);

  Future<KlasBoardList> listPosts({
    int page = 0,
    String keyword = '',
    String searchCondition = 'ALL',
    Map<String, dynamic>? query,
  }) async {
    final payload = <String, dynamic>{
      'searchCondition': searchCondition,
      'searchKeyword': keyword,
      'currentPage': page,
      if (query != null) ...query,
    };
    final raw = await executor.callCourseObject(
      listEndpoint,
      context: context,
      payload: payload,
    );
    return KlasBoardList.fromJson(
      raw,
      detailResolver:
          ({
            required int boardNo,
            required String cmd,
            Map<String, dynamic>? query,
          }) {
            return getPost(boardNo: boardNo, cmd: cmd, query: query);
          },
    );
  }

  Future<KlasBoardPostDetail> getPost({
    required int boardNo,
    String cmd = 'select',
    Map<String, dynamic>? query,
  }) async {
    // 일부 배포는 상세 JSON 조회 전에 페이지 진입(폼 POST) 히스토리가 필요하다.
    // preflight 실패는 무시하고 본 조회를 계속 시도한다.
    try {
      await executor.callCourseText(
        pageEndpoint,
        context: context,
        payload: _buildBoardPagePayload(
          boardNo: boardNo,
          cmd: cmd,
          query: query,
        ),
      );
    } catch (_) {
      // no-op
    }

    final resolvedSearchMasterNo = (query?['searchMasterNo'] ?? searchMasterNo)
        .toString();

    final payload = <String, dynamic>{
      'cmd': cmd,
      'searchMasterNo': resolvedSearchMasterNo,
      'searchCondition': 'ALL',
      'searchKeyword': '',
      'currentPage': '1',
      'masterNo': resolvedSearchMasterNo,
      'boardNo': boardNo.toString(),
      if (query != null) ...query,
    };

    final raw = await executor.callCourseObject(
      viewEndpoint,
      context: context,
      payload: payload,
    );
    return KlasBoardPostDetail.fromJson(raw);
  }

  Future<String> openPostPage({
    required int boardNo,
    String cmd = 'select',
    Map<String, dynamic>? query,
  }) {
    return executor.callCourseText(
      pageEndpoint,
      context: context,
      payload: _buildBoardPagePayload(boardNo: boardNo, cmd: cmd, query: query),
    );
  }

  Map<String, dynamic> _buildBoardPagePayload({
    required int boardNo,
    required String cmd,
    Map<String, dynamic>? query,
  }) {
    final selectedYearhakgi = context.selectYearhakgi;
    final selectedSubj = context.selectSubj;

    final resolvedSearchMasterNo = (query?['searchMasterNo'] ?? searchMasterNo)
        .toString();

    return <String, dynamic>{
      'selectedGrcode': '',
      'selectedYearhakgi': selectedYearhakgi,
      'selectedSubj': selectedSubj,
      'cmd': cmd,
      'selectYearhakgi': selectedYearhakgi,
      'selectSubj': selectedSubj,
      'selectChangeYn': context.selectChangeYn,
      'searchMasterNo': resolvedSearchMasterNo,
      'searchCondition': 'ALL',
      'searchKeyword': '',
      'currentPage': '1',
      'masterNo': resolvedSearchMasterNo,
      'boardNo': boardNo.toString(),
      if (query != null) ...query,
    };
  }
}

/// 공지 게시판 feature입니다.
final class KlasNoticeBoard extends _BaseBoardFeature {
  KlasNoticeBoard(KlasDomainExecutor executor, CourseContext context)
    : super(
        executor: executor,
        context: context,
        listEndpoint: 'boardSurvey.boardStdList_d052b8f8',
        viewEndpoint: 'boardSurvey.boardStdView_d052b8f8',
        pageEndpoint: 'boardSurvey.boardViewStdPage_d052b8f8',
        searchMasterNo: '1',
      );
}

/// 강의 자료 게시판 feature입니다.
final class KlasMaterialBoard extends _BaseBoardFeature {
  KlasMaterialBoard(KlasDomainExecutor executor, CourseContext context)
    : super(
        executor: executor,
        context: context,
        listEndpoint: 'boardSurvey.boardStdList_6972896b',
        viewEndpoint: 'boardSurvey.boardStdView_6972896b',
        pageEndpoint: 'boardSurvey.boardViewStdPage_d052b8f8',
        searchMasterNo: '3',
      );
}

/// 설문 feature입니다.
final class KlasSurveyFeature extends _CourseFeatureBase {
  KlasSurveyFeature(super.executor, super.context);

  Future<String> openPage({Map<String, dynamic>? query}) {
    return text('boardSurvey.qustnrStdPage', payload: query);
  }

  Future<List<KlasRecord>> list({Map<String, dynamic>? query}) {
    return array('boardSurvey.qustnrStdList', payload: query);
  }

  /// 설문 목록을 고수준 모델로 조회합니다.
  Future<List<KlasSurveyEntry>> listSurveyItems({
    Map<String, dynamic>? query,
  }) async {
    final rows = await list(query: query);
    return List<KlasSurveyEntry>.unmodifiable(
      rows.map((row) => KlasSurveyEntry.fromJson(row.raw)),
    );
  }
}

/// eClass feature입니다.
final class KlasEClassFeature extends _CourseFeatureBase {
  KlasEClassFeature(super.executor, super.context);

  Future<List<KlasRecord>> listItems({
    int page = 0,
    Map<String, dynamic>? query,
  }) {
    return array('eclass.eClassStdList', payload: withPage(page, query));
  }

  /// e-Class 항목 목록을 고수준 모델로 조회합니다.
  Future<List<KlasEClassItem>> listEClassItems({
    int page = 0,
    Map<String, dynamic>? query,
  }) async {
    final rows = await listItems(page: page, query: query);
    return List<KlasEClassItem>.unmodifiable(
      rows.map((row) => KlasEClassItem.fromJson(row.raw)),
    );
  }
}

abstract base class _UserFeatureBase {
  final KlasDomainExecutor executor;

  _UserFeatureBase(this.executor);

  Future<List<KlasRecord>> array(
    String endpoint, {
    Map<String, dynamic>? payload,
  }) async {
    final rows = await executor.callArray(
      endpoint,
      payload: payload ?? const <String, dynamic>{},
      includeContext: false,
    );
    return rows.map(_recordFromDynamic).toList(growable: false);
  }

  Future<KlasRecord> object(
    String endpoint, {
    Map<String, dynamic>? payload,
  }) async {
    final row = await executor.callObject(
      endpoint,
      payload: payload ?? const <String, dynamic>{},
      includeContext: false,
    );
    return KlasRecord(row);
  }

  Future<Object?> scalar(String endpoint, {Map<String, dynamic>? payload}) {
    return executor.call(
      endpoint,
      payload: payload ?? const <String, dynamic>{},
      includeContext: false,
    );
  }

  Future<String> text(String endpoint, {Map<String, dynamic>? payload}) {
    return executor.callText(
      endpoint,
      payload: payload ?? const <String, dynamic>{},
      includeContext: false,
    );
  }
}

/// 학사/성적 feature입니다.
final class KlasAcademicFeature extends _UserFeatureBase {
  KlasAcademicFeature(super.executor);

  Future<KlasRecord> checkTerm({Map<String, dynamic>? query}) {
    return object('academic.atnlcScreCheckTerm', payload: query);
  }

  Future<KlasRecord> hakjukInfo({Map<String, dynamic>? query}) {
    return object('academic.atnlcScreHakjukInfo', payload: query);
  }

  Future<KlasRecord> programCategory({Map<String, dynamic>? query}) {
    return object('academic.atnlcScreProgramGubun', payload: query);
  }

  Future<Object?> sugangOption({Map<String, dynamic>? query}) {
    return scalar('academic.atnlcScreSugangOpt', payload: query);
  }

  Future<List<KlasRecord>> listGrades({Map<String, dynamic>? query}) {
    return array('academic.atnlcScreSungjukInfo', payload: query);
  }

  /// 성적 목록을 고수준 모델로 조회합니다.
  Future<List<KlasGradeEntry>> listGradeEntries({
    Map<String, dynamic>? query,
  }) async {
    final rows = await listGrades(query: query);
    return List<KlasGradeEntry>.unmodifiable(
      rows.map((row) => KlasGradeEntry.fromJson(row.raw)),
    );
  }

  Future<KlasRecord> gradeSummary({Map<String, dynamic>? query}) {
    return object('academic.atnlcScreSungjukTot', payload: query);
  }

  Future<List<KlasRecord>> listDeletedApplications({
    Map<String, dynamic>? query,
  }) {
    return array('academic.delAppliedList', payload: query);
  }

  Future<KlasRecord> deletedHakjukInfo({Map<String, dynamic>? query}) {
    return object('academic.delHakjukInfo', payload: query);
  }

  Future<List<KlasRecord>> listDeletedGrades({Map<String, dynamic>? query}) {
    return array('academic.delSungjukStdList', payload: query);
  }

  Future<KlasRecord> gyoyangInfo({Map<String, dynamic>? query}) {
    return object('academic.gyoyangIsuInfo', payload: query);
  }

  Future<List<KlasRecord>> listPortfolio({Map<String, dynamic>? query}) {
    return array('academic.individualPortfolioStdList', payload: query);
  }

  Future<List<KlasRecord>> listScholarshipHistory({
    Map<String, dynamic>? query,
  }) {
    return array('academic.janghakHistoryStdList', payload: query);
  }

  Future<List<KlasRecord>> listScholarships({Map<String, dynamic>? query}) {
    return array('academic.janghakStdList', payload: query);
  }

  Future<List<KlasRecord>> listLectureEvalCourses({
    Map<String, dynamic>? query,
  }) {
    return array('academic.lctreEvlResultGwamokList', payload: query);
  }

  Future<List<KlasRecord>> listLectureEvalDepartments({
    Map<String, dynamic>? query,
  }) {
    return array('academic.lctreEvlResultSetHakgwa', payload: query);
  }

  Future<List<KlasRecord>> listStanding({Map<String, dynamic>? query}) {
    return array('academic.standStdList', payload: query);
  }

  Future<List<KlasRecord>> listToeicInfo({Map<String, dynamic>? query}) {
    return array('academic.toeicInfoStd', payload: query);
  }

  Future<String> toeicLevelText({Map<String, dynamic>? query}) {
    return text('academic.toeicLevelInfo', payload: query);
  }

  Future<List<KlasRecord>> listToeicRecords({Map<String, dynamic>? query}) {
    return array('academic.toeicStdList', payload: query);
  }
}

/// 수강/시간표 feature입니다.
final class KlasEnrollmentFeature extends _UserFeatureBase {
  KlasEnrollmentFeature(super.executor);

  Future<List<KlasRecord>> listYears({Map<String, dynamic>? query}) {
    return array('enrollment.atnlcYearList', payload: query);
  }

  Future<List<KlasRecord>> listColleges({Map<String, dynamic>? query}) {
    return array('enrollment.cmmnGamokList', payload: query);
  }

  Future<List<KlasRecord>> listDepartments({Map<String, dynamic>? query}) {
    return array('enrollment.cmmnHakgwaList', payload: query);
  }

  Future<String> lecturePlanStopFlag({Map<String, dynamic>? query}) {
    return text('enrollment.lctrePlanStopFlag', payload: query);
  }

  Future<List<KlasRecord>> listTimetable({
    String? termId,
    Map<String, dynamic>? query,
  }) {
    return array(
      'enrollment.timetableStdList',
      payload: _resolveTimetableQuery(termId: termId, query: query),
    );
  }

  /// 학기 시간표 목록을 고수준 모델로 조회합니다.
  Future<List<KlasTimetableEntry>> listTimetableEntries({
    String? termId,
    Map<String, dynamic>? query,
  }) async {
    final parsed = await timetable(termId: termId, query: query);
    return parsed.entries;
  }

  /// 학기 시간표를 조회합니다.
  Future<KlasTimetable> timetable({
    String? termId,
    Map<String, dynamic>? query,
  }) async {
    final rows = await listTimetable(termId: termId, query: query);
    return KlasTimetable.fromRows(rows.map((row) => row.raw));
  }
}

/// 일정/출석 feature입니다.
final class KlasAttendanceFeature extends _UserFeatureBase {
  KlasAttendanceFeature(super.executor);

  Future<List<KlasRecord>> listSubjects({Map<String, dynamic>? query}) {
    return array('attendance.kwAttendStdGwakmokList', payload: query);
  }

  /// 출석 관리 과목 목록을 고수준 모델로 조회합니다.
  Future<List<KlasAttendanceSubject>> listSubjectItems({
    Map<String, dynamic>? query,
  }) async {
    final rows = await listSubjects(query: query);
    return List<KlasAttendanceSubject>.unmodifiable(
      rows.map((row) => KlasAttendanceSubject.fromJson(row.raw)),
    );
  }

  /// 과목 ID로 출석 과목 항목을 찾습니다.
  Future<KlasAttendanceSubject?> findSubjectItemById(
    String subjectId, {
    Map<String, dynamic>? query,
  }) async {
    final normalized = subjectId.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final items = await listSubjectItems(query: query);
    for (final item in items) {
      if (_isSameQrAttendanceValue(item.subjectId, normalized)) {
        return item;
      }
    }
    return null;
  }

  /// 표시 과목명으로 출석 과목 항목을 찾습니다.
  Future<KlasAttendanceSubject?> findSubjectItemByTitle(
    String title, {
    Map<String, dynamic>? query,
  }) async {
    final normalized = title.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }

    final items = await listSubjectItems(query: query);
    for (final item in items) {
      final subjectTitle = item.subjectName?.trim().toLowerCase();
      if (subjectTitle == normalized) {
        return item;
      }
    }
    return null;
  }

  /// QR 출석 원본 응답을 조회합니다.
  Future<KlasRecord> qrCheckInRaw({
    required KlasAttendanceSubject subject,
    required String qrCode,
  }) async {
    final normalizedQrCode = qrCode.trim();
    if (normalizedQrCode.isEmpty) {
      throw ArgumentError('qrCode must not be empty.');
    }

    final payload = await _resolveQrAttendancePayload(subject);
    final attendanceRows = await array(
      'attendance.kwAttendStdAttendList',
      payload: payload,
    );
    final attendancePayload = Map<String, dynamic>.from(payload)
      ..['list'] = attendanceRows.map((row) => row.raw).toList(growable: false);

    final randomKeyResponse = await object(
      'attendance.certiPushSucStd',
      payload: attendancePayload,
    );
    final randomKey = _requireQrAttendanceString(
      randomKeyResponse.raw,
      const <String>['randomKey'],
      'QR attendance preparation did not return randomKey.',
    );

    final submitPayload = Map<String, dynamic>.from(attendancePayload)
      ..['randomKey'] = randomKey
      ..['encrypt'] = normalizedQrCode;
    return object('attendance.kwAttendQRCodeInsert', payload: submitPayload);
  }

  /// QR 출석 처리 결과를 고수준 모델로 조회합니다.
  Future<KlasQrAttendanceResult> qrCheckIn({
    required KlasAttendanceSubject subject,
    required String qrCode,
  }) async {
    final result = await qrCheckInRaw(subject: subject, qrCode: qrCode);
    return _parseQrAttendanceResult(result.raw);
  }

  /// 과목 객체에 대응하는 출석 과목 항목을 조회합니다.
  Future<KlasAttendanceSubject> findSubjectItemByCourse(
    KlasCourse course, {
    bool refresh = false,
  }) async {
    final items = await listSubjectItems(
      query: _defaultQrAttendanceSubjectQuery(course.termId),
    );
    final matched = _findUniqueQrAttendanceSubject(
      items,
      termId: course.termId,
      subjectId: course.courseId,
      subjectName: course.title,
      professorName: course.professorName,
      ambiguousMessage:
          'QR attendance subject match is ambiguous for ${course.title ?? course.courseId}.',
    );
    if (matched != null) {
      return matched;
    }

    throw QrAttendanceUnavailableException(
      'QR attendance subject was not found for ${course.title ?? course.courseId}.',
    );
  }

  /// 월간 일정 원본 목록을 조회합니다.
  ///
  /// 최근 배포에서는 `schdulYear`, `schdulMonth`가 없으면 500을 반환하는 경우가 있어,
  /// 값이 비어있으면 현재 연/월을 기본으로 채워 요청합니다.
  Future<List<KlasRecord>> monthList({
    int? year,
    int? month,
    Map<String, dynamic>? query,
  }) {
    return array(
      'attendance.mySchdulMonthList',
      payload: _resolveMonthlyScheduleQuery(
        year: year,
        month: month,
        query: query,
      ),
    );
  }

  /// 월간 일정 목록을 고수준 모델로 조회합니다.
  Future<List<KlasMonthlyScheduleItem>> listMonthlySchedules({
    int? year,
    int? month,
    Map<String, dynamic>? query,
  }) async {
    final payload = _resolveMonthlyScheduleQuery(
      year: year,
      month: month,
      query: query,
    );
    late final List<KlasRecord> rows;
    try {
      rows = await array('attendance.mySchdulMonthList', payload: payload);
    } on ServiceUnavailableException {
      rows = await _fallbackMonthlyScheduleRows(payload);
    }
    return List<KlasMonthlyScheduleItem>.unmodifiable(
      rows.map((row) => KlasMonthlyScheduleItem.fromJson(row.raw)),
    );
  }

  Future<List<KlasRecord>> _fallbackMonthlyScheduleRows(
    Map<String, dynamic> payload,
  ) async {
    final summary = await object('frame.schdulStdList', payload: payload);
    final list = summary.raw['list'];
    if (list is! List) {
      throw ParsingException(
        'Frame schedule summary fallback did not return a list payload.',
      );
    }

    return List<KlasRecord>.unmodifiable(
      list.map<KlasRecord>((item) => _recordFromDynamic(item)),
    );
  }

  /// 월간 일정 테이블 원본 목록을 조회합니다.
  ///
  /// 최근 배포에서는 `schdulYear`, `schdulMonth`가 없으면 500을 반환하는 경우가 있어,
  /// 값이 비어있으면 현재 연/월을 기본으로 채워 요청합니다.
  Future<List<KlasRecord>> monthTable({
    int? year,
    int? month,
    Map<String, dynamic>? query,
  }) {
    return array(
      'attendance.mySchdulMonthTableList',
      payload: _resolveMonthlyScheduleQuery(
        year: year,
        month: month,
        query: query,
      ),
    );
  }

  /// 월간 일정 테이블을 고수준 모델로 조회합니다.
  Future<List<KlasMonthlyScheduleTableItem>> listMonthlyScheduleTableItems({
    int? year,
    int? month,
    Map<String, dynamic>? query,
  }) async {
    final rows = await monthTable(year: year, month: month, query: query);
    return List<KlasMonthlyScheduleTableItem>.unmodifiable(
      rows.map((row) => KlasMonthlyScheduleTableItem.fromJson(row.raw)),
    );
  }

  Future<Map<String, dynamic>> _resolveQrAttendancePayload(
    KlasAttendanceSubject subject,
  ) async {
    final initial = _buildQrAttendancePayload(
      source: subject.raw,
      subjectId: subject.subjectId,
      subjectName: subject.subjectName,
      termId: subject.termId,
    );
    if (initial != null) {
      return initial;
    }

    final fallbackRows = await listSubjects(
      query: _defaultQrAttendanceSubjectQuery(subject.termId),
    );
    final matched = _findUniqueQrAttendanceSubjectRow(
      fallbackRows,
      subject,
      ambiguousMessage:
          'QR attendance subject match is ambiguous for ${subject.displayName}.',
    );
    if (matched == null) {
      throw QrAttendanceUnavailableException(
        'QR attendance is not available for ${subject.displayName}.',
      );
    }

    final fallback = _buildQrAttendancePayload(
      source: matched.raw,
      subjectId: subject.subjectId,
      subjectName: subject.subjectName,
      termId: subject.termId,
    );
    if (fallback == null) {
      throw QrAttendanceUnavailableException(
        'QR attendance payload is incomplete for ${subject.displayName}.',
      );
    }
    return fallback;
  }

  Map<String, dynamic>? _buildQrAttendancePayload({
    required Map<String, dynamic> source,
    required String? subjectId,
    required String? subjectName,
    required String? termId,
  }) {
    final resolvedSubjectId =
        _readQrAttendanceValue(source, const <String>[
          'subj',
          'subjectId',
          'selectSubj',
        ]) ??
        subjectId;
    final resolvedSubjectName =
        _readQrAttendanceValue(source, const <String>[
          'gwamokKname',
          'subjNm',
          'subjectName',
          'title',
        ]) ??
        subjectName;
    final resolvedYear =
        _readQrAttendanceValue(source, const <String>[
          'selectYear',
          'thisYear',
        ]) ??
        _yearFromTermId(termId);
    final resolvedHakgi =
        _readQrAttendanceValue(source, const <String>[
          'selectHakgi',
          'hakgi',
        ]) ??
        _hakgiFromTermId(termId);

    final payload = <String, dynamic>{
      'list': const <dynamic>[],
      'selectYear': resolvedYear ?? '',
      'selectHakgi': resolvedHakgi ?? '',
      'openMajorCode': _readQrAttendanceValue(
        source,
        const <String>['openMajorCode'],
      ),
      'openGrade': _readQrAttendanceValue(source, const <String>['openGrade']),
      'openGwamokNo': _readQrAttendanceValue(
        source,
        const <String>['openGwamokNo'],
      ),
      'bunbanNo': _readQrAttendanceValue(source, const <String>['bunbanNo']),
      'gwamokKname': resolvedSubjectName ?? '',
      'codeName1': _readQrAttendanceValue(source, const <String>['codeName1']),
      'hakjumNum': _readQrAttendanceValue(source, const <String>['hakjumNum']),
      'sisuNum': _readQrAttendanceValue(source, const <String>['sisuNum']),
      'memberName': _readQrAttendanceValue(
        source,
        const <String>['memberName', 'prfsrNm'],
      ),
      'currentNum': _readQrAttendanceValue(
        source,
        const <String>['currentNum'],
      ),
      'yoil': _readQrAttendanceValue(source, const <String>['yoil']),
      'subj': resolvedSubjectId ?? '',
    };

    for (final key in const <String>[
      'selectYear',
      'selectHakgi',
      'openMajorCode',
      'openGrade',
      'openGwamokNo',
      'bunbanNo',
      'gwamokKname',
      'codeName1',
      'hakjumNum',
      'sisuNum',
      'memberName',
      'currentNum',
      'yoil',
      'subj',
    ]) {
      final value = payload[key];
      if (value is! String || value.trim().isEmpty) {
        return null;
      }
    }

    return payload;
  }

  KlasAttendanceSubject? _findUniqueQrAttendanceSubject(
    List<KlasAttendanceSubject> items, {
    required String? termId,
    required String? subjectId,
    required String? subjectName,
    required String? professorName,
    required String ambiguousMessage,
  }) {
    return _findUniqueQrAttendanceMatch<KlasAttendanceSubject>(
      items: items,
      ambiguousMessage: ambiguousMessage,
      stageOne: (item) =>
          _isSameQrAttendanceValue(item.termId, termId) &&
          _isSameQrAttendanceValue(item.subjectId, subjectId) &&
          _isSameQrAttendanceValue(item.professorName, professorName),
      stageTwo: (item) =>
          _isSameQrAttendanceValue(item.termId, termId) &&
          _isSameQrAttendanceValue(item.subjectId, subjectId),
      stageThree: (item) =>
          _isSameQrAttendanceValue(item.termId, termId) &&
          _isSameQrAttendanceValue(item.subjectName, subjectName) &&
          _isSameQrAttendanceValue(item.professorName, professorName),
      stageFour: (item) =>
          _isSameQrAttendanceValue(item.termId, termId) &&
          _isSameQrAttendanceValue(item.subjectName, subjectName),
    );
  }

  KlasRecord? _findUniqueQrAttendanceSubjectRow(
    List<KlasRecord> rows,
    KlasAttendanceSubject subject, {
    required String ambiguousMessage,
  }
  ) {
    return _findUniqueQrAttendanceMatch<KlasRecord>(
      items: rows,
      ambiguousMessage: ambiguousMessage,
      stageOne: (row) =>
          _isSameQrAttendanceValue(_qrAttendanceRowTermId(row), subject.termId) &&
          _isSameQrAttendanceValue(_qrAttendanceRowSubjectId(row), subject.subjectId) &&
          _isSameQrAttendanceValue(
            _qrAttendanceRowProfessorName(row),
            subject.professorName,
          ),
      stageTwo: (row) =>
          _isSameQrAttendanceValue(_qrAttendanceRowTermId(row), subject.termId) &&
          _isSameQrAttendanceValue(_qrAttendanceRowSubjectId(row), subject.subjectId),
      stageThree: (row) =>
          _isSameQrAttendanceValue(_qrAttendanceRowTermId(row), subject.termId) &&
          _isSameQrAttendanceValue(
            _qrAttendanceRowSubjectName(row),
            subject.subjectName,
          ) &&
          _isSameQrAttendanceValue(
            _qrAttendanceRowProfessorName(row),
            subject.professorName,
          ),
      stageFour: (row) =>
          _isSameQrAttendanceValue(_qrAttendanceRowTermId(row), subject.termId) &&
          _isSameQrAttendanceValue(
            _qrAttendanceRowSubjectName(row),
            subject.subjectName,
          ),
    );
  }
}

Map<String, dynamic> _defaultQrAttendanceSubjectQuery(String? termId) {
  final now = DateTime.now();
  final year = _yearFromTermId(termId) ?? now.year.toString();
  final hakgi = _hakgiFromTermId(termId) ?? (now.month <= 6 ? '1' : '2');
  return <String, dynamic>{
    'list': const <dynamic>[],
    'selectYear': year,
    'selectHakgi': hakgi,
    'openMajorCode': '',
    'openGrade': '',
    'openGwamokNo': '',
    'bunbanNo': '',
    'gwamokKname': '',
    'codeName1': '',
    'hakjumNum': '',
    'sisuNum': '',
    'memberName': '',
    'currentNum': '',
    'yoil': '',
  };
}

String? _readQrAttendanceValue(
  Map<String, dynamic> source,
  List<String> candidateKeys,
) {
  for (final key in candidateKeys) {
    final value = source[key];
    if (value == null) {
      continue;
    }
    final normalized = value.toString().trim();
    if (normalized.isNotEmpty) {
      return normalized;
    }
  }
  return null;
}

String _requireQrAttendanceString(
  Map<String, dynamic> source,
  List<String> candidateKeys,
  String message,
) {
  final value = _readQrAttendanceValue(source, candidateKeys);
  if (value == null) {
    throw ParsingException(message);
  }
  return value;
}

String? _composeQrAttendanceTermId(Map<String, dynamic> source) {
  final year = _readQrAttendanceValue(source, const <String>['thisYear']);
  final hakgi = _readQrAttendanceValue(source, const <String>['hakgi']);
  if (year == null || hakgi == null) {
    return null;
  }
  return '$year$hakgi';
}

String? _yearFromTermId(String? termId) {
  if (termId == null) {
    return null;
  }
  final normalized = termId.trim();
  if (normalized.length < 4) {
    return null;
  }
  return normalized.substring(0, 4);
}

String? _hakgiFromTermId(String? termId) {
  if (termId == null) {
    return null;
  }
  final normalized = termId.trim();
  if (normalized.length < 5) {
    return null;
  }
  final suffix = normalized.substring(4);
  return suffix.isEmpty ? null : suffix;
}

bool _isSameQrAttendanceValue(String? left, String? right) {
  if (left == null || right == null) {
    return false;
  }
  return left.trim() == right.trim();
}

T? _findUniqueQrAttendanceMatch<T>({
  required List<T> items,
  required String ambiguousMessage,
  required bool Function(T item) stageOne,
  required bool Function(T item) stageTwo,
  required bool Function(T item) stageThree,
  required bool Function(T item) stageFour,
}) {
  for (final matcher in <bool Function(T item)>[
    stageOne,
    stageTwo,
    stageThree,
    stageFour,
  ]) {
    final matches = items.where(matcher).toList(growable: false);
    if (matches.length == 1) {
      return matches.first;
    }
    if (matches.length > 1) {
      throw QrAttendanceUnavailableException(ambiguousMessage);
    }
  }
  return null;
}

String? _qrAttendanceRowSubjectId(KlasRecord row) {
  return _readQrAttendanceValue(row.raw, const <String>[
    'subj',
    'subjectId',
    'selectSubj',
  ]);
}

String? _qrAttendanceRowSubjectName(KlasRecord row) {
  return _readQrAttendanceValue(row.raw, const <String>[
    'gwamokKname',
    'subjNm',
    'subjectName',
  ]);
}

String? _qrAttendanceRowProfessorName(KlasRecord row) {
  return _readQrAttendanceValue(row.raw, const <String>[
    'memberName',
    'prfsrNm',
  ]);
}

String? _qrAttendanceRowTermId(KlasRecord row) {
  return _readQrAttendanceValue(row.raw, const <String>[
        'yearhakgi',
        'selectYearhakgi',
      ]) ??
      _composeQrAttendanceTermId(row.raw);
}

KlasQrAttendanceResult _parseQrAttendanceResult(Map<String, dynamic> source) {
  final fieldErrorMessages = _collectQrAttendanceFieldErrorMessages(source);
  if (fieldErrorMessages.isNotEmpty) {
    final message = fieldErrorMessages.join(' ').trim();
    return KlasQrAttendanceResult(
      accepted: false,
      messages: List<String>.unmodifiable(fieldErrorMessages),
      message: message.isEmpty ? null : message,
      raw: source,
    );
  }

  final outcomeToken =
      _readQrAttendanceValue(source, const <String>[
        'success',
        'isSuccess',
        'authenticated',
      ]) ??
      _readQrAttendanceValue(source, const <String>[
        'result',
        'status',
        'code',
      ]);
  final message = _readQrAttendanceValue(source, const <String>[
    'message',
    'msg',
    'errorMessage',
    'errorMsg',
    'defaultMessage',
  ]);
  final successState = _parseQrAttendanceOutcomeToken(outcomeToken);

  if (successState == false) {
    final failureMessage = message ?? 'QR attendance request failed.';
    return KlasQrAttendanceResult(
      accepted: false,
      messages: List<String>.unmodifiable(<String>[failureMessage]),
      message: failureMessage,
      raw: source,
    );
  }

  if (successState == true) {
    return KlasQrAttendanceResult(
      accepted: true,
      messages: const <String>[],
      message: message,
      raw: source,
    );
  }

  if (_isEffectivelyEmptyQrAttendanceResponse(source)) {
    throw ParsingException('QR attendance response was empty.');
  }

  return KlasQrAttendanceResult(
    accepted: true,
    messages: const <String>[],
    message: message,
    raw: source,
  );
}

List<String> _collectQrAttendanceFieldErrorMessages(Map<String, dynamic> source) {
  final messages = <String>[];
  final fieldErrors = source['fieldErrors'];
  if (fieldErrors is! List) {
    return messages;
  }

  for (final item in fieldErrors) {
    if (item is! Map) {
      continue;
    }
    final rawItem = item.cast<String, dynamic>();
    final message = _readQrAttendanceValue(rawItem, const <String>[
      'message',
      'defaultMessage',
      'msg',
    ]);
    if (message != null && message.trim().isNotEmpty) {
      messages.add(message.trim());
    }
  }
  return messages;
}

bool? _parseQrAttendanceOutcomeToken(String? token) {
  if (token == null) {
    return null;
  }

  final normalized = token.trim().toLowerCase();
  if (normalized.isEmpty) {
    return null;
  }

  if (const <String>{'ok', 'success', 's', '0', '200', 'y', 'true'}.contains(
    normalized,
  )) {
    return true;
  }
  if (const <String>{
    'fail',
    'failed',
    'error',
    '401',
    'n',
    'false',
  }.contains(normalized)) {
    return false;
  }
  return null;
}

bool _isEffectivelyEmptyQrAttendanceResponse(Map<String, dynamic> source) {
  if (source.isEmpty) {
    return true;
  }
  return source.values.every(_isEffectivelyEmptyQrAttendanceValue);
}

bool _isEffectivelyEmptyQrAttendanceValue(Object? value) {
  if (value == null) {
    return true;
  }
  if (value is String) {
    return value.trim().isEmpty;
  }
  if (value is List) {
    return value.isEmpty || value.every(_isEffectivelyEmptyQrAttendanceValue);
  }
  if (value is Map) {
    return value.isEmpty || value.values.every(_isEffectivelyEmptyQrAttendanceValue);
  }
  return false;
}

/// 학적 feature입니다.
final class KlasStudentRecordFeature extends _UserFeatureBase {
  KlasStudentRecordFeature(super.executor);

  Future<KlasRecord> temporaryLeaveHakjuk({Map<String, dynamic>? query}) {
    return object('studentRecord.tmpabssklGetHakjuk', payload: query);
  }

  Future<KlasRecord> temporaryLeaveStatus({Map<String, dynamic>? query}) {
    return object('studentRecord.tmpabssklStatu', payload: query);
  }
}

/// 파일 feature입니다.
final class KlasFileFeature extends _UserFeatureBase {
  KlasFileFeature(super.executor);

  Future<List<KlasAttachedFile>> listByAttachId({
    required String attachId,
    Map<String, dynamic>? query,
  }) async {
    final resolvedAttachId = attachId.trim();
    final baseQuery = <String, dynamic>{if (query != null) ...query};
    final storageIdRaw = baseQuery['storageId']?.toString().trim();
    final storageId = (storageIdRaw == null || storageIdRaw.isEmpty)
        ? 'CLS_BOARD'
        : storageIdRaw;

    // 서버 배포 버전에 따라 요청 키가 다르게 동작해서, 관측된 조합을 순차 시도한다.
    final attempts = <Map<String, dynamic>>[
      <String, dynamic>{
        ...baseQuery,
        'storageId': storageId,
        'attachId': resolvedAttachId,
      },
      <String, dynamic>{...baseQuery, 'attachId': resolvedAttachId},
      <String, dynamic>{...baseQuery, 'atchFileId': resolvedAttachId},
    ];

    KlasException? lastKlasError;
    Object? lastError;
    var hadSuccessfulCall = false;

    for (final payload in attempts) {
      try {
        final rows = await array('file.uploadFileList', payload: payload);
        hadSuccessfulCall = true;
        final files = rows
            .map(
              (record) => KlasAttachedFile.fromJson(
                record.raw,
                defaultAttachId: resolvedAttachId,
                downloadResolver:
                    ({required String attachId, required String fileSn}) {
                      return download(attachId: attachId, fileSn: fileSn);
                    },
              ),
            )
            .toList(growable: false);
        if (files.isNotEmpty) {
          return files;
        }
      } on KlasException catch (error) {
        lastKlasError = error;
      } catch (error) {
        lastError = error;
      }
    }

    // API는 성공(200)인데 빈 배열을 주는 경우가 있어, 이 경우는 정상 빈 결과로 처리한다.
    if (hadSuccessfulCall) {
      return const <KlasAttachedFile>[];
    }
    if (lastKlasError != null) {
      throw lastKlasError;
    }
    if (lastError != null) {
      throw lastError;
    }
    return const <KlasAttachedFile>[];
  }

  Future<FilePayload> download({
    required String attachId,
    required String fileSn,
  }) {
    return executor.callBinary(
      'file.downloadFile',
      pathParams: <String, String>{'attachId': attachId, 'fileSn': fileSn},
    );
  }
}

/// 프레임 feature입니다.
final class KlasFrameFeature extends _UserFeatureBase {
  KlasFrameFeature(super.executor);

  Future<KlasRecord> homeOverview({Map<String, dynamic>? query}) {
    return object('frame.stdHome', payload: query);
  }

  /// 월별 일정 요약을 조회합니다.
  ///
  /// 최근 배포에서는 `schdulYear`, `schdulMonth`를 요구하는 경우가 있어
  /// 값이 비어있으면 현재 연/월을 기본으로 채워 요청합니다.
  Future<KlasRecord> scheduleSummary({
    int? year,
    int? month,
    Map<String, dynamic>? query,
  }) {
    return object(
      'frame.schdulStdList',
      payload: _resolveMonthlyScheduleQuery(
        year: year,
        month: month,
        query: query,
      ),
    );
  }

  Future<KlasRecord> gyojikExamCheck({Map<String, dynamic>? query}) {
    return object('frame.gyojikExamCheck', payload: query);
  }
}

KlasRecord _recordFromDynamic(Object? value) {
  final map = _recordMap(value);
  return KlasRecord(map);
}

Map<String, dynamic> _recordMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, dynamic>();
  }
  return <String, dynamic>{'value': value};
}

Map<String, dynamic> _resolveMonthlyScheduleQuery({
  required int? year,
  required int? month,
  required Map<String, dynamic>? query,
}) {
  final payload = <String, dynamic>{if (query != null) ...query};
  if (year != null) {
    payload['schdulYear'] = year;
  }
  if (month != null) {
    payload['schdulMonth'] = month;
  }

  final now = DateTime.now();
  payload.putIfAbsent('schdulYear', () => now.year);
  payload.putIfAbsent('schdulMonth', () => now.month);
  return payload;
}

Map<String, dynamic> _resolveTimetableQuery({
  required String? termId,
  required Map<String, dynamic>? query,
}) {
  final payload = <String, dynamic>{if (query != null) ...query};

  final normalizedTermId =
      _normalizeTermId(termId) ?? _extractTermFromTimetableQuery(payload);
  final fromTerm = _splitTermYearHakgi(normalizedTermId);

  final searchYear = _asTrimmedString(payload['searchYear']) ?? fromTerm?.$1;
  final searchHakgi = _asTrimmedString(payload['searchHakgi']) ?? fromTerm?.$2;

  if (searchYear != null && searchHakgi != null) {
    payload.putIfAbsent('searchYear', () => searchYear);
    payload.putIfAbsent('searchHakgi', () => searchHakgi);
    payload.putIfAbsent('selectYearhakgi', () => '$searchYear,$searchHakgi');
  } else if (normalizedTermId != null) {
    payload.putIfAbsent('selectYearhakgi', () => normalizedTermId);
  }

  // 실서버는 빈 기본 필드를 함께 보낼 때 안정적으로 동작한다.
  payload.putIfAbsent('searchPgmNo', () => '');
  payload.putIfAbsent('list', () => const <Object>[]);
  payload.putIfAbsent('atnlcYearList', () => const <Object>[]);
  payload.putIfAbsent('timeTableList', () => const <Object>[]);
  return payload;
}

bool _hasTimetableTermQuery(Map<String, dynamic>? query) {
  if (query == null || query.isEmpty) {
    return false;
  }
  return _extractTermFromTimetableQuery(query) != null ||
      (_asTrimmedString(query['searchYear']) != null &&
          _asTrimmedString(query['searchHakgi']) != null);
}

String? _extractTermFromTimetableQuery(Map<String, dynamic> query) {
  return _normalizeTermId(_asTrimmedString(query['selectYearhakgi'])) ??
      _normalizeTermId(_asTrimmedString(query['yearhakgi'])) ??
      _normalizeTermId(_asTrimmedString(query['termId']));
}

(String, String)? _splitTermYearHakgi(String? termId) {
  final normalized = _normalizeTermId(termId);
  if (normalized == null) {
    return null;
  }

  final comma = RegExp(r'^(\d{4}),(\d{1,2})$').firstMatch(normalized);
  if (comma != null) {
    return (comma.group(1)!, comma.group(2)!);
  }

  final compact = RegExp(r'^(\d{4})(\d{1,2})$').firstMatch(normalized);
  if (compact != null) {
    return (compact.group(1)!, compact.group(2)!);
  }
  return null;
}

String? _normalizeTermId(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }

  final withSeparator = RegExp(
    r'^(\d{4})\s*[-,./]\s*(\d{1,2})$',
  ).firstMatch(trimmed);
  if (withSeparator != null) {
    return '${withSeparator.group(1)},${withSeparator.group(2)}';
  }

  final compact = RegExp(r'^(\d{4})(\d{1,2})$').firstMatch(trimmed);
  if (compact != null) {
    return trimmed;
  }

  return null;
}

String? _asTrimmedString(Object? value) {
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

(String?, String?) _parseCourseLabel(String? source) {
  if (source == null) {
    return (null, null);
  }

  final trimmed = source.trim();
  if (trimmed.isEmpty) {
    return (null, null);
  }

  // 일반 케이스: "과목명 - 교수명"
  final withProfessor = RegExp(r'^(.*?)\s+-\s+(.+)$').firstMatch(trimmed);
  if (withProfessor != null) {
    final title = withProfessor.group(1)?.trim();
    final professor = withProfessor.group(2)?.trim();
    return (
      title == null || title.isEmpty ? null : title,
      professor == null || professor.isEmpty || professor == '-'
          ? null
          : professor,
    );
  }

  // 교수명이 비어있는 케이스: "과목명 -"
  final trailingDash = RegExp(r'^(.*?)\s+-$').firstMatch(trimmed);
  if (trailingDash != null) {
    final title = trailingDash.group(1)?.trim();
    return (title == null || title.isEmpty ? null : title, null);
  }

  return (trimmed, null);
}
