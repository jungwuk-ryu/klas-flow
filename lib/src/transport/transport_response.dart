/// HTTP 응답 공통 래퍼입니다.
final class TransportResponse<T> {
  /// 상태 코드입니다.
  final int statusCode;

  /// 응답 헤더입니다.
  final Map<String, String> headers;

  /// 파싱된 본문입니다.
  final T body;

  const TransportResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
  });
}
