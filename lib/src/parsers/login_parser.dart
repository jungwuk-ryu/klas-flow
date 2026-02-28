import '../exceptions/klas_exceptions.dart';
import '../models/login_result.dart';
import '../models/login_security.dart';

/// 로그인 관련 JSON 응답을 모델로 변환합니다.
final class LoginParser {
  /// LoginSecurity 응답을 파싱합니다.
  LoginSecurity parseSecurity(Map<String, dynamic> json) {
    final normalized = _normalize(json);
    final publicKey = _optionalString(normalized, const [
      'publicKey',
      'rsaPublicKey',
      'publicKeyPem',
    ]);

    if (publicKey != null) {
      return LoginSecurity(publicKey: publicKey, raw: json);
    }

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

  /// LoginConfirm 응답을 파싱합니다.
  LoginResult parseLoginResult(Map<String, dynamic> json) {
    final normalized = _normalize(json);
    final responsePayload =
        _firstMap(json, const ['response', 'result']) ??
        const <String, dynamic>{};

    final merged = <String, dynamic>{...normalized, ...responsePayload};
    final message =
        _optionalString(merged, const [
          'message',
          'msg',
          'errorMessage',
          'resultMsg',
          'errorMsg',
        ]) ??
        _optionalString(json, const [
          'message',
          'msg',
          'errorMessage',
          'resultMsg',
          'errorMsg',
        ]);

    final errorCount = _intFromAny(
      _firstValue(json, const ['errorCount', 'errorCnt', 'error']),
    );

    final successToken =
        _firstValue(merged, const ['success', 'isSuccess', 'authenticated']) ??
        _firstValue(merged, const ['result', 'status', 'code']) ??
        _firstValue(json, const ['result', 'status', 'code']);

    final success = errorCount != null
        ? errorCount == 0
        : _boolFromAny(
            successToken,
            trueTokens: const {'ok', 'success', 's', '0', '200', 'y', 'true'},
            falseTokens: const {'fail', 'failed', 'error', '401', 'n', 'false'},
          );

    final otpRequired =
        _boolFromAny(
          _firstValue(merged, const [
            'otpRequired',
            'needOtp',
            'otpYn',
            'twoFactorAt',
            'twoFactorYn',
          ]),
          trueTokens: const {'y', 'true', '1'},
          falseTokens: const {'n', 'false', '0'},
        ) ||
        (message?.toLowerCase().contains('otp') ?? false);

    final captchaRequired =
        _boolFromAny(
          _firstValue(merged, const [
            'captchaRequired',
            'needCaptcha',
            'captchaYn',
            'captchaNeedYn',
          ]),
          trueTokens: const {'y', 'true', '1'},
          falseTokens: const {'n', 'false', '0'},
        ) ||
        ((message?.contains('캡차') ?? false) ||
            (message?.toLowerCase().contains('captcha') ?? false));

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

  Map<String, dynamic>? _firstMap(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = source[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
      if (value is Map) {
        return value.cast<String, dynamic>();
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

  int? _intFromAny(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }
}
