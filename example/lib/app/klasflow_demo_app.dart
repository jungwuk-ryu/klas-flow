import 'package:flutter/material.dart';

import '../feature/klas/klas_login_page.dart';

/// 데모 앱의 루트 MaterialApp을 구성한다.
class KlasflowDemoApp extends StatelessWidget {
  const KlasflowDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KLAS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2A5CAA),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const KlasLoginPage(),
    );
  }
}
