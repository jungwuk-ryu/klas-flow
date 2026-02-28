/// 로그인 암호화에 필요한 공개키 정보입니다.
final class LoginSecurity {
  /// PEM 형식 RSA 공개키입니다(신규 로그인 플로우).
  final String? publicKey;

  /// RSA 공개키 modulus입니다.
  final String? publicKeyModulus;

  /// RSA 공개키 exponent입니다.
  final String? publicKeyExponent;

  /// 서버가 발급한 로그인 토큰(구형 로그인 플로우)입니다.
  final String? loginToken;

  /// 원본 응답 데이터입니다.
  final Map<String, dynamic> raw;

  const LoginSecurity({
    this.publicKey,
    this.publicKeyModulus,
    this.publicKeyExponent,
    this.loginToken,
    required this.raw,
  });

  /// PEM 키 기반 신규 로그인 플로우인지 여부입니다.
  bool get usesPemPublicKey =>
      publicKey != null && publicKey!.trim().isNotEmpty;
}
