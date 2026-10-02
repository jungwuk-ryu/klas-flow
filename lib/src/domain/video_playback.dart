import '../api/video_lecture_api.dart';
import '../exceptions/klas_exceptions.dart';
import '../models/video_lecture.dart';

Future<void> verifyVideoLecture(
  VideoLectureApi api,
  VideoLectureTarget target, {
  KlasVideoVerificationHandler? onVerification,
  required int maxAttempts,
  required void Function() assertSession,
}) async {
  if (target.lecture.progress.isComplete) return;
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    final status = await api.checkVerification(target);
    assertSession();
    if (status['status'] == true) return;
    if (status['status'] != false) {
      throw const ParsingException('Invalid video verification status.');
    }
    if (onVerification == null) {
      throw const VideoVerificationRequiredException(
        'Video lecture requires additional verification.',
      );
    }
    final challenge = _VideoVerificationChallenge(
      api,
      target,
      status,
      attempt,
      assertSession,
    );
    KlasVideoVerificationAnswer? answer;
    try {
      answer = await onVerification(challenge);
    } finally {
      challenge.active = false;
    }
    assertSession();
    final code = answer?.code.trim();
    if (answer == null || code == null || code.isEmpty) {
      throw const VideoVerificationException(
        'Video verification was cancelled.',
      );
    }
    if (!RegExp(r'^\d{1,32}$').hasMatch(code)) {
      throw ArgumentError.value(
        'invalid',
        'code',
        'Verification requires numeric digits.',
      );
    }
    if (answer.method == KlasVideoVerificationMethod.otp &&
        !challenge.otpAvailable) {
      throw const VideoVerificationException(
        'An existing OTP is not available.',
      );
    }
    final accepted = await api.verifyCode({
      ...target.verificationPayload,
      'certiGubun': answer.method == KlasVideoVerificationMethod.email
          ? 'eml'
          : 'otp',
      'inputKey': code,
    });
    assertSession();
    if (accepted) return;
  }
  throw const VideoVerificationException(
    'Video verification answer limit was reached.',
  );
}

final class _VideoVerificationChallenge
    implements KlasVideoVerificationChallenge {
  final VideoLectureApi api;
  final VideoLectureTarget target;
  final Map<String, dynamic> status;
  final void Function() assertSession;
  @override
  final int attempt;
  bool active = true;
  Future<void>? _emailRequest;

  _VideoVerificationChallenge(
    this.api,
    this.target,
    this.status,
    this.attempt,
    this.assertSession,
  );

  @override
  String get lectureTitle => target.lecture.displayTitle;
  @override
  bool get otpAvailable =>
      status['otpIssue'] == true || status['otpIssue'] == 'Y';
  @override
  String? get emailHint {
    final email = status['curEmail']?.toString();
    if (email == null || !email.contains('@')) return null;
    final parts = email.split('@');
    return '${parts.first.isEmpty ? '*' : parts.first[0]}***@${parts.last}';
  }

  @override
  Future<void> requestEmailCode() {
    if (!active) {
      throw StateError('Video verification challenge is no longer active.');
    }
    assertSession();
    return _emailRequest ??= api.sendEmail({
      ...target.verificationPayload,
      'certiGubun': 'eml',
      if (status['curEmail'] != null) 'curEmail': status['curEmail'],
      if (status['curMobile'] != null) 'curMobile': status['curMobile'],
    });
  }
}

/// 시청 이벤트를 실제 재생 구간으로 묶습니다. 서버 인정 시간을 직접 만들지 않습니다.
final class VideoPlaybackSession implements KlasVideoPlaybackSession {
  final VideoLectureApi _api;
  final VideoLectureTarget _target;
  final int Function() _sessionRevision;
  final Duration Function() _elapsed;
  final int _revision;
  int _generation;
  VideoPlaybackBootstrap _bootstrap;
  KlasVideoProgress _progress;
  bool _closed = false;
  bool _busy = false;
  Duration? _savedAt;
  Duration? _sampleAt;
  Duration? _position;

  @override
  final KlasVideoMedia media;

  VideoPlaybackSession({
    required VideoLectureApi api,
    required VideoLectureTarget target,
    required VideoPlaybackBootstrap bootstrap,
    required this.media,
    required int Function() sessionRevision,
    Duration Function()? elapsed,
  }) : _api = api,
       _target = target,
       _bootstrap = bootstrap,
       _progress = bootstrap.progress,
       _sessionRevision = sessionRevision,
       _revision = sessionRevision(),
       _generation = bootstrap.generation,
       _elapsed = elapsed ?? _monotonicClock();

