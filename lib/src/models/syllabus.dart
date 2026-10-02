/// 한 과목의 강의계획서입니다. 미등록 항목은 null 또는 빈 목록으로 남습니다.
final class KlasSyllabus {
  final String courseId;
  final String termId;
  final String? title;
  final String? englishTitle;
  final String? academicNumber;
  final String? category;
  final double? credits;
  final double? classHours;
  final double? theoryCredits;
  final double? laboratoryCredits;
  final double? designCredits;
  final KlasSyllabusInstructor instructor;
  final List<KlasSyllabusInstructor> coInstructors;
  final List<KlasSyllabusInstructor> assistants;
  final List<KlasSyllabusClassTime> classTimes;
  final String? summary;
  final String? objectives;
  final String? competency;
  final String? prerequisites;
  final String? concurrentCourses;
  final String? followUpCourses;
  final List<String> teachingMethods;
  final List<String> deliveryModes;
  final List<KlasSyllabusAssessment> assessments;
  final String? assessmentNotes;
  final List<KlasSyllabusTextbook> textbooks;
  final String? textbookNotes;
  final List<KlasSyllabusWeek> weeks;
  final String? weeklyNotes;
  final List<KlasSyllabusLearningOutcome> learningOutcomes;

  /// 여러 분반에 적용되는 공통 강의계획서를 사용하는지 여부입니다.
  final bool usesSharedPlan;

  /// 공통 강의계획서의 수업 진행 방법입니다.
  final String? teachingNotes;

  KlasSyllabus({
    required this.courseId,
    required this.termId,
    required this.instructor,
    this.title,
    this.englishTitle,
    this.academicNumber,
    this.category,
    this.credits,
    this.classHours,
    this.theoryCredits,
    this.laboratoryCredits,
    this.designCredits,
    this.summary,
    this.objectives,
    this.competency,
    this.prerequisites,
    this.concurrentCourses,
    this.followUpCourses,
    this.assessmentNotes,
    this.textbookNotes,
    this.weeklyNotes,
    this.teachingNotes,
    this.usesSharedPlan = false,
    List<KlasSyllabusInstructor> coInstructors = const [],
    List<KlasSyllabusInstructor> assistants = const [],
    List<KlasSyllabusClassTime> classTimes = const [],
    List<String> teachingMethods = const [],
    List<String> deliveryModes = const [],
    List<KlasSyllabusAssessment> assessments = const [],
    List<KlasSyllabusTextbook> textbooks = const [],
    List<KlasSyllabusWeek> weeks = const [],
    List<KlasSyllabusLearningOutcome> learningOutcomes = const [],
  }) : coInstructors = List.unmodifiable(coInstructors),
       assistants = List.unmodifiable(assistants),
       classTimes = List.unmodifiable(classTimes),
       teachingMethods = List.unmodifiable(teachingMethods),
       deliveryModes = List.unmodifiable(deliveryModes),
       assessments = List.unmodifiable(assessments),
       textbooks = List.unmodifiable(textbooks),
       weeks = List.unmodifiable(weeks),
       learningOutcomes = List.unmodifiable(learningOutcomes);
}

/// 강의계획서에 기재된 담당 교수 또는 조교의 연락처입니다.
final class KlasSyllabusInstructor {
  final String? name;
  final String? role;
  final String? phone;
  final String? mobilePhone;
  final String? email;

  const KlasSyllabusInstructor({
    this.name,
    this.role,
    this.phone,
    this.mobilePhone,
    this.email,
  });
}

/// 강의계획서에 기재된 요일, 교시와 강의실입니다.
final class KlasSyllabusClassTime {
  final String? day;
  final List<int> periods;
  final List<String> rooms;

  KlasSyllabusClassTime({
    this.day,
    List<int> periods = const [],
    List<String> rooms = const [],
  }) : periods = List.unmodifiable(periods),
       rooms = List.unmodifiable(rooms);
}

/// 성적 평가 항목입니다.
enum KlasSyllabusAssessmentCategory {
  attendance,
  midterm,
  finalExam,
  assignment,
  participation,
  quiz,
  presentation,
  discussion,
  other,
}

/// 한 평가 항목의 성적 반영 비율입니다. null은 미기재이고 0은 0%입니다.
final class KlasSyllabusAssessment {
  final KlasSyllabusAssessmentCategory category;
  final double? percentage;

  const KlasSyllabusAssessment({required this.category, this.percentage});
}

/// 주교재 또는 부교재입니다.
final class KlasSyllabusTextbook {
  final bool isPrimary;
  final String? title;
  final String? author;
  final String? publisher;
  final String? publicationYear;

  const KlasSyllabusTextbook({
    required this.isPrimary,
    this.title,
    this.author,
    this.publisher,
    this.publicationYear,
  });
}

/// 주차별 강의내용, 운영 메모와 보강 계획입니다.
final class KlasSyllabusWeek {
  final int week;
  final String? content;
  final String? notes;
  final String? makeUpPlan;

  const KlasSyllabusWeek({
    required this.week,
    this.content,
    this.notes,
    this.makeUpPlan,
  });
}

/// 강의계획서 본문에 기재된 교과목 학습성과입니다.
final class KlasSyllabusLearningOutcome {
  final int number;
  final String? title;
  final String? description;
  final double? reflectionPercentage;

  const KlasSyllabusLearningOutcome({
    required this.number,
    this.title,
    this.description,
    this.reflectionPercentage,
  });
}
