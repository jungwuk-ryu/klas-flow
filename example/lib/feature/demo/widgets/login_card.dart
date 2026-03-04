import 'package:flutter/material.dart';

/// 로그인 입력과 로그인 버튼만 담당하는 프리젠테이션 위젯이다.
class LoginCard extends StatelessWidget {
  final TextEditingController idController;
  final TextEditingController passwordController;
  final bool isLoading;
  final bool isLoginDisabled;
  final Future<void> Function() onLoginPressed;

  const LoginCard({
    super.key,
    required this.idController,
    required this.passwordController,
    required this.isLoading,
    required this.isLoginDisabled,
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
            Text('Login', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: idController,
              enabled: !isLoading,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Student ID',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              enabled: !isLoading,
              obscureText: true,
              onSubmitted: (_) {
                if (!isLoading && !isLoginDisabled) {
                  onLoginPressed();
                }
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Password',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: (isLoading || isLoginDisabled) ? null : onLoginPressed,
              child: const Text('Sign in and load data'),
            ),
          ],
        ),
      ),
    );
  }
}
