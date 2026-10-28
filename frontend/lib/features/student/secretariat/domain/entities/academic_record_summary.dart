// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

/// Entidade de domínio que sintetiza os dados do Prontuário Acadêmico Regular do aluno.
class AcademicRecordSummary {
  /// Registro Acadêmico (R.A.) formatado.
  final String ra;

  /// Nome oficial do curso de graduação.
  final String course;

  /// Coeficiente de Rendimento (CR) acumulado.
  final String academicIndex;

  /// Carga horária integralizada e percentual concluído.
  final String completedWorkload;

  /// Período de matrícula vigente.
  final String activeEnrollmentBadge;

  /// Cria uma instância imutável de [AcademicRecordSummary].
  const AcademicRecordSummary({
    required this.ra,
    required this.course,
    required this.academicIndex,
    required this.completedWorkload,
    required this.activeEnrollmentBadge,
  });
}
