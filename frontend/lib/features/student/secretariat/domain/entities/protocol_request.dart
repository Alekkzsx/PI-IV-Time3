// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

/// [ProtocolStatus]
///
/// Status possíveis de um protocolo formal submetido à Secretaria Acadêmica.
enum ProtocolStatus {
  /// Requerimento aprovado e deferido pela secretaria ou coordenação.
  approved,

  /// Requerimento em análise técnica ou documental.
  pending,

  /// Requerimento indeferido pela autoridade acadêmica competente.
  rejected,
}

/// [ProtocolRequest]
///
/// Entidade imutável de domínio que representa um protocolo formal de requerimento discente.
/// Engloba código de rastreabilidade, tipo de solicitação, componente curricular afetado,
/// justificativa, anexos comprobatórios e despacho/parecer oficial emitido.
class ProtocolRequest {
  /// Identificador do registro no banco de dados.
  final String? id;

  /// Código oficial do protocolo emitido no recebimento (ex: 'PROT-2026/8835').
  final String protocolCode;

  /// Data/hora formatada da submissão do protocolo.
  final String submittedAt;

  /// Assunto ou categoria do requerimento (ex: '2ª Chamada', 'Revisão de Faltas').
  final String subjectType;

  /// Componente curricular ou disciplina associada ao pedido.
  final String componentObject;

  /// Situação atual da tramitação do requerimento.
  final ProtocolStatus status;

  /// Parecer circunstanciado e fundamentação do despacho emitido pela secretaria.
  final String officialOpinion;

  /// Justificativa apresentada pelo discente no momento do pedido.
  final String justification;

  /// Nome do arquivo de comprovante ou atestado médico anexado, se houver.
  final String? attachmentName;

  /// Nome do setor ou autoridade responsável pelo despacho.
  final String? approverName;

  /// Data de registro do despacho formal.
  final String? responseDate;

  /// Cria uma nova instância imutável de [ProtocolRequest].
  const ProtocolRequest({
    this.id,
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

  /// Retorna o rótulo textual legível correspondente ao status do protocolo.
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

  /// Retorna uma cópia atualizada do protocolo com campos alterados seletivamente.
  ProtocolRequest copyWith({
    String? id,
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
      id: id ?? this.id,
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
