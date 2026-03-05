import 'package:klasflow/klasflow.dart';

/// 로그인 이후 앱 화면들이 공유하는 세션 상태이다.
///
/// 실제 서비스 앱처럼 여러 화면에서 같은 사용자/과목 컨텍스트를 재사용하기 위해
/// `KlasClient`와 고수준 도메인 객체를 한 묶음으로 보관한다.
class KlasAppSession {
  final KlasClient client;
  final KlasUser user;
  KlasUserProfile profile;
  KlasPersonalInfo personalInfo;
  List<KlasCourse> courses;
  KlasTimetable? _cachedTimetable;

  KlasAppSession({
    required this.client,
    required this.user,
    required this.profile,
    required this.personalInfo,
    required this.courses,
  });

  /// 홈 화면에서 필요한 핵심 정보를 다시 가져온다.
  Future<void> refreshHomeData() async {
    profile = await user.profile(refresh: true);
    personalInfo = await user.personalInfo(refresh: true);
    courses = await user.courses(refresh: true);
    if (_cachedTimetable != null) {
      _cachedTimetable = await user.timetable();
    }
  }

  /// 학기 시간표를 조회한다.
  Future<KlasTimetable> loadTimetable({bool refresh = false}) async {
    if (!refresh && _cachedTimetable != null) {
      return _cachedTimetable!;
    }

    final loaded = await user.timetable();
    _cachedTimetable = loaded;
    return loaded;
  }

  /// 앱 로그아웃 시 클라이언트를 정리한다.
  void close() {
    client.close();
  }
}
