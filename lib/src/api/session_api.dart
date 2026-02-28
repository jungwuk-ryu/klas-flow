import '../models/session_info.dart';
import '../transport/transport.dart';
import 'api_paths.dart';

/// 세션 조회 API를 담당한다.
final class SessionApi {
  final KlasTransport _transport;
  final ApiPaths _paths;

  SessionApi(this._transport, this._paths);

  /// 현재 세션 정보를 조회한다.
  Future<SessionInfo> fetchSessionInfo() async {
    final response = await _transport.getJson(_paths.sessionInfo);
    return SessionInfo.fromJson(response.body);
  }
}
