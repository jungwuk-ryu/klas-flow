/// klasflow에서 발생하는 모든 예외의 기본 타입입니다.
sealed class KlasException implements Exception {
  /// 예외를 설명하는 메시지입니다.
  final String message;

  /// 원본 예외 객체입니다.
  final Object? cause;

  /// 스택 트레이스입니다.
  final StackTrace? stackTrace;

  const KlasException(this.message, {this.cause, this.stackTrace});

  @override
  String toString() => '$runtimeType: $message';
}

/// 아이디/비밀번호가 올바르지 않을 때 발생합니다.
final class InvalidCredentialsException extends KlasException {
  const InvalidCredentialsException(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}

/// OTP 인증 단계가 필요한 경우 발생합니다.
final class OtpRequiredException extends KlasException {
  const OtpRequiredException(super.message, {super.cause, super.stackTrace});
}

/// 캡차 인증 단계가 필요한 경우 발생합니다.
final class CaptchaRequiredException extends KlasException {
  const CaptchaRequiredException(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}

/// 세션이 만료되어 인증이 필요할 때 발생합니다.
final class SessionExpiredException extends KlasException {
  const SessionExpiredException(super.message, {super.cause, super.stackTrace});
}

/// 서버가 점검 중이거나 비정상 응답을 반환할 때 발생합니다.
final class ServiceUnavailableException extends KlasException {
  const ServiceUnavailableException(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}

/// 네트워크 호출 자체가 실패했을 때 발생합니다.
final class NetworkException extends KlasException {
  const NetworkException(super.message, {super.cause, super.stackTrace});
}

/// 응답 파싱에 실패했을 때 발생합니다.
final class ParsingException extends KlasException {
  const ParsingException(super.message, {super.cause, super.stackTrace});
}

/// QR 출석을 지원하지 않거나 필요한 준비 데이터가 부족할 때 발생합니다.
final class QrAttendanceUnavailableException extends KlasException {
  const QrAttendanceUnavailableException(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}
