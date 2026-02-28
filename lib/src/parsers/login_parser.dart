import '../exceptions/klas_exceptions.dart';
import '../models/login_result.dart';
import '../models/login_security.dart';

/// 로그인 관련 JSON 응답을 모델로 변환한다.
final class LoginParser {
  /// LoginSecurity 응답을 파싱한다.
  LoginSecurity parseSecurity(Map<String, dynamic> json) {
    final normalized = _normalize(json);

    try {
      return LoginSecurity(
        publicKeyModulus: _requiredString(normalized, const [
          'publicKeyModulus',
          'modulus',
          'rsaModulus',
          'RSAModulus',
        ]),
        publicKeyExponent: _requiredString(normalized, const [
          'publicKeyExponent',
          'exponent',
          'rsaExponent',
          'RSAExponent',
        ]),
        loginToken: _requiredString(normalized, const [
          'loginToken',
          'token',
          'nonce',
        ]),
        raw: json,
      );
    } on StateError catch (error, stackTrace) {
      throw ParsingException(
        error.message,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// LoginConfirm 응답을 파싱한다.
  LoginResult parseLoginResult(Map<String, dynamic> json) {
    final normalized = _normalize(json);

    final message = _optionalString(normalized, const [
      'message',
      'msg',
      'errorMessage',
      'resultMsg',
    ]);

    final success = _boolFromAny(
      _firstValue(normalized, const [
            'success',
            'isSuccess',
            'authenticated',
          ]) ??
          _firstValue(normalized, const ['result', 'status', 'code']),
      trueTokens: const {'ok', 'success', 's', '0', '200', 'y'},
      falseTokens: const {'fail', 'failed', 'error', '401', 'n'},
    );

    final otpRequired =
        _boolFromAny(
          _firstValue(normalized, const ['otpRequired', 'needOtp', 'otpYn']),
          trueTokens: const {'y', 'true', '1'},
          falseTokens: const {'n', 'false', '0'},
        ) ||
        (message?.toLowerCase().contains('otp') ?? false);

    final captchaRequired =
        _boolFromAny(
          _firstValue(normalized, const [
            'captchaRequired',
            'needCaptcha',
            'captchaYn',
          ]),
          trueTokens: const {'y', 'true', '1'},
          falseTokens: const {'n', 'false', '0'},
        ) ||
        (message?.contains('캡차') ?? false);

    return LoginResult(
      success: success,
      otpRequired: otpRequired,
      captchaRequired: captchaRequired,
      message: message,
      raw: json,
    );
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return json;
  }

  String _requiredString(Map<String, dynamic> source, List<String> keys) {
    final value = _optionalString(source, keys);
    if (value != null) {
      return value;
    }
    throw StateError('Missing required field: ${keys.join(', ')}');
  }

  String? _optionalString(Map<String, dynamic> source, List<String> keys) {
    final value = _firstValue(source, keys);
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  Object? _firstValue(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      if (source.containsKey(key)) {
        return source[key];
      }
    }
    return null;
  }

  bool _boolFromAny(
    Object? value, {
    required Set<String> trueTokens,
    required Set<String> falseTokens,
  }) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      if (trueTokens.contains(normalized)) {
        return true;
      }
      if (falseTokens.contains(normalized)) {
        return false;
      }
    }
    return false;
  }
}
