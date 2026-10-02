import 'dart:async';

import '../exceptions/klas_exceptions.dart';

/// QR 출석에 사용할 추가 인증 방식입니다.
enum KlasQrVerificationMethod { email, otp }

/// 사용자가 입력한 인증 코드입니다. 앞자리의 0을 보존하도록 문자열로 받습니다.
final class KlasQrVerificationAnswer {
  final KlasQrVerificationMethod method;
  final String code;

  const KlasQrVerificationAnswer({required this.method, required this.code});
}

/// QR 출석 인증 입력을 요청합니다. 이메일 발송은 명시적으로 요청해야 합니다.
final class KlasQrVerificationChallenge {
  final int attempt;
  final int maxAttempts;
  final bool otpAvailable;
  final bool previousAttemptRejected;
  final Future<void> Function() _sendEmailCode;
  final bool Function() _isActive;
  Future<void>? _emailRequest;

  KlasQrVerificationChallenge({
    required this.attempt,
    required this.maxAttempts,
    required this.otpAvailable,
    required this.previousAttemptRejected,
    required Future<void> Function() sendEmailCode,
    required bool Function() isActive,
  }) : _sendEmailCode = sendEmailCode,
       _isActive = isActive;

  /// 등록된 이메일로 코드를 한 번 발송합니다. 같은 challenge의 중복 요청은 합칩니다.
  Future<void> requestEmailCode() {
    if (!_isActive()) {
      throw const QrAttendanceVerificationException(
        'This QR verification challenge is no longer active.',
      );
    }
    return _emailRequest ??= _sendEmailCode();
  }
}

/// 추가 인증 코드를 입력합니다. null을 반환하면 출석 절차를 취소합니다.
typedef KlasQrVerificationHandler =
    FutureOr<KlasQrVerificationAnswer?> Function(
      KlasQrVerificationChallenge challenge,
    );
