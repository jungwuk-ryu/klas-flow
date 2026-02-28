/// KLAS 엔드포인트 경로 모음입니다.
final class ApiPaths {
  /// 로그인 보안키 조회 경로입니다.
  final String loginSecurity;

  /// 캡차 초기화 경로입니다.
  final String loginCaptcha;

  /// 로그인 확인 경로입니다.
  final String loginConfirm;

  /// 프레임 초기화 경로입니다.
  final String frameInitialize;

  /// 세션 확인 경로입니다.
  final String sessionInfo;

  /// 학기/과목 목록 조회 경로입니다.
  final String yearhakgiSubjectList;

  const ApiPaths({
    this.loginSecurity = '/usr/cmn/login/LoginSecurity.do',
    this.loginCaptcha = '/usr/cmn/login/LoginCaptcha.do',
    this.loginConfirm = '/usr/cmn/login/LoginConfirm.do',
    this.frameInitialize = '/std/cmn/frame/KlasStop.do',
    this.sessionInfo = '/api/v1/session/info',
    this.yearhakgiSubjectList = '/std/cmn/frame/YearhakgiAtnlcSbjectList.do',
  });
}
