/// API 호출에 필요한 학기/과목 컨텍스트다.
final class CourseContext {
  /// API에서 요구하는 학기 코드다.
  final String selectYearhakgi;

  /// API에서 요구하는 과목 코드다.
  final String selectSubj;

  /// API에서 요구하는 변경 플래그다.
  final String selectChangeYn;

  /// 사용자에게 보여줄 과목명이다.
  final String? subjectName;

  /// 기본 선택 과목 여부다.
  final bool isDefault;

  /// 원본 응답 데이터다.
  final Map<String, dynamic> raw;

  const CourseContext({
    required this.selectYearhakgi,
    required this.selectSubj,
    required this.selectChangeYn,
    required this.isDefault,
    this.subjectName,
    this.raw = const {},
  });

  /// JSON 객체로부터 CourseContext를 생성한다.
  factory CourseContext.fromJson(Map<String, dynamic> json) {
    final selectYearhakgi = _stringValue(json, const [
      'selectYearhakgi',
      'yearhakgi',
      'yearHakgi',
    ]);
    final selectSubj = _stringValue(json, const [
      'selectSubj',
      'subj',
      'subjectId',
    ]);

    return CourseContext(
      selectYearhakgi: selectYearhakgi,
      selectSubj: selectSubj,
      selectChangeYn: _stringValue(json, const [
        'selectChangeYn',
        'changeYn',
      ], fallback: 'Y'),
      subjectName: _optionalString(json, const [
        'subjectName',
        'subjNm',
        'title',
      ]),
      isDefault: _boolValue(json, const ['isDefault', 'defaultYn', 'selected']),
      raw: json,
    );
  }

  /// 요청 폼 데이터로 변환한다.
  Map<String, String> toFormData() {
    return {
      'selectYearhakgi': selectYearhakgi,
      'selectSubj': selectSubj,
      'selectChangeYn': selectChangeYn,
    };
  }

  static String _stringValue(
    Map<String, dynamic> source,
    List<String> keys, {
    String? fallback,
  }) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
      if (value is num) {
        return value.toString();
      }
    }
    if (fallback != null) {
      return fallback;
    }
    throw StateError('Missing required string field: ${keys.join(', ')}');
  }

  static String? _optionalString(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static bool _boolValue(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is bool) {
        return value;
      }
      if (value is num) {
        return value != 0;
      }
      if (value is String) {
        final normalized = value.toLowerCase();
        if (normalized == 'y' || normalized == 'yes' || normalized == 'true') {
          return true;
        }
      }
    }
    return false;
  }
}
