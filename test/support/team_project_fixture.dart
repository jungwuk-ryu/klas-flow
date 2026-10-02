import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:klasflow/klasflow.dart';

import 'mobile_qr_fixture.dart';

const projectListPath = '/std/lis/evltn/PrjctStdList.do';
const projectDetailPath = '/std/lis/evltn/PrjctStdDetail.do';
const projectMembersPath = '/std/lis/evltn/PrjctTeamMberStdList.do';
const projectFilesPath = '/common/file/UploadFileList.do';
const projectReadPaths = {
  projectListPath,
  projectDetailPath,
  projectMembersPath,
};

/// Project contents, identities and attachment groups below are synthetic.
Map<String, dynamic> projectRow() => {
  'teamseq': 11,
  'ordseq': '2',
  'teamno': '3',
  'title': '팀 프로젝트 연습',
  'startdate': '202610010900',
  'expiredate': '202610202359',
  'restartdate': '202610210000',
  'reexpiredate': '202610222359',
  'submityn': 'Y',
  'indate': 'N',
  'adddate': 'Y',
  'isopen': '3',
};

Map<String, dynamic> projectDetailRow() => {
  ...projectRow(),
  'contents': '<p>문제 설명</p>\n<p>협업 결과를 정리하세요.</p>',
  'weeklyseq': 7,
  'weeklysubseq': '1',
  'basicscore': 0,
  'submitfiletypeNms': 'PDF, ZIP',
  'filelimit': '20',
  'atchFileId': 'synthetic-instructions',
};

Map<String, dynamic> projectSubmissionRow() => {
  'title': '팀 제출물',
  'contents': '구현 내용\n\n역할 분담',
  'finalscore': '92.5',
  'isbestreport': 'N',
  'tutorcontents': '검토 의견\n수고했습니다.',
  'atchFileId': 'synthetic-submission',
  'tutorFileId': 'synthetic-feedback',
};

final class TeamProjectFixture {
  late final MobileQrFixture _auth;
  final FutureOr<http.Response?> Function(http.Request)? handle;

  TeamProjectFixture({this.handle}) {
    _auth = MobileQrFixture(
      handle: (request) async =>
          await handle?.call(request) ?? _response(request),
    );
  }

  KlasClient get client => _auth.client;
  List<http.Request> get requests => _auth.requests;
  List<http.Request> calls(String path) => _auth.calls(path);
  Future<KlasUser> login() => _auth.login();
  Future<KlasCourse> course() async => (await (await login()).defaultCourse())!;
  void close() => client.close();

  http.Response? _response(http.Request request) {
    switch (request.url.path) {
      case projectListPath:
        return qrJson([projectRow()]);
      case projectDetailPath:
        return qrJson({
          'prjctDetail': projectDetailRow(),
          'rptDetail': projectSubmissionRow(),
          'isLeader': 'Y',
        });
      case projectMembersPath:
        return qrJson([
          {
            'name': '팀장 테스트',
            'hakgwanm': '테스트학과',
            'hakbun': 'synthetic-001',
            'email': 'leader@example.com',
            'teamno': 3,
            'leader': 'Y',
          },
          {
            'name': '팀원 테스트',
            'hakgwanm': '테스트학과',
            'hakbun': 'synthetic-002',
            'email': null,
            'teamno': '3',
            'leader': 'N',
          },
        ]);
      case projectFilesPath:
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        return qrJson([
          {'fileSn': '1', 'fileName': '${body['attachId']}.pdf', 'fileSize': 3},
        ]);
      default:
        if (request.url.path.startsWith(
          '/common/file/DownloadFile/synthetic-',
        )) {
          return http.Response.bytes(
            [1, 2, 3],
            200,
            headers: {'content-type': 'application/pdf'},
          );
        }
        return null;
    }
  }
}
