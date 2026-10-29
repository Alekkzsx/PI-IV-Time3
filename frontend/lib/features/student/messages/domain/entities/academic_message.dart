// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

/// Categorias oficiais de comunicados exibidos na Central de Mensagens do aluno.
enum MessageCategory {
  /// Comunicados institucionais emitidos pela Secretaria Acadêmica, Reitoria ou Diretoria.
  institutional,

  /// Avisos acadêmicos emitidos pelos docentes das disciplinas matriculadas.
  discipline,
}

/// Opções de filtragem rápida de comunicados na Central de Mensagens.
enum MessageFilter {
  /// Exibe todos os comunicados sem restrição de categoria.
  all,

  /// Exibe exclusivamente comunicados da Secretaria Acadêmica & Reitoria.
  institutional,

  /// Exibe exclusivamente avisos de disciplinas e docentes.
  discipline,
}

/// Entidade de domínio que representa um comunicado ou mensagem acadêmica.
class AcademicMessage {
  /// Identificador único do comunicado.
  final String id;

  /// Nome da unidade emissora ou docente responsável pelo comunicado.
  final String sender;

  /// Categoria do comunicado ([MessageCategory.institutional] ou [MessageCategory.discipline]).
  final MessageCategory category;

  /// Indica se a mensagem é recente/não lida e deve exibir o selo 'Novo'.
  final bool isNew;

  /// Rótulo temporal formatado de publicação (ex: '18/09/2026', 'Hoje, 14:10').
  final String dateLabel;

  /// Título principal em destaque do comunicado.
  final String title;

  /// Corpo descritivo do comunicado.
  final String body;

  /// Cria uma instância imutável de [AcademicMessage].
  const AcademicMessage({
    required this.id,
    required this.sender,
    required this.category,
    required this.isNew,
    required this.dateLabel,
    required this.title,
    required this.body,
  });

  /// Cria uma cópia da entidade alterando seletivamente seus atributos.
  AcademicMessage copyWith({
    String? id,
    String? sender,
    MessageCategory? category,
    bool? isNew,
    String? dateLabel,
    String? title,
    String? body,
  }) {
    return AcademicMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      category: category ?? this.category,
      isNew: isNew ?? this.isNew,
      dateLabel: dateLabel ?? this.dateLabel,
      title: title ?? this.title,
      body: body ?? this.body,
    );
  }
}
