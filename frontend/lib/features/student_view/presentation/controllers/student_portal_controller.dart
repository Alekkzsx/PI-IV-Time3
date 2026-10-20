// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import '../../data/student_mock_data.dart';

/// Controlador reativo com estado unificado em memória para o Portal do Aluno.
class StudentPortalController extends ChangeNotifier {
  // Singleton para compartilhamento de estado entre páginas e shell
  static final StudentPortalController instance = StudentPortalController._internal();
  StudentPortalController._internal();
  factory StudentPortalController() => instance;

  // Visualização do Dashboard
  bool isGridView = true;

  // Disciplina selecionada para o Cockpit do AVA
  StudentDisciplineModel selectedDiscipline = StudentMockData.disciplines.first;

  // Calendário
  String calendarViewMode = 'Mês'; // 'Mês' ou 'Agenda'
  final Set<String> activeEventTypes = {'Entrega', 'Aula', 'Fórum', 'Avaliação'};
  final Set<String> activeDisciplineFilters = {'APS-II', 'BD-II', 'FIS', 'FSO'};
  late List<StudentCalendarEvent> events = List.from(StudentMockData.calendarEvents);

  // Entregas
  late List<StudentDeliveryItem> deliveries = List.from(StudentMockData.deliveries);
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
  String studentPersonalNotes = '# Anotações da Aula 14 - Padrão Adapter\n\n- O Adapter converte a interface de uma classe em outra que o cliente espera.\n- Permite que classes com interfaces incompatíveis trabalhem juntas.\n- Exemplo prático: Integração com legado via Wrapper.';

  final List<Map<String, String>> forumTopics = [
    {
      'autor': 'Mariana Rios Costa',
      'tempo': 'Há 2 horas',
      'titulo': 'Dúvida na estrutura de classes do padrão Adapter com herança múltipla',
      'respostas': '2 respostas (Profa. Helena respondeu)',
    },
    {
      'autor': 'Lucas Silva Santos',
      'tempo': 'Ontem',
      'titulo': 'Formato do arquivo de entrega: zip com testes unitários é obrigatório?',
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
    calendarViewMode = mode;
    notifyListeners();
  }

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

  void submitDelivery({
    required String deliveryId,
    required String fileName,
    String? gitUrl,
    String? comments,
  }) {
    final index = deliveries.indexWhere((d) => d.id == deliveryId);
    if (index != -1) {
      final old = deliveries[index];
      deliveries[index] = StudentDeliveryItem(
        id: old.id,
        title: old.title,
        disciplineCode: old.disciplineCode,
        disciplineName: old.disciplineName,
        dueDate: old.dueDate,
        dueHour: old.dueHour,
        status: 'Em Análise',
        weight: old.weight,
        score: null,
        feedback: comments ?? 'Aguardando avaliação docente.',
        protocol: 'AGR-2026-${1000 + deliveries.length}-SUB',
        rubrics: old.rubrics,
      );
      notifyListeners();
    }
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

