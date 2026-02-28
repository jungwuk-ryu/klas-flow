/// 로그인 암호화에 필요한 공개키 정보입니다.
final class LoginSecurity {
  /// RSA 공개키 modulus입니다.
  final String publicKeyModulus;

  /// RSA 공개키 exponent입니다.
  final String publicKeyExponent;

  /// 서버가 발급한 로그인 토큰입니다.
  final String loginToken;

  /// 원본 응답 데이터입니다.
  final Map<String, dynamic> raw;

  const LoginSecurity({
    required this.publicKeyModulus,
    required this.publicKeyExponent,
    required this.loginToken,
    required this.raw,
  });
}
