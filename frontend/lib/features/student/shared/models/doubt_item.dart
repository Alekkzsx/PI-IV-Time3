// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/// [DoubtItem]
///
/// Entidade imutável que representa uma dúvida acadêmica enviada por um aluno
/// em relação a uma disciplina ou atividade específica, incluindo a eventual resposta docente.
class DoubtItem {
  /// Identificador único da dúvida no sistema acadêmico.
  final String id;

  /// Nome legível do discente autor da dúvida.
  final String studentName;

  /// Texto descritivo contendo o questionamento formulado pelo aluno.
  final String question;

  /// Data e hora de publicação da dúvida no formato legível ou ISO-8601.
  final String askedAt;

  /// Resposta fornecida pelo professor ou monitor acadêmico, ou nulo se pendente.
  final String? reply;

  /// Data e hora da resposta fornecida pelo corpo docente, se houver.
  final String? repliedAt;

  /// Cria uma nova instância imutável de [DoubtItem].
  const DoubtItem({
    required this.id,
    required this.studentName,
    required this.question,
    required this.askedAt,
    this.reply,
    this.repliedAt,
  });

  /// Desserializa um mapa JSON na instância tipada de [DoubtItem].
  ///
  /// Parâmetros:
  /// - [json]: Mapa de dados brutos proveniente do backend.
  ///
  /// Retorna uma instância validada com fallback para valores padrão seguros.
  factory DoubtItem.fromJson(Map<String, dynamic> json) {
    return DoubtItem(
      id: json['id']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      askedAt: json['askedAt']?.toString() ?? '',
      reply: json['reply']?.toString(),
      repliedAt: json['repliedAt']?.toString(),
    );
  }
}

/// Alias de compatibilidade retroativa para garantir Zero-Breakage.
typedef StudentDoubtItem = DoubtItem;
