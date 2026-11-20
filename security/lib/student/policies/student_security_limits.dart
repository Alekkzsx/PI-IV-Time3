// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/// Limites numéricos invariantes e tetos regimentais de segurança para a Visão do Aluno.
abstract final class StudentSecurityLimits {
  StudentSecurityLimits._();

  // ─── LIMITES FÍSICOS DE ARQUIVOS (BYTES) ───
  /// Tamanho máximo para upload de arquivos em entregas acadêmicas (7 MB).
  static const int maxDeliveryFileBytes = 7 * 1024 * 1024;

  /// Tamanho máximo para anexos comprobatórios da Secretaria Geral (7 MB).
  static const int maxProtocolAttachmentBytes = 7 * 1024 * 1024;

  /// Tamanho máximo do nome do arquivo (em caracteres).
  static const int maxFileNameLength = 120;

  // ─── LIMITES DE CARACTERES EM TEXTOS DIGITADOS PELO ALUNO ───
  /// Limite mínimo de caracteres para a justificativa formal de protocolo.
  static const int minJustificationLength = 5;

  /// Limite máximo de caracteres para a justificativa formal de protocolo (mitigação de DoS).
  static const int maxJustificationLength = 2000;

  /// Limite máximo de caracteres para observações/comentários ao docente na entrega.
  static const int maxDeliveryCommentsLength = 1000;

  /// Limite mínimo de caracteres para título de dúvida no Fórum AVA.
  static const int minForumTitleLength = 3;

  /// Limite máximo de caracteres para título de dúvida no Fórum AVA.
  static const int maxForumTitleLength = 120;

  /// Limite mínimo de caracteres para a descrição detalhada no Fórum AVA.
  static const int minForumBodyLength = 10;

  /// Limite máximo de caracteres para a descrição detalhada no Fórum AVA.
  static const int maxForumBodyLength = 4000;

  /// Limite máximo de caracteres para as anotações pessoais do caderno em Markdown.
  static const int maxPersonalNotesLength = 30000;

  /// Limite máximo de caracteres para URLs de repositório Git.
  static const int maxGitUrlLength = 250;

  // ─── JANELAS E COTAS DE RATE LIMITING (CONTROLE DE VAZÃO DISCENTE) ───
  /// Duração padrão da janela deslizante para ações do aluno.
  static const Duration slidingWindowDuration = Duration(seconds: 60);

  /// Cota máxima de submissões de atividades permitidas por janela de 60s.
  static const int maxDeliverySubmissionsPerWindow = 3;

  /// Cota máxima de abertura de protocolos formais permitidos por janela de 60s.
  static const int maxProtocolSubmissionsPerWindow = 2;

  /// Cota máxima de emissão de declarações de matrícula permitidas por janela de 60s.
  static const int maxEnrollmentDeclarationsPerWindow = 2;

  /// Cota máxima de publicação de novos tópicos no Fórum AVA por janela de 60s.
  static const int maxForumTopicsPerWindow = 3;

  /// Cota máxima de tentativas de troca de senha por janela de 60s.
  static const int maxPasswordChangesPerWindow = 3;
}
