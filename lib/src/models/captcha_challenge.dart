import 'dart:async';

import 'file_payload.dart';

/// Requests a human answer for the current login captcha.
/// Return digits as a string to preserve leading zeros, or null to cancel.
typedef KlasCaptchaHandler =
    FutureOr<String?> Function(KlasCaptchaChallenge challenge);

/// A captcha image and the number of the answer requested during this login.
final class KlasCaptchaChallenge {
  /// The current image. Display these bytes without fetching another challenge.
  final FilePayload image;

  /// The one-based number of the answer requested during this login.
  final int attempt;

  /// The maximum number of answers requested during this login.
  final int maxAttempts;

  const KlasCaptchaChallenge({
    required this.image,
    required this.attempt,
    required this.maxAttempts,
  });
}
