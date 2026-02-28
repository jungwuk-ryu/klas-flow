import 'package:klasflow/src/context/context_manager.dart';
import 'package:klasflow/src/models/course_context.dart';
import 'package:test/test.dart';

void main() {
  group('ContextManager', () {
    test('기본 컨텍스트를 우선 선택한다', () {
      final manager = ContextManager();
      manager.setAvailableContexts([
        const CourseContext(
          selectYearhakgi: '20261',
          selectSubj: 'A',
          selectChangeYn: 'N',
          isDefault: false,
        ),
        const CourseContext(
          selectYearhakgi: '20261',
          selectSubj: 'B',
          selectChangeYn: 'Y',
          isDefault: true,
        ),
      ]);

      expect(manager.currentContext?.selectSubj, equals('B'));
    });

    test('mergeForm은 기존 값을 덮어쓰지 않는다', () {
      final manager = ContextManager();
      manager.setCurrentByValues(selectYearhakgi: '20261', selectSubj: 'A');

      final merged = manager.mergeForm({
        'selectSubj': 'override',
        'custom': 'value',
      });

      expect(merged['selectYearhakgi'], equals('20261'));
      expect(merged['selectSubj'], equals('override'));
      expect(merged['custom'], equals('value'));
    });

    test('clear 호출 시 상태를 비운다', () {
      final manager = ContextManager();
      manager.setAvailableContexts([
        const CourseContext(
          selectYearhakgi: '20261',
          selectSubj: 'A',
          selectChangeYn: 'N',
          isDefault: true,
        ),
      ]);

      manager.clear();

      expect(manager.availableContexts, isEmpty);
      expect(manager.currentContext, isNull);
    });
  });
}
