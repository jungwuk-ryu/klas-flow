import '../api/auth_api.dart';
import '../api/frame_api.dart';
import '../api/session_api.dart';
import '../exceptions/klas_exceptions.dart';
import 'credentials_encryptor.dart';

/// 다단계 로그인 오케스트레이션을 담당한다.
final class AuthFlow {
  final AuthApi _authApi;
  final FrameApi _frameApi;
  final SessionApi _sessionApi;
  final CredentialsEncryptor _encryptor;

  AuthFlow({
    required AuthApi authApi,
    required FrameApi frameApi,
    required SessionApi sessionApi,
    required CredentialsEncryptor encryptor,
  }) : _authApi = authApi,
       _frameApi = frameApi,
       _sessionApi = sessionApi,
       _encryptor = encryptor;

  /// 로그인 전체 과정을 수행한다.
  Future<void> login({required String id, required String password}) async {
    final security = await _authApi.fetchLoginSecurity();
    final encryptedLoginToken = _encryptor.encryptLoginToken(
      id: id,
      password: password,
      security: security,
    );

    await _authApi.invokeLoginCaptcha();

    final loginResult = await _authApi.confirmLogin(
      id: id,
      encryptedLoginToken: encryptedLoginToken,
    );

    if (loginResult.otpRequired) {
      throw OtpRequiredException(loginResult.message ?? 'OTP 인증이 필요하다.');
    }

    if (loginResult.captchaRequired) {
      throw CaptchaRequiredException(loginResult.message ?? '캡차 인증이 필요하다.');
    }

    if (!loginResult.success) {
      throw InvalidCredentialsException(
        loginResult.message ?? '아이디 또는 비밀번호가 올바르지 않다.',
      );
    }

    await _frameApi.initializeFrame();
    final session = await _sessionApi.fetchSessionInfo();

    if (!session.authenticated) {
      throw const SessionExpiredException('로그인 이후 세션 검증에 실패했다.');
    }
  }
}
