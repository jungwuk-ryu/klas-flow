import '../exceptions/klas_exceptions.dart';
import '../models/course_context.dart';
import '../models/high_level_models.dart';
import '../models/team_project.dart';
import 'request_executor.dart';

const _projectRoot = '/std/lis/evltn/';

/// 팀 프로젝트 조회 요청을 과목에 바인딩하고 응답을 검증합니다.
final class TeamProjectApi {
  final RequestExecutor _requests;

  TeamProjectApi(this._requests);

  Future<List<TeamProjectTarget>> list(CourseContext context) async {
    final rows = _rows(await _post('PrjctStdList.do', context.toFormData()));
    final targets = rows.map((row) => TeamProjectTarget(row, context)).toList();
    if (targets.map((target) => target.id).toSet().length != targets.length) {
      throw const ParsingException('Team project identifiers are ambiguous.');
    }
    return targets;
  }

  Future<TeamProjectTarget> resolve(
    CourseContext context,
    KlasTeamProject project,
  ) async {
    if (project.courseId != context.selectSubj ||
        project.termId != context.selectYearhakgi) {
      throw ArgumentError('The team project belongs to another course.');
    }
    if (project.id.trim().isEmpty) {
      throw ArgumentError('The team project identifier is empty.');
    }
    final targets = await list(context);
    final matches = targets.where((target) => target.id == project.id);
    if (matches.isEmpty) {
      throw const TeamProjectUnavailableException(
        'The team project is no longer available in this course.',
      );
    }
    return matches.single;
  }

  Future<TeamProjectDetailData> detail(TeamProjectTarget target) async {
    final response = _object(await _post('PrjctStdDetail.do', target.payload));
    if (!response.containsKey('prjctDetail')) {
      throw const ParsingException('Team project details are missing.');
    }
    if (response['prjctDetail'] == null) {
      throw const TeamProjectUnavailableException(
        'Team project details are unavailable.',
      );
    }
    final row = _object(response['prjctDetail']);
    if (row.isEmpty) {
      throw const TeamProjectUnavailableException(
        'Team project details are unavailable.',
      );
    }
    for (final key in ['teamseq', 'ordseq']) {
      if (row.containsKey(key) &&
          _identifier(row, key) != _identifier(target.row, key)) {
        throw const ParsingException(
          'Team project details belong to another project.',
        );
      }
    }
    if (_integer(row['teamno']) != null &&
        _integer(target.row['teamno']) != null &&
        _integer(row['teamno']) != _integer(target.row['teamno'])) {
      throw const ParsingException(
        'Team project details belong to another team.',
      );
    }
    return TeamProjectDetailData(
      TeamProjectTarget({...target.row, ...row}, target.context),
      response['rptDetail'] == null ? null : _object(response['rptDetail']),
      _flag(response['isLeader']),
    );
  }

  Future<List<KlasTeamProjectMember>> members(TeamProjectTarget target) async {
    if (_text(target.row['teamno']) == null) return const [];
    final rows = _rows(await _post('PrjctTeamMberStdList.do', target.payload));
    if (rows.any(
      (row) =>
          _integer(row['teamno']) != null &&
          _integer(row['teamno']) != _integer(target.row['teamno']),
    )) {
      throw const ParsingException(
        'Team project members belong to another team.',
      );
    }
    return List.unmodifiable(
      rows.map(
        (row) => KlasTeamProjectMember(
          name: _text(row['name']),
          department: _text(row['hakgwanm']),
          studentId: _text(row['hakbun']),
          email: _text(row['email']),
          teamNumber: _integer(row['teamno']),
          isLeader: _flag(row['leader']),
        ),
      ),
    );
  }

  Future<Object?> _post(String file, Map<String, dynamic> payload) async {
    final result = await _requests.postJsonDynamic(
      '$_projectRoot$file',
      payload: payload,
      includeContext: false,
    );
    return result is Map && result.length == 1 && result.containsKey('data')
        ? result['data']
        : result;
  }
}

final class TeamProjectTarget {
  final Map<String, dynamic> row;
  final CourseContext context;
  final String id;

  TeamProjectTarget(Map<String, dynamic> source, this.context)
    : row = Map.unmodifiable(source),
      id =
          '${_identifier(source, 'teamseq')}/${_identifier(source, 'ordseq')}' {
    final course = _text(row['selectSubj']);
    final term = _text(row['selectYearhakgi']);
    if ((course != null && course != context.selectSubj) ||
        (term != null &&
            term.replaceAll(',', '') !=
                context.selectYearhakgi.replaceAll(',', ''))) {
      throw const ParsingException(
        'Team project response belongs to another course.',
      );
    }
  }

  Map<String, dynamic> get payload => {
    ...context.toFormData(),
    'pageInit': true,
    'searchTeamseq': _identifier(row, 'teamseq'),
    'searchOrdseq': _identifier(row, 'ordseq'),
    'searchTeamno': _text(row['teamno']) ?? '',
  };

