import '../exceptions/klas_exceptions.dart';
import '../transport/mobile_attendance_headers.dart';
import 'request_executor.dart';

/// 모바일 출석의 인증 및 일회용 제출 요청을 담당합니다.
final class QrAttendanceApi {
  final RequestExecutor _requests;

  QrAttendanceApi(this._requests);

  Future<bool> isClosed(Map<String, dynamic> payload) async {
    final response = await _requests.postJsonText(
      '/mst/ads/admst/KWAtendSubjseqFinishOpt.do',
      payload: payload,
      includeContext: false,
      headers: mobileAttendanceHeaders,
    );
    final value = response.trim();
    if (value == 'Y' || value == '"Y"') return true;
    if (value == 'N' || value == '"N"') return false;
    throw const ParsingException('Unrecognized attendance closing status.');
  }

  Future<Map<String, dynamic>> checkVerification(
    Map<String, dynamic> payload,
  ) async {
    return _object(
      await _requests.postJsonDynamic(
        '/std/lis/evltn/CertiLctreStdCheck.do',
        payload: payload,
        includeContext: false,
        headers: mobileAttendanceHeaders,
      ),
    );
  }

  Future<Map<String, dynamic>> sendEmail(Map<String, dynamic> payload) {
    return _once('/std/lis/evltn/CertiEmailSendStd.do', payload);
  }

  Future<Map<String, dynamic>> verifyCode(Map<String, dynamic> payload) {
    return _once('/std/lis/evltn/CertiKeyCheckStd.do', payload);
  }

  Future<Map<String, dynamic>> verifiedAppKey(Map<String, dynamic> payload) {
    return _once('/std/lis/evltn/CertiPushSucStd.do', payload);
  }

  Future<Map<String, dynamic>> submit(Map<String, dynamic> payload) {
    return _once('/mst/ads/admst/KwAttendQRCodeInsert.do', payload);
  }

  Future<Map<String, dynamic>> _once(
    String path,
    Map<String, dynamic> payload,
  ) async {
    return _object(
      await _requests.postJsonDynamicOnce(
        path,
        payload: payload,
        headers: mobileAttendanceHeaders,
      ),
    );
  }

  Map<String, dynamic> _object(Object? value) {
    if (value is Map<String, dynamic>) return value;
    throw const ParsingException('QR attendance expected an object response.');
  }
}
