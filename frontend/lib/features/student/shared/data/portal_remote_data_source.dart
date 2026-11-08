// Desenvolvido por Rafael Henrique dos Santos Inácio - RA: 25009719

import 'dart:convert';
import '../../../../core/network/authenticated_api_client.dart';
import '../models/models.dart' as models;

/// [DashboardSnapshot]
///
/// Objeto de transferência de dados (DTO) que consolida a carga inicial de dados
/// acadêmicos do discente (`bootstrap`), agregando perfil, estatísticas, disciplinas,
/// entregas, eventos, mensagens e protocolos.
class DashboardSnapshot {
  /// Dados cadastrais e institucionais do estudante.
  final Map<String, dynamic> studentInfo;

  /// Métricas e indicadores consolidados (média global, frequência, créditos).
  final Map<String, dynamic> stats;

  /// Resumo do histórico escolar e coeficientes de rendimento.
  final Map<String, dynamic> recordSummary;

  /// Informações da próxima aula síncrona ou presencial do dia, se houver.
  final Map<String, dynamic>? todayClass;

  /// Grade de horários livres ou períodos sem compromissos letivos.
  final Map<String, dynamic>? freeSchedule;

  /// Lista de disciplinas ativas cursadas no semestre letivo.
  final List<models.DisciplineModel> disciplines;

  /// Coleção de atividades avaliativas e entregas com prazos.
  final List<models.DeliveryItem> deliveries;

  /// Eventos e compromissos mapeados na agenda acadêmica.
  final List<models.CalendarEvent> events;

  /// Mensagens e avisos acadêmicos recebidos pelo discente.
  final List<Map<String, dynamic>> messages;

  /// Anotações e lembretes particulares mantidos pelo estudante.
  final Map<String, dynamic> personalNotes;

  /// Protocolos e requerimentos administrativos em tramitação.
  final List<Map<String, dynamic>> protocols;

  /// Tópicos de discussão em fóruns acadêmicos vinculados às disciplinas.
  final List<Map<String, dynamic>> forumTopics;

  /// Cria uma nova instância imutável do snapshot do dashboard.
  const DashboardSnapshot({
    required this.studentInfo,
    required this.stats,
    required this.recordSummary,
    required this.todayClass,
    required this.freeSchedule,
    required this.disciplines,
    required this.deliveries,
    required this.events,
    required this.messages,
    required this.personalNotes,
    required this.protocols,
    required this.forumTopics,
  });

