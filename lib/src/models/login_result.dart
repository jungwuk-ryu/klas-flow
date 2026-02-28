/// 로그인 결과 모델입니다.
final class LoginResult {
  /// 로그인 성공 여부입니다.
  final bool success;

  /// OTP 단계 필요 여부입니다.
  final bool otpRequired;

  /// 캡차 단계 필요 여부입니다.
  final bool captchaRequired;

  /// 서버 메시지입니다.
  final String? message;

  /// 원본 응답 데이터입니다.
  final Map<String, dynamic> raw;

  const LoginResult({
    required this.success,
    this.otpRequired = false,
    this.captchaRequired = false,
    this.message,
    this.raw = const {},
  });
}
