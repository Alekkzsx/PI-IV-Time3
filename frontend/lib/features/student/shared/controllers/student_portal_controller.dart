// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/core/state/academic_bridge_service.dart';
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
  StudentPortalController._internal() {
    _initAcademicBridgeListener();
  }
  factory StudentPortalController() => instance;

  // Disciplinas do Aluno (mutáveis para recálculo de notas e presenças)
  late List<StudentDisciplineModel> disciplines = List.from(
    StudentMockData.disciplines,
  );

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
    if (!AppUserSession.instance.hasPermission('manage_personal_calendar')) {
      return;
    }
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

  void _initAcademicBridgeListener() {
    AcademicBridgeService.instance.onStudentDataChanged = () {
      notifyListeners();
    };

    AcademicBridgeService.instance.onAssignmentPublishedToStudent =
        (delivery, event) {
          deliveries.insert(0, delivery);
          events.insert(0, event);

          final discIdx = disciplines.indexWhere(
            (d) => d.code == delivery.disciplineCode,
          );
          if (discIdx != -1) {
            final oldDisc = disciplines[discIdx];
            disciplines[discIdx] = StudentDisciplineModel(
              code: oldDisc.code,
              fullCode: oldDisc.fullCode,
              name: oldDisc.name,
              professor: oldDisc.professor,
              time: oldDisc.time,
              location: oldDisc.location,
              progress: oldDisc.progress,
              n1: oldDisc.n1,
              n2: oldDisc.n2,
              p1: oldDisc.p1,
              p2: oldDisc.p2,
              trab: oldDisc.trab,
              partialAverage: oldDisc.partialAverage,
              attendancePercentage: oldDisc.attendancePercentage,
              absences: oldDisc.absences,
              totalHours: oldDisc.totalHours,
              completedHours: oldDisc.completedHours,
              maxAbsenceHours: oldDisc.maxAbsenceHours,
              hasPendingTask: true,
            );
          }
          notifyListeners();
        };

    AcademicBridgeService.instance.onGradedReceivedByStudent =
        (deliveryId, finalScore, feedback, rubrics) {
          final idx = deliveries.indexWhere((d) => d.id == deliveryId);
          if (idx != -1) {
            final old = deliveries[idx];
            deliveries[idx] = StudentDeliveryItem(
              id: old.id,
              sourceAssignmentId: old.sourceAssignmentId,
              activityCode: old.activityCode,
              title: old.title,
              disciplineCode: old.disciplineCode,
              disciplineName: old.disciplineName,
              description: old.description,
              dueDate: old.dueDate,
              dueHour: old.dueHour,
              deadlineBadge: 'Corrigida • Nota Homologada',
              isUrgent: false,
              professor: old.professor,
              allowedFormats: old.allowedFormats,
              submissionDate: old.submissionDate,
              status: 'Avaliada',
              weight: old.weight,
              maxScore: old.maxScore,
              score: finalScore,
              feedback: feedback,
              protocol: old.protocol,
              attachmentCount: old.attachmentCount,
              rubrics: rubrics
                  .map(
                    (r) => {
                      'id': r.id,
                      'title': r.title,
                      'maxPoints': r.maxPoints,
                      'assignedScore': r.assignedScore,
                      'description': r.description,
                    },
                  )
                  .toList(),
            );

            final discIdx = disciplines.indexWhere(
              (d) => d.code == old.disciplineCode,
            );
            if (discIdx != -1) {
              final oldDisc = disciplines[discIdx];
              final newAverage = double.parse(
                ((finalScore * 0.4 + oldDisc.p2 * 0.4 + oldDisc.trab * 0.2))
                    .toStringAsFixed(1),
              );
              disciplines[discIdx] = StudentDisciplineModel(
                code: oldDisc.code,
                fullCode: oldDisc.fullCode,
                name: oldDisc.name,
                professor: oldDisc.professor,
                time: oldDisc.time,
                location: oldDisc.location,
                progress: oldDisc.progress,
                n1: finalScore,
                n2: oldDisc.n2,
                p1: finalScore,
                p2: oldDisc.p2,
                trab: oldDisc.trab,
                partialAverage: newAverage,
                attendancePercentage: oldDisc.attendancePercentage,
                absences: oldDisc.absences,
                totalHours: oldDisc.totalHours,
                completedHours: oldDisc.completedHours,
                maxAbsenceHours: oldDisc.maxAbsenceHours,
                hasPendingTask: false,
              );
            }
            notifyListeners();
          }
        };

    AcademicBridgeService
        .instance
        .onAttendanceHomologated = (courseCode, sessionDate, attendances) {
      final discIdx = disciplines.indexWhere(
        (d) =>
            d.code.toUpperCase() == courseCode.toUpperCase() ||
            (d.fullCode != null &&
                d.fullCode!.toUpperCase().contains(courseCode.toUpperCase())),
      );

      if (discIdx != -1) {
        final oldDisc = disciplines[discIdx];
        Map<String, dynamic>? myRecord;
        for (final a in attendances) {
          if (a['ra'] == '24802449' ||
              a['studentName']?.toString().toLowerCase().contains('alex') ==
                  true) {
            myRecord = a;
            break;
          }
        }
        myRecord ??= attendances.isNotEmpty ? attendances.first : null;
        if (myRecord == null) return;

        final status = myRecord['status'] as String? ?? 'presente';
        int newAbsences = oldDisc.absences;
        int newCompletedHours = oldDisc.completedHours + 2;

        if (status == 'ausente') {
          newAbsences += 2;
        }

        final rate =
            ((newCompletedHours - newAbsences) / newCompletedHours * 100).clamp(
              0.0,
              100.0,
            );
        final newAttendancePercentage = double.parse(rate.toStringAsFixed(1));

        disciplines[discIdx] = StudentDisciplineModel(
          code: oldDisc.code,
          fullCode: oldDisc.fullCode,
          name: oldDisc.name,
          professor: oldDisc.professor,
          time: oldDisc.time,
          location: oldDisc.location,
          progress: (newCompletedHours / oldDisc.totalHours).clamp(0.0, 1.0),
          n1: oldDisc.n1,
          n2: oldDisc.n2,
          p1: oldDisc.p1,
          p2: oldDisc.p2,
          trab: oldDisc.trab,
          partialAverage: oldDisc.partialAverage,
          attendancePercentage: newAttendancePercentage,
          absences: newAbsences,
          totalHours: oldDisc.totalHours,
          completedHours: newCompletedHours,
          maxAbsenceHours: oldDisc.maxAbsenceHours,
          hasPendingTask: oldDisc.hasPendingTask,
        );

        if (selectedDiscipline.code == oldDisc.code) {
          selectedDiscipline = disciplines[discIdx];
        }

        notifyListeners();
      }
    };

    AcademicBridgeService.instance.onStudentProtocolUpdated =
        (protocolCode, isApproved, decisionNote, approverName) {
          if (isApproved &&
              (protocolCode.contains('MED') ||
                  decisionNote.toLowerCase().contains('abono') ||
                  decisionNote.toLowerCase().contains('falta') ||
                  decisionNote.toLowerCase().contains('atestado'))) {
            final discIdx = disciplines.indexWhere((d) => d.code == 'APS-II');
            if (discIdx != -1) {
              final oldDisc = disciplines[discIdx];
              final newAbsences = (oldDisc.absences - 2).clamp(0, 100);
              final rate =
                  ((oldDisc.completedHours - newAbsences) /
                          oldDisc.completedHours *
                          100)
                      .clamp(0.0, 100.0);
              disciplines[discIdx] = StudentDisciplineModel(
                code: oldDisc.code,
                fullCode: oldDisc.fullCode,
                name: oldDisc.name,
                professor: oldDisc.professor,
                time: oldDisc.time,
                location: oldDisc.location,
                progress: oldDisc.progress,
                n1: oldDisc.n1,
                n2: oldDisc.n2,
                p1: oldDisc.p1,
                p2: oldDisc.p2,
                trab: oldDisc.trab,
                partialAverage: oldDisc.partialAverage,
                attendancePercentage: double.parse(rate.toStringAsFixed(1)),
                absences: newAbsences,
                totalHours: oldDisc.totalHours,
                completedHours: oldDisc.completedHours,
                maxAbsenceHours: oldDisc.maxAbsenceHours,
                hasPendingTask: oldDisc.hasPendingTask,
              );
              if (selectedDiscipline.code == oldDisc.code) {
                selectedDiscipline = disciplines[discIdx];
              }
              notifyListeners();
            }
          }
        };
  }

  String submitDelivery({
    required String deliveryId,
    required String fileName,
    String? gitUrl,
    String? comments,
  }) {
    if (!AppUserSession.instance.hasPermission('submit_assignments')) {
      debugPrint('[StudentPortal] Submissão negada para o perfil atual.');
      return '';
    }
    final index = deliveries.indexWhere((d) => d.id == deliveryId);
    if (index != -1) {
      final old = deliveries[index];
      if (old.status != 'Pendente') {
        debugPrint(
          '[StudentPortal] Submissão recusada: a atividade não está pendente.',
        );
        return '';
      }
      final now = DateTime.now();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      final randomSuffix = (1000 + (now.millisecondsSinceEpoch % 9000))
          .toString();
      final generatedProtocol =
          'AGR-${now.year}-${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$randomSuffix';

      final accepted = AcademicBridgeService.instance.notifySubmissionToDocente(
        deliveryId: deliveryId,
        assignmentId: old.sourceAssignmentId ?? old.id,
        courseCode: old.disciplineCode,
        studentName: StudentMockData.studentName,
        studentRa: StudentMockData.studentRa,
        fileName: fileName,
        protocol: generatedProtocol,
        comments: comments,
      );
      if (!accepted) return '';

      deliveries[index] = StudentDeliveryItem(
        id: old.id,
        sourceAssignmentId: old.sourceAssignmentId,
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
    debugPrint('[StudentPortal] Submissão recusada: atividade não encontrada.');
    return '';
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
