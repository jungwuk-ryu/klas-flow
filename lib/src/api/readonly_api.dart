import '../exceptions/klas_exceptions.dart';
import '../models/file_payload.dart';

/// 엔드포인트 HTTP 메서드다.
enum KlasEndpointMethod { get, post }

/// 엔드포인트 응답 타입이다.
enum KlasEndpointResponseType {
  jsonObject,
  jsonArray,
  jsonScalar,
  text,
  binary,
}

/// POST 요청 본문 인코딩 타입이다.
enum KlasEndpointRequestEncoding { none, json, form }

/// 단일 엔드포인트 메타데이터다.
final class KlasEndpointSpec {
  final String id;
  final KlasEndpointMethod method;
  final String path;
  final KlasEndpointResponseType responseType;
  final KlasEndpointRequestEncoding requestEncoding;
  final bool includeContextByDefault;

  const KlasEndpointSpec({
    required this.id,
    required this.method,
    required this.path,
    required this.responseType,
    required this.requestEncoding,
    required this.includeContextByDefault,
  });
}

/// 검증된 읽기 전용 엔드포인트 카탈로그다.
final class KlasEndpointCatalog {
  static const Map<String, KlasEndpointSpec> byId = <String, KlasEndpointSpec>{
    'learning.anytmQuizStdList': KlasEndpointSpec(
      id: 'learning.anytmQuizStdList',
      method: KlasEndpointMethod.post,
      path: '/std/lis/evltn/AnytmQuizStdList.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: true,
    ),
    'learning.dscsnStdList': KlasEndpointSpec(
      id: 'learning.dscsnStdList',
      method: KlasEndpointMethod.post,
      path: '/std/lis/evltn/DscsnStdList.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: true,
    ),
    'learning.lctrumHomeStdInfo': KlasEndpointSpec(
      id: 'learning.lctrumHomeStdInfo',
      method: KlasEndpointMethod.post,
      path: '/std/lis/evltn/LctrumHomeStdInfo.do',
      responseType: KlasEndpointResponseType.jsonObject,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: true,
    ),
    'learning.lrnSttusStdAtendList': KlasEndpointSpec(
      id: 'learning.lrnSttusStdAtendList',
      method: KlasEndpointMethod.post,
      path: '/std/lis/evltn/LrnSttusStdAtendList.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: true,
    ),
    'learning.lrnSttusStdAtendListSub': KlasEndpointSpec(
      id: 'learning.lrnSttusStdAtendListSub',
      method: KlasEndpointMethod.post,
      path: '/std/lis/evltn/LrnSttusStdAtendListSub.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: true,
    ),
    'learning.lrnSttusStdDscsnList': KlasEndpointSpec(
      id: 'learning.lrnSttusStdDscsnList',
      method: KlasEndpointMethod.post,
      path: '/std/lis/evltn/LrnSttusStdDscsnList.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: true,
    ),
    'learning.lrnSttusStdOne': KlasEndpointSpec(
      id: 'learning.lrnSttusStdOne',
      method: KlasEndpointMethod.post,
      path: '/std/lis/evltn/LrnSttusStdOne.do',
      responseType: KlasEndpointResponseType.jsonObject,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: true,
    ),
    'learning.lrnSttusStdRtprgsList': KlasEndpointSpec(
      id: 'learning.lrnSttusStdRtprgsList',
      method: KlasEndpointMethod.post,
      path: '/std/lis/evltn/LrnSttusStdRtprgsList.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: true,
    ),
    'learning.lrnSttusStdTaskList': KlasEndpointSpec(
      id: 'learning.lrnSttusStdTaskList',
      method: KlasEndpointMethod.post,
      path: '/std/lis/evltn/LrnSttusStdTaskList.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: true,
    ),
    'learning.lrnSttusStdTeamPrjctList': KlasEndpointSpec(
      id: 'learning.lrnSttusStdTeamPrjctList',
      method: KlasEndpointMethod.post,
      path: '/std/lis/evltn/LrnSttusStdTeamPrjctList.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: true,
    ),
    'learning.lrnSttusStdTestAnQuizList': KlasEndpointSpec(
      id: 'learning.lrnSttusStdTestAnQuizList',
      method: KlasEndpointMethod.post,
      path: '/std/lis/evltn/LrnSttusStdTestAnQuizList.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: true,
    ),
    'learning.onlineTestStdList': KlasEndpointSpec(
      id: 'learning.onlineTestStdList',
      method: KlasEndpointMethod.post,
      path: '/std/lis/evltn/OnlineTestStdList.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: true,
    ),
    'learning.selectOnlineCntntsStdList': KlasEndpointSpec(
      id: 'learning.selectOnlineCntntsStdList',
      method: KlasEndpointMethod.post,
      path: '/std/lis/evltn/SelectOnlineCntntsStdList.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: true,
    ),
    'learning.taskStdList': KlasEndpointSpec(
      id: 'learning.taskStdList',
      method: KlasEndpointMethod.post,
      path: '/std/lis/evltn/TaskStdList.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: true,
    ),
    'boardSurvey.boardStdList_6972896b': KlasEndpointSpec(
      id: 'boardSurvey.boardStdList_6972896b',
      method: KlasEndpointMethod.post,
      path: '/std/lis/sport/6972896bfe72408eb72926780e85d041/BoardStdList.do',
      responseType: KlasEndpointResponseType.jsonObject,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: true,
    ),
    'boardSurvey.boardStdView_6972896b': KlasEndpointSpec(
      id: 'boardSurvey.boardStdView_6972896b',
      method: KlasEndpointMethod.post,
      path: '/std/lis/sport/6972896bfe72408eb72926780e85d041/BoardStdView.do',
      responseType: KlasEndpointResponseType.jsonObject,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: true,
    ),
    'boardSurvey.boardStdList_d052b8f8': KlasEndpointSpec(
      id: 'boardSurvey.boardStdList_d052b8f8',
      method: KlasEndpointMethod.post,
      path: '/std/lis/sport/d052b8f845784c639f036b102fdc3023/BoardStdList.do',
      responseType: KlasEndpointResponseType.jsonObject,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: true,
    ),
    'boardSurvey.boardStdView_d052b8f8': KlasEndpointSpec(
      id: 'boardSurvey.boardStdView_d052b8f8',
      method: KlasEndpointMethod.post,
      path: '/std/lis/sport/d052b8f845784c639f036b102fdc3023/BoardStdView.do',
      responseType: KlasEndpointResponseType.jsonObject,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: true,
    ),
    'boardSurvey.boardViewStdPage_d052b8f8': KlasEndpointSpec(
      id: 'boardSurvey.boardViewStdPage_d052b8f8',
      method: KlasEndpointMethod.post,
      path:
          '/std/lis/sport/d052b8f845784c639f036b102fdc3023/BoardViewStdPage.do',
      responseType: KlasEndpointResponseType.text,
      requestEncoding: KlasEndpointRequestEncoding.form,
      includeContextByDefault: true,
    ),
    'boardSurvey.qustnrStdList': KlasEndpointSpec(
      id: 'boardSurvey.qustnrStdList',
      method: KlasEndpointMethod.post,
      path: '/std/lis/sport/QustnrStdList.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: true,
    ),
    'boardSurvey.qustnrStdPage': KlasEndpointSpec(
      id: 'boardSurvey.qustnrStdPage',
      method: KlasEndpointMethod.post,
      path: '/std/lis/sport/QustnrStdPage.do',
      responseType: KlasEndpointResponseType.text,
      requestEncoding: KlasEndpointRequestEncoding.form,
      includeContextByDefault: true,
    ),
    'frame.gyojikExamCheck': KlasEndpointSpec(
      id: 'frame.gyojikExamCheck',
      method: KlasEndpointMethod.post,
      path: '/std/cmn/frame/GyojikExamCheck.do',
      responseType: KlasEndpointResponseType.jsonObject,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'frame.klasStop': KlasEndpointSpec(
      id: 'frame.klasStop',
      method: KlasEndpointMethod.post,
      path: '/std/cmn/frame/KlasStop.do',
      responseType: KlasEndpointResponseType.text,
      requestEncoding: KlasEndpointRequestEncoding.form,
      includeContextByDefault: false,
    ),
    'frame.lctrumSchdulInfo': KlasEndpointSpec(
      id: 'frame.lctrumSchdulInfo',
      method: KlasEndpointMethod.post,
      path: '/std/cmn/frame/LctrumSchdulInfo.do',
      responseType: KlasEndpointResponseType.jsonScalar,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: true,
    ),
    'frame.schdulStdList': KlasEndpointSpec(
      id: 'frame.schdulStdList',
      method: KlasEndpointMethod.post,
      path: '/std/cmn/frame/SchdulStdList.do',
      responseType: KlasEndpointResponseType.jsonObject,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'frame.stdHome': KlasEndpointSpec(
      id: 'frame.stdHome',
      method: KlasEndpointMethod.post,
      path: '/std/cmn/frame/StdHome.do',
      responseType: KlasEndpointResponseType.jsonObject,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'frame.yearhakgiAtnlcSbjectList': KlasEndpointSpec(
      id: 'frame.yearhakgiAtnlcSbjectList',
      method: KlasEndpointMethod.post,
      path: '/std/cmn/frame/YearhakgiAtnlcSbjectList.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'loginSession.captchaImg': KlasEndpointSpec(
      id: 'loginSession.captchaImg',
      method: KlasEndpointMethod.get,
      path: '/usr/cmn/login/captchaImg.do',
      responseType: KlasEndpointResponseType.binary,
      requestEncoding: KlasEndpointRequestEncoding.none,
      includeContextByDefault: false,
    ),
    'loginSession.loginCaptcha': KlasEndpointSpec(
      id: 'loginSession.loginCaptcha',
      method: KlasEndpointMethod.post,
      path: '/usr/cmn/login/LoginCaptcha.do',
      responseType: KlasEndpointResponseType.jsonScalar,
      requestEncoding: KlasEndpointRequestEncoding.form,
      includeContextByDefault: false,
    ),
    'loginSession.loginConfirm': KlasEndpointSpec(
      id: 'loginSession.loginConfirm',
      method: KlasEndpointMethod.post,
      path: '/usr/cmn/login/LoginConfirm.do',
      responseType: KlasEndpointResponseType.jsonObject,
      requestEncoding: KlasEndpointRequestEncoding.form,
      includeContextByDefault: false,
    ),
    'loginSession.loginSecurity': KlasEndpointSpec(
      id: 'loginSession.loginSecurity',
      method: KlasEndpointMethod.post,
      path: '/usr/cmn/login/LoginSecurity.do',
      responseType: KlasEndpointResponseType.jsonObject,
      requestEncoding: KlasEndpointRequestEncoding.form,
      includeContextByDefault: false,
    ),
    'loginSession.updateSession': KlasEndpointSpec(
      id: 'loginSession.updateSession',
      method: KlasEndpointMethod.get,
      path: '/usr/cmn/login/UpdateSession.do',
      responseType: KlasEndpointResponseType.jsonObject,
      requestEncoding: KlasEndpointRequestEncoding.none,
      includeContextByDefault: false,
    ),
    'session.info': KlasEndpointSpec(
      id: 'session.info',
      method: KlasEndpointMethod.get,
      path: '/api/v1/session/info',
      responseType: KlasEndpointResponseType.jsonObject,
      requestEncoding: KlasEndpointRequestEncoding.none,
      includeContextByDefault: false,
    ),
    'enrollment.atnlcYearList': KlasEndpointSpec(
      id: 'enrollment.atnlcYearList',
      method: KlasEndpointMethod.post,
      path: '/std/cps/atnlc/AtnlcYearList.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'enrollment.cmmnGamokList': KlasEndpointSpec(
      id: 'enrollment.cmmnGamokList',
      method: KlasEndpointMethod.post,
      path: '/std/cps/atnlc/CmmnGamokList.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'enrollment.cmmnHakgwaList': KlasEndpointSpec(
      id: 'enrollment.cmmnHakgwaList',
      method: KlasEndpointMethod.post,
      path: '/std/cps/atnlc/CmmnHakgwaList.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'enrollment.lctrePlanStopFlag': KlasEndpointSpec(
      id: 'enrollment.lctrePlanStopFlag',
      method: KlasEndpointMethod.post,
      path: '/std/cps/atnlc/LctrePlanStopFlag.do',
      responseType: KlasEndpointResponseType.text,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'enrollment.timetableStdList': KlasEndpointSpec(
      id: 'enrollment.timetableStdList',
      method: KlasEndpointMethod.post,
      path: '/std/cps/atnlc/TimetableStdList.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'eclass.eClassStdList': KlasEndpointSpec(
      id: 'eclass.eClassStdList',
      method: KlasEndpointMethod.post,
      path: '/std/lis/lctre/EClassStdList.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: true,
    ),
    'attendance.kwAttendStdGwakmokList': KlasEndpointSpec(
      id: 'attendance.kwAttendStdGwakmokList',
      method: KlasEndpointMethod.post,
      path: '/std/ads/admst/KwAttendStdGwakmokList.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'attendance.mySchdulMonthList': KlasEndpointSpec(
      id: 'attendance.mySchdulMonthList',
      method: KlasEndpointMethod.post,
      path: '/std/ads/admst/MySchdulMonthList.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'attendance.mySchdulMonthTableList': KlasEndpointSpec(
      id: 'attendance.mySchdulMonthTableList',
      method: KlasEndpointMethod.post,
      path: '/std/ads/admst/MySchdulMonthTableList.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'file.downloadFile': KlasEndpointSpec(
      id: 'file.downloadFile',
      method: KlasEndpointMethod.get,
      path: '/common/file/DownloadFile/{attachId}/{fileSn}',
      responseType: KlasEndpointResponseType.binary,
      requestEncoding: KlasEndpointRequestEncoding.none,
      includeContextByDefault: false,
    ),
    'file.uploadFileList': KlasEndpointSpec(
      id: 'file.uploadFileList',
      method: KlasEndpointMethod.post,
      path: '/common/file/UploadFileList.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'academic.atnlcScreCheckTerm': KlasEndpointSpec(
      id: 'academic.atnlcScreCheckTerm',
      method: KlasEndpointMethod.post,
      path: '/std/cps/inqire/AtnlcScreCheckTerm.do',
      responseType: KlasEndpointResponseType.jsonObject,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'academic.atnlcScreHakjukInfo': KlasEndpointSpec(
      id: 'academic.atnlcScreHakjukInfo',
      method: KlasEndpointMethod.post,
      path: '/std/cps/inqire/AtnlcScreHakjukInfo.do',
      responseType: KlasEndpointResponseType.jsonObject,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'academic.atnlcScreProgramGubun': KlasEndpointSpec(
      id: 'academic.atnlcScreProgramGubun',
      method: KlasEndpointMethod.post,
      path: '/std/cps/inqire/AtnlcScreProgramGubun.do',
      responseType: KlasEndpointResponseType.jsonObject,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'academic.atnlcScreSugangOpt': KlasEndpointSpec(
      id: 'academic.atnlcScreSugangOpt',
      method: KlasEndpointMethod.post,
      path: '/std/cps/inqire/AtnlcScreSugangOpt.do',
      responseType: KlasEndpointResponseType.jsonScalar,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'academic.atnlcScreSungjukInfo': KlasEndpointSpec(
      id: 'academic.atnlcScreSungjukInfo',
      method: KlasEndpointMethod.post,
      path: '/std/cps/inqire/AtnlcScreSungjukInfo.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'academic.atnlcScreSungjukTot': KlasEndpointSpec(
      id: 'academic.atnlcScreSungjukTot',
      method: KlasEndpointMethod.post,
      path: '/std/cps/inqire/AtnlcScreSungjukTot.do',
      responseType: KlasEndpointResponseType.jsonObject,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'academic.delAppliedList': KlasEndpointSpec(
      id: 'academic.delAppliedList',
      method: KlasEndpointMethod.post,
      path: '/std/cps/inqire/DelAppliedList.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'academic.delHakjukInfo': KlasEndpointSpec(
      id: 'academic.delHakjukInfo',
      method: KlasEndpointMethod.post,
      path: '/std/cps/inqire/DelHakjukInfo.do',
      responseType: KlasEndpointResponseType.jsonObject,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'academic.delSungjukStdList': KlasEndpointSpec(
      id: 'academic.delSungjukStdList',
      method: KlasEndpointMethod.post,
      path: '/std/cps/inqire/DelSungjukStdList.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'academic.gyoyangIsuInfo': KlasEndpointSpec(
      id: 'academic.gyoyangIsuInfo',
      method: KlasEndpointMethod.post,
      path: '/std/cps/inqire/GyoyangIsuInfo.do',
      responseType: KlasEndpointResponseType.jsonObject,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'academic.individualPortfolioStdList': KlasEndpointSpec(
      id: 'academic.individualPortfolioStdList',
      method: KlasEndpointMethod.post,
      path: '/std/cps/inqire/IndividualPortfolioStdList.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'academic.janghakHistoryStdList': KlasEndpointSpec(
      id: 'academic.janghakHistoryStdList',
      method: KlasEndpointMethod.post,
      path: '/std/cps/inqire/JanghakHistoryStdList.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'academic.janghakStdList': KlasEndpointSpec(
      id: 'academic.janghakStdList',
      method: KlasEndpointMethod.post,
      path: '/std/cps/inqire/JanghakStdList.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'academic.lctreEvlResultGwamokList': KlasEndpointSpec(
      id: 'academic.lctreEvlResultGwamokList',
      method: KlasEndpointMethod.post,
      path: '/std/cps/inqire/LctreEvlResultGwamokList.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'academic.lctreEvlResultSetHakgwa': KlasEndpointSpec(
      id: 'academic.lctreEvlResultSetHakgwa',
      method: KlasEndpointMethod.post,
      path: '/std/cps/inqire/LctreEvlResultSetHakgwa.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'academic.standStdList': KlasEndpointSpec(
      id: 'academic.standStdList',
      method: KlasEndpointMethod.post,
      path: '/std/cps/inqire/StandStdList.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'academic.toeicInfoStd': KlasEndpointSpec(
      id: 'academic.toeicInfoStd',
      method: KlasEndpointMethod.post,
      path: '/std/cps/inqire/ToeicInfoStd.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'academic.toeicLevelInfo': KlasEndpointSpec(
      id: 'academic.toeicLevelInfo',
      method: KlasEndpointMethod.post,
      path: '/std/cps/inqire/ToeicLevelInfo.do',
      responseType: KlasEndpointResponseType.text,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'academic.toeicStdList': KlasEndpointSpec(
      id: 'academic.toeicStdList',
      method: KlasEndpointMethod.post,
      path: '/std/cps/inqire/ToeicStdList.do',
      responseType: KlasEndpointResponseType.jsonArray,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'studentRecord.tmpabssklGetHakjuk': KlasEndpointSpec(
      id: 'studentRecord.tmpabssklGetHakjuk',
      method: KlasEndpointMethod.post,
      path: '/std/hak/hakjuk/TmpabssklGetHakjuk.do',
      responseType: KlasEndpointResponseType.jsonObject,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
    'studentRecord.tmpabssklStatu': KlasEndpointSpec(
      id: 'studentRecord.tmpabssklStatu',
      method: KlasEndpointMethod.post,
      path: '/std/hak/hakjuk/TmpabssklStatu.do',
      responseType: KlasEndpointResponseType.jsonObject,
      requestEncoding: KlasEndpointRequestEncoding.json,
      includeContextByDefault: false,
    ),
  };
}

typedef KlasPostJsonDynamic =
    Future<Object?> Function(
      String path, {
      Map<String, dynamic>? payload,
      required bool includeContext,
    });

typedef KlasPostJsonText =
    Future<String> Function(
      String path, {
      Map<String, dynamic>? payload,
      required bool includeContext,
    });

typedef KlasPostFormDynamic =
    Future<Object?> Function(
      String path, {
      Map<String, dynamic>? payload,
      required bool includeContext,
    });

typedef KlasPostFormText =
    Future<String> Function(
      String path, {
      Map<String, dynamic>? payload,
      required bool includeContext,
    });

typedef KlasGetJsonObject =
    Future<Map<String, dynamic>> Function(
      String path, {
      Map<String, String>? query,
    });

typedef KlasGetText =
    Future<String> Function(String path, {Map<String, String>? query});

typedef KlasGetBinary =
    Future<FilePayload> Function(String path, {Map<String, String>? query});

/// 카탈로그 기반 읽기 전용 API 호출기다.
final class KlasReadOnlyApi {
  final KlasPostJsonDynamic _postJsonDynamic;
  final KlasPostJsonText _postJsonText;
  final KlasPostFormDynamic _postFormDynamic;
  final KlasPostFormText _postFormText;
  final KlasGetJsonObject _getJsonObject;
  final KlasGetText _getText;
  final KlasGetBinary _getBinary;

  KlasReadOnlyApi({
    required KlasPostJsonDynamic postJsonDynamic,
    required KlasPostJsonText postJsonText,
    required KlasPostFormDynamic postFormDynamic,
    required KlasPostFormText postFormText,
    required KlasGetJsonObject getJsonObject,
    required KlasGetText getText,
    required KlasGetBinary getBinary,
  }) : _postJsonDynamic = postJsonDynamic,
       _postJsonText = postJsonText,
       _postFormDynamic = postFormDynamic,
       _postFormText = postFormText,
       _getJsonObject = getJsonObject,
       _getText = getText,
       _getBinary = getBinary;

  /// 사용 가능한 엔드포인트 ID 목록이다.
  List<String> get endpointIds =>
      KlasEndpointCatalog.byId.keys.toList(growable: false);

  /// 엔드포인트 메타데이터를 조회한다.
  KlasEndpointSpec? spec(String id) => KlasEndpointCatalog.byId[id];

  /// 카탈로그 ID로 API를 호출한다.
  Future<Object?> call(
    String id, {
    Map<String, dynamic>? payload,
    Map<String, String>? pathParams,
    Map<String, String>? query,
    bool? includeContext,
  }) async {
    final endpoint = KlasEndpointCatalog.byId[id];
    if (endpoint == null) {
      throw ArgumentError('Unknown endpoint id: $id');
    }

    final resolvedPath = _resolvePath(endpoint.path, pathParams);
    final useContext = includeContext ?? endpoint.includeContextByDefault;

    return switch (endpoint.method) {
      KlasEndpointMethod.get => _callGet(
        endpoint: endpoint,
        resolvedPath: resolvedPath,
        query: query,
      ),
      KlasEndpointMethod.post => _callPost(
        endpoint: endpoint,
        resolvedPath: resolvedPath,
        payload: payload,
        includeContext: useContext,
      ),
    };
  }

  /// JSON 객체 응답을 강제한다.
  Future<Map<String, dynamic>> callObject(
    String id, {
    Map<String, dynamic>? payload,
    Map<String, String>? pathParams,
    Map<String, String>? query,
    bool? includeContext,
  }) async {
    final result = await call(
      id,
      payload: payload,
      pathParams: pathParams,
      query: query,
      includeContext: includeContext,
    );

    if (result is Map<String, dynamic>) {
      return result;
    }
    if (result is Map) {
      return result.cast<String, dynamic>();
    }
    throw const ParsingException('Expected JSON object response.');
  }

  /// JSON 배열 응답을 강제한다.
  Future<List<dynamic>> callArray(
    String id, {
    Map<String, dynamic>? payload,
    Map<String, String>? pathParams,
    Map<String, String>? query,
    bool? includeContext,
  }) async {
    final result = await call(
      id,
      payload: payload,
      pathParams: pathParams,
      query: query,
      includeContext: includeContext,
    );

    if (result is List<dynamic>) {
      return result;
    }
    throw const ParsingException('Expected JSON array response.');
  }

  /// 문자열 응답을 강제한다.
  Future<String> callText(
    String id, {
    Map<String, dynamic>? payload,
    Map<String, String>? pathParams,
    Map<String, String>? query,
    bool? includeContext,
  }) async {
    final result = await call(
      id,
      payload: payload,
      pathParams: pathParams,
      query: query,
      includeContext: includeContext,
    );

    if (result is String) {
      return result;
    }
    throw const ParsingException('Expected text response.');
  }

  /// 바이너리 응답을 강제한다.
  Future<FilePayload> callBinary(
    String id, {
    Map<String, String>? pathParams,
    Map<String, String>? query,
  }) async {
    final result = await call(id, pathParams: pathParams, query: query);
    if (result is FilePayload) {
      return result;
    }
    throw const ParsingException('Expected binary response.');
  }

  Future<Object?> _callGet({
    required KlasEndpointSpec endpoint,
    required String resolvedPath,
    Map<String, String>? query,
  }) async {
    return switch (endpoint.responseType) {
      KlasEndpointResponseType.jsonObject => await _getJsonObject(
        resolvedPath,
        query: query,
      ),
      KlasEndpointResponseType.text => await _getText(
        resolvedPath,
        query: query,
      ),
      KlasEndpointResponseType.binary => await _getBinary(
        resolvedPath,
        query: query,
      ),
      _ => throw ParsingException(
        'Unsupported GET response type for ${endpoint.id}: ${endpoint.responseType}',
      ),
    };
  }

  Future<Object?> _callPost({
    required KlasEndpointSpec endpoint,
    required String resolvedPath,
    Map<String, dynamic>? payload,
    required bool includeContext,
  }) async {
    final response = switch (endpoint.requestEncoding) {
      KlasEndpointRequestEncoding.form => await _callPostForm(
        endpoint,
        resolvedPath,
        payload,
        includeContext,
      ),
      KlasEndpointRequestEncoding.json => await _callPostJson(
        endpoint,
        resolvedPath,
        payload,
        includeContext,
      ),
      KlasEndpointRequestEncoding.none => throw ParsingException(
        'POST endpoint must declare request encoding: ${endpoint.id}',
      ),
    };

    return _validateResponseType(endpoint, response);
  }

  Future<Object?> _callPostForm(
    KlasEndpointSpec endpoint,
    String resolvedPath,
    Map<String, dynamic>? payload,
    bool includeContext,
  ) async {
    return switch (endpoint.responseType) {
      KlasEndpointResponseType.text => await _postFormText(
        resolvedPath,
        payload: payload,
        includeContext: includeContext,
      ),
      _ => await _postFormDynamic(
        resolvedPath,
        payload: payload,
        includeContext: includeContext,
      ),
    };
  }

  Future<Object?> _callPostJson(
    KlasEndpointSpec endpoint,
    String resolvedPath,
    Map<String, dynamic>? payload,
    bool includeContext,
  ) async {
    return switch (endpoint.responseType) {
      KlasEndpointResponseType.text => await _postJsonText(
        resolvedPath,
        payload: payload,
        includeContext: includeContext,
      ),
      _ => await _postJsonDynamic(
        resolvedPath,
        payload: payload,
        includeContext: includeContext,
      ),
    };
  }

  Object? _validateResponseType(KlasEndpointSpec endpoint, Object? response) {
    return switch (endpoint.responseType) {
      KlasEndpointResponseType.jsonObject => _asJsonObject(endpoint, response),
      KlasEndpointResponseType.jsonArray => _asJsonArray(endpoint, response),
      KlasEndpointResponseType.jsonScalar => _asJsonScalar(endpoint, response),
      KlasEndpointResponseType.text => _asText(endpoint, response),
      KlasEndpointResponseType.binary => _asBinary(endpoint, response),
    };
  }

  Map<String, dynamic> _asJsonObject(KlasEndpointSpec endpoint, Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    throw ParsingException(
      'Expected JSON object for ${endpoint.id}, got ${value.runtimeType}.',
    );
  }

  List<dynamic> _asJsonArray(KlasEndpointSpec endpoint, Object? value) {
    if (value is List<dynamic>) {
      return value;
    }
    throw ParsingException(
      'Expected JSON array for ${endpoint.id}, got ${value.runtimeType}.',
    );
  }

  Object? _asJsonScalar(KlasEndpointSpec endpoint, Object? value) {
    if (value is Map || value is List) {
      throw ParsingException(
        'Expected JSON scalar for ${endpoint.id}, got ${value.runtimeType}.',
      );
    }
    return value;
  }

  String _asText(KlasEndpointSpec endpoint, Object? value) {
    if (value is String) {
      return value;
    }
    throw ParsingException(
      'Expected text response for ${endpoint.id}, got ${value.runtimeType}.',
    );
  }

  FilePayload _asBinary(KlasEndpointSpec endpoint, Object? value) {
    if (value is FilePayload) {
      return value;
    }
    throw ParsingException(
      'Expected binary response for ${endpoint.id}, got ${value.runtimeType}.',
    );
  }

  String _resolvePath(String template, Map<String, String>? pathParams) {
    var resolved = template;
    if (pathParams != null) {
      pathParams.forEach((key, value) {
        resolved = resolved.replaceAll('{$key}', Uri.encodeComponent(value));
      });
    }

    final unresolved = RegExp(r'\{[^}]+\}');
    if (unresolved.hasMatch(resolved)) {
      throw ArgumentError(
        'Missing path parameters for endpoint path: $template',
      );
    }
    return resolved;
  }
}
