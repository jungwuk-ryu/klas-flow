import 'package:flutter/material.dart';
import 'package:klasflow/klasflow.dart';

/// 로그인된 사용자 프로필 요약을 렌더링한다.
class ProfileCard extends StatelessWidget {
  final KlasUserProfile? profile;

  const ProfileCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final value = profile;
    if (value == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Profile', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Authenticated: ${value.authenticated}'),
            Text('User ID: ${value.userId ?? '(unknown)'}'),
            Text('User Name: ${value.userName ?? '(unknown)'}'),
          ],
        ),
      ),
    );
  }
}
