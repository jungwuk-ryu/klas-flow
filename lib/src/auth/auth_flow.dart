import '../api/auth_api.dart';
import '../api/frame_api.dart';
import '../api/session_api.dart';
import '../exceptions/klas_exceptions.dart';
import '../models/login_result.dart';
import '../models/captcha_challenge.dart';
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
  Future<void> login({
    required String id,
    required String password,
    KlasCaptchaHandler? onCaptcha,
    int maxCaptchaAttempts = 3,
  }) async {
    if (maxCaptchaAttempts < 1) {
      throw RangeError.range(maxCaptchaAttempts, 1, null, 'maxCaptchaAttempts');
    }
    var answer = '';
    var attempts = 0;
    Future<String> requestAnswer() async {
      if (onCaptcha == null || attempts >= maxCaptchaAttempts) {
        throw const CaptchaRequiredException(
          'Captcha verification is required to continue login.',
        );
      }
      final image = await _authApi.fetchCaptchaImage();
      if (image.bytes.isEmpty) {
        throw const ParsingException('The captcha image was empty.');
      }
      attempts++;
      final value = (await onCaptcha(
        KlasCaptchaChallenge(
          image: image,
          attempt: attempts,
          maxAttempts: maxCaptchaAttempts,
        ),
      ))?.trim();
      if (value == null || value.isEmpty) {
        throw const CaptchaRequiredException('Captcha input was cancelled.');
      }
      if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
        throw const FormatException('Captcha answer must contain digits only.');
      }
      return value;
    }

    while (true) {
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
          captcha: answer,
        );
        if (captchaCount != null && captchaCount > 2 && answer.isEmpty) {
          answer = await requestAnswer();
          continue;
        }

        loginResult = await _authApi.confirmLogin(
          encryptedLoginToken: encryptedLoginToken,
          captcha: answer,
          redirectUrl: '',
          redirectTabUrl: '',
        );
      } else {
        final captchaCount = await _authApi.invokeLoginCaptcha(captcha: answer);
        if (captchaCount != null && captchaCount > 2 && answer.isEmpty) {
          answer = await requestAnswer();
          continue;
        }
        loginResult = await _authApi.confirmLogin(
          id: id,
          encryptedLoginToken: encryptedLoginToken,
          captcha: answer,
        );
      }

      if (loginResult.otpRequired) {
        throw OtpRequiredException(
          loginResult.message ?? 'OTP verification required.',
        );
      }

      if (loginResult.captchaRequired) {
        answer = await requestAnswer();
        continue;
      }

      if (!loginResult.success) {
        throw InvalidCredentialsException(
          loginResult.message ?? 'Invalid ID or password.',
        );
      }
      break;
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