  KlasTeamProject get project => KlasTeamProject(
    id: id,
    courseId: context.selectSubj,
    termId: context.selectYearhakgi,
    number: _integer(row['ordseq'])!,
    title: _text(row['title']),
    teamNumber: _integer(row['teamno']),
    startsAt: _date(row['startdate']),
    dueAt: _date(row['expiredate']),
    additionalStartsAt: _date(row['restartdate']),
    additionalDueAt: _date(row['reexpiredate']),
    submitted: _flag(row['submityn']),
    isWithinSubmissionPeriod: _flag(row['indate']),
    isWithinAdditionalSubmissionPeriod: _flag(row['adddate']),
    submissionVisibility: switch (_text(row['isopen'])) {
      '1' => KlasTeamProjectSubmissionVisibility.bestSubmissions,
      '2' => KlasTeamProjectSubmissionVisibility.allSubmissions,
      '3' => KlasTeamProjectSubmissionVisibility.private,
      _ => null,
    },
  );
}

/// 첨부파일은 기존 파일 feature로 읽은 뒤 공개 모델에 결합합니다.
final class TeamProjectDetailData {
  final TeamProjectTarget target;
  final Map<String, dynamic>? submission;
  final bool? isLeader;

  TeamProjectDetailData(
    this.target,
    Map<String, dynamic>? submission,
    this.isLeader,
  ) : submission = submission == null ? null : Map.unmodifiable(submission);

  String? get attachmentId => _text(target.row['atchFileId']);
  String? get submissionAttachmentId => _text(submission?['atchFileId']);
  String? get feedbackAttachmentId => _text(submission?['tutorFileId']);

  KlasTeamProjectDetail toPublic({
    List<KlasAttachedFile> files = const [],
    List<KlasAttachedFile> submittedFiles = const [],
    List<KlasAttachedFile> feedbackFiles = const [],
  }) {
    final row = target.row;
    final report = submission;
    return KlasTeamProjectDetail(
      project: target.project,
      contentHtml: _content(row['contents']),
      week: _integer(row['weeklyseq']),
      session: _integer(row['weeklysubseq']),
      basicScore: _number(row['basicscore']),
      allowedFileTypes: _text(row['submitfiletypeNms']),
      fileSizeLimitMegabytes: _number(row['filelimit']),
      isCurrentUserLeader: isLeader,
      files: files,
      submission: report == null || report.isEmpty
          ? null
          : KlasTeamProjectSubmission(
              title: _text(report['title']),
              content: _content(report['contents']),
              score: _number(report['finalscore']),
              isSelectedAsBest: _flag(report['isbestreport']),
              instructorFeedback: _content(report['tutorcontents']),
              files: submittedFiles,
              feedbackFiles: feedbackFiles,
            ),
    );
  }
}

Map<String, dynamic> _object(Object? value) {
  if (value is Map<String, dynamic>) return value;
  throw const ParsingException('Expected a team project object response.');
}

List<Map<String, dynamic>> _rows(Object? value) {
  if (value is! List) {
    throw const ParsingException('Expected a team project list response.');
  }
  return value.map(_object).toList();
}

String _identifier(Map<String, dynamic> row, String key) {
  final value = _text(row[key]);
  if (value == null ||
      !RegExp(r'^\d+$').hasMatch(value) ||
      _integer(value) == null) {
    throw const ParsingException(
      'A team project identifier is missing or invalid.',
    );
  }
  return _integer(value)!.toString();
}

String? _text(Object? value) {
  if (value is! String && value is! num) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

String? _content(Object? value) => value is String ? value : null;
int? _integer(Object? value) => int.tryParse(_text(value) ?? '');
double? _number(Object? value) {
  final number = double.tryParse(_text(value) ?? '');
  return number != null && number.isFinite ? number : null;
}

bool? _flag(Object? value) => switch (value) {
  true || 'Y' => true,
  false || 'N' => false,
  _ => null,
};

DateTime? _date(Object? value) {
  final text = _text(value);
  if (text == null) return null;
  final compact = RegExp(
    r'^(\d{4})(\d{2})(\d{2})(?:(\d{2})(\d{2})(\d{2})?)?$',
  ).firstMatch(text);
  if (compact != null) {
    final parts = [for (var i = 1; i <= 6; i++) int.parse(compact[i] ?? '0')];
    final date = DateTime(
      parts[0],
      parts[1],
      parts[2],
      parts[3],
      parts[4],
      parts[5],
    );
    return _validDate(date, parts) ? date : null;
  }
  final iso = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2})(?::(\d{2})(?:\.\d{1,9})?)?(?:[zZ]|[+-](\d{2}):?(\d{2}))?)?$',
  ).firstMatch(text);
  if (iso == null) return null;
  final parts = [for (var i = 1; i <= 6; i++) int.parse(iso[i] ?? '0')];
  final date = DateTime(
    parts[0],
    parts[1],
    parts[2],
    parts[3],
    parts[4],
    parts[5],
  );
  if (!_validDate(date, parts) ||
      (iso[7] != null && int.parse(iso[7]!) > 23) ||
      (iso[8] != null && int.parse(iso[8]!) > 59)) {
    return null;
  }
  return DateTime.tryParse(text);
}

bool _validDate(DateTime value, List<int> parts) =>
    parts[0] > 0 &&
    value.year == parts[0] &&
    value.month == parts[1] &&
    value.day == parts[2] &&
    value.hour == parts[3] &&
    value.minute == parts[4] &&
    value.second == parts[5];
