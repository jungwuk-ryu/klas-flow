import '../api/auth_api.dart';
import '../api/frame_api.dart';
import '../api/session_api.dart';
import '../exceptions/klas_exceptions.dart';
import '../models/login_result.dart';
import 'credentials_encryptor.dart';

/// 다단계 로그인 오케스트레이션을 담당합니다.
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

  /// 로그인 전체 과정을 수행합니다.
  Future<void> login({required String id, required String password}) async {
    final security = await _authApi.fetchLoginSecurity();
    final encryptedLoginToken = _encryptor.encryptLoginToken(
      id: id,
      password: password,
      security: security,
    );

    LoginResult loginResult;
    if (security.usesPemPublicKey) {
      final captchaCount = await _authApi.invokeLoginCaptcha(
        encryptedLoginToken: encryptedLoginToken,
        captcha: '',
      );
      if (captchaCount != null && captchaCount > 2) {
        throw const CaptchaRequiredException(
          'Captcha input is required after multiple failed attempts.',
        );
      }

      loginResult = await _authApi.confirmLogin(
        encryptedLoginToken: encryptedLoginToken,
        captcha: '',
        redirectUrl: '',
        redirectTabUrl: '',
      );
    } else {
      await _authApi.invokeLoginCaptcha();
      loginResult = await _authApi.confirmLogin(
        id: id,
        encryptedLoginToken: encryptedLoginToken,
      );
    }

    if (loginResult.otpRequired) {
      throw OtpRequiredException(
        loginResult.message ?? 'OTP verification required.',
      );
    }

    if (loginResult.captchaRequired) {
      throw CaptchaRequiredException(
        loginResult.message ?? 'Captcha verification required.',
      );
    }

    if (!loginResult.success) {
      throw InvalidCredentialsException(
        loginResult.message ?? 'Invalid ID or password.',
      );
    }

    await _frameApi.initializeFrame();
    final session = await _sessionApi.fetchSessionInfo();

    if (!session.authenticated) {
      throw const SessionExpiredException(
        'Session verification failed after login.',
      );
    }
  }
}