  /// Instancia [DashboardSnapshot] a partir do mapa JSON retornado pelo endpoint de bootstrap.
  ///
  /// Parâmetros:
  /// - [json]: Mapa contendo a árvore completa de dados do portal.
  ///
  /// Executa:
  /// 1. Extração e validação dos mapas obrigatórios `studentInfo` e `stats`.
  /// 2. Lançamento de [ApiException] caso campos mandatórios estejam ausentes.
  /// 3. Conversão tipada de coleções de disciplinas, entregas e eventos para modelos de domínio.
  ///
  /// Retorna o snapshot inicial estruturado.
  factory DashboardSnapshot.fromJson(Map<String, dynamic> json) {
    final studentInfo = _asMap(json['studentInfo']);
    final stats = _asMap(json['stats']);
    if (studentInfo.isEmpty || stats.isEmpty) {
      throw const ApiException('A API retornou um painel acadêmico incompleto.');
    }

    return DashboardSnapshot(
      studentInfo: studentInfo,
      stats: stats,
      recordSummary: _asMap(json['recordSummary']),
      todayClass: json['todayClass'] is Map
          ? _asMap(json['todayClass'])
          : null,
      freeSchedule: json['freeSchedule'] is Map
          ? _asMap(json['freeSchedule'])
          : null,
      disciplines: _asMaps(json['disciplines'])
          .map(models.DisciplineModel.fromJson)
          .toList(),
      deliveries: _asMaps(json['deliveries'])
          .map(models.DeliveryItem.fromJson)
          .toList(),
      events: _asMaps(json['events'])
          .map(models.CalendarEvent.fromJson)
          .toList(),
      messages: _asMaps(json['messages']),
      personalNotes: _asMap(json['personalNotes']),
      protocols: _asMaps(json['protocols']),
      forumTopics: _asMaps(json['forumTopics']),
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _asMaps(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map(_asMap).toList();
  }
}

/// [PortalRemoteDataSource]
///
/// Fonte de dados remota responsável pela comunicação HTTP autenticada com os
/// endpoints da API do Portal do Aluno (`/api/student/*` e `/api/files/*`).
class PortalRemoteDataSource {
  final AuthenticatedApiClient _api;

  /// Cria o data source remoto com injeção opcional do cliente HTTP autenticado.
  PortalRemoteDataSource({AuthenticatedApiClient? api})
    : _api = api ?? AuthenticatedApiClient();

  /// Obtém o snapshot agregado inicial do portal do aluno via `/api/student/bootstrap`.
  ///
  /// Retorna um [DashboardSnapshot] contendo informações acadêmicas e operacionais.
  Future<DashboardSnapshot> getBootstrap() async {
    final response = await _api.getMap('/api/student/bootstrap');
    return DashboardSnapshot.fromJson(response);
  }

  /// Recupera o histórico do boletim escolar consolidado por períodos letivos.
  ///
  /// Retorna uma lista de [models.BoletimPeriod] com notas, faltas e coeficientes.
  Future<List<models.BoletimPeriod>> getBoletim() async {
    final response = await _api.getList('/api/student/boletim');
    return response.map(models.BoletimPeriod.fromJson).toList();
  }

  /// Emite uma declaração formal de matrícula assinada digitalmente.
  ///
  /// Retorna um mapa contendo os dados do documento gerado e código de validação.
  Future<Map<String, dynamic>> createEnrollmentDeclaration() =>
      _api.postMap('/api/student/enrollment-declaration', const {});

  /// Submete os artefatos de entrega de uma atividade acadêmica para avaliação docente.
  ///
  /// Parâmetros:
  /// - [assignmentId]: Identificador da atividade no sistema acadêmico.
  /// - [fileName]: Nome do arquivo enviado.
  /// - [fileSize]: Tamanho textual do arquivo.
  /// - [mimeType]: Tipo MIME correspondente ao binário.
  /// - [contentBase64]: Conteúdo do arquivo codificado em Base64.
  /// - [gitUrl]: URL opcional para repositório público ou privado no GitHub/GitLab.
  /// - [comments]: Comentários ou anotações explicativas submetidas pelo aluno.
  ///
  /// Retorna a resposta de confirmação de entrega do backend.
  Future<Map<String, dynamic>> submitDelivery({
    required String assignmentId,
    required String fileName,
    required String fileSize,
    required String mimeType,
    required String contentBase64,
    String? gitUrl,
    String? comments,
  }) {
    return _api.postMap('/api/student/deliveries/$assignmentId/submit', {
      'fileName': fileName,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'contentBase64': contentBase64,
      if (gitUrl != null) 'gitUrl': gitUrl,
      if (comments != null) 'comments': comments,
    });
  }

  /// Envia uma dúvida acadêmica associada a uma atividade letiva específica.
  ///
  /// Parâmetros:
  /// - [assignmentId]: Identificador da atividade questionada.
  /// - [question]: Texto da dúvida formulada.
  Future<Map<String, dynamic>> postDoubt({
    required String assignmentId,
    required String question,
  }) {
    return _api.postMap(
      '/api/student/assignments/$assignmentId/doubts',
      {'question': question},
    );
  }

  /// Cria um novo lembrete acadêmico ou compromisso no calendário pessoal do discente.
  ///
  /// Parâmetros:
  /// - [title]: Título descritivo do lembrete.
  /// - [date]: Data de agendamento (AAAA-MM-DD).
  /// - [timeRange]: Faixa de horário do evento.
  /// - [courseCode]: Código da disciplina associada, se aplicável.
  /// - [location]: Local físico ou link da sala virtual.
  Future<Map<String, dynamic>> addReminder({
    required String title,
    required String date,
    required String timeRange,
    required String courseCode,
    required String location,
  }) {
    return _api.postMap('/api/student/calendar/reminders', {
      'title': title,
      'date': date,
      'timeRange': timeRange,
      'courseCode': courseCode,
      'location': location,
    });
  }

  /// Registra um novo protocolo ou requerimento acadêmico na secretaria virtual.
  ///
  /// Parâmetros:
  /// - [requestType]: Categoria do requerimento solicitado.
  /// - [targetComponent]: Componente ou setor acadêmico de destino.
  /// - [justification]: Justificativa circunstanciada do pedido.
  /// - [attachmentName]: Nome do arquivo probatório anexado, se houver.
  /// - [attachmentBase64]: Conteúdo em Base64 do documento comprobatório anexo.
  Future<Map<String, dynamic>> submitProtocol({
    required String requestType,
    required String targetComponent,
    required String justification,
    String? attachmentName,
    String? attachmentBase64,
  }) {
    return _api.postMap('/api/student/protocols', {
      'requestType': requestType,
      'targetComponent': targetComponent,
      'justification': justification,
      if (attachmentName != null) 'attachmentName': attachmentName,
      if (attachmentBase64 != null) 'attachmentBase64': attachmentBase64,
    });
  }

  /// Sinaliza uma mensagem individual do discente como lida no servidor.
  ///
  /// Parâmetros:
  /// - [id]: Identificador da notificação ou comunicado.
  Future<void> markMessageRead(String id) async {
    await _api.patchMap('/api/student/messages/$id/read', const {});
  }

  /// Marca todas as mensagens e comunicados não lidos como lidos de forma atômica.
  Future<void> markAllRead() async {
    await _api.postMap('/api/student/messages/read-all');
  }

  /// Persiste as anotações particulares do estudante associadas a uma disciplina.
  ///
  /// Parâmetros:
  /// - [classCode]: Código identificador da disciplina curricular.
  /// - [content]: Texto contendo as notas pessoais atualizadas.
  Future<void> saveNote({
    required String classCode,
    required String content,
  }) async {
    await _api.putMap('/api/student/disciplines/$classCode/notes', {
      'content': content,
    });
  }

  /// Abre um novo tópico de discussão no fórum de uma turma acadêmica.
  ///
  /// Parâmetros:
  /// - [classCode]: Código da disciplina destinatária.
  /// - [title]: Assunto da discussão.
  /// - [body]: Texto descritivo da postagem inicial.
  /// - [category]: Categoria opcional de classificação.
  Future<Map<String, dynamic>> createForumTopic({
    required String classCode,
    required String title,
    required String body,
    String? category,
  }) {
    return _api.postMap('/api/student/disciplines/$classCode/forum', {
      'title': title,
      'body': body,
      if (category != null) 'category': category,
    });
  }

  /// Envia uma resposta em uma thread de fórum acadêmico existente.
  ///
  /// Parâmetros:
  /// - [classCode]: Código da disciplina correspondente.
  /// - [topicId]: Identificador do tópico que está sendo respondido.
  /// - [body]: Texto da contribuição ou resposta.
  Future<Map<String, dynamic>> replyForumTopic({
    required String classCode,
    required String topicId,
    required String body,
  }) {
    return _api.postMap(
      '/api/student/disciplines/$classCode/forum/$topicId/reply',
      {'body': body},
    );
  }

  /// Realiza o download dos metadados e conteúdo binário de um material pedagógico.
  Future<Map<String, dynamic>> downloadMaterial(String id) =>
      _api.getMap('/api/files/materials/$id');

  /// Baixa o comprovante ou arquivo enviado em uma submissão discente.
  Future<Map<String, dynamic>> downloadSubmission(String id) =>
      _api.getMap('/api/files/submissions/$id');

  /// Faz o download de documentos anexados em requerimentos de protocolo.
  Future<Map<String, dynamic>> downloadProtocol(String id) =>
      _api.getMap('/api/files/protocols/$id');

  /// Recupera o feed ordenado da linha do tempo acadêmica do estudante.
  ///
  /// Retorna um [TimelineResponse] estruturado em blocos cronológicos.
  Future<TimelineResponse> getTimeline() async {
    final response = await _api.getMap('/api/student/timeline');
    return TimelineResponse.fromJson(response);
  }

  /// Decodifica de forma segura a carga Base64 retornada nos endpoints de download de arquivos.
  ///
  /// Parâmetros:
  /// - [response]: Mapa retornado pelo backend contendo o campo `contentBase64`.
  ///
  /// Retorna a sequência bruta de bytes [List<int>] pronta para persistência ou download local.
  List<int> decodeFileContent(Map<String, dynamic> response) {
    final encoded = response['contentBase64']?.toString();
    if (encoded == null || encoded.isEmpty) {
      throw const ApiException('A API não retornou o conteúdo do arquivo.');
    }
    try {
      return base64Decode(encoded);
    } on FormatException {
      throw const ApiException('O conteúdo do arquivo está inválido.');
    }
  }
}

/// [TimelineResponse]
///
/// Modela o pacote de dados cronológicos retornado pela API da linha do tempo.
class TimelineResponse {
  /// Timestamp de geração do relatório no servidor.
  final String generatedAt;

  /// Lista de agrupamentos cronológicos de eventos e tarefas.
  final List<TimelineBlock> blocks;

  /// Cria uma nova instância imutável de [TimelineResponse].
  const TimelineResponse({
    required this.generatedAt,
    required this.blocks,
  });

  /// Desserializa o JSON da linha do tempo em instâncias tipadas de [TimelineBlock].
  factory TimelineResponse.fromJson(Map<String, dynamic> json) {
    final list = json['blocks'] as List? ?? const [];
    return TimelineResponse(
      generatedAt: json['generatedAt']?.toString() ?? '',
      blocks: list
          .whereType<Map>()
          .map((m) => TimelineBlock.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }
}

/// [TimelineItem]
///
/// Representa uma entrada atômica de compromisso, atividade ou entrega na linha do tempo.
class TimelineItem {
  /// Identificador do item cronológico.
  final String id;

  /// Tipo de item (ex.: 'assignment', 'event', 'notice').
  final String kind;

  /// Título sintético do compromisso.
  final String title;

  /// Subtítulo explicativo com detalhes adicionais.
  final String subtitle;

  /// Status indicando se a atividade já foi concluída pelo estudante.
  final bool completed;

  /// Tipo de representação visual do sufixo (ex.: 'badge', 'text').
  final String trailingType;

  /// Texto exibido no sufixo visual da entrada cronológica.
  final String trailingText;

  /// Construtor imutável de [TimelineItem].
  const TimelineItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.completed,
    required this.trailingType,
    required this.trailingText,
  });

  /// Instancia [TimelineItem] extraindo atributos aninhados de formatação de sufixo com segurança.
  factory TimelineItem.fromJson(Map<String, dynamic> json) {
    final trailing = json['trailing'] is Map
        ? Map<String, dynamic>.from(json['trailing'])
        : const <String, dynamic>{};
    return TimelineItem(
      id: json['id']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'assignment',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      completed: json['completed'] == true,
      trailingType: trailing['type']?.toString() ?? 'text',
      trailingText: trailing['text']?.toString() ?? '',
    );
  }
}

/// [TimelineBlock]
///
/// Bloco agrupador cronológico da linha do tempo (ex.: 'Hoje', 'Amanhã', 'Esta Semana').
class TimelineBlock {
  /// Tipo de bloco temporal (ex.: 'day', 'week', 'empty').
  final String type;

  /// Rótulo textual de cabeçalho do bloco temporal.
  final String label;

  /// Coleção de entradas pertencentes a este período.
  final List<TimelineItem> items;

  /// Indica se o bloco exibe o mascote acadêmico com mensagem motivacional.
  final bool mascot;

  /// Mensagem de destaque do mascote ou comunicado do bloco.
  final String message;

  /// Descrição secundária informativa.
  final String description;

  /// Construtor imutável de [TimelineBlock].
  const TimelineBlock({
    required this.type,
    required this.label,
    this.items = const [],
    this.mascot = false,
    this.message = '',
    this.description = '',
  });

  /// Instancia [TimelineBlock] garantindo a conversão de todos os itens associados.
  factory TimelineBlock.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List? ?? const [];
    return TimelineBlock(
      type: json['type']?.toString() ?? 'day',
      label: json['label']?.toString() ?? '',
      items: itemsList
          .whereType<Map>()
          .map((m) => TimelineItem.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      mascot: json['mascot'] == true,
      message: json['message']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}

/// Aliases de compatibilidade retroativa para garantir Zero-Breakage.
typedef StudentDashboardSnapshot = DashboardSnapshot;
typedef StudentRemoteDataSource = PortalRemoteDataSource;
typedef StudentTimelineResponse = TimelineResponse;
typedef StudentTimelineItem = TimelineItem;
typedef StudentTimelineBlock = TimelineBlock;
