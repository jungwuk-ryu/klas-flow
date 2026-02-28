import 'dart:convert';

import '../parsers/login_parser.dart';
import '../transport/transport.dart';
import '../models/login_result.dart';
import '../models/login_security.dart';
import 'api_paths.dart';

/// 인증 관련 엔드포인트 호출을 담당한다.
final class AuthApi {
  final KlasTransport _transport;
  final ApiPaths _paths;
  final LoginParser _loginParser;

  AuthApi(this._transport, this._paths, this._loginParser);

  /// 공개키/로그인 토큰을 조회한다.
  Future<LoginSecurity> fetchLoginSecurity() async {
    final response = await _transport.postFormJson(_paths.loginSecurity);
    return _loginParser.parseSecurity(response.body);
  }

  /// 캡차 단계 초기화를 요청한다.
  Future<void> invokeLoginCaptcha() async {
    await _transport.postFormText(_paths.loginCaptcha);
  }

  /// 로그인 확인 요청을 수행한다.
  Future<LoginResult> confirmLogin({
    required String id,
    required String encryptedLoginToken,
  }) async {
    final response = await _transport.postFormText(
      _paths.loginConfirm,
      form: {'id': id, 'loginToken': encryptedLoginToken},
    );

    final maybeJson = _tryDecodeJson(response.body);
    if (maybeJson != null) {
      return _loginParser.parseLoginResult(maybeJson);
    }

    final html = response.body.toLowerCase();
    if (html.contains('otp')) {
      return const LoginResult(success: false, otpRequired: true);
    }
    if (html.contains('captcha') || html.contains('캡차')) {
      return const LoginResult(success: false, captchaRequired: true);
    }
    if (html.contains('login') && html.contains('fail')) {
      return const LoginResult(success: false, message: 'Login failed.');
    }

    return LoginResult(
      success: true,
      message: 'Login response was HTML; treated as success.',
      raw: const {},
    );
  }

  Map<String, dynamic>? _tryDecodeJson(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // JSON이 아닌 경우는 로그인 페이지 HTML일 수 있다.
    }
    return null;
  }
}
