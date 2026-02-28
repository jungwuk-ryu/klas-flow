import 'dart:convert';

import '../parsers/login_parser.dart';
import '../transport/transport.dart';
import '../models/login_result.dart';
import '../models/login_security.dart';
import 'api_paths.dart';

/// 인증 관련 엔드포인트 호출을 담당합니다.
final class AuthApi {
  final KlasTransport _transport;
  final ApiPaths _paths;
  final LoginParser _loginParser;

  AuthApi(this._transport, this._paths, this._loginParser);

  /// 공개키/로그인 토큰을 조회합니다.
  Future<LoginSecurity> fetchLoginSecurity() async {
    final response = await _transport.postFormJson(_paths.loginSecurity);
    return _loginParser.parseSecurity(response.body);
  }

  /// 캡차 단계 초기화를 요청합니다.
  Future<int?> invokeLoginCaptcha({
    String? encryptedLoginToken,
    String captcha = '',
  }) async {
    if (encryptedLoginToken == null) {
      final response = await _transport.postFormText(_paths.loginCaptcha);
      return _parseCaptchaCount(response.body);
    }

    final response = await _transport.postJsonDynamic(
      _paths.loginCaptcha,
      json: {'loginToken': encryptedLoginToken, 'captcha': captcha},
    );
    return _parseCaptchaCount(response.body);
  }

  /// 로그인 확인 요청을 수행합니다.
  Future<LoginResult> confirmLogin({
    String? id,
    required String encryptedLoginToken,
    String captcha = '',
    String redirectUrl = '',
    String redirectTabUrl = '',
  }) async {
    if (id == null) {
      final response = await _transport.postJsonDynamic(
        _paths.loginConfirm,
        json: {
          'loginToken': encryptedLoginToken,
          'captcha': captcha,
          'redirectUrl': redirectUrl,
          'redirectTabUrl': redirectTabUrl,
        },
      );

      if (response.body is Map<String, dynamic>) {
        return _loginParser.parseLoginResult(
          response.body as Map<String, dynamic>,
        );
      }
      if (response.body is Map) {
        return _loginParser.parseLoginResult(
          (response.body as Map).cast<String, dynamic>(),
        );
      }

      final scalar = response.body?.toString();
      return LoginResult(
        success: false,
        message: scalar == null
            ? 'Unexpected LoginConfirm response type.'
            : 'Unexpected LoginConfirm response: $scalar',
      );
    }

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

  int? _parseCaptchaCount(Object? body) {
    if (body == null) {
      return null;
    }

    if (body is num) {
      return body.toInt();
    }

    if (body is String) {
      return int.tryParse(body.trim());
    }

    if (body is Map<String, dynamic>) {
      return _parseCaptchaCountFromMap(body);
    }
    if (body is Map) {
      return _parseCaptchaCountFromMap(body.cast<String, dynamic>());
    }

    return null;
  }

  int? _parseCaptchaCountFromMap(Map<String, dynamic> payload) {
    final candidates = <Object?>[
      payload['count'],
      payload['errorCount'],
      payload['captchaCount'],
      payload['data'],
    ];

    for (final value in candidates) {
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  Map<String, dynamic>? _tryDecodeJson(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // JSON이 아닌 경우는 로그인 페이지 HTML일 수 있습니다.
    }
    return null;
  }
}
