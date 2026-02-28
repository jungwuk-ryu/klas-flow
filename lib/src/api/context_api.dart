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
    final response = await _transport.postJsonDynamic(
      _paths.yearhakgiSubjectList,
      json: const <String, dynamic>{},
    );
    final body = response.body;

    final listCandidate = _findArrayCandidate(body);
    if (listCandidate == null) {
      throw const ParsingException(
        'Could not find a context list in the API response.',
      );
    }

    final contexts = _toCourseContexts(listCandidate);
    if (contexts.isEmpty) {
      throw const ParsingException(
        'Context list exists but no usable context was parsed.',
      );
    }
    return contexts;
  }

  List<Object?>? _findArrayCandidate(Object? body) {
    if (body is List) {
      return body;
    }
    if (body is Map<String, dynamic>) {
      final candidates = <Object?>[
        body['data'],
        body['list'],
        body['items'],
        body['result'],
      ];
      for (final candidate in candidates) {
        if (candidate is List) {
          return candidate;
        }
      }
    }
    if (body is Map) {
      return _findArrayCandidate(body.cast<String, dynamic>());
    }
    return null;
  }

  List<CourseContext> _toCourseContexts(List<Object?> source) {
    final contexts = <CourseContext>[];

    for (final item in source) {
      if (item is! Map && item is! Map<String, dynamic>) {
        continue;
      }

      final object = item is Map<String, dynamic>
          ? item
          : (item as Map).cast<String, dynamic>();

      if (object.containsKey('selectYearhakgi') || object.containsKey('subj')) {
        contexts.add(CourseContext.fromJson(object));
        continue;
      }

      final yearhakgiValue = object['value'];
      final subjListValue = object['subjList'];
      if (yearhakgiValue is! String || subjListValue is! List) {
        continue;
      }

      for (final subjEntry in subjListValue) {
        if (subjEntry is! Map && subjEntry is! Map<String, dynamic>) {
          continue;
        }
        final subj = subjEntry is Map<String, dynamic>
            ? subjEntry
            : (subjEntry as Map).cast<String, dynamic>();
        final selectSubj = subj['value'];
        if (selectSubj is! String || selectSubj.trim().isEmpty) {
          continue;
        }
        final subjectName = subj['label'];
        contexts.add(
          CourseContext(
            selectYearhakgi: yearhakgiValue,
            selectSubj: selectSubj,
            selectChangeYn: 'Y',
            isDefault: contexts.isEmpty,
            subjectName: subjectName is String ? subjectName : null,
            raw: <String, dynamic>{
              ...object,
              ...subj,
              'selectYearhakgi': yearhakgiValue,
              'selectSubj': selectSubj,
              'selectChangeYn': 'Y',
            },
          ),
        );
      }
    }

    return contexts;
  }
}
