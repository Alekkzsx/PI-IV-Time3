// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

/// [AcademicRecordSummary]
///
/// Entidade de domínio que sintetiza os dados oficiais do Prontuário Acadêmico Regular do discente,
/// incluindo Registro Acadêmico (RA), curso ativo, coeficiente de rendimento (CR) e horas integralizadas.
class AcademicRecordSummary {
  /// Registro Acadêmico (R.A.) institucional do estudante.
  final String ra;

  /// Nome oficial do curso universitário em andamento.
  final String course;

  /// Coeficiente de Rendimento (CR) acumulado no histórico acadêmico.
  final String academicIndex;

  /// Carga horária integralizada e percentual curricular concluído.
  final String completedWorkload;

  /// Rótulo representativo do status da matrícula e período letivo vigente.
  final String activeEnrollmentBadge;

  /// Cria uma nova instância imutável de [AcademicRecordSummary].
  const AcademicRecordSummary({
    required this.ra,
    required this.course,
    required this.academicIndex,
    required this.completedWorkload,
    required this.activeEnrollmentBadge,
  });
}
