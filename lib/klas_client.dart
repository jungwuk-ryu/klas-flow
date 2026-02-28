import 'dart:convert';

import 'package:http/http.dart' as http;

import 'src/api/auth_api.dart';
import 'src/api/context_api.dart';
import 'src/api/frame_api.dart';
import 'src/api/readonly_api.dart';
import 'src/api/session_api.dart';
import 'src/auth/auth_flow.dart';
import 'src/auth/credentials_encryptor.dart';
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
  late final AuthFlow _authFlow;
  late final KlasReadOnlyApi api;
  Future<void>? _sessionRefreshInProgress;
  String? _lastLoginId;
  String? _lastLoginPassword;

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

    _authFlow = AuthFlow(
      authApi: AuthApi(_transport, _config.apiPaths, LoginParser()),
      frameApi: _frameApi,
      sessionApi: _sessionApi,
      encryptor: CredentialsEncryptor(),
    );

    api = KlasReadOnlyApi(
      postJsonDynamic: _postJsonDynamic,
      postJsonText: _postJsonText,
      postFormDynamic: _postFormDynamic,
      postFormText: _postFormText,
      getJsonObject: _getJsonObject,
      getText: _getText,
      getBinary: _getBinary,
    );
  }

  /// 현재 선택된 과목 컨텍스트다.
  CourseContext? get currentContext => _contextManager.currentContext;

  /// 저장된 컨텍스트 목록이다.
  List<CourseContext> get availableContexts =>
      _contextManager.availableContexts;

  /// 로그인 오케스트레이션을 실행한다.
  Future<void> login(String id, String password) async {
    await _loginAndInitialize(id: id, password: password);
    _lastLoginId = id;
    _lastLoginPassword = password;
  }

  /// 세션 정보를 조회한다.
  Future<SessionInfo> getSessionInfo() =>
      _withAutoSessionRenewal(() => _sessionApi.fetchSessionInfo());

  /// 학기/과목 컨텍스트 목록을 다시 불러온다.
  Future<List<CourseContext>> refreshContexts() async {
    return _withAutoSessionRenewal(() async {
      final contexts = await _contextApi.fetchCourseContexts();
      _contextManager.setAvailableContexts(contexts);
      return _contextManager.availableContexts;
    });
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
  Future<HtmlPage> initializeFrame() =>
      _withAutoSessionRenewal(() => _frameApi.initializeFrame());

  /// 파일을 다운로드한다.
  Future<FilePayload> downloadFile(
    String path, {
    Map<String, String>? query,
  }) async {
    return _withAutoSessionRenewal(() async {
      final response = await _transport.download(path, query: query);
      return response.body;
    });
  }

  /// 컨텍스트가 필요한 JSON API를 호출한다.
  Future<Map<String, dynamic>> postJsonWithContext(
    String path, {
    Map<String, String>? form,
  }) async {
    return _withAutoSessionRenewal(() async {
      final merged = _contextManager.mergeForm(form);
      final response = await _transport.postFormJson(path, form: merged);
      return response.body;
    });
  }

  /// 로컬 세션/컨텍스트를 초기화한다.
  void clearLocalState() {
    _transport.clearSession();
    _contextManager.clear();
    _lastLoginId = null;
    _lastLoginPassword = null;
  }

  /// 내부 리소스를 정리한다.
  void close() {
    _transport.close();
  }

  Future<void> _loginAndInitialize({
    required String id,
    required String password,
    CourseContext? preferredContext,
  }) async {
    await _authFlow.login(id: id, password: password);
    final contexts = await _contextApi.fetchCourseContexts();
    _contextManager.setAvailableContexts(contexts);

    if (preferredContext != null) {
      final matched = _findMatchingContext(
        preferredContext: preferredContext,
        contexts: contexts,
      );

      if (matched != null) {
        _contextManager.setCurrentContext(matched);
      } else {
        _contextManager.setCurrentByValues(
          selectYearhakgi: preferredContext.selectYearhakgi,
          selectSubj: preferredContext.selectSubj,
          selectChangeYn: preferredContext.selectChangeYn,
        );
      }
    }
  }

  CourseContext? _findMatchingContext({
    required CourseContext preferredContext,
    required List<CourseContext> contexts,
  }) {
    for (final context in contexts) {
      if (context.selectYearhakgi == preferredContext.selectYearhakgi &&
          context.selectSubj == preferredContext.selectSubj) {
        return context;
      }
    }
    return null;
  }

  Future<T> _withAutoSessionRenewal<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on SessionExpiredException {
      await _renewSessionIfPossible();
      return request();
    }
  }

  Future<void> _renewSessionIfPossible() async {
    final inProgress = _sessionRefreshInProgress;
    if (inProgress != null) {
      await inProgress;
      return;
    }

    final refresh = _renewSession();
    _sessionRefreshInProgress = refresh;

    try {
      await refresh;
    } finally {
      if (identical(_sessionRefreshInProgress, refresh)) {
        _sessionRefreshInProgress = null;
      }
    }
  }

  Future<void> _renewSession() async {
    final id = _lastLoginId;
    final password = _lastLoginPassword;

    if (id == null || password == null) {
      throw const SessionExpiredException(
        'Session expired and no cached credentials are available. '
        'Call login() again.',
      );
    }

    final preferredContext = _contextManager.currentContext;
    await _loginAndInitialize(
      id: id,
      password: password,
      preferredContext: preferredContext,
    );
  }

  Future<Object?> _postJsonDynamic(
    String path, {
    Map<String, dynamic>? payload,
    required bool includeContext,
  }) {
    return _withAutoSessionRenewal(() async {
      final merged = _mergePayload(payload, includeContext: includeContext);
      final response = await _transport.postJsonDynamic(path, json: merged);
      return response.body;
    });
  }

  Future<String> _postJsonText(
    String path, {
    Map<String, dynamic>? payload,
    required bool includeContext,
  }) {
    return _withAutoSessionRenewal(() async {
      final merged = _mergePayload(payload, includeContext: includeContext);
      final response = await _transport.postJsonText(path, json: merged);
      return response.body;
    });
  }

  Future<Object?> _postFormDynamic(
    String path, {
    Map<String, dynamic>? payload,
    required bool includeContext,
  }) {
    return _withAutoSessionRenewal(() async {
      final merged = _mergePayload(payload, includeContext: includeContext);
      final response = await _transport.postFormText(
        path,
        form: _toFormData(merged),
      );
      return _decodeJsonString(response.body);
    });
  }

  Future<String> _postFormText(
    String path, {
    Map<String, dynamic>? payload,
    required bool includeContext,
  }) {
    return _withAutoSessionRenewal(() async {
      final merged = _mergePayload(payload, includeContext: includeContext);
      final response = await _transport.postFormText(
        path,
        form: _toFormData(merged),
      );
      return response.body;
    });
  }

  Future<Map<String, dynamic>> _getJsonObject(
    String path, {
    Map<String, String>? query,
  }) {
    return _withAutoSessionRenewal(() async {
      final response = await _transport.getJson(path, query: query);
      return response.body;
    });
  }

  Future<String> _getText(String path, {Map<String, String>? query}) {
    return _withAutoSessionRenewal(() async {
      final response = await _transport.getText(path, query: query);
      return response.body;
    });
  }

  Future<FilePayload> _getBinary(String path, {Map<String, String>? query}) {
    return _withAutoSessionRenewal(() async {
      final response = await _transport.download(path, query: query);
      return response.body;
    });
  }

  Map<String, dynamic> _mergePayload(
    Map<String, dynamic>? payload, {
    required bool includeContext,
  }) {
    if (!includeContext) {
      return <String, dynamic>{if (payload != null) ...payload};
    }
    return _contextManager.mergeJson(payload);
  }

  Map<String, String> _toFormData(Map<String, dynamic> payload) {
    final form = <String, String>{};
    payload.forEach((key, value) {
      if (value == null) {
        return;
      }
      form[key] = value.toString();
    });
    return form;
  }

  Object? _decodeJsonString(String source) {
    try {
      return jsonDecode(source);
    } catch (error, stackTrace) {
      throw ParsingException(
        'Failed to parse JSON response from form request.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}
