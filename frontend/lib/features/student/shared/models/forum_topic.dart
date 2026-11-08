// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'forum_reply.dart';

/// [ForumTopic]
///
/// Modela uma thread de discussão acadêmica no fórum da turma, contendo
/// metadados de autoria, status de fixação e a lista aninhada de respostas.
class ForumTopic {
  /// Identificador exclusivo da thread no fórum.
  final String id;

  /// Código da disciplina ou turma à qual o tópico pertence.
  final String classCode;

  /// Título sintético do tema em debate.
  final String title;

  /// Corpo textual contendo a mensagem ou dúvida inicial do tópico.
  final String body;

  /// Categoria temática de classificação (ex.: 'Geral', 'Trabalho', 'Dúvidas').
  final String category;

  /// Nome do autor criador do tópico.
  final String authorName;

  /// Papel funcional do autor ('aluno', 'professor', etc.).
  final String authorRole;

  /// Data de abertura da discussão.
  final String date;

  /// Flag que determina se a thread está fixada no topo pelo corpo docente.
  final bool isPinned;

  /// Coleção de respostas encadeadas associadas a este tópico.
  final List<ForumReply> replies;

  /// Construtor imutável de [ForumTopic].
  const ForumTopic({
    required this.id,
    required this.classCode,
    required this.title,
    required this.body,
    this.category = 'Geral',
    required this.authorName,
    this.authorRole = 'aluno',
    required this.date,
    this.isPinned = false,
    this.replies = const [],
  });

  /// Instancia [ForumTopic] a partir de um payload JSON, convertendo de forma segura
  /// tanto os atributos primitivos quanto a lista de respostas filhas.
  ///
  /// Parâmetros:
  /// - [json]: Mapa de dados retornado pela API REST.
  ///
  /// Retorna o tópico formatado e com respostas parseadas.
  factory ForumTopic.fromJson(Map<String, dynamic> json) {
    final rawReplies = json['replies'];
    return ForumTopic(
      id: json['id']?.toString() ?? '',
      classCode: json['classCode']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: (json['body'] ?? json['content'])?.toString() ?? '',
      category: json['category']?.toString() ?? 'Geral',
      authorName: json['authorName']?.toString() ?? '',
      authorRole: json['authorRole']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      isPinned: json['isPinned'] == true,
      replies: rawReplies is List
          ? rawReplies
                .whereType<Map>()
                .map(
                  (e) =>
                      ForumReply.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
    );
  }
}

/// Alias de compatibilidade retroativa para garantir Zero-Breakage.
typedef StudentForumTopic = ForumTopic;
