import 'package:flutter/material.dart';

/// 기능 버튼 하나를 표현하는 단순 모델이다.
///
/// 화면 코드에서 버튼 속성을 한 줄씩 넘기면 길어지기 때문에,
/// 제목/설명/핸들러를 묶어 전달한다.
class FeatureActionItem {
  final String id;
  final String title;
  final String description;
  final bool enabled;
  final Future<void> Function() onPressed;

  const FeatureActionItem({
    required this.id,
    required this.title,
    required this.description,
    required this.enabled,
    required this.onPressed,
  });
}

/// 같은 성격의 기능 버튼들을 카드 한 장으로 묶어 보여준다.
class FeatureActionsCard extends StatelessWidget {
  final String title;
  final String description;
  final String? runningActionId;
  final bool isLoading;
  final List<FeatureActionItem> actions;

  const FeatureActionsCard({
    super.key,
    required this.title,
    required this.description,
    required this.runningActionId,
    required this.isLoading,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(description, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            ...actions.map((action) {
              final isRunning = runningActionId == action.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            action.title,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            action.description,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonal(
                      onPressed: (!isLoading && action.enabled)
                          ? action.onPressed
                          : null,
                      child: isRunning
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('실행'),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
