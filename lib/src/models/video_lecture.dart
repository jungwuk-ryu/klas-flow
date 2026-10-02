import 'dart:async';

/// 수강 과목에 등록된 온라인 동영상 강의입니다.
final class KlasVideoLecture {
  final String id;
  final String courseId;
  final String termId;
  final String? title;
  final String? unitTitle;
  final int? week;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final Duration? estimatedDuration;
  final bool isAvailable;
  final bool isWithinLearningPeriod;
  final KlasVideoProgress progress;

  const KlasVideoLecture({
    required this.id,
    required this.courseId,
    required this.termId,
    required this.isAvailable,
    required this.isWithinLearningPeriod,
    required this.progress,
    this.title,
    this.unitTitle,
    this.week,
    this.availableFrom,
    this.availableUntil,
    this.estimatedDuration,
  });

  String get displayTitle => title ?? '(제목 없음)';
}

/// KLAS가 반환한 학습 인정 진도입니다. 영상 재생 위치와는 다릅니다.
final class KlasVideoProgress {
  final double? percent;
  final Duration? watchedDuration;
  final Duration? requiredDuration;

  const KlasVideoProgress({
    this.percent,
    this.watchedDuration,
    this.requiredDuration,
  });

  /// 진도가 완료되어도 별도 학습 활동이나 출석 요건이 있을 수 있습니다.
  bool get isComplete => percent != null && percent! >= 100;
}

enum KlasVideoSourceFormat { mp4, hls }

/// 호출자의 영상 플레이어에 전달할 미디어입니다.
final class KlasVideoSource {
  final Uri uri;
  final KlasVideoSourceFormat format;

  const KlasVideoSource({required this.uri, required this.format});
}

/// 직접 재생 가능한 영상과 공식 임베드 플레이어 정보입니다.
final class KlasVideoMedia {
  /// 공식 임베드가 있는 영상의 주소입니다. 구형 E-class 녹화에는 없을 수 있습니다.
  final Uri? embedUri;
  final Duration duration;
  final List<KlasVideoSource> sources;

  KlasVideoMedia({
    this.embedUri,
    required this.duration,
    required List<KlasVideoSource> sources,
  }) : sources = List.unmodifiable(sources);
}

/// 호출자의 실제 플레이어 상태입니다.
enum KlasVideoPlaybackState { playing, paused, buffering, seeking, ended }

/// UI나 플레이어 구현에 의존하지 않는 동영상 재생 세션입니다.
abstract interface class KlasVideoPlaybackSession {
  KlasVideoLecture get lecture;
  KlasVideoMedia get media;
  KlasVideoProgress get progress;
  bool get isOpen;
  bool get canRecordProgress;

  /// 실제 플레이어의 위치와 상태를 전달합니다.
  ///
  /// 재생 중에는 1~5초마다, 상태가 바뀌면 즉시 호출합니다. 진행률은 서버
  /// 응답만 반영합니다. 일시정지/버퍼링/탐색 시간은 다음 재생 구간에서 제외합니다.
  /// 10초 이상 이벤트가 끊기면 해당 구간을 버리고 새로 시작합니다. 공식 저장
  /// 주기는 60초이며 그보다 짧은 미저장 구간은 인정되지 않을 수 있습니다.
  /// 동시에 호출할 수 없으며 오류가 불확실한 저장 요청은 자동 재전송하지 않습니다.
  Future<KlasVideoProgress> recordPlayback({
    required Duration position,
    required KlasVideoPlaybackState state,
  });

  /// 다른 재생 창이 이 세션을 대체했는지 확인합니다. 진도를 저장하지 않습니다.
  Future<void> checkStatus();

  /// 아직 저장하지 않은 재생 구간을 정리하고 로컬 세션을 종료합니다.
  /// 여러 번 호출해도 됩니다. 완료 진도를 강제로 설정하지 않습니다.
  Future<KlasVideoProgress> close();
}

enum KlasVideoVerificationMethod { email, otp }

/// 추가 인증 입력입니다. 기존에 등록된 OTP나 이메일 인증번호를 사용합니다.
final class KlasVideoVerificationAnswer {
  final KlasVideoVerificationMethod method;
  final String code;

  const KlasVideoVerificationAnswer({required this.method, required this.code});
}

abstract interface class KlasVideoVerificationChallenge {
  String get lectureTitle;
  int get attempt;
  bool get otpAvailable;
  String? get emailHint;

  /// 사용자가 이메일 인증을 선택한 경우에만 호출합니다.
  Future<void> requestEmailCode();
}

typedef KlasVideoVerificationHandler =
    FutureOr<KlasVideoVerificationAnswer?> Function(
      KlasVideoVerificationChallenge challenge,
    );
