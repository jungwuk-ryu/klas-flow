import 'package:html/dom.dart';

/// HTML 응답 파싱 결과 모델이다.
final class HtmlPage {
  /// 원본 HTML 문자열이다.
  final String source;

  /// 파싱된 DOM 문서다.
  final Document document;

  /// 페이지 제목이다.
  final String? title;

  const HtmlPage({required this.source, required this.document, this.title});
}
