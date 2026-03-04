import '../api/frame_api.dart';
import '../api/readonly_api.dart';
import '../api/request_executor.dart';
import '../api/session_api.dart';
import '../auth/session_coordinator.dart';
import '../context/context_manager.dart';
import '../models/course_context.dart';
import '../models/file_payload.dart';
import '../models/high_level_models.dart';
import '../models/html_page.dart';
import '../models/session_info.dart';

/// 고수준 도메인 객체가 내부 호출에 사용하는 실행기입니다.
final class KlasDomainExecutor {
  final KlasReadOnlyApi _api;
  final SessionApi _sessionApi;
  final FrameApi _frameApi;
  final RequestExecutor _requestExecutor;
  final SessionCoordinator _sessionCoordinator;
  final ContextManager _contextManager;

  KlasDomainExecutor({
    required KlasReadOnlyApi api,
    required SessionApi sessionApi,
    required FrameApi frameApi,
    required RequestExecutor requestExecutor,
    required SessionCoordinator sessionCoordinator,
    required ContextManager contextManager,
  }) : _api = api,
       _sessionApi = sessionApi,
       _frameApi = frameApi,
       _requestExecutor = requestExecutor,
       _sessionCoordinator = sessionCoordinator,
       _contextManager = contextManager;

  Future<SessionInfo> fetchSessionInfo() {
    return _sessionCoordinator.withAutoRenewal(
      () => _sessionApi.fetchSessionInfo(),
    );
  }

  /// 세션 정보를 기반으로 사용자 프로필을 조회한다.
  ///
  /// `/api/v1/session/info`에 사용자 식별자가 없는 배포를 대비해
  /// 읽기 전용 API 몇 개를 순차적으로 조회하여 userId/userName을 보완한다.
  Future<KlasUserProfile> fetchUserProfile() async {
    final session = await fetchSessionInfo();
    var userId = session.userId;
    var userName = session.userName;

    final raw = <String, dynamic>{'sessionInfo': session.raw};
    if (userId == null || userName == null) {
      final fallback = await _fetchIdentityFallback();
      if (fallback.rawBySource.isNotEmpty) {
        raw['identityFallback'] = fallback.rawBySource;
      }
      userId ??= fallback.userId;
      userName ??= fallback.userName;
    }

    return KlasUserProfile(
      authenticated: session.authenticated,
      userId: userId,
      userName: userName,
      raw: raw,
    );
  }

  Future<HtmlPage> initializeFrame() {
    return _sessionCoordinator.withAutoRenewal(
      () => _frameApi.initializeFrame(),
    );
  }

  Future<List<CourseContext>> refreshContexts() {
    return _sessionCoordinator.refreshContexts();
  }

  List<CourseContext> get availableContexts =>
      _contextManager.availableContexts;

  CourseContext? get currentContext => _contextManager.currentContext;

  Future<void> keepAlive() async {
    await callObject('loginSession.updateSession', includeContext: false);
  }

  Future<Object?> call(
    String id, {
    Map<String, dynamic>? payload,
    Map<String, String>? pathParams,
    Map<String, String>? query,
    bool? includeContext,
  }) {
    return _api.call(
      id,
      payload: payload,
      pathParams: pathParams,
      query: query,
      includeContext: includeContext,
    );
  }

  Future<Map<String, dynamic>> callObject(
    String id, {
    Map<String, dynamic>? payload,
    Map<String, String>? pathParams,
    Map<String, String>? query,
    bool? includeContext,
  }) {
    return _api.callObject(
      id,
      payload: payload,
      pathParams: pathParams,
      query: query,
      includeContext: includeContext,
    );
  }

  Future<List<dynamic>> callArray(
    String id, {
    Map<String, dynamic>? payload,
    Map<String, String>? pathParams,
    Map<String, String>? query,
    bool? includeContext,
  }) {
    return _api.callArray(
      id,
      payload: payload,
      pathParams: pathParams,
      query: query,
      includeContext: includeContext,
    );
  }

  Future<String> callText(
    String id, {
    Map<String, dynamic>? payload,
    Map<String, String>? pathParams,
    Map<String, String>? query,
    bool? includeContext,
  }) {
    return _api.callText(
      id,
      payload: payload,
      pathParams: pathParams,
      query: query,
      includeContext: includeContext,
    );
  }

  Future<FilePayload> callBinary(
    String id, {
    Map<String, String>? pathParams,
    Map<String, String>? query,
  }) {
    return _api.callBinary(id, pathParams: pathParams, query: query);
  }

  Future<Object?> callCourse(
    String id, {
    required CourseContext context,
    Map<String, dynamic>? payload,
    Map<String, String>? pathParams,
    Map<String, String>? query,
  }) {
    return _api.call(
      id,
      payload: _mergeContext(payload, context),
      pathParams: pathParams,
      query: query,
      includeContext: false,
    );
  }

  Future<Map<String, dynamic>> callCourseObject(
    String id, {
    required CourseContext context,
    Map<String, dynamic>? payload,
    Map<String, String>? pathParams,
    Map<String, String>? query,
  }) {
    return _api.callObject(
      id,
      payload: _mergeContext(payload, context),
      pathParams: pathParams,
      query: query,
      includeContext: false,
    );
  }