  static Duration Function() _monotonicClock() {
    final watch = Stopwatch()..start();
    return () => watch.elapsed;
  }

  @override
  KlasVideoLecture get lecture => _target.lecture;
  @override
  KlasVideoProgress get progress => _progress;
  @override
  bool get isOpen =>
      !_closed &&
      _revision == _sessionRevision() &&
      _generation == _api.generation;
  @override
  bool get canRecordProgress => isOpen && _target.isWithinPeriod;

  @override
  Future<KlasVideoProgress> recordPlayback({
    required Duration position,
    required KlasVideoPlaybackState state,
  }) {
    if (position < Duration.zero ||
        position > media.duration + const Duration(seconds: 1)) {
      throw ArgumentError('Playback position must be inside the video.');
    }
    return _exclusive(() async {
      if (!_target.isWithinPeriod) return progress;
      final now = _elapsed();
      // 플레이어 이벤트가 끊긴 구간은 실제 재생으로 확인할 수 없습니다.
      if (_sampleAt != null && now - _sampleAt! > const Duration(seconds: 10)) {
        _savedAt = null;
        _sampleAt = null;
      }
      if (state != KlasVideoPlaybackState.playing) {
        await _stop();
        _position = position;
        return progress;
      }
      // 전달된 탐색 이벤트 외에 갑작스러운 위치 이동도 새 구간으로 처리합니다.
      if (_sampleAt != null && _position != null) {
        final delta = position - _position!;
        final elapsed = now - _sampleAt!;
        if (delta < Duration.zero ||
            delta.inMicroseconds > elapsed.inMicroseconds * 4 + 3000000 ||
            (delta == Duration.zero && elapsed > const Duration(seconds: 2))) {
          await _stop();
        }
      }
      if (_savedAt == null) {
        // 준비한 뒤 기다린 시간과 정지 시간을 새 재생 키에서 제외합니다.
        _bootstrap = await _api.prepare(_target, progress: _progress);
        _generation = _bootstrap.generation;
        _assertVersion();
        if (_bootstrap.embedUri != media.embedUri) {
          throw const VideoLectureUnavailableException(
            'Video source changed; reopen this lecture.',
          );
        }
        _progress = _bootstrap.progress;
        _savedAt = _elapsed();
      } else {
        await _saveIfDue();
      }
      _sampleAt = _elapsed();
      _position = position;
      return progress;
    });
  }

  @override
  Future<void> checkStatus() => _exclusive(() async {
    await _api.check(_bootstrap);
    _assertVersion();
  });

  @override
  Future<KlasVideoProgress> close() {
    if (_busy) {
      throw StateError('Await the current playback operation before closing.');
    }
    if (_closed) return Future.value(progress);
    return _exclusive(() async {
      try {
        await _stop();
        return progress;
      } finally {
        _closed = true;
      }
    });
  }

  Future<void> _stop() async {
    if (_sampleAt != null &&
        _elapsed() - _sampleAt! <= const Duration(seconds: 10)) {
      await _saveIfDue();
    }
    _savedAt = null;
    _sampleAt = null;
  }

  Future<void> _saveIfDue() async {
    final now = _elapsed();
    if (_savedAt == null || now - _savedAt! < const Duration(minutes: 1)) {
      return;
    }
    _savedAt = now;
    await _api.check(_bootstrap);
    _assertVersion();
    final response = await _api.save(_bootstrap);
    _assertVersion();
    validateVideoSessionResponse(response);
    final percent = videoPercent(response['prog']);
    final watched = videoMinutes(response['totalTime']);
    if (percent == null || watched == null) {
      throw const ParsingException('Video progress response is incomplete.');
    }
    _progress = KlasVideoProgress(
      percent: percent,
      watchedDuration: watched,
      requiredDuration: _progress.requiredDuration,
    );
  }

  Future<T> _exclusive<T>(Future<T> Function() action) async {
    if (_busy) throw StateError('Await playback operations sequentially.');
    if (_closed) throw StateError('Video playback session is closed.');
    _assertVersion();
    _busy = true;
    try {
      return await action();
    } catch (_) {
      // 서버가 저장했는지 불확실한 요청을 같은 키로 재전송하지 않습니다.
      _closed = true;
      rethrow;
    } finally {
      _busy = false;
    }
  }

  void _assertVersion() {
    if (_revision != _sessionRevision()) {
      _closed = true;
      throw const SessionExpiredException(
        'Login changed; reopen the video lecture.',
      );
    }
    if (_generation != _api.generation) {
      _closed = true;
      throw const VideoPlaybackInterruptedException(
        'Another video session replaced this player.',
      );
    }
  }
}
