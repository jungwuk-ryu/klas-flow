/// 단일 헬스체크 항목 결과입니다.
final class KlasHealthCheckItem {
  /// 체크 항목 식별자입니다.
  final String id;

  /// 성공 여부입니다.
  final bool success;

  /// 소요 시간입니다.
  final Duration elapsed;

  /// 추가 정보입니다.
  final String detail;

  const KlasHealthCheckItem({
    required this.id,
    required this.success,
    required this.elapsed,
    required this.detail,
  });
}

/// KLAS API 호환성/세션 상태 점검 결과입니다.
final class KlasHealthReport {
  /// 점검 시각입니다.
  final DateTime checkedAt;

  /// 점검 항목 결과입니다.
  final List<KlasHealthCheckItem> items;

  const KlasHealthReport({required this.checkedAt, required this.items});

  /// 전체 항목 성공 여부입니다.
  bool get allPassed => items.every((item) => item.success);

  /// 실패 항목 개수입니다.
  int get failedCount => items.where((item) => !item.success).length;
}
