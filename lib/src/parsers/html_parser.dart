import 'package:html/parser.dart' as html_parser;

import '../exceptions/klas_exceptions.dart';
import '../models/html_page.dart';

/// HTML 문자열을 DOM 모델로 파싱한다.
final class HtmlPageParser {
  /// HTML 응답을 HtmlPage로 변환한다.
  HtmlPage parse(String source) {
    try {
      final document = html_parser.parse(source);
      return HtmlPage(
        source: source,
        document: document,
        title: document.querySelector('title')?.text.trim(),
      );
    } catch (error, stackTrace) {
      throw ParsingException(
        'HTML 파싱에 실패했다.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}
