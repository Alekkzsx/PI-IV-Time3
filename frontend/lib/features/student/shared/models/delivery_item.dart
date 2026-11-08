// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/foundation.dart';
import 'doubt_item.dart';

/// Entidade de domínio imutável que representa uma atividade avaliativa ou entrega discente.
///
/// Encapsula todo o ciclo de vida de uma submissão acadêmica: dados da tarefa, prazos regimentais,
/// status de correção, critérios de avaliação (rubricas), metadados criptográficos SHA-256 de integridade,
/// anexos de arquivos, repositórios Git vinculados e canal de dúvidas pedagógicas com o docente.
@immutable
class DeliveryItem {
  /// Identificador único universal da entrega discente.
  final String id;

  /// Identificador de origem da atividade avaliativa vinculada no AVA.
  final String? sourceAssignmentId;

  /// Título descritivo da atividade acadêmica ou projeto integrador.
  final String title;

  /// Código de catálogo da disciplina (ex: "MAT101", "PI4").
  final String disciplineCode;

  /// Nome por extenso da disciplina correspondente.
  final String disciplineName;

  /// Data limite regimental para entrega no formato `AAAA-MM-DD`.
  final String dueDate;

  /// Horário limite regimental de envio (ex: "23:59").
  final String dueHour;

  /// Estado atual da entrega: `'Pendente'`, `'Em Análise'` ou `'Avaliada'`.
  final String status;

  /// Peso ponderado da atividade na composição da nota final do módulo.
  final double weight;

  /// Nota atribuída pelo docente após a correção, ou `null` quando ainda não avaliada.
  final double? score;

  /// Parecer pedagógico detalhado ou justificativa qualitativa da avaliação do professor.
  final String? feedback;

  /// Número de protocolo acadêmico gerado no ato de confirmação da submissão.
  final String? protocol;

  /// Hash criptográfico SHA-256 do arquivo entregue para garantia de integridade e não-repúdio.
  final String? sha256;

  /// Nome físico do arquivo submetido pelo estudante (ex: "relatorio_final.pdf").
  final String? fileName;

  /// Tamanho formatado do arquivo enviado (ex: "2.4 MB").
  final String? fileSize;

  /// URL de repositório remoto homologado (GitHub, GitLab, PUC) vinculado ao código-fonte.
  final String? gitUrl;

  /// Comentários e observações técnicas adicionais informadas pelo aluno na entrega.
  final String? comments;

  /// Identificador do registro de submissão persistido no servidor backend.
  final String? submissionId;

  /// Rubricas e critérios de avaliação matriciais definidos pelo plano de ensino.
  final List<Map<String, dynamic>> rubrics;

  /// Histórico de dúvidas e esclarecimentos trocados com o corpo docente sobre a atividade.
  final List<DoubtItem> doubts;

  /// Código interno de rastreamento da atividade no plano da disciplina.
  final String? activityCode;

  /// Enunciado completo, orientações de execução e requisitos da tarefa.
  final String? description;

  /// Nome do docente responsável pela publicação e avaliação da atividade.
  final String? professor;

  /// Rótulo visual de urgência temporal (ex: "Vence hoje", "Prazo expirado").
  final String? deadlineBadge;

  /// Tag temática do módulo ou unidade de aprendizagem correspondente.
  final String? moduleTag;

  /// Sinaliza se a entrega está na janela crítica de encerramento de prazo.
  final bool isUrgent;

  /// Extensões e formatos permitidos pelo edital da atividade (ex: "PDF, ZIP").
  final String? allowedFormats;

  /// Data e hora exatas do envio efetivado pelo estudante.
  final String? submissionDate;

  /// Data e hora da publicação da devolutiva pelo docente.
  final String? feedbackDate;

  /// Pontuação máxima atingível na avaliação (ex: 10.0).
  final double maxScore;

  /// Quantidade de arquivos anexados à submissão.
  final int attachmentCount;

