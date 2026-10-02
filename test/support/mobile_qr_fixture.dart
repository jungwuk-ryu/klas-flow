import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:klasflow/klasflow.dart';
import 'package:test/test.dart';

const qrSubjectPath = '/std/ads/admst/KwAttendStdGwakmokList.do';
const qrFinishPath = '/mst/ads/admst/KWAtendSubjseqFinishOpt.do';
const qrListPath = '/mst/ads/admst/KwAttendStdAttendList.do';
const qrCheckPath = '/std/lis/evltn/CertiLctreStdCheck.do';
const qrEmailPath = '/std/lis/evltn/CertiEmailSendStd.do';
const qrCodePath = '/std/lis/evltn/CertiKeyCheckStd.do';
const qrAppKeyPath = '/std/lis/evltn/CertiPushSucStd.do';
const qrSubmitPath = '/mst/ads/admst/KwAttendQRCodeInsert.do';
const qrSubjectId = 'U20261101CSE013';

const qrRequestPaths = <String>{
  qrSubjectPath,
  qrFinishPath,
  qrListPath,
  qrCheckPath,
  qrEmailPath,
  qrCodePath,
  qrAppKeyPath,
  qrSubmitPath,
};

void expectAutomaticAttendanceHeaders(Iterable<http.Request> requests) {
  for (final request in requests) {
    final agent = request.headers['user-agent']?.toLowerCase();
    if (qrRequestPaths.contains(request.url.path)) {
      expect(agent, contains('nuriwareapp'), reason: request.url.path);
      expect(agent, contains('android'), reason: request.url.path);
    } else {
      expect(agent, isNull, reason: request.url.path);
    }
  }
}

/// Synthetic responses keep live attendance and account data out of tests.
final class MobileQrFixture {
  final List<http.Request> requests = [];
  final bool verificationRequired;
  final bool otpAvailable;
  final FutureOr<http.Response?> Function(http.Request)? handle;
  late final KlasClient client;

  MobileQrFixture({
    this.verificationRequired = true,
    this.otpAvailable = true,
    this.handle,
    KlasClientConfig? config,
  }) {
    client = KlasClient(
      config: config,
      httpClient: MockClient((request) async {
        requests.add(request);
        return await handle?.call(request) ?? _response(request);
      }),
    );
  }

  Future<KlasUser> login() => client.login('test-user', 'test-password');

  List<http.Request> calls(String path) =>
      requests.where((request) => request.url.path == path).toList();

  http.Response _response(http.Request request) {
    switch (request.url.path) {
      case '/usr/cmn/login/LoginSecurity.do':
        return qrJson({
          'data': {
            'publicKeyModulus': _modulus,
            'publicKeyExponent': '10001',
            'loginToken': 'test-nonce',
          },
        });
      case '/usr/cmn/login/LoginCaptcha.do':
        return qrJson(0);
      case '/usr/cmn/login/LoginConfirm.do':
        return qrJson(
          {'success': true},
          headers: {
            'set-cookie': 'JSESSIONID=synthetic-session; Path=/; Secure',
          },
        );
      case '/std/cmn/frame/KlasStop.do':
        return http.Response('<html><title>KLAS</title></html>', 200);
      case '/std/cmn/frame/YearhakgiAtnlcSbjectList.do':
        return qrJson({
          'data': [
            {
              'selectYearhakgi': '20261',
              'selectSubj': qrSubjectId,
              'selectChangeYn': 'N',
              'isDefault': true,
              'subjectName': '자료구조 - 김교수',
            },
          ],
        });
      case '/api/v1/session/info':
        return qrJson({
          'authenticated': true,
          'userId': 'test-user',
          'userName': '테스터',
        });
      case '/usr/cmn/login/captchaImg.do':
        return http.Response.bytes([1, 2, 3], 200);
      case '/std/ads/admst/KwAttendStdGwakmokList.do':
        return qrJson([
          {
            'thisYear': '2026',
            'hakgi': '1',
            'openMajorCode': 'CSE',
            'openGrade': '3',
            'openGwamokNo': '101',
            'bunbanNo': '01',
            'gwamokKname': '자료구조',
            'codeName1': '전공필수',
            'hakjumNum': '3',
            'sisuNum': '3',
            'memberName': '김교수',
            'currentNum': '45',
            'yoil': '월',
          },
        ]);
      case qrFinishPath:
        return qrJson('N');
      case qrListPath:
        return qrJson([
          {'weekNo': '3', 'attendOpenYn': 'Y'},
        ]);
      case qrCheckPath:
        return qrJson({
          'status': !verificationRequired,
          'curEmail': 'qr-test@example.com',
          'otpIssue': otpAvailable ? 'Y' : 'N',
        });
      case qrEmailPath:
        return qrJson({'status': true});
      case qrCodePath:
      case qrAppKeyPath:
        return qrJson({'status': true, 'randomKey': 'test-key'});
      case qrSubmitPath:
        return qrJson({'errorCount': 0, 'responseText': '출석 처리 완료'});
      default:
        return http.Response('Not Found', 404);
    }
  }
}

http.Response qrJson(Object? value, {Map<String, String>? headers}) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(value)),
    200,
    headers: {'content-type': 'application/json; charset=utf-8', ...?headers},
  );
}

Map<String, dynamic> qrBody(http.Request request) =>
    jsonDecode(request.body) as Map<String, dynamic>;

const _modulus =
    'd3b0a5d2e6f8c1b4998e77aa31bc4d2f3a7cb9e1ffacde099812f3aa1c8d9e07'
    '84a79b7654f0cc22a1346d8eaf3b70c9d11be9ee02baf7a90876efbda12340fd'
    'c7a8f9d01234abcdeffedcba98765432100112233445566778899aabbccddeeff';