  Future<List<dynamic>> callCourseArray(
    String id, {
    required CourseContext context,
    Map<String, dynamic>? payload,
    Map<String, String>? pathParams,
    Map<String, String>? query,
  }) {
    return _api.callArray(
      id,
      payload: _mergeContext(payload, context),
      pathParams: pathParams,
      query: query,
      includeContext: false,
    );
  }

  Future<String> callCourseText(
    String id, {
    required CourseContext context,
    Map<String, dynamic>? payload,
    Map<String, String>? pathParams,
    Map<String, String>? query,
  }) {
    return _api.callText(
      id,
      payload: _mergeContext(payload, context),
      pathParams: pathParams,
      query: query,
      includeContext: false,
    );
  }

  Future<FilePayload> downloadPath(String path, {Map<String, String>? query}) {
    return _requestExecutor.getBinary(path, query: query);
  }

  Map<String, dynamic> _mergeContext(
    Map<String, dynamic>? payload,
    CourseContext context,
  ) {
    return <String, dynamic>{
      if (payload != null) ...payload,
      'selectYearhakgi': context.selectYearhakgi,
      'selectSubj': context.selectSubj,
      'selectChangeYn': context.selectChangeYn,
    };
  }

  Future<_IdentityFallback> _fetchIdentityFallback() async {
    String? userId;
    String? userName;
    final rawBySource = <String, Map<String, dynamic>>{};

    for (final endpointId in _identityFallbackEndpointIds) {
      if (userId != null && userName != null) {
        break;
      }

      try {
        final raw = await callObject(endpointId, includeContext: false);
        rawBySource[endpointId] = raw;
        userId ??= _findStringByKeys(raw, _userIdFieldCandidates);
        userName ??= _findStringByKeys(raw, _userNameFieldCandidates);
      } catch (_) {
        // Fallback probe 실패는 로그인 실패로 취급하지 않는다.
      }
    }

    if (userId == null || userName == null) {
      try {
        final frameHtml = await _requestExecutor.getText(
          _frameIdentityFallbackPath,
        );
        final identityFromHtml = _extractIdentityFromFrameHtml(frameHtml);
        userId ??= identityFromHtml.userId;
        userName ??= identityFromHtml.userName;
      } catch (_) {
        // HTML fallback 실패도 프로필 조회 전체 실패로 처리하지 않는다.
      }
    }

    return _IdentityFallback(
      userId: userId,
      userName: userName,
      rawBySource: rawBySource,
    );
  }
}

final class _IdentityFallback {
  final String? userId;
  final String? userName;
  final Map<String, Map<String, dynamic>> rawBySource;

  const _IdentityFallback({
    required this.userId,
    required this.userName,
    required this.rawBySource,
  });
}

final class _FrameIdentity {
  final String? userId;
  final String? userName;

  const _FrameIdentity({required this.userId, required this.userName});
}

String? _findStringByKeys(Map<String, dynamic> source, List<String> keys) {
  final normalizedKeys = keys.map(_normalizeFieldKey).toSet();
  final queue = <Object?>[source];

  for (var index = 0; index < queue.length; index++) {
    final current = queue[index];
    if (current is Map) {
      String? matched;
      current.forEach((Object? key, Object? value) {
        if (value is Map || value is List) {
          queue.add(value);
        }

        final keyText = key?.toString();
        if (keyText == null) {
          return;
        }

        if (!normalizedKeys.contains(_normalizeFieldKey(keyText))) {
          return;
        }

        final text = _toNonEmptyString(value);
        if (text != null) {
          matched = text;
        }
      });

      if (matched != null) {
        return matched;
      }
    } else if (current is List) {
      queue.addAll(current);
    }
  }

  return null;
}

String? _toNonEmptyString(Object? value) {
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (value is num) {
    return value.toString();
  }
  return null;
}

String _normalizeFieldKey(String key) {
  return key.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toLowerCase();
}

_FrameIdentity _extractIdentityFromFrameHtml(String html) {
  final matches = _frameProfileAnchorPattern.allMatches(html);
  for (final match in matches) {
    final name = match.group(1)?.trim();
    final id = match.group(2)?.trim();
    if (name != null && name.isNotEmpty && id != null && id.isNotEmpty) {
      return _FrameIdentity(userId: id, userName: name);
    }
  }
  return const _FrameIdentity(userId: null, userName: null);
}

const List<String> _identityFallbackEndpointIds = <String>[
  'user.personalInfo',
  'frame.stdHome',
  'academic.atnlcScreHakjukInfo',
  'studentRecord.tmpabssklGetHakjuk',
];

const List<String> _userIdFieldCandidates = <String>[
  'userId',
  'studentNo',
  'stdNo',
  'stdntNo',
  'hakbun',
  'hakbeon',
  'loginId',
  'memberId',
  'memberNo',
  'mberNo',
  'studentId',
  'stdId',
  'usrId',
];

const List<String> _userNameFieldCandidates = <String>[
  'kname',
  'userName',
  'userNm',
  'stdNm',
  'studentName',
  'memberName',
  'mberNm',
  'korName',
  'korNm',
  'name',
  'nm',
];

const String _frameIdentityFallbackPath = '/std/cmn/frame/Frame.do';

final RegExp _frameProfileAnchorPattern = RegExp(
  r'MyInfoStdPage\.do"[^>]*>\s*(?:<i[^>]*>.*?</i>\s*)?([^<(]+)\(([^)]+)\)',
  caseSensitive: false,
  dotAll: true,
);