  /// Cria uma nova instância imutável de [DeliveryItem].
  const DeliveryItem({
    required this.id,
    this.sourceAssignmentId,
    required this.title,
    required this.disciplineCode,
    required this.disciplineName,
    required this.dueDate,
    required this.dueHour,
    required this.status,
    required this.weight,
    this.score,
    this.feedback,
    this.protocol,
    this.sha256,
    this.fileName,
    this.fileSize,
    this.gitUrl,
    this.comments,
    this.submissionId,
    this.rubrics = const [],
    this.doubts = const [],
    this.activityCode,
    this.description,
    this.professor,
    this.deadlineBadge,
    this.moduleTag,
    this.isUrgent = false,
    this.allowedFormats,
    this.submissionDate,
    this.feedbackDate,
    this.maxScore = 0,
    this.attachmentCount = 0,
  });

  /// Constrói um [DeliveryItem] a partir de um mapa de dados serializado da API REST.
  ///
  /// Parâmetros:
  /// - [json]: Mapa JSON contendo todos os atributos da atividade e da submissão.
  ///
  /// Executa:
  /// 1. Extração segura de identificadores e títulos com fallbacks defensivos.
  /// 2. Conversão numérica de pesos e notas para [double].
  /// 3. Desserialização da lista de dúvidas associadas em objetos [DoubtItem].
  /// 4. Parsing das rubricas em mapas estruturados.
  ///
  /// Retorna a entidade [DeliveryItem] populada e consistente.
  factory DeliveryItem.fromJson(Map<String, dynamic> json) {
    final rawRubrics = json['rubrics'];
    final rawDoubts = json['doubts'];
    return DeliveryItem(
      id: json['id']?.toString() ?? '',
      sourceAssignmentId:
          json['sourceAssignmentId']?.toString() ?? json['id']?.toString(),
      title: json['title']?.toString() ?? '',
      disciplineCode: json['disciplineCode']?.toString() ?? '',
      disciplineName: json['disciplineName']?.toString() ?? '',
      dueDate: json['dueDate']?.toString() ?? '',
      dueHour: json['dueHour']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      weight: json['weight'] is num ? (json['weight'] as num).toDouble() : 0,
      score: json['score'] is num ? (json['score'] as num).toDouble() : null,
      feedback: json['feedback']?.toString(),
      protocol: json['protocol']?.toString(),
      sha256: json['sha256']?.toString(),
      fileName: json['fileName']?.toString(),
      fileSize: json['fileSize']?.toString(),
      gitUrl: json['gitUrl']?.toString(),
      comments: json['comments']?.toString(),
      submissionId: json['submissionId']?.toString(),
      rubrics: rawRubrics is List
          ? rawRubrics
                .whereType<Map>()
                .map((r) => Map<String, dynamic>.from(r))
                .toList()
          : const [],
      doubts: rawDoubts is List
          ? rawDoubts
                .whereType<Map>()
                .map(
                  (d) =>
                      DoubtItem.fromJson(Map<String, dynamic>.from(d)),
                )
                .toList()
          : const [],
      activityCode: json['activityCode']?.toString(),
      description: json['description']?.toString(),
      professor: json['professor']?.toString(),
      deadlineBadge: json['deadlineBadge']?.toString(),
      moduleTag: json['moduleTag']?.toString(),
      isUrgent: json['isUrgent'] == true,
      allowedFormats: json['allowedFormats']?.toString(),
      submissionDate: json['submissionDate']?.toString(),
      feedbackDate: json['feedbackDate']?.toString(),
      maxScore: json['maxScore'] is num
          ? (json['maxScore'] as num).toDouble()
          : 0.0,
      attachmentCount: json['attachmentCount'] is num
          ? (json['attachmentCount'] as num).toInt()
          : 0,
    );
  }
}

/// Alias de tipo retrocompatível para testes automatizados existentes.
typedef StudentDeliveryItem = DeliveryItem;
