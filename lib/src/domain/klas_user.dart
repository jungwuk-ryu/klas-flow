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

  Future<List<KlasRecord>> listDiscussions({
    int page = 0,
    Map<String, dynamic>? query,
  }) {
    return array('learning.dscsnStdList', payload: withPage(page, query));
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

  Future<List<KlasRecord>> onlineContents({
    int page = 0,
    Map<String, dynamic>? query,
  }) {
    return array(
      'learning.selectOnlineCntntsStdList',
      payload: withPage(page, query),
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

  Future<List<KlasRecord>> listTimetable({Map<String, dynamic>? query}) {
    return array('enrollment.timetableStdList', payload: query);
  }
}

/// 일정/출석 feature입니다.
final class KlasAttendanceFeature extends _UserFeatureBase {
  KlasAttendanceFeature(super.executor);

  Future<List<KlasRecord>> listSubjects({Map<String, dynamic>? query}) {
    return array('attendance.kwAttendStdGwakmokList', payload: query);
  }

  Future<List<KlasRecord>> monthList({Map<String, dynamic>? query}) {
    return array('attendance.mySchdulMonthList', payload: query);
  }

  Future<List<KlasRecord>> monthTable({Map<String, dynamic>? query}) {
    return array('attendance.mySchdulMonthTableList', payload: query);
  }
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

  Future<KlasRecord> scheduleSummary({Map<String, dynamic>? query}) {
    return object('frame.schdulStdList', payload: query);
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

(String?, String?) _parseCourseLabel(String? source) {
  if (source == null) {
    return (null, null);
  }

  final trimmed = source.trim();
  if (trimmed.isEmpty) {
    return (null, null);
  }

  final separator = trimmed.lastIndexOf(' - ');
  if (separator == -1) {
    return (trimmed, null);
  }

  final title = trimmed.substring(0, separator).trim();
  final professor = trimmed.substring(separator + 3).trim();
  return (title.isEmpty ? null : title, professor.isEmpty ? null : professor);
}
