import 'high_level_models.dart';

/// 교수가 지정한 제출 과제 공개 범위입니다.
enum KlasTeamProjectSubmissionVisibility {
  bestSubmissions,
  allSubmissions,
  private,
}

/// 수강 과목의 팀 프로젝트입니다. 제출 여부는 팀의 제출 상태입니다.
final class KlasTeamProject {
  final String id;
  final String courseId;
  final String termId;
  final int number;
  final String? title;
  final int? teamNumber;
  final DateTime? startsAt;
  final DateTime? dueAt;
  final DateTime? additionalStartsAt;
  final DateTime? additionalDueAt;
  final bool? submitted;
  final bool? isWithinSubmissionPeriod;
  final bool? isWithinAdditionalSubmissionPeriod;
  final KlasTeamProjectSubmissionVisibility? submissionVisibility;

  const KlasTeamProject({
    required this.id,
    required this.courseId,
    required this.termId,
    required this.number,
    this.title,
    this.teamNumber,
    this.startsAt,
    this.dueAt,
    this.additionalStartsAt,
    this.additionalDueAt,
    this.submitted,
    this.isWithinSubmissionPeriod,
    this.isWithinAdditionalSubmissionPeriod,
    this.submissionVisibility,
  });

  String get displayTitle => title ?? '(제목 없음)';
}

/// 출제 내용과 현재 팀의 제출 결과입니다. HTML 본문은 호출자가 렌더링합니다.
final class KlasTeamProjectDetail {
  final KlasTeamProject project;
  final String? contentHtml;
  final int? week;
  final int? session;
  final double? basicScore;
  final String? allowedFileTypes;
  final double? fileSizeLimitMegabytes;
  final bool? isCurrentUserLeader;
  final List<KlasAttachedFile> files;
  final KlasTeamProjectSubmission? submission;

  KlasTeamProjectDetail({
    required this.project,
    this.contentHtml,
    this.week,
    this.session,
    this.basicScore,
    this.allowedFileTypes,
    this.fileSizeLimitMegabytes,
    this.isCurrentUserLeader,
    this.submission,
    List<KlasAttachedFile> files = const [],
  }) : files = List.unmodifiable(files);
}

/// 현재 팀이 제출한 본문, 파일과 교수의 평가입니다.
final class KlasTeamProjectSubmission {
  final String? title;
  final String? content;
  final double? score;
  final bool? isSelectedAsBest;
  final String? instructorFeedback;
  final List<KlasAttachedFile> files;
  final List<KlasAttachedFile> feedbackFiles;

  KlasTeamProjectSubmission({
    this.title,
    this.content,
    this.score,
    this.isSelectedAsBest,
    this.instructorFeedback,
    List<KlasAttachedFile> files = const [],
    List<KlasAttachedFile> feedbackFiles = const [],
  }) : files = List.unmodifiable(files),
       feedbackFiles = List.unmodifiable(feedbackFiles);
}

/// 프로젝트에 배정된 팀 구성원입니다. 기재되지 않은 정보는 null입니다.
final class KlasTeamProjectMember {
  final String? name;
  final String? department;
  final String? studentId;
  final String? email;
  final int? teamNumber;
  final bool? isLeader;

  const KlasTeamProjectMember({
    this.name,
    this.department,
    this.studentId,
    this.email,
    this.teamNumber,
    this.isLeader,
  });
}
