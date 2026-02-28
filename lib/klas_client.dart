import 'dart:async';

import 'package:http/http.dart' as http;

import 'src/api/auth_api.dart';
import 'src/api/context_api.dart';
import 'src/api/frame_api.dart';
import 'src/api/readonly_api.dart';
import 'src/api/request_executor.dart';
import 'src/api/session_api.dart';
import 'src/api/typed_endpoints.dart';
import 'src/auth/auth_flow.dart';
import 'src/auth/credentials_encryptor.dart';
import 'src/auth/session_coordinator.dart';
import 'src/context/context_manager.dart';
import 'src/exceptions/klas_exceptions.dart';
import 'src/models/course_context.dart';
import 'src/models/file_payload.dart';
import 'src/models/html_page.dart';
import 'src/models/klas_bootstrap_result.dart';
import 'src/models/klas_client_config.dart';
import 'src/models/klas_health_report.dart';
import 'src/models/session_info.dart';
import 'src/parsers/html_parser.dart';
import 'src/parsers/login_parser.dart';
import 'src/transport/transport.dart';

/// KLAS를 위한 고수준 Dart 클라이언트입니다.
final class KlasClient {
  final KlasClientConfig _config;
  final ContextManager _contextManager = ContextManager();

  late final KlasTransport _transport;
  late final SessionApi _sessionApi;
  late final ContextApi _contextApi;
  late final FrameApi _frameApi;
  late final SessionCoordinator _sessionCoordinator;
  late final RequestExecutor _requestExecutor;
  Timer? _sessionHeartbeatTimer;
  bool _sessionHeartbeatInFlight = false;
  void Function(Object error, StackTrace stackTrace)?
  _sessionHeartbeatErrorHandler;

  /// 명세 기반 읽기 전용 API 진입점입니다.
  late final KlasReadOnlyApi api;

  /// 그룹별 자동완성 API 진입점입니다.
  late final KlasTypedEndpoints endpoints;

  /// 클라이언트를 생성합니다.
  KlasClient({KlasClientConfig? config, http.Client? httpClient})
    : _config = config ?? KlasClientConfig() {
    final sharedHttpClient = httpClient ?? http.Client();

    _transport = KlasTransport(
      baseUri: _config.baseUri,
      timeout: _config.timeout,
      httpClient: sharedHttpClient,
      ownsHttpClient: httpClient == null,
    );

    _sessionApi = SessionApi(_transport, _config.apiPaths);
    _contextApi = ContextApi(_transport, _config.apiPaths);
    _frameApi = FrameApi(_transport, _config.apiPaths, HtmlPageParser());

    final authFlow = AuthFlow(
      authApi: AuthApi(_transport, _config.apiPaths, LoginParser()),
      frameApi: _frameApi,
      sessionApi: _sessionApi,
      encryptor: CredentialsEncryptor(),
    );

    _sessionCoordinator = SessionCoordinator(
      authFlow: authFlow,
      contextApi: _contextApi,
      contextManager: _contextManager,
      maxSessionRenewRetries: _config.maxSessionRenewRetries,
      cacheCredentialsForAutoRenewal: _config.cacheCredentialsForAutoRenewal,
    );

    _requestExecutor = RequestExecutor(
      transport: _transport,
      contextManager: _contextManager,
      sessionCoordinator: _sessionCoordinator,
    );

    api = KlasReadOnlyApi(
      postJsonDynamic: _requestExecutor.postJsonDynamic,
      postJsonText: _requestExecutor.postJsonText,
      postFormDynamic: _requestExecutor.postFormDynamic,
      postFormText: _requestExecutor.postFormText,
      getJsonObject: _requestExecutor.getJsonObject,
      getText: _requestExecutor.getText,
      getBinary: _requestExecutor.getBinary,
    );

    endpoints = KlasTypedEndpoints(api);
  }

  /// 현재 선택된 과목 컨텍스트입니다.
  CourseContext? get currentContext => _contextManager.currentContext;

  /// 저장된 컨텍스트 목록입니다.
  List<CourseContext> get availableContexts =>
      _contextManager.availableContexts;

  /// 세션 하트비트 타이머가 동작 중인지 여부입니다.
  bool get isSessionHeartbeatRunning => _sessionHeartbeatTimer != null;

  /// 로그인 오케스트레이션을 실행합니다.
  Future<void> login(String id, String password) {
    return _sessionCoordinator.login(id, password);
  }

  /// 로그인 후 앱 초기화에 필요한 상태를 한 번에 반환합니다.
  Future<KlasBootstrapResult> loginAndBootstrap(
    String id,
    String password,
  ) async {
    await login(id, password);
    final session = await getSessionInfo();
    return KlasBootstrapResult(
      session: session,
      contexts: availableContexts,
      currentContext: currentContext,
    );
  }

  /// 세션 정보를 조회합니다.
  Future<SessionInfo> getSessionInfo() {
    return _sessionCoordinator.withAutoRenewal(
      () => _sessionApi.fetchSessionInfo(),
    );
  }

