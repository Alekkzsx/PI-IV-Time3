// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

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

  /// Tipo ou assunto do requerimento (ex: 'Horas Complementares', '2ª Chamada de Avaliação').
  final String subjectType;

  /// Objeto ou componente curricular relacionado (ex: '218131 - APS-II (Análise e Projeto de Sistemas II)').
  final String componentObject;

  /// Situação atual do protocolo.
  final ProtocolStatus status;

  /// Texto do parecer oficial emitido pela Secretaria Acadêmica ou Coordenação.
  final String officialOpinion;

  /// Justificativa detalhada informada pelo estudante na submissão.
  final String justification;

  /// Nome do arquivo anexo comprobatório (se houver).
  final String? attachmentName;

  /// Responsável pela análise/despacho (ex: 'Coordenadoria de Engenharia de Software').
  final String? approverName;

  /// Data de emissão do parecer (ex: '22/10/2026 às 17:40').
  final String? responseDate;

  /// Cria uma instância imutável de [ProtocolRequest].
  const ProtocolRequest({
    required this.protocolCode,
    required this.submittedAt,
    required this.subjectType,
    required this.componentObject,
    required this.status,
    required this.officialOpinion,
    this.justification =
        'Solicitação formal protocolada conforme regulamento acadêmico.',
    this.attachmentName,
    this.approverName,
    this.responseDate,
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

  /// Retorna uma cópia atualizada do protocolo.
  ProtocolRequest copyWith({
    String? protocolCode,
    String? submittedAt,
    String? subjectType,
    String? componentObject,
    ProtocolStatus? status,
    String? officialOpinion,
    String? justification,
    String? attachmentName,
    String? approverName,
    String? responseDate,
  }) {
    return ProtocolRequest(
      protocolCode: protocolCode ?? this.protocolCode,
      submittedAt: submittedAt ?? this.submittedAt,
      subjectType: subjectType ?? this.subjectType,
      componentObject: componentObject ?? this.componentObject,
      status: status ?? this.status,
      officialOpinion: officialOpinion ?? this.officialOpinion,
      justification: justification ?? this.justification,
      attachmentName: attachmentName ?? this.attachmentName,
      approverName: approverName ?? this.approverName,
      responseDate: responseDate ?? this.responseDate,
    );
  }
}
