import 'package:flutter/material.dart';
import 'package:klasflow/klasflow.dart';

import 'app_session.dart';
import 'klas_app_utils.dart';
import 'klas_home_page.dart';

/// 앱 진입점 로그인 화면.
///
/// "데모 실행 버튼" 대신 실제 서비스 로그인 UX에 가깝게
/// ID/비밀번호 입력 후 홈으로 진입하는 흐름만 제공한다.
class KlasLoginPage extends StatefulWidget {
  const KlasLoginPage({super.key});

  @override
  State<KlasLoginPage> createState() => _KlasLoginPageState();
}

class _KlasLoginPageState extends State<KlasLoginPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final Uri _apiBaseUri = resolveBaseUri();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    final id = _idController.text.trim();
    final password = _passwordController.text;
    if (id.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = '학번(또는 ID)과 비밀번호를 모두 입력해 주세요.';
      });
      return;
    }

    if (isLikelyBrowserCrossOriginLogin(_apiBaseUri)) {
      setState(() {
        _errorMessage =
            '현재 Web origin과 KLAS origin이 달라 브라우저 쿠키 정책에 막힐 수 있습니다.\n'
            '앱/데스크톱 실행 또는 same-origin 프록시를 사용해 주세요.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final client = KlasClient(config: KlasClientConfig(baseUri: _apiBaseUri));
    try {
      final user = await client.login(id, password);
      final profile = await user.profile(refresh: true);
      final personalInfo = await user.personalInfo(refresh: true);
      final courses = await user.courses(refresh: true);
      final session = KlasAppSession(
        client: client,
        user: user,
        profile: profile,
        personalInfo: personalInfo,
        courses: courses,
      );

      if (!mounted) {
        session.close();
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<KlasHomePage>(
          builder: (_) => KlasHomePage(session: session),
        ),
      );
    } catch (error) {
      client.close();
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = friendlyError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text('KLAS', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    const Text('klasflow로 만든 간단한 학생 포털'),
                    const SizedBox(height: 18),
                    Text(
                      '대상 서버: $_apiBaseUri',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _idController,
                      enabled: !_isLoading,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '학번 / ID',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      enabled: !_isLoading,
                      obscureText: true,
                      onSubmitted: (_) {
                        if (!_isLoading) {
                          _onLoginPressed();
                        }
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '비밀번호',
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: _isLoading ? null : _onLoginPressed,
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('로그인'),
                    ),
                    if (_errorMessage != null) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
