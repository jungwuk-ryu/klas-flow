import '../models/html_page.dart';
import '../parsers/html_parser.dart';
import '../transport/transport.dart';
import 'api_paths.dart';

/// 프레임 초기화 API를 담당한다.
final class FrameApi {
  final KlasTransport _transport;
  final ApiPaths _paths;
  final HtmlPageParser _htmlParser;

  FrameApi(this._transport, this._paths, this._htmlParser);

  /// 로그인 이후 프레임 초기화를 수행한다.
  Future<HtmlPage> initializeFrame() async {
    final response = await _transport.getText(_paths.frameInitialize);
    return _htmlParser.parse(response.body);
  }
}
