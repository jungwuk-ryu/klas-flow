import 'package:flutter/material.dart';

import '../klasflow_demo_controller.dart';

/// 기능 실행 결과 로그를 카드 형태로 보여준다.
///
/// 결과 본문(payloadPreview)은 길 수 있으므로 ExpansionTile 내부에 넣어서
/// 필요할 때만 열어보도록 구성한다.
class ActionResultsCard extends StatelessWidget {
  final List<DemoActionResult> results;

  const ActionResultsCard({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('기능 실행 결과', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (results.isEmpty)
              const Text('아직 실행한 기능이 없습니다. 위의 기능 버튼을 눌러 결과를 확인해 보세요.')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: results.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final result = results[index];
                  return ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    leading: Icon(
                      result.success ? Icons.check_circle : Icons.error,
                      color: result.success
                          ? Colors.green.shade700
                          : Theme.of(context).colorScheme.error,
                    ),
                    title: Text(result.title),
                    subtitle: Text(
                      '${_formatTime(result.executedAt)} · '
                      '${result.elapsed.inMilliseconds}ms · '
                      '${result.success ? '성공' : '실패'}',
                    ),
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              result.summary,
                              style: TextStyle(
                                color: result.success
                                    ? null
                                    : Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (result.payloadPreview.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 8),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: SelectableText(
                                    result.payloadPreview,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}
