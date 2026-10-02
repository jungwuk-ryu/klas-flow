import 'high_level_models.dart';

/// 과목 선택과 추가 인증을 마친 QR 출석 준비입니다.
///
/// QR 문자열은 호출하는 프로그램이 직접 얻습니다. 인증 키는 노출하지 않으며,
/// 준비한 로그인 세션에서 한 번만 제출할 수 있습니다.
abstract interface class KlasQrCheckInSession {
  /// 제출하거나 취소하지 않았고 준비한 로그인 세션이 유지되는지 나타냅니다.
  bool get isPending;

  /// 디코딩된 QR 문자열을 그대로 제출하고 출석 처리 결과를 반환합니다.
  ///
  /// 빈 문자열은 ArgumentError를 발생시키며 준비를 소비하지 않습니다.
  /// 제출을 시작하면 성공, 거절, 네트워크 실패에 관계없이 다시 쓸 수 없습니다.
  /// 재사용하거나 취소 후 제출하면 StateError, 로그인 세션이 바뀌면
  /// SessionExpiredException이 발생합니다. 요청을 자동으로 재전송하지 않습니다.
  Future<KlasQrAttendanceResult> submit(String qrCode);

  /// 제출 전의 준비를 로컬에서 해제합니다. 여러 번 호출해도 됩니다.
  /// 이미 시작한 서버 요청은 중단하지 않습니다.
  void cancel();
}
