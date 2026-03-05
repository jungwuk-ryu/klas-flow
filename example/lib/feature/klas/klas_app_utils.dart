import 'package:flutter/foundation.dart';
import 'package:klasflow/klasflow.dart';

/// `--dart-define=KLAS_BASE_URI=...`가 있으면 해당 서버를 사용한다.
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

/// Web 환경에서 cross-origin 쿠키 제약으로 로그인 실패가 예상되는지 검사한다.
bool isLikelyBrowserCrossOriginLogin(Uri apiBaseUri) {
  if (!kIsWeb) {
    return false;
  }
  final appOrigin = Uri.base;
  return appOrigin.scheme != apiBaseUri.scheme ||
      appOrigin.host != apiBaseUri.host ||
      _effectivePort(appOrigin) != _effectivePort(apiBaseUri);
}

String friendlyError(Object error) {
  if (error is InvalidCredentialsException) {
    return '로그인 정보가 올바르지 않습니다. 학번/비밀번호를 확인해 주세요.';
  }
  if (error is OtpRequiredException) {
    return 'OTP 인증이 필요한 계정입니다.';
  }
  if (error is CaptchaRequiredException) {
    return '캡차 입력이 필요한 계정입니다.';
  }
  if (error is SessionExpiredException) {
    return '세션이 만료되었습니다. 다시 로그인해 주세요.';
  }
  if (error is NetworkException) {
    return '네트워크 요청에 실패했습니다. 인터넷 연결을 확인해 주세요.';
  }
  if (error is ServiceUnavailableException) {
    return 'KLAS 서비스가 일시적으로 불안정합니다. 잠시 후 다시 시도해 주세요.';
  }
  if (error is KlasException) {
    return 'KLAS 요청 실패: ${error.message}';
  }
  return '예상하지 못한 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.';
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
