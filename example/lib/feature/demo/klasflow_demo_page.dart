import 'package:flutter/material.dart';

import 'klasflow_demo_controller.dart';
import 'widgets/action_results_card.dart';
import 'widgets/course_card.dart';
import 'widgets/feature_actions_card.dart';
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
      appBar: AppBar(title: const Text('klasflow 데모 앱')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _buildIntroCard(context),
            const SizedBox(height: 12),
            LoginCard(
              idController: _controller.idController,
              passwordController: _controller.passwordController,
              isLoading: _controller.isLoading,
              isLoginDisabled: _controller.isLikelyBrowserCrossOriginLogin,
              apiBaseUri: _controller.apiBaseUri,
              onLoginPressed: _controller.loginAndLoad,
            ),
            if (_controller.isLoading) ...<Widget>[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(_controller.activeOperation ?? '요청 처리 중...'),
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
              ProfileCard(
                profile: _controller.profile,
                personalInfo: _controller.personalInfo,
                sessionStatus: _controller.sessionStatus,
              ),
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
              const SizedBox(height: 12),
              FeatureActionsCard(
                title: '사용자 기능 점검',
                description: '로그인 사용자 단위 API를 실행합니다.',
                runningActionId: _controller.runningActionId,
                isLoading: _controller.isLoading,
                actions: <FeatureActionItem>[
                  FeatureActionItem(
                    id: 'user.profile',
                    title: '프로필 새로고침',
                    description: 'user.profile(refresh: true)',
                    enabled: true,
                    onPressed: _controller.refreshProfile,
                  ),
                  FeatureActionItem(
                    id: 'user.personalInfo',
                    title: '개인정보 상세 조회',
                    description: 'user.personalInfo(refresh: true)',
                    enabled: true,
                    onPressed: _controller.loadPersonalInfo,
                  ),
                  FeatureActionItem(
                    id: 'user.sessionStatus',
                    title: '세션 상태 조회',
                    description: 'user.sessionStatus()',
                    enabled: true,
                    onPressed: _controller.refreshSessionStatus,
                  ),
                  FeatureActionItem(
                    id: 'user.keepAlive',
                    title: '세션 연장',
                    description: 'user.keepAlive() + sessionStatus()',
                    enabled: true,
                    onPressed: _controller.keepAliveSession,
                  ),
                  FeatureActionItem(
                    id: 'user.frame.homeOverview',
                    title: '홈 개요 조회',
                    description: 'user.frame.homeOverview()',
                    enabled: true,
                    onPressed: _controller.loadFrameHomeOverview,
                  ),
                  FeatureActionItem(
                    id: 'user.frame.scheduleSummary',
                    title: '일정 요약 조회',
                    description: 'user.frame.scheduleSummary()',
                    enabled: true,
                    onPressed: _controller.loadFrameScheduleSummary,
                  ),
                  FeatureActionItem(
                    id: 'user.attendance.listSubjects',
                    title: '출석 과목 목록',
                    description: 'user.attendance.listSubjects()',
                    enabled: true,
                    onPressed: _controller.loadAttendanceSubjects,
                  ),
                  FeatureActionItem(
                    id: 'user.attendance.monthList',
                    title: '월간 일정 목록',
                    description: 'user.attendance.monthList()',
                    enabled: true,
                    onPressed: _controller.loadAttendanceMonthList,
                  ),
                  FeatureActionItem(
                    id: 'user.attendance.monthTable',
                    title: '월간 일정 테이블',
                    description: 'user.attendance.monthTable()',
                    enabled: true,
                    onPressed: _controller.loadAttendanceMonthTable,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FeatureActionsCard(
                title: '강의 기능 점검',
                description: '현재 선택한 과목 기준 API를 실행합니다.',
                runningActionId: _controller.runningActionId,
                isLoading: _controller.isLoading,
                actions: <FeatureActionItem>[
                  FeatureActionItem(
                    id: 'course.overview',
                    title: '강의 개요 조회',
                    description: 'course.overview()',
                    enabled: _controller.currentCourse != null,
                    onPressed: _controller.loadCourseOverview,
                  ),
                  FeatureActionItem(
                    id: 'course.scheduleText',
                    title: '강의 시간표 문자열',
                    description: 'course.scheduleText()',
                    enabled: _controller.currentCourse != null,
                    onPressed: _controller.loadCourseScheduleText,
                  ),
                  FeatureActionItem(
                    id: 'course.noticeBoard.listPosts',
                    title: '공지사항 게시판',
                    description: 'course.noticeBoard.listPosts(page: 0)',
                    enabled: _controller.currentCourse != null,
                    onPressed: _controller.loadNoticeBoardPosts,
                  ),
                  FeatureActionItem(
                    id: 'course.materialBoard.listPosts',
                    title: '강의자료실 게시판',
                    description: 'course.materialBoard.listPosts(page: 0)',
                    enabled: _controller.currentCourse != null,
                    onPressed: _controller.loadMaterialBoardPosts,
                  ),
                  FeatureActionItem(
                    id: 'course.learning.anytimeQuizzes',
                    title: '수시퀴즈 목록',
                    description: 'course.learning.listAnytimeQuizzes(page: 0)',
                    enabled: _controller.currentCourse != null,
                    onPressed: _controller.loadAnytimeQuizzes,
                  ),
                  FeatureActionItem(
                    id: 'course.learning.discussions',
                    title: '토론 목록',
                    description: 'course.learning.listDiscussions(page: 0)',
                    enabled: _controller.currentCourse != null,
                    onPressed: _controller.loadDiscussions,
                  ),
                  FeatureActionItem(
                    id: 'course.learning.onlineContents',
                    title: '온라인 콘텐츠 목록',
                    description: 'course.learning.onlineContents(page: 0)',
                    enabled: _controller.currentCourse != null,
                    onPressed: _controller.loadOnlineContents,
                  ),
                  FeatureActionItem(
                    id: 'course.learning.onlineTests',
                    title: '온라인 시험 목록',
                    description: 'course.learning.onlineTests(page: 0)',
                    enabled: _controller.currentCourse != null,
                    onPressed: _controller.loadOnlineTests,
                  ),
                  FeatureActionItem(
                    id: 'course.surveys.list',
                    title: '설문 목록',
                    description: 'course.surveys.list()',
                    enabled: _controller.currentCourse != null,
                    onPressed: _controller.loadSurveys,
                  ),
                  FeatureActionItem(
                    id: 'course.eclass.listItems',
                    title: 'e-Class 목록',
                    description: 'course.eclass.listItems(page: 0)',
                    enabled: _controller.currentCourse != null,
                    onPressed: _controller.loadEclassItems,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FeatureActionsCard(
                title: '클라이언트 진단',
                description: 'SDK 내부 상태와 주요 엔드포인트를 종합 점검합니다.',
                runningActionId: _controller.runningActionId,
                isLoading: _controller.isLoading,
                actions: <FeatureActionItem>[
                  FeatureActionItem(
                    id: 'client.healthCheck',
                    title: '헬스체크 실행',
                    description: 'client.runHealthCheck()',
                    enabled: true,
                    onPressed: _controller.runHealthCheck,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ActionResultsCard(results: _controller.actionResults),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('데모 안내', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              '이 화면은 klasflow의 고수준 API를 실제 흐름처럼 점검하기 위한 예제입니다.\n'
              '로그인 후 과목을 선택하고, 기능 점검 버튼을 눌러 각 API 결과를 확인하세요.\n'
              '모든 결과는 하단 "기능 실행 결과" 카드에 기록됩니다.',
            ),
            const SizedBox(height: 8),
            Text(
              '주의: 실계정 테스트 시 상태 변경 API는 호출하지 마세요. '
              '본 데모는 읽기 전용 흐름 위주로 구성되어 있습니다.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
