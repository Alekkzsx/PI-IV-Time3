// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student/shell/presentation/models/student_nav_item.dart';
import '../data/student_mock_data.dart';

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// Controlador reativo com estado unificado em memória para o Portal do Aluno.
class StudentPortalController extends ChangeNotifier {
  // Singleton para compartilhamento de estado entre páginas e shell
  static final StudentPortalController instance =
      StudentPortalController._internal();
  StudentPortalController._internal();
  factory StudentPortalController() => instance;

  // Navegação Ativa
  StudentNavItem activeNavItem = StudentNavItem.painelGeral;

  void setNavItem(StudentNavItem item) {
    if (activeNavItem != item) {
      activeNavItem = item;
      notifyListeners();
    }
  }

  // Visualização do Dashboard
  bool isGridView = true;

  // Disciplina selecionada para o Cockpit do AVA
  StudentDisciplineModel selectedDiscipline = StudentMockData.disciplines.first;

  // Calendário
  String calendarViewMode = 'Mês'; // 'Mês' ou 'Agenda'
  DateTime calendarFocusedDate = _today();
  final Set<String> activeEventTypes = {
    'Entrega',
    'Aula',
    'Fórum',
    'Avaliação',
  };
  final Set<String> activeDisciplineFilters = {'APS-II', 'BD-II', 'FIS', 'FSO'};
  late List<StudentCalendarEvent> events = List.from(
    StudentMockData.calendarEvents,
  );

  // Entregas
  late List<StudentDeliveryItem> deliveries = List.from(
    StudentMockData.deliveries,
  );
  String activeDeliveryFilter = 'Todas';

  // Configurações
  int selectedSettingsTabIndex = 0;
  bool isTwoFactorEnabled = true;
  bool emailNotifications = true;
  bool pushNotifications = true;
  bool smsNotifications = false;

  // Cockpit do AVA
  int activeAvaTabIndex = 0;
  int currentSlideIndex = 14;
  final int totalSlides = 28;
  bool isMicMuted = true;
  bool isCameraOff = true;
  bool isHandRaised = false;
  String studentPersonalNotes =
      '# Anotações da Aula 14 - Padrão Adapter\n\n- O Adapter converte a interface de uma classe em outra que o cliente espera.\n- Permite que classes com interfaces incompatíveis trabalhem juntas.\n- Exemplo prático: Integração com legado via Wrapper.';

  final List<Map<String, String>> forumTopics = [
    {
      'autor': 'Mariana Rios Costa',
      'tempo': 'Há 2 horas',
      'titulo':
          'Dúvida na estrutura de classes do padrão Adapter com herança múltipla',
      'respostas': '2 respostas (Profa. Helena respondeu)',
    },
    {
      'autor': 'Lucas Silva Santos',
      'tempo': 'Ontem',
      'titulo':
          'Formato do arquivo de entrega: zip com testes unitários é obrigatório?',
      'respostas': '1 resposta (Monitor Victor respondeu)',
    },
  ];

  // Métodos de Modificação de Estado

  void toggleDashboardView(bool grid) {
    if (isGridView != grid) {
      isGridView = grid;
      notifyListeners();
    }
  }

  void selectDiscipline(StudentDisciplineModel discipline) {
    selectedDiscipline = discipline;
    notifyListeners();
  }

  void setCalendarViewMode(String mode) {
    if (!const {'Semana', 'Mês', 'Agenda'}.contains(mode) ||
        calendarViewMode == mode) {
      return;
    }
    calendarViewMode = mode;
    notifyListeners();
  }

