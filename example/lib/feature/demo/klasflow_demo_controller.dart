import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:klasflow/klasflow.dart';

/// 데모 화면의 상태와 KLAS 호출 흐름을 관리한다.
///
/// 화면은 이 컨트롤러의 getter만 읽고, 비동기 동작은
/// `loginAndLoad`, `reloadTasks`, `changeCourse`로만 트리거한다.
class KlasflowDemoController extends ChangeNotifier {
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final Uri apiBaseUri;
  late final KlasClientConfig _clientConfig = KlasClientConfig(
    baseUri: apiBaseUri,
  );
  late final KlasClient _client = KlasClient(config: _clientConfig);

  bool _isLoading = false;
  String? _errorMessage;
  KlasUser? _user;
  KlasUserProfile? _profile;
  List<KlasCourse> _courses = const <KlasCourse>[];
  KlasCourse? _currentCourse;
  List<KlasTask> _tasks = const <KlasTask>[];
  bool _disposed = false;

  KlasflowDemoController({required this.apiBaseUri});

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  KlasUser? get user => _user;
  KlasUserProfile? get profile => _profile;
  List<KlasCourse> get courses => _courses;
  KlasCourse? get currentCourse => _currentCourse;
  List<KlasTask> get tasks => _tasks;

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

  /// 로그인 후 사용자/과목/과제 데이터를 한 번에 초기 로딩한다.
  Future<void> loginAndLoad() async {
    if (isLikelyBrowserCrossOriginLogin) {
      _errorMessage =
          'Web cross-origin login is blocked by browser cookie policy. '
          'Use Android/iOS/desktop, or a same-origin reverse proxy.';
      _notify();
      return;
    }

    final id = idController.text.trim();
    final password = passwordController.text;
    if (id.isEmpty || password.isEmpty) {
      _errorMessage = 'Enter both ID and password.';
      _notify();
      return;
    }

    // 새 로그인 요청 전 화면 상태를 초기화해 이전 사용자 데이터 잔존을 막는다.
    _setLoading(true);
    _errorMessage = null;
    _clearSessionViewState();
    _notify();

    try {
      final user = await _client.login(id, password);
      final profile = await user.profile(refresh: true);
      final courses = await user.courses(refresh: true);
      final current = await user.defaultCourse();
      final tasks = current == null
          ? const <KlasTask>[]
          : await current.listTasks(page: 0);

      _user = user;
      _profile = profile;
      _courses = List<KlasCourse>.unmodifiable(courses);
      _currentCourse = current;
      _tasks = List<KlasTask>.unmodifiable(tasks);
    } on KlasException catch (error) {
      _errorMessage = _friendlyError(error);
    } catch (_) {
      _errorMessage = 'Unexpected error occurred. Please try again.';
    } finally {
      _setLoading(false);
      _notify();
    }
  }

  /// 현재 선택된 과목의 과제 목록만 다시 불러온다.
  Future<void> reloadTasks() async {
    final course = _currentCourse;
    if (course == null) {
      return;
    }

    _setLoading(true);
    _errorMessage = null;
    _notify();

    try {
      final tasks = await course.listTasks(page: 0);
      _tasks = List<KlasTask>.unmodifiable(tasks);
    } on KlasException catch (error) {
      _errorMessage = _friendlyError(error);
    } catch (_) {
      _errorMessage = 'Failed to load tasks.';
    } finally {
      _setLoading(false);
      _notify();
    }
  }

  /// 과목 선택을 변경하고 선택한 과목 기준으로 과제를 다시 조회한다.
  Future<void> changeCourse(KlasCourse? course) async {
    if (course == null) {
      return;
    }

    _setLoading(true);
    _errorMessage = null;
    _notify();

    try {
      final tasks = await course.listTasks(page: 0);
      _currentCourse = course;
      _tasks = List<KlasTask>.unmodifiable(tasks);
    } on KlasException catch (error) {
      _errorMessage = _friendlyError(error);
    } catch (_) {
      _errorMessage = 'Failed to switch course.';
    } finally {
      _setLoading(false);
      _notify();
    }
  }

  /// 드롭다운에 표시할 강의 라벨을 만든다.
  String courseLabel(KlasCourse course) {
    final title = course.title ?? '(unknown course)';
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

  String _friendlyError(KlasException error) {
    if (error is InvalidCredentialsException) {
      return 'Invalid credentials. Check your ID and password.';
    }
    if (error is OtpRequiredException) {
      return 'OTP verification is required for this account.';
    }
    if (error is CaptchaRequiredException) {
      return 'Captcha verification is required for this account.';
    }
    if (error is SessionExpiredException) {
      return 'Session expired. Please sign in again.';
    }
    if (error is NetworkException) {
      return 'Network request failed. Check your connection.';
    }
    if (error is ServiceUnavailableException) {
      return 'KLAS service is unavailable. Try again later.';
    }
    return 'KLAS request failed: ${error.message}';
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

  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  void _clearSessionViewState() {
    _user = null;
    _profile = null;
    _courses = const <KlasCourse>[];
    _currentCourse = null;
    _tasks = const <KlasTask>[];
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
