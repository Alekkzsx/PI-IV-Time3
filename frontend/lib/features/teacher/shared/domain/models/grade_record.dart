// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:pi_iv_time3/core/academic/grade_calculator.dart';

/// Situação acadêmica de um discente na pauta oficial de notas.
enum AcademicStatus { semNotas, aprovado, exame, reprovadoPorNota, reprovadoPorFalta }

/// Representa o registro de notas de um discente na pauta oficial.
class StudentGrade {
  final String studentId;
  final String courseId;
  final String ra;
  final String studentName;
  final double assignmentsScore;
  final double p1Score;
  final double projectsScore;
  final double p2Score;
  final double attendanceRate;
  final bool hasGrades;
  final String evaluationFormula;
  final AcademicThresholds thresholds;

  const StudentGrade({
    required this.studentId,
    this.courseId = '',
    required this.ra,
    required this.studentName,
    required this.assignmentsScore,
    required this.p1Score,
    required this.projectsScore,
    required this.p2Score,
    required this.attendanceRate,
    this.hasGrades = true,
    this.evaluationFormula = '(N1 × 0.4) + (N2 × 0.6)',
    this.thresholds = AcademicThresholds.defaults,
  });

  /// N1 calculada dinamicamente pela fórmula da turma.
  double get n1Total => GradeCalculator.computeN1(
    assignmentsScore,
    p1Score,
    formula: evaluationFormula,
  );

  /// Alias para n1Total.
  double get n1Score => n1Total;

  /// N2 calculada dinamicamente pela fórmula da turma.
  double get n2Total => GradeCalculator.computeN2(
    projectsScore,
    p2Score,
    formula: evaluationFormula,
  );

  /// Alias para n2Total.
  double get n2Score => n2Total;

  /// Média semestral calculada dinamicamente pela fórmula da turma.
  double get finalAverage => GradeCalculator.computeFinalAverage(
    assignmentsScore: assignmentsScore,
    p1Score: p1Score,
    projectsScore: projectsScore,
    p2Score: p2Score,
    formula: evaluationFormula,
  );

  /// Situação acadêmica como enum de acordo com os limites institucionais.
  AcademicStatus get status {
    if (attendanceRate < thresholds.minimumAttendance) {
      return AcademicStatus.reprovadoPorFalta;
    }
    final hasAnyScore =
        hasGrades ||
        assignmentsScore > 0 ||
        p1Score > 0 ||
        projectsScore > 0 ||
        p2Score > 0;
    if (!hasAnyScore) {
      return AcademicStatus.semNotas;
    }
    if (finalAverage >= thresholds.minimumGrade) {
      return AcademicStatus.aprovado;
    }
    if (finalAverage >= thresholds.specialExamGrade) {
      return AcademicStatus.exame;
    }
    return AcademicStatus.reprovadoPorNota;
  }

  /// Situação acadêmica como string.
  String get statusLabel {
    switch (status) {
      case AcademicStatus.semNotas:
        return 'Em Curso';
      case AcademicStatus.aprovado:
        return 'Aprovado';
      case AcademicStatus.exame:
        return 'Em Exame';
      case AcademicStatus.reprovadoPorNota:
        return 'Reprovado por Nota';
      case AcademicStatus.reprovadoPorFalta:
        return 'Reprovado por Falta';
    }
  }

  StudentGrade copyWith({
    String? studentId,
    String? courseId,
    String? ra,
    String? studentName,
    double? assignmentsScore,
    double? p1Score,
    double? projectsScore,
    double? p2Score,
    double? attendanceRate,
    bool? hasGrades,
    String? evaluationFormula,
    AcademicThresholds? thresholds,
  }) {
    return StudentGrade(
      studentId: studentId ?? this.studentId,
      courseId: courseId ?? this.courseId,
      ra: ra ?? this.ra,
      studentName: studentName ?? this.studentName,
      assignmentsScore: assignmentsScore ?? this.assignmentsScore,
      p1Score: p1Score ?? this.p1Score,
      projectsScore: projectsScore ?? this.projectsScore,
      p2Score: p2Score ?? this.p2Score,
      attendanceRate: attendanceRate ?? this.attendanceRate,
      hasGrades: hasGrades ?? this.hasGrades,
      evaluationFormula: evaluationFormula ?? this.evaluationFormula,
      thresholds: thresholds ?? this.thresholds,
    );
  }
}