  /// 서버 세션을 연장하기 위해 UpdateSession API를 호출합니다.
  Future<Map<String, dynamic>> updateSession() {
    return api.callObject('loginSession.updateSession', includeContext: false);
  }

  /// 주기적으로 UpdateSession API를 호출해 세션을 유지합니다.
  void startSessionHeartbeat({
    Duration interval = const Duration(minutes: 5),
    bool immediate = true,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    stopSessionHeartbeat();

    if (interval <= Duration.zero) {
      throw ArgumentError('Heartbeat interval must be greater than zero.');
    }

    _sessionHeartbeatErrorHandler = onError;
    _sessionHeartbeatTimer = Timer.periodic(interval, (_) {
      unawaited(_runHeartbeatTick());
    });

    if (immediate) {
      unawaited(_runHeartbeatTick());
    }
  }

  /// 세션 유지 타이머를 중지합니다.
  void stopSessionHeartbeat() {
    _sessionHeartbeatTimer?.cancel();
    _sessionHeartbeatTimer = null;
    _sessionHeartbeatErrorHandler = null;
  }

  /// 학기/과목 컨텍스트 목록을 다시 불러옵니다.
  Future<List<CourseContext>> refreshContexts() {
    return _sessionCoordinator.refreshContexts();
  }

  /// 현재 과목 컨텍스트를 수동 지정합니다.
  void setContext({
    required String selectYearhakgi,
    required String selectSubj,
    String selectChangeYn = 'Y',
  }) {
    _contextManager.setCurrentByValues(
      selectYearhakgi: selectYearhakgi,
      selectSubj: selectSubj,
      selectChangeYn: selectChangeYn,
    );
  }

  /// 프레임 초기화 페이지를 조회합니다.
  Future<HtmlPage> initializeFrame() {
    return _sessionCoordinator.withAutoRenewal(
      () => _frameApi.initializeFrame(),
    );
  }

  /// 파일을 다운로드합니다.
  Future<FilePayload> downloadFile(String path, {Map<String, String>? query}) {
    return _requestExecutor.getBinary(path, query: query);
  }

  /// 컨텍스트가 필요한 JSON API를 호출합니다.
  Future<Map<String, dynamic>> postJsonWithContext(
    String path, {
    Map<String, String>? form,
  }) async {
    final result = await _requestExecutor.postFormDynamic(
      path,
      payload: form == null
          ? null
          : <String, dynamic>{
              for (final entry in form.entries) entry.key: entry.value,
            },
      includeContext: true,
    );

    if (result is Map<String, dynamic>) {
      return result;
    }
    if (result is Map) {
      return result.cast<String, dynamic>();
    }

    throw ParsingException(
      'Expected JSON object from $path, got ${result.runtimeType}.',
    );
  }

  /// 로컬 세션/컨텍스트를 초기화합니다.
  void clearLocalState() {
    _transport.clearSession();
    _contextManager.clear();
    _sessionCoordinator.clearCachedCredentials();
  }

  /// 주요 API 호환성과 세션 상태를 점검합니다.
  ///
  /// 운영 환경에서는 앱 시작 또는 문제 신고 시 진단용으로 사용할 수 있습니다.
  Future<KlasHealthReport> runHealthCheck({
    bool includeCourseEndpoints = true,
    int taskPage = 0,
  }) async {
    final items = <KlasHealthCheckItem>[];

    Future<void> probe(String id, Future<String> Function() run) async {
      final stopwatch = Stopwatch()..start();
      try {
        final detail = await run();
        stopwatch.stop();
        items.add(
          KlasHealthCheckItem(
            id: id,
            success: true,
            elapsed: stopwatch.elapsed,
            detail: detail,
          ),
        );
      } catch (error) {
        stopwatch.stop();
        items.add(
          KlasHealthCheckItem(
            id: id,
            success: false,
            elapsed: stopwatch.elapsed,
            detail: '$error',
          ),
        );
      }
    }

    await probe('session.info', () async {
      final session = await getSessionInfo();
      return 'authenticated=${session.authenticated}';
    });

    await probe('context.refresh', () async {
      final contexts = await refreshContexts();
      return 'count=${contexts.length}';
    });

    await probe('session.update', () async {
      final result = await updateSession();
      return 'keys=${result.keys.length}';
    });

    if (includeCourseEndpoints && currentContext != null) {
      await probe('learning.taskStdList', () async {
        final tasks = await endpoints.learning.taskStdList(
          payload: {'currentPage': taskPage},
        );
        return 'items=${tasks.length}';
      });
    }

    return KlasHealthReport(checkedAt: DateTime.now(), items: items);
  }

  /// 내부 리소스를 정리합니다.
  void close() {
    stopSessionHeartbeat();
    _transport.close();
  }

  Future<void> _runHeartbeatTick() async {
    if (_sessionHeartbeatInFlight) {
      return;
    }
    _sessionHeartbeatInFlight = true;
    try {
      await updateSession();
    } catch (error, stackTrace) {
      _sessionHeartbeatErrorHandler?.call(error, stackTrace);
    } finally {
      _sessionHeartbeatInFlight = false;
    }
  }
}
