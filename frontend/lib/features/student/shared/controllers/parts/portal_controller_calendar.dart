// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

part of '../portal_controller.dart';

/// [_PortalCalendarMixin]
///
/// Mixin de domínio responsável pela navegação temporal, modos de visualização
/// ('Semana', 'Mês', 'Agenda'), filtragem por categoria/disciplina e registro
/// de novos lembretes no calendário acadêmico do discente.
mixin _PortalCalendarMixin on _PortalControllerBase {
  /// Altera o modo de apresentação do calendário ('Semana', 'Mês' ou 'Agenda').
  ///
  /// Parâmetros:
  /// - [mode]: Nome do modo desejado.
  void setCalendarViewMode(String mode) {
    if (!const {'Semana', 'Mês', 'Agenda'}.contains(mode) ||
        calendarViewMode == mode) {
      return;
    }
    calendarViewMode = mode;
    notifyListeners();
  }

  /// Atualiza o dia selecionado no calendário acadêmico.
  ///
  /// Parâmetros:
  /// - [date]: Instância de [DateTime] correspondente à nova data de foco.
  void setCalendarFocusedDate(DateTime date) {
    calendarFocusedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  /// Desloca o foco do calendário temporalmente de acordo com a visualização ativa.
  ///
  /// Parâmetros:
  /// - [amount]: Quantidade de unidades (meses, semanas ou dias) para avançar (+) ou recuar (-).
  void shiftCalendarFocus(int amount) {
    if (calendarViewMode == 'Mês') {
      calendarFocusedDate = DateTime(
        calendarFocusedDate.year,
        calendarFocusedDate.month + amount,
        1,
      );
    } else if (calendarViewMode == 'Semana') {
      calendarFocusedDate = calendarFocusedDate.add(Duration(days: amount * 7));
    } else {
      calendarFocusedDate = calendarFocusedDate.add(Duration(days: amount));
    }
    notifyListeners();
  }

  /// Desloca o mês do calendário pelo número de meses especificado.
  void shiftCalendarMonth(int amount) {
    calendarFocusedDate = DateTime(
      calendarFocusedDate.year,
      calendarFocusedDate.month + amount,
      1,
    );
    notifyListeners();
  }

  /// Redefine a data de foco do calendário acadêmico para o dia corrente.
  void goToCalendarToday() {
    setCalendarFocusedDate(DateTime.now());
  }

  /// Retorna a lista de eventos visíveis após a aplicação dos filtros de tipo e disciplina.
  List<StudentCalendarEvent> get visibleCalendarEvents => events.where((event) {
    return activeEventTypes.contains(event.type) &&
        (activeDisciplineFilters.isEmpty ||
            activeDisciplineFilters.contains(event.discipline));
  }).toList();

  /// Alterna o filtro de exibição para uma categoria de evento específica no calendário.
  void toggleEventTypeFilter(String type) {
    if (activeEventTypes.contains(type)) {
      if (activeEventTypes.length > 1) {
        activeEventTypes.remove(type);
      }
    } else {
      activeEventTypes.add(type);
    }
    notifyListeners();
  }

  /// Alterna o filtro de exibição de eventos para uma disciplina específica.
  void toggleDisciplineFilter(String code) {
    if (activeDisciplineFilters.contains(code)) {
      if (activeDisciplineFilters.length > 1) {
        activeDisciplineFilters.remove(code);
      }
    } else {
      activeDisciplineFilters.add(code);
    }
    notifyListeners();
  }

  /// Registra um novo lembrete acadêmico ou compromisso no calendário.
  ///
  /// Parâmetros:
  /// - [title]: Título descritivo do evento.
  /// - [date]: Data formatada (AAAA-MM-DD).
  /// - [time]: Faixa horária da atividade.
  /// - [type]: Categoria do compromisso.
  /// - [discipline]: Código da disciplina vinculada.
  /// - [location]: Local de realização (sala ou link virtual).
  Future<void> addCalendarEvent({
    required String title,
    required String date,
    required String time,
    required String type,
    required String discipline,
    required String location,
  }) async {
    if (!AppUserSession.instance.hasRole('aluno')) {
      throw const ApiException('Apenas alunos podem criar lembretes pessoais.');
    }
    await _remote.addReminder(
      title: title,
      date: date,
      timeRange: time,
      courseCode: discipline,
      location: location,
    );
    await loadRemote(force: true);
  }
}
