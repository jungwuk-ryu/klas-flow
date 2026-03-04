import 'package:flutter/material.dart';
import 'package:klasflow/klasflow.dart';

/// 과제 목록과 새로고침 버튼을 렌더링한다.
class TaskCard extends StatelessWidget {
  final List<KlasTask> tasks;
  final bool isLoading;
  final Future<void> Function() onReload;

  const TaskCard({
    super.key,
    required this.tasks,
    required this.isLoading,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('과제 목록', style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: isLoading ? null : onReload,
                  child: const Text('새로고침'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('조회된 항목 수: ${tasks.length}'),
            const SizedBox(height: 8),
            if (tasks.isEmpty)
              const Text('과제 데이터가 없습니다.')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final task = tasks[index];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(task.title ?? '(제목 없음)'),
                    subtitle: Text(
                      '번호:${task.taskNo ?? '-'}  '
                      '시작:${task.startDate ?? '-'}  '
                      '마감:${task.expireDate ?? '-'}',
                    ),
                    trailing: Text(task.submitted == true ? '제출완료' : '-'),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
