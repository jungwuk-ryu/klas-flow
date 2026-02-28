import '../exceptions/klas_exceptions.dart';
import '../models/course_context.dart';
import '../transport/transport.dart';
import 'api_paths.dart';

/// 학기/과목 컨텍스트 API를 담당합니다.
final class ContextApi {
  final KlasTransport _transport;
  final ApiPaths _paths;

  ContextApi(this._transport, this._paths);

  /// 사용 가능한 컨텍스트 목록을 조회합니다.
  Future<List<CourseContext>> fetchCourseContexts() async {
    final response = await _transport.getJson(_paths.yearhakgiSubjectList);
    final body = response.body;

    final candidates = <Object?>[];
    candidates.add(body['data']);
    candidates.add(body['list']);
    candidates.add(body['items']);
    candidates.add(body['result']);

    for (final candidate in candidates) {
      if (candidate is List) {
        final contexts = <CourseContext>[];
        for (final item in candidate) {
          if (item is Map<String, dynamic>) {
            contexts.add(CourseContext.fromJson(item));
          } else if (item is Map) {
            contexts.add(CourseContext.fromJson(item.cast<String, dynamic>()));
          }
        }
        return contexts;
      }
    }

    throw const ParsingException(
      'Could not find a context list in the API response.',
    );
  }
}
