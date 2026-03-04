import 'package:flutter/material.dart';
import 'package:klasflow/klasflow.dart';

/// 로그인된 사용자 프로필 요약을 렌더링한다.
class ProfileCard extends StatelessWidget {
  final KlasUserProfile? profile;
  final KlasPersonalInfo? personalInfo;
  final KlasSessionStatus? sessionStatus;

  const ProfileCard({
    super.key,
    required this.profile,
    required this.personalInfo,
    required this.sessionStatus,
  });

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
            Text('사용자 정보', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('인증 상태: ${value.authenticated ? '로그인됨' : '미인증'}'),
            Text('User ID: ${value.userId ?? '(unknown)'}'),
            Text('User Name: ${value.userName ?? '(unknown)'}'),
            if (personalInfo != null) ...<Widget>[
              const Divider(height: 20),
              Text('학번(상세): ${personalInfo!.userId ?? '(unknown)'}'),
              Text('이름(상세): ${personalInfo!.userName ?? '(unknown)'}'),
              Text('이메일: ${personalInfo!.email ?? '(unknown)'}'),
              Text('휴대폰: ${personalInfo!.mobilePhone ?? '(unknown)'}'),
            ],
            if (sessionStatus != null) ...<Widget>[
              const Divider(height: 20),
              Text('세션 남은 시간(초): ${sessionStatus!.remainingTime ?? '-'}'),
              Text(
                '자동 로그아웃 카운트다운(초): '
                '${sessionStatus!.logoutCountDownSec ?? '-'}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
