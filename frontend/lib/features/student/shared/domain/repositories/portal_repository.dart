// Desenvolvido por Murillo Caravita - RA: 25014012

import '../../models/models.dart';

/// [IPortalRepository]
///
/// Contrato abstrato da camada de domínio que dita os métodos de obtenção e persistência
/// de dados acadêmicos do discente, isolando os controladores das implementações de rede.
abstract class IPortalRepository {
  /// Obtém a listagem completa de disciplinas nas quais o aluno está matriculado.
  Future<List<StudentDisciplineModel>> getDisciplines();

  /// Recupera todos os eventos acadêmicos, aulas e compromissos do calendário discente.
  Future<List<StudentCalendarEvent>> getCalendarEvents();

  /// Busca as entregas e tarefas pendentes ou já avaliadas vinculadas ao discente.
  Future<List<StudentDeliveryItem>> getDeliveries();

  /// Recupera os tópicos ativos de fóruns acadêmicos e grupos de discussão.
  Future<List<Map<String, String>>> getForumTopics();

  /// Obtém o bloco de anotações pessoais do aluno mantido na nuvem.
  Future<String> getPersonalNotes();

  /// Persiste as anotações textuais do aluno no servidor acadêmico.
  ///
  /// Parâmetros:
  /// - [notes]: Conteúdo em texto plano das anotações.
  Future<void> savePersonalNotes(String notes);

  /// Submete uma entrega de trabalho acadêmico vinculada a uma atividade.
  ///
  /// Parâmetros:
  /// - [deliveryId]: Identificador único da atividade/entrega.
  /// - [fileName]: Nome do arquivo digital anexado.
  /// - [gitUrl]: URL opcional para repositório Git de código-fonte.
  /// - [comments]: Observações adicionais do aluno destinadas ao docente avaliador.
  Future<void> submitDelivery({
    required String deliveryId,
    required String fileName,
    String? gitUrl,
    String? comments,
  });
}

/// Alias de compatibilidade retroativa para garantir Zero-Breakage.
typedef IStudentRepository = IPortalRepository;
