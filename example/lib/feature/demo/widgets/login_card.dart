import 'package:flutter/material.dart';

/// 로그인 입력과 로그인 버튼만 담당하는 프리젠테이션 위젯이다.
class LoginCard extends StatelessWidget {
  final TextEditingController idController;
  final TextEditingController passwordController;
  final bool isLoading;
  final bool isLoginDisabled;
  final Uri apiBaseUri;
  final Future<void> Function() onLoginPressed;

  const LoginCard({
    super.key,
    required this.idController,
    required this.passwordController,
    required this.isLoading,
    required this.isLoginDisabled,
    required this.apiBaseUri,
    required this.onLoginPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('로그인', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(
              '대상 서버: $apiBaseUri',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: idController,
              enabled: !isLoading,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '학번 / ID',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              enabled: !isLoading,
              obscureText: true,
              onSubmitted: (_) {
                // 엔터 입력 시에도 같은 로그인 로직을 사용한다.
                if (!isLoading && !isLoginDisabled) {
                  onLoginPressed();
                }
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '비밀번호',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: (isLoading || isLoginDisabled) ? null : onLoginPressed,
              child: const Text('로그인하고 기본 데이터 불러오기'),
            ),
            if (isLoginDisabled) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                '현재 Web origin과 KLAS origin이 달라 브라우저 쿠키 정책에 막힐 수 있습니다.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
