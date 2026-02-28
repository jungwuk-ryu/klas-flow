import '../api/context_api.dart';
import '../auth/auth_flow.dart';
import '../context/context_manager.dart';
import '../exceptions/klas_exceptions.dart';
import '../models/course_context.dart';

/// 로그인, 컨텍스트 초기화, 세션 자동 연장 정책을 관리합니다.
final class SessionCoordinator {
  final AuthFlow _authFlow;
  final ContextApi _contextApi;
  final ContextManager _contextManager;
  final int _maxSessionRenewRetries;
  final bool _cacheCredentialsForAutoRenewal;

  Future<void>? _renewalInProgress;
  String? _cachedId;
  String? _cachedPassword;

  SessionCoordinator({
    required AuthFlow authFlow,
    required ContextApi contextApi,
    required ContextManager contextManager,
    required int maxSessionRenewRetries,
    required bool cacheCredentialsForAutoRenewal,
  }) : _authFlow = authFlow,
       _contextApi = contextApi,
       _contextManager = contextManager,
       _maxSessionRenewRetries = maxSessionRenewRetries,
       _cacheCredentialsForAutoRenewal = cacheCredentialsForAutoRenewal;

  /// 로그인 후 컨텍스트까지 초기화합니다.
  Future<void> login(String id, String password) async {
    await _loginAndInitialize(id: id, password: password);
    if (_cacheCredentialsForAutoRenewal) {
      _cachedId = id;
      _cachedPassword = password;
    } else {
      _cachedId = null;
      _cachedPassword = null;
    }
  }

  /// 컨텍스트 목록을 갱신합니다.
  Future<List<CourseContext>> refreshContexts() {
    return withAutoRenewal(() async {
      final contexts = await _contextApi.fetchCourseContexts();
      _contextManager.setAvailableContexts(contexts);
      return _contextManager.availableContexts;
    });
  }

  /// 세션 만료 시 자동 재로그인 후 지정된 횟수만큼 재시도합니다.
  Future<T> withAutoRenewal<T>(Future<T> Function() request) async {
    var retryCount = 0;
    while (true) {
      try {
        return await request();
      } on SessionExpiredException {
        if (retryCount >= _maxSessionRenewRetries) {
          rethrow;
        }
        retryCount++;
        await _renewSessionIfPossible();
      }
    }
  }

  /// 캐시된 로그인 정보를 삭제합니다.
  void clearCachedCredentials() {
    _cachedId = null;
    _cachedPassword = null;
  }

  Future<void> _renewSessionIfPossible() async {
    final inProgress = _renewalInProgress;
    if (inProgress != null) {
      await inProgress;
      return;
    }

    final renewal = _renewSession();
    _renewalInProgress = renewal;

    try {
      await renewal;
    } finally {
      if (identical(_renewalInProgress, renewal)) {
        _renewalInProgress = null;
      }
    }
  }

  Future<void> _renewSession() async {
    final id = _cachedId;
    final password = _cachedPassword;

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

  Future<void> _loginAndInitialize({
    required String id,
    required String password,
    CourseContext? preferredContext,
  }) async {
    await _authFlow.login(id: id, password: password);

    final contexts = await _contextApi.fetchCourseContexts();
    _contextManager.setAvailableContexts(contexts);

    if (preferredContext == null) {
      return;
    }

    final matched = _findMatchingContext(
      preferredContext: preferredContext,
      contexts: contexts,
    );

    if (matched != null) {
      _contextManager.setCurrentContext(matched);
      return;
    }

    _contextManager.setCurrentByValues(
      selectYearhakgi: preferredContext.selectYearhakgi,
      selectSubj: preferredContext.selectSubj,
      selectChangeYn: preferredContext.selectChangeYn,
    );
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
}
