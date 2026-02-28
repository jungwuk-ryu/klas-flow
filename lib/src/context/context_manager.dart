import 'dart:collection';

import '../models/course_context.dart';

/// 과목 컨텍스트를 저장하고 요청 폼에 자동 주입한다.
final class ContextManager {
  final List<CourseContext> _availableContexts = <CourseContext>[];
  CourseContext? _currentContext;

  /// 사용 가능한 컨텍스트 목록이다.
  List<CourseContext> get availableContexts =>
      UnmodifiableListView<CourseContext>(_availableContexts);

  /// 현재 선택된 컨텍스트다.
  CourseContext? get currentContext => _currentContext;

  /// 목록을 갱신하고 기본 컨텍스트를 선택한다.
  void setAvailableContexts(List<CourseContext> contexts) {
    _availableContexts
      ..clear()
      ..addAll(contexts);

    if (_availableContexts.isEmpty) {
      _currentContext = null;
      return;
    }

    _currentContext = _availableContexts.firstWhere(
      (context) => context.isDefault,
      orElse: () => _availableContexts.first,
    );
  }

  /// 수동으로 현재 컨텍스트를 지정한다.
  void setCurrentContext(CourseContext context) {
    _currentContext = context;
  }

  /// 학기/과목 코드로 현재 컨텍스트를 변경한다.
  void setCurrentByValues({
    required String selectYearhakgi,
    required String selectSubj,
    String selectChangeYn = 'Y',
  }) {
    _currentContext = CourseContext(
      selectYearhakgi: selectYearhakgi,
      selectSubj: selectSubj,
      selectChangeYn: selectChangeYn,
      isDefault: false,
    );
  }

  /// 요청 폼에 컨텍스트를 자동 병합한다.
  Map<String, String> mergeForm(Map<String, String>? input) {
    final merged = <String, String>{if (input != null) ...input};
    final current = _currentContext;
    if (current == null) {
      return merged;
    }

    merged.putIfAbsent('selectYearhakgi', () => current.selectYearhakgi);
    merged.putIfAbsent('selectSubj', () => current.selectSubj);
    merged.putIfAbsent('selectChangeYn', () => current.selectChangeYn);
    return merged;
  }

  /// 저장된 컨텍스트를 초기화한다.
  void clear() {
    _availableContexts.clear();
    _currentContext = null;
  }
}
