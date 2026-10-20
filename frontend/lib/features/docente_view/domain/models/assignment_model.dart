// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'rubric_model.dart';

/// Submission status of a student assignment.
enum SubmissionStatus {
  entregue,
  aguardandoCorrecao,
  corrigido,
  atrasado,
  naoEntregue,
}

/// Represents a student's submission for an assignment.
class StudentSubmission {
  final String id;
  final String studentId;
  final String ra;
  final String studentName;
  final String? fileName;
  final String? submittedAtFormatted;
  final String? fileSize;
  final double? grade;
  final SubmissionStatus status;
  final String? teacherFeedback;
  final List<RubricCriterion> rubricEvaluations;

  const StudentSubmission({
    required this.id,
    required this.studentId,
    required this.ra,
    required this.studentName,
    this.fileName,
    this.submittedAtFormatted,
    this.fileSize,
    this.grade,
    required this.status,
    this.teacherFeedback,
    this.rubricEvaluations = const [],
  });

  StudentSubmission copyWith({
    String? id,
    String? studentId,
    String? ra,
    String? studentName,
    String? fileName,
    String? submittedAtFormatted,
    String? fileSize,
    double? grade,
    SubmissionStatus? status,
    String? teacherFeedback,
    List<RubricCriterion>? rubricEvaluations,
  }) {
    return StudentSubmission(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      ra: ra ?? this.ra,
      studentName: studentName ?? this.studentName,
      fileName: fileName ?? this.fileName,
      submittedAtFormatted: submittedAtFormatted ?? this.submittedAtFormatted,
      fileSize: fileSize ?? this.fileSize,
      grade: grade ?? this.grade,
      status: status ?? this.status,
      teacherFeedback: teacherFeedback ?? this.teacherFeedback,
      rubricEvaluations: rubricEvaluations ?? this.rubricEvaluations,
    );
  }
}

/// Represents an assignment/evaluative task for a course.
class AssignmentItem {
  final String id;
  final String courseId;
  final String courseCode;
  final String title;
  final double weight; // e.g. 0.4 for 40%
  final String stage; // e.g. 'Etapa N1'
  final String dueDateFormatted;
  final bool isUrgent;
  final String modality; // e.g. 'Individual com Rubrica'
  final bool allowLateWithPenalty;
  final List<RubricCriterion> rubricCriteria;
  final List<StudentSubmission> submissions;

  const AssignmentItem({
    required this.id,
    required this.courseId,
    required this.courseCode,
    required this.title,
    required this.weight,
    required this.stage,
    required this.dueDateFormatted,
    required this.isUrgent,
    required this.modality,
    required this.allowLateWithPenalty,
    required this.rubricCriteria,
    required this.submissions,
  });

  int get deliveredCount =>
      submissions.where((s) => s.status != SubmissionStatus.naoEntregue).length;

  int get totalCount => submissions.length;

  double get progressPercentage =>
      totalCount == 0 ? 0.0 : (deliveredCount / totalCount) * 100;

  AssignmentItem copyWith({
    String? id,
    String? courseId,
    String? courseCode,
    String? title,
    double? weight,
    String? stage,
    String? dueDateFormatted,
    bool? isUrgent,
    String? modality,
    bool? allowLateWithPenalty,
    List<RubricCriterion>? rubricCriteria,
    List<StudentSubmission>? submissions,
  }) {
    return AssignmentItem(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      courseCode: courseCode ?? this.courseCode,
      title: title ?? this.title,
      weight: weight ?? this.weight,
      stage: stage ?? this.stage,
      dueDateFormatted: dueDateFormatted ?? this.dueDateFormatted,
      isUrgent: isUrgent ?? this.isUrgent,
      modality: modality ?? this.modality,
      allowLateWithPenalty: allowLateWithPenalty ?? this.allowLateWithPenalty,
      rubricCriteria: rubricCriteria ?? this.rubricCriteria,
      submissions: submissions ?? this.submissions,
    );
  }
}
