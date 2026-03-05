import 'package:flutter/material.dart';
import 'package:klasflow/klasflow.dart';

/// 학기 시간표 전용 화면.
///
/// 요일 단위로 수업을 묶어서 표시해 한눈에 주간 수업 구성을 확인할 수 있다.
class KlasTimetablePage extends StatelessWidget {
  final KlasTimetable timetable;

  const KlasTimetablePage({super.key, required this.timetable});

  @override
  Widget build(BuildContext context) {
    final grouped = timetable.groupedByWeekday;
    return Scaffold(
      appBar: AppBar(title: const Text('학기 시간표')),
      body: grouped.isEmpty
          ? const Center(child: Text('조회된 시간표가 없습니다.'))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: grouped.entries
                  .map((group) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  group.key,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(width: 8),
                                Text('(${group.value.length})'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...group.value.map((entry) {
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.menu_book_outlined),
                                title: Text(
                                  entry.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  _join(<String?>[
                                        entry.professorName,
                                        entry.classroom,
                                      ]) ??
                                      '-',
                                ),
                                trailing: Text(
                                  _scheduleLabel(entry),
                                  textAlign: TextAlign.end,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
    );
  }
}

String _scheduleLabel(KlasTimetableEntry entry) {
  final start = entry.startTime;
  final end = entry.endTime;
  if (start != null && end != null) {
    return '$start\n~$end';
  }
  if (entry.periodText != null && entry.periodText!.trim().isNotEmpty) {
    return entry.periodText!;
  }
  return '-';
}

String? _join(List<String?> values) {
  final filtered = values
      .whereType<String>()
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
  if (filtered.isEmpty) {
    return null;
  }
  return filtered.join(' · ');
}
