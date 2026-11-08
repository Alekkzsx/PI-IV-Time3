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
  List<Map<String, dynamic>> forumTopics(String classCode) {
    final disc = disciplines
        .where(
          (d) =>
              d.code == classCode ||
              d.roomCode == classCode ||
              d.fullCode == classCode,
        )
        .firstOrNull;
    return remoteDashboard?.forumTopics
            .where((topic) {
              final tCode = topic['classCode']?.toString() ?? '';
              return tCode == classCode ||
                  (disc != null &&
                      (tCode == disc.code ||
                          tCode == disc.roomCode ||
                          tCode == disc.fullCode));
            })
            .toList(growable: false) ??
        const [];
  }

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

  /// Verifica se um item didático do checklist da unidade foi marcado como concluído.
  bool isChecklistItemCompleted(String classCode, String itemId) {
    final tracked = completedChecklistIds[classCode];
    if (tracked != null) {
      return tracked.contains(itemId);
    }
    final disc = disciplines.where((d) => d.code == classCode).firstOrNull;
    return disc?.completedChecklistItems.contains(itemId) ?? false;
  }

  /// Alterna o estado de conclusão de um item didático da unidade e sincroniza com o MongoDB.
  Future<void> toggleChecklistItem(String classCode, String itemId) async {
    if (!AppUserSession.instance.hasRole('aluno')) {
      throw const ApiException('Apenas alunos podem atualizar o progresso.');
    }
    final currentSet = completedChecklistIds.putIfAbsent(
      classCode,
      () => Set<String>.from(
        disciplines
                .where((d) => d.code == classCode)
                .firstOrNull
                ?.completedChecklistItems ??
            const <String>[],
      ),
    );
    final nextCompleted = !currentSet.contains(itemId);
    if (nextCompleted) {
      currentSet.add(itemId);
    } else {
      currentSet.remove(itemId);
    }
    notifyListeners();

    try {
      final response = await _remote.setChecklistItem(
        classCode: classCode,
        itemId: itemId,
        completed: nextCompleted,
      );
      final serverList = response['completedChecklistItems'];
      if (serverList is List) {
        completedChecklistIds[classCode] = serverList
            .map((e) => '$e')
            .where((s) => s.isNotEmpty)
            .toSet();
        notifyListeners();
      }
    } catch (_) {
      // Reverte estado otimista em caso de falha na rede
      if (nextCompleted) {
        currentSet.remove(itemId);
      } else {
        currentSet.add(itemId);
      }
      notifyListeners();
      rethrow;
    }
  }

  /// Publica uma mensagem síncrona no canal da turma e atualiza o estado a partir do MongoDB.
  Future<void> sendClassChatMessage(String classCode, String message) async {
    if (!AppUserSession.instance.hasRole('aluno')) {
      throw const ApiException('Apenas alunos podem publicar no chat da turma.');
    }
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      throw const ApiException('Digite uma mensagem antes de enviar.');
    }
    await _remote.postClassChatMessage(classCode: classCode, message: trimmed);
    await loadRemote(force: true);
  }

  /// Envia mensagem institucional e e-mail ao docente titular da disciplina.
  Future<Map<String, dynamic>> contactProfessor({
    required String classCode,
    required String subject,
    required String message,
  }) async {
    if (!AppUserSession.instance.hasRole('aluno')) {
      throw const ApiException('Apenas alunos podem contatar o docente.');
    }
    if (subject.trim().length < 3 || message.trim().length < 5) {
      throw const ApiException('Preencha o assunto e a mensagem detalhada.');
    }
    final res = await _remote.contactProfessor(
      classCode: classCode,
      subject: subject.trim(),
      message: message.trim(),
    );
    await loadRemote(force: true);
    return res;
  }

  /// Registra protocolo oficial de esclarecimento ou revisão de nota na disciplina.
  Future<Map<String, dynamic>> requestGradeClarification({
    required String classCode,
    required String evaluationType,
    required String question,
  }) async {
    if (!AppUserSession.instance.hasRole('aluno')) {
      throw const ApiException('Apenas alunos podem solicitar esclarecimento.');
    }
    if (question.trim().length < 5) {
      throw const ApiException('Descreva o pedido de esclarecimento.');
    }
    final res = await _remote.requestGradeClarification(
      classCode: classCode,
      evaluationType: evaluationType.trim(),
      question: question.trim(),
    );
    await loadRemote(force: true);
    return res;
  }

  /// Atualiza o repositório Git, título ou status de sprint de um Squad da disciplina.
  Future<void> updateSquad({
    required String classCode,
    required String squadId,
    String? repoUrl,
    String? projectTitle,
    String? sprintStatus,
  }) async {
    if (!AppUserSession.instance.hasRole('aluno')) {
      throw const ApiException('Apenas alunos podem atualizar o Squad.');
    }
    await _remote.updateSquad(
      classCode: classCode,
      squadId: squadId,
      repoUrl: repoUrl?.trim(),
      projectTitle: projectTitle?.trim(),
      sprintStatus: sprintStatus?.trim(),
    );
    await loadRemote(force: true);
  }

  /// Calcula a quantidade real de entregas pendentes vinculadas a uma disciplina.
  int pendingDeliveriesCountFor(String classCode) {
    final disc = disciplines.where((d) => d.code == classCode).firstOrNull;
    return deliveries.where((item) {
      final matchesCode =
          item.disciplineCode == classCode ||
          item.disciplineCode == disc?.roomCode ||
          item.disciplineCode == disc?.fullCode;
      return matchesCode && item.status == 'Pendente';
    }).length;
  }

  /// Calcula a quantidade real de tópicos do fórum vinculados a uma disciplina.
  int forumTopicsCountFor(String classCode) {
    final disc = disciplines.where((d) => d.code == classCode).firstOrNull;
    return (remoteDashboard?.forumTopics ?? const []).where((topic) {
      final tCode = topic['classCode']?.toString() ?? '';
      return tCode == classCode ||
          tCode == disc?.roomCode ||
          tCode == disc?.fullCode;
    }).length;
  }

  /// Calcula a quantidade real de materiais publicados para uma disciplina.
  int materialsCountFor(String classCode) {
    final disc = disciplines.where((d) => d.code == classCode).firstOrNull;
    if (disc != null &&
        selectedDiscipline != null &&
        selectedDiscipline!.code == classCode) {
      return selectedDiscipline!.materials.length;
    }
    return disc?.materials.length ?? 0;
  }
}
