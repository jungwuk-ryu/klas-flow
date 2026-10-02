import 'package:klasflow/klasflow.dart';
import 'package:test/test.dart';

void main() {
  test('compact month-table timestamps retain the full cross-month period', () {
    final item = KlasMonthlyScheduleTableItem.fromJson({
      'title': '[과제] 연습 문제',
      'started': '202609252000',
      'ended': '202610061459',
      'typeNm': '과제',
    });
    expect(item.startsAt, '2026-09-25T20:00:00.000');
    expect(item.endsAt, '2026-10-06T14:59:00.000');
    expect(item.dayOfMonth, '25');
    expect(item.weekday, '금');
  });

  test('date-only and second-precision records normalize to ISO 8601', () {
    final item = KlasMonthlyScheduleTableItem.fromJson({
      'started': '20280229',
      'ended': '20280301123456',
    });
    expect(item.startsAt, '2028-02-29T00:00:00.000');
    expect(item.endsAt, '2028-03-01T12:34:56.000');
  });

  test('ISO records preserve time and explicit offsets', () {
    final item = KlasMonthlyScheduleTableItem.fromJson({
      'startDate': '2026-10-02T14:30:00.123+09:00',
      'endDate': '2026-10-03',
    });
    expect(item.startsAt, '2026-10-02T05:30:00.123Z');
    expect(item.endsAt, '2026-10-03T00:00:00.000');
  });

  for (final invalid in [
    '202602290000',
    '202610320000',
    '202610022460',
    '2026-02-30',
    '2026-10-02T25:00:00',
    'not-a-date',
  ]) {
    test('invalid timestamp $invalid stays unknown without rollover', () {
      final item = KlasMonthlyScheduleTableItem.fromJson({
        'started': invalid,
        'ended': invalid,
      });
      expect(item.startsAt, isNull);
      expect(item.endsAt, isNull);
      expect(item.dayOfMonth, isNull);
    });
  }

  test('legacy day-only items retain their existing fields', () {
    final item = KlasMonthlyScheduleTableItem.fromJson({
      'dayNo': '20',
      'dayname': '2',
      'schdulTitle': '행사',
    });
    expect(item.dayOfMonth, '20');
    expect(item.weekday, '화');
    expect(item.displayTitle, '행사');
    expect(item.startsAt, isNull);
    expect(item.endsAt, isNull);
  });
}
