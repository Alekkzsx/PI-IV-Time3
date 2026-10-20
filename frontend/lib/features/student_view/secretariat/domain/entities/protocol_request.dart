// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/// Status possíveis de um protocolo formal submetido à Secretaria Acadêmica.
enum ProtocolStatus {
  /// Requerimento aprovado e deferido pela secretaria.
  approved,

  /// Requerimento em análise técnica ou documental.
  pending,

  /// Requerimento indeferido.
  rejected,
}

/// Entidade de domínio que representa um protocolo de requerimento acadêmico.
class ProtocolRequest {
  /// Código oficial do protocolo (ex: 'PROT-2026/8835').
  final String protocolCode;

  /// Data/hora formatada de envio (ex: 'Ontem, 16:20').
  final String submittedAt;

  /// Tipo ou assunto do requerimento (ex: 'Horas Complementares').
  final String subjectType;

  /// Objeto ou componente curricular relacionado (ex: 'Validação de Curso Extracurricular (40h)').
  final String componentObject;

  /// Situação atual do protocolo.
  final ProtocolStatus status;

  /// Texto do parecer oficial emitido pela Secretaria Acadêmica.
  final String officialOpinion;

  /// Cria uma instância imutável de [ProtocolRequest].
  const ProtocolRequest({
    required this.protocolCode,
    required this.submittedAt,
    required this.subjectType,
    required this.componentObject,
    required this.status,
    required this.officialOpinion,
  });

  /// Retorna o rótulo textual correspondente à situação do protocolo.
  String get statusLabel {
    switch (status) {
      case ProtocolStatus.approved:
        return 'Deferido';
      case ProtocolStatus.pending:
        return 'Em Análise';
      case ProtocolStatus.rejected:
        return 'Indeferido';
    }
  }
}
