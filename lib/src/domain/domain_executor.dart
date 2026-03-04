import '../api/frame_api.dart';
import '../api/readonly_api.dart';
import '../api/request_executor.dart';
import '../api/session_api.dart';
import '../auth/session_coordinator.dart';
import '../context/context_manager.dart';
import '../models/course_context.dart';
import '../models/file_payload.dart';
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
}
