// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

part of '../portal_controller.dart';

/// [_PortalAvaMixin]
///
/// Mixin de domínio responsável pela gestão de estado do Cockpit AVA:
/// seleção de disciplina, navegação entre as 11 abas, tópicos e respostas de fórum,
/// envio de dúvidas sobre avaliações, consulta de boletim e persistência de anotações.
mixin _PortalAvaMixin on _PortalControllerBase {
  /// Consulta os períodos e notas do boletim escolar acadêmico.
  ///
  /// Executa:
  /// 1. Validação do papel de discente em [AppUserSession].
  /// 2. Chamada à fonte remota para obtenção dos dados do boletim.
  ///
  /// Retorna lista de [StudentBoletimPeriod] com os desempenhos semestrais.
  Future<List<StudentBoletimPeriod>> loadBoletim() async {
    if (!AppUserSession.instance.hasRole('aluno')) {
      throw const ApiException('Apenas alunos podem consultar o boletim.');
    }
    return _remote.getBoletim();
  }

  /// Filtra os tópicos de fórum vinculados a uma disciplina específica (formato bruto).
  ///
  /// Parâmetros:
  /// - [classCode]: Código identificador da turma.
  ///
  /// Retorna a lista de tópicos filtrados.
  List<Map<String, dynamic>> forumTopics(String classCode) =>
      remoteDashboard?.forumTopics
          .where((topic) => topic['classCode']?.toString() == classCode)
          .toList(growable: false) ??
      const [];

  /// Retorna os tópicos do fórum fortemente tipados como [StudentForumTopic].
  ///
  /// Parâmetros:
  /// - [classCode]: Código identificador da turma.
  List<StudentForumTopic> typedForumTopics(String classCode) =>
      forumTopics(classCode).map(StudentForumTopic.fromJson).toList(growable: false);

  /// Envia uma dúvida acadêmica referente a uma atividade avaliativa.
  ///
  /// Parâmetros:
  /// - [assignmentId]: Identificador da atividade.
  /// - [question]: Texto da dúvida a ser enviada ao professor.
  Future<void> postDoubt({
    required String assignmentId,
    required String question,
  }) async {
    if (!AppUserSession.instance.hasRole('aluno')) {
      throw const ApiException('Apenas alunos podem enviar dúvidas.');
    }
    if (question.trim().length < 2) {
      throw const ApiException('Escreva uma dúvida antes de enviar.');
    }
    await _remote.postDoubt(
      assignmentId: assignmentId,
      question: question.trim(),
    );
    await loadRemote(force: true);
  }

  /// Cria um novo tópico de discussão no fórum de uma disciplina.
  ///
  /// Parâmetros:
  /// - [classCode]: Código da disciplina.
  /// - [title]: Título do tópico.
  /// - [body]: Conteúdo descritivo da postagem inicial.
  /// - [category]: Categoria opcional do tópico.
  Future<void> createForumTopic({
    required String classCode,
    required String title,
    required String body,
    String? category,
  }) async {
    if (!AppUserSession.instance.hasPermission('participate_course_forum')) {
      throw const ApiException('Seu perfil não pode participar deste fórum.');
    }
    await _remote.createForumTopic(
      classCode: classCode,
      title: title.trim(),
      body: body.trim(),
      category: category,
    );
    await loadRemote(force: true);
  }

  /// Responde a um tópico pré-existente no fórum acadêmico.
  ///
  /// Parâmetros:
  /// - [classCode]: Código da disciplina.
  /// - [topicId]: Identificador da discussão em andamento.
  /// - [body]: Texto da contribuição ou resposta.
  Future<void> replyForumTopic({
    required String classCode,
    required String topicId,
    required String body,
  }) async {
    if (!AppUserSession.instance.hasPermission('participate_course_forum')) {
      throw const ApiException('Seu perfil não pode participar deste fórum.');
    }
    await _remote.replyForumTopic(
      classCode: classCode,
      topicId: topicId,
      body: body.trim(),
    );
    await loadRemote(force: true);
  }

  /// Define a disciplina em foco no cockpit do AVA e sincroniza suas anotações pessoais.
  ///
  /// Parâmetros:
  /// - [discipline]: Modelo da disciplina selecionada pelo estudante.
  void selectDiscipline(StudentDisciplineModel discipline) {
    selectedDiscipline = discipline;
    studentPersonalNotes =
        remoteDashboard?.personalNotes[discipline.code]?.toString() ?? '';
    notifyListeners();
  }

  /// Define a aba ativa no cockpit do Ambiente Virtual de Aprendizagem (AVA).
  ///
  /// Parâmetros:
  /// - [index]: Índice da aba do cockpit (0 a 10).
  void setAvaTab(int index) {
    activeAvaTabIndex = index;
    notifyListeners();
  }

  /// Persiste as anotações particulares do aluno vinculadas à disciplina selecionada.
  ///
  /// Parâmetros:
  /// - [text]: Novo conteúdo textual das anotações.
  Future<void> updatePersonalNotes(String text) async {
    if (!AppUserSession.instance.hasRole('aluno')) {
      throw const ApiException('Apenas alunos podem salvar anotações.');
    }
    final classCode = selectedDiscipline?.code;
    if (classCode == null || classCode.isEmpty) {
      throw const ApiException('Selecione uma disciplina para salvar.');
    }
    await _remote.saveNote(classCode: classCode, content: text);
    await loadRemote(force: true);
  }
}
