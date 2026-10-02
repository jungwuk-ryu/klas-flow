/// E-class에 게시된 강의실 녹화 영상입니다. 온라인 학습 진도와 별도로 복습합니다.
final class KlasEClassRecording {
  final String id;
  final String courseId;
  final String termId;
  final String? title;
  final DateTime? recordedAt;
  final Duration? duration;

  const KlasEClassRecording({
    required this.id,
    required this.courseId,
    required this.termId,
    this.title,
    this.recordedAt,
    this.duration,
  });

  String get displayTitle => title ?? '(제목 없음)';
}
