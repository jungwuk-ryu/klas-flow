import 'package:flutter/material.dart';

import '../feature/demo/klasflow_demo_page.dart';

/// 데모 앱의 루트 MaterialApp을 구성한다.
class KlasflowDemoApp extends StatelessWidget {
  const KlasflowDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'klasflow Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const KlasflowDemoPage(),
    );
  }
}