  void setCalendarFocusedDate(DateTime date) {
    calendarFocusedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

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

  void shiftCalendarMonth(int amount) {
    calendarFocusedDate = DateTime(
      calendarFocusedDate.year,
      calendarFocusedDate.month + amount,
      1,
    );
    notifyListeners();
  }

  void goToCalendarToday() {
    setCalendarFocusedDate(DateTime.now());
  }

  List<StudentCalendarEvent> get visibleCalendarEvents => events.where((event) {
    return activeEventTypes.contains(event.type) &&
        activeDisciplineFilters.contains(event.discipline);
  }).toList();

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

  void addCalendarEvent({
    required String title,
    required String date,
    required String time,
    required String type,
    required String discipline,
    required String location,
  }) {
    events.insert(
      0,
      StudentCalendarEvent(
        id: 'EV-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        date: date,
        time: time,
        type: type,
        discipline: discipline,
        location: location,
      ),
    );
    notifyListeners();
  }

  void setDeliveryFilter(String filter) {
    activeDeliveryFilter = filter;
    notifyListeners();
  }

  String submitDelivery({
    required String deliveryId,
    required String fileName,
    String? gitUrl,
    String? comments,
  }) {
    final index = deliveries.indexWhere((d) => d.id == deliveryId);
    if (index != -1) {
      final old = deliveries[index];
      final now = DateTime.now();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      final randomSuffix = (1000 + (now.millisecondsSinceEpoch % 9000))
          .toString();
      final generatedProtocol =
          'AGR-${now.year}-${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$randomSuffix';

      deliveries[index] = StudentDeliveryItem(
        id: old.id,
        activityCode: old.activityCode,
        title: old.title,
        disciplineCode: old.disciplineCode,
        disciplineName: old.disciplineName,
        description: old.description,
        dueDate: old.dueDate,
        dueHour: old.dueHour,
        deadlineBadge: 'Enviada hoje',
        isUrgent: false,
        professor: old.professor,
        allowedFormats: old.allowedFormats,
        submissionDate: dateStr,
        status: 'Em Análise',
        weight: old.weight,
        maxScore: old.maxScore,
        score: null,
        feedback: comments ?? 'Aguardando avaliação docente.',
        protocol: generatedProtocol,
        attachmentCount: 1,
        rubrics: old.rubrics,
      );
      notifyListeners();
      return generatedProtocol;
    }
    return 'AGR-2026-SUB';
  }

  String get settingsSubtab {
    switch (selectedSettingsTabIndex) {
      case 0:
        return 'perfil';
      case 1:
        return 'seguranca';
      case 2:
        return 'notificacoes';
      case 3:
        return 'preferencias';
      case 4:
        return 'privacidade';
      default:
        return 'perfil';
    }
  }

  void setSettingsSubtab(String key) {
    switch (key) {
      case 'perfil':
        selectedSettingsTabIndex = 0;
        break;
      case 'seguranca':
        selectedSettingsTabIndex = 1;
        break;
      case 'notificacoes':
        selectedSettingsTabIndex = 2;
        break;
      case 'preferencias':
        selectedSettingsTabIndex = 3;
        break;
      case 'privacidade':
        selectedSettingsTabIndex = 4;
        break;
      default:
        selectedSettingsTabIndex = 0;
    }
    notifyListeners();
  }

  void setSettingsTab(int index) {
    selectedSettingsTabIndex = index;
    notifyListeners();
  }

  void toggleTwoFactor() {
    isTwoFactorEnabled = !isTwoFactorEnabled;
    notifyListeners();
  }

  void setAvaTab(int index) {
    activeAvaTabIndex = index;
    notifyListeners();
  }

  void toggleMic() {
    isMicMuted = !isMicMuted;
    notifyListeners();
  }

  void toggleCamera() {
    isCameraOff = !isCameraOff;
    notifyListeners();
  }

  void toggleHandRaise() {
    isHandRaised = !isHandRaised;
    notifyListeners();
  }

  void nextSlide() {
    if (currentSlideIndex < totalSlides) {
      currentSlideIndex++;
      notifyListeners();
    }
  }

  void prevSlide() {
    if (currentSlideIndex > 1) {
      currentSlideIndex--;
      notifyListeners();
    }
  }

  void postForumTopic(String title, String description) {
    forumTopics.insert(0, {
      'autor': StudentMockData.studentName,
      'tempo': 'Agora mesmo',
      'titulo': title,
      'respostas': '0 respostas (Aguardando monitoria)',
    });
    notifyListeners();
  }

  void updatePersonalNotes(String text) {
    studentPersonalNotes = text;
    notifyListeners();
  }
}
