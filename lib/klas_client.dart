import 'package:http/http.dart' as http;

import 'src/api/auth_api.dart';
import 'src/api/context_api.dart';
import 'src/api/frame_api.dart';
import 'src/api/readonly_api.dart';
import 'src/api/request_executor.dart';
import 'src/api/session_api.dart';
import 'src/auth/auth_flow.dart';
import 'src/auth/credentials_encryptor.dart';
import 'src/auth/session_coordinator.dart';
import 'src/context/context_manager.dart';
import 'src/exceptions/klas_exceptions.dart';
import 'src/models/course_context.dart';
import 'src/models/file_payload.dart';
import 'src/models/html_page.dart';
import 'src/models/klas_client_config.dart';
import 'src/models/session_info.dart';
import 'src/parsers/html_parser.dart';
import 'src/parsers/login_parser.dart';
import 'src/transport/transport.dart';

/// KLAS를 위한 고수준 Dart 클라이언트다.
final class KlasClient {
  final KlasClientConfig _config;
  final ContextManager _contextManager = ContextManager();

  late final KlasTransport _transport;
  late final SessionApi _sessionApi;
  late final ContextApi _contextApi;
  late final FrameApi _frameApi;
  late final SessionCoordinator _sessionCoordinator;
  late final RequestExecutor _requestExecutor;

  /// 명세 기반 읽기 전용 API 진입점이다.
  late final KlasReadOnlyApi api;

  /// 클라이언트를 생성한다.
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
  }

  /// 현재 선택된 과목 컨텍스트다.
  CourseContext? get currentContext => _contextManager.currentContext;

  /// 저장된 컨텍스트 목록이다.
  List<CourseContext> get availableContexts =>
      _contextManager.availableContexts;

  /// 로그인 오케스트레이션을 실행한다.
  Future<void> login(String id, String password) {
    return _sessionCoordinator.login(id, password);
  }

  /// 세션 정보를 조회한다.
  Future<SessionInfo> getSessionInfo() {
    return _sessionCoordinator.withAutoRenewal(
      () => _sessionApi.fetchSessionInfo(),
    );
  }

  /// 학기/과목 컨텍스트 목록을 다시 불러온다.
  Future<List<CourseContext>> refreshContexts() {
    return _sessionCoordinator.refreshContexts();
  }

  /// 현재 과목 컨텍스트를 수동 지정한다.
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

  /// 프레임 초기화 페이지를 조회한다.
  Future<HtmlPage> initializeFrame() {
    return _sessionCoordinator.withAutoRenewal(
      () => _frameApi.initializeFrame(),
    );
  }

  /// 파일을 다운로드한다.
  Future<FilePayload> downloadFile(String path, {Map<String, String>? query}) {
    return _requestExecutor.getBinary(path, query: query);
  }

  /// 컨텍스트가 필요한 JSON API를 호출한다.
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

  /// 로컬 세션/컨텍스트를 초기화한다.
  void clearLocalState() {
    _transport.clearSession();
    _contextManager.clear();
    _sessionCoordinator.clearCachedCredentials();
  }

  /// 내부 리소스를 정리한다.
  void close() {
    _transport.close();
  }
}
