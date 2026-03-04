import 'package:flutter/material.dart';

import 'klasflow_demo_controller.dart';
import 'widgets/course_card.dart';
import 'widgets/login_card.dart';
import 'widgets/profile_card.dart';
import 'widgets/task_card.dart';

/// 컨트롤러 상태를 렌더링하는 데모 화면이다.
class KlasflowDemoPage extends StatefulWidget {
  const KlasflowDemoPage({super.key});

  @override
  State<KlasflowDemoPage> createState() => _KlasflowDemoPageState();
}

class _KlasflowDemoPageState extends State<KlasflowDemoPage> {
  late final KlasflowDemoController _controller;

  @override
  void initState() {
    super.initState();
    _controller = KlasflowDemoController(apiBaseUri: resolveBaseUri())
      ..addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }
    // 컨트롤러가 notify할 때 화면 전체를 재빌드한다.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('klasflow Flutter Demo')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            LoginCard(
              idController: _controller.idController,
              passwordController: _controller.passwordController,
              isLoading: _controller.isLoading,
              isLoginDisabled: _controller.isLikelyBrowserCrossOriginLogin,
              onLoginPressed: _controller.loginAndLoad,
            ),
            if (_controller.isLoading) ...<Widget>[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (_controller.errorMessage != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                _controller.errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (_controller.user != null) ...<Widget>[
              const SizedBox(height: 16),
              ProfileCard(profile: _controller.profile),
              const SizedBox(height: 12),
              CourseCard(
                courses: _controller.courses,
                currentCourse: _controller.currentCourse,
                isLoading: _controller.isLoading,
                courseLabel: _controller.courseLabel,
                onCourseChanged: _controller.changeCourse,
              ),
              const SizedBox(height: 12),
              TaskCard(
                tasks: _controller.tasks,
                isLoading: _controller.isLoading,
                onReload: _controller.reloadTasks,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
