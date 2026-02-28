/// HTTP 응답 공통 래퍼다.
final class TransportResponse<T> {
  /// 상태 코드다.
  final int statusCode;

  /// 응답 헤더다.
  final Map<String, String> headers;

  /// 파싱된 본문이다.
  final T body;

  const TransportResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
  });
}
