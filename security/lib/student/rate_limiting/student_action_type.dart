// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/// Ações discentes auditadas e protegidas por controle de vazão (Rate Limiting).
enum StudentActionType {
  /// Envio formal de entrega de atividade acadêmica.
  submitDelivery,

  /// Protocolar novo requerimento na Secretaria Geral.
  issueProtocol,

  /// Emissão de declaração de matrícula oficial.
  issueEnrollmentDeclaration,

  /// Publicação de nova dúvida no Fórum de Turma do AVA.
  createForumTopic,

  /// Alteração de senha nas preferências de segurança.
  changePassword,
}
