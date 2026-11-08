// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/// [ForumReply]
///
/// Entidade imutável que modela uma resposta individual a um tópico de discussão
/// acadêmico dentro do ambiente virtual de aprendizagem (AVA).
class ForumReply {
  /// Identificador único da resposta.
  final String id;

  /// Nome do autor que redigiu a resposta.
  final String authorName;

  /// Perfil ou papel acadêmico do autor (ex.: 'aluno', 'professor', 'monitor').
  final String authorRole;

  /// Conteúdo textual da mensagem de resposta.
  final String body;

  /// Data de postagem formatada ou em padrão ISO-8601.
  final String date;

  /// Cria uma nova instância imutável de [ForumReply].
  const ForumReply({
    required this.id,
    required this.authorName,
    required this.authorRole,
    required this.body,
    required this.date,
  });

  /// Constrói uma instância de [ForumReply] a partir de um mapa serializado em JSON.
  ///
  /// Parâmetros:
  /// - [json]: Mapa contendo as chaves brutas enviadas pelo backend.
  ///
  /// Retorna o objeto fortemente tipado com tolerância a variações de chave (`body` ou `content`).
  factory ForumReply.fromJson(Map<String, dynamic> json) {
    return ForumReply(
      id: json['id']?.toString() ?? '',
      authorName: json['authorName']?.toString() ?? '',
      authorRole: json['authorRole']?.toString() ?? 'aluno',
      body: (json['body'] ?? json['content'])?.toString() ?? '',
      date: json['date']?.toString() ?? '',
    );
  }
}

/// Alias de compatibilidade retroativa para garantir Zero-Breakage.
typedef StudentForumReply = ForumReply;
