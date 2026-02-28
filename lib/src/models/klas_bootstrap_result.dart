import 'course_context.dart';
import 'session_info.dart';

/// 로그인 직후 앱이 사용할 핵심 상태를 묶은 결과입니다.
final class KlasBootstrapResult {
  /// 로그인 이후 확인한 세션 정보입니다.
  final SessionInfo session;

  /// 사용 가능한 컨텍스트 목록입니다.
  final List<CourseContext> contexts;

  /// 현재 선택된 컨텍스트입니다.
  final CourseContext? currentContext;

  const KlasBootstrapResult({
    required this.session,
    required this.contexts,
    required this.currentContext,
  });
}
