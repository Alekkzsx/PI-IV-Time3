// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/core/state/academic_bridge_service.dart';
import 'package:pi_iv_time3/features/student/shell/presentation/models/student_nav_item.dart';
import '../../../../core/network/authenticated_api_client.dart';
import '../data/student_remote_data_source.dart';
import '../data/student_mock_data.dart';
import '../models/student_models.dart' as remote_models;

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// Controlador reativo com estado unificado em memória para o Portal do Aluno.
class StudentPortalController extends ChangeNotifier {
  // Singleton para compartilhamento de estado entre páginas e shell
  static final StudentPortalController instance =
      StudentPortalController._internal();
  final StudentRemoteDataSource _remote;

  StudentPortalController._internal({StudentRemoteDataSource? remote})
    : _remote = remote ?? StudentRemoteDataSource() {
    _initAcademicBridgeListener();
  }

  @visibleForTesting
  StudentPortalController.withRemoteDataSource(StudentRemoteDataSource remote)
    : _remote = remote {
    _initAcademicBridgeListener();
  }

  factory StudentPortalController() => instance;
  StudentDashboardSnapshot? remoteDashboard;
  bool isLoadingRemote = false;
  String? remoteError;
  String? _loadedForToken;

  /// Loads only server-owned student data; it never falls back to fixtures.
  Future<void> loadRemote({bool force = false}) async {
    final token = AppUserSession.instance.accessToken;
    if (token == null || token.isEmpty) {
      remoteDashboard = null;
      _loadedForToken = null;
      remoteError = 'Entre novamente para carregar seus dados acadêmicos.';
      disciplines = [];
      deliveries = [];
      events = [];
      notifyListeners();
      return;
    }
    if (isLoadingRemote || (!force && _loadedForToken == token)) return;

    isLoadingRemote = true;
    remoteError = null;
    if (_loadedForToken != token) remoteDashboard = null;
    notifyListeners();
    try {
      final result = await _remote.getBootstrap();
      if (AppUserSession.instance.accessToken == token) {
        remoteDashboard = result;
        _loadedForToken = token;
        AcademicBridgeService.instance.registerStudentEnrollments(
          result.studentInfo['ra']?.toString() ??
              AppUserSession.instance.identity ??
              '',
          result.disciplines.map((discipline) => discipline.code),
          studentEmail: result.studentInfo['email']?.toString(),
        );
        disciplines = result.disciplines.map(_legacyDiscipline).toList();
        deliveries = result.deliveries.map(_legacyDelivery).toList();
        events = result.events.map(_legacyEvent).toList();
        if (disciplines.isNotEmpty) selectedDiscipline = disciplines.first;
        studentPersonalNotes = result.personalNotes.values
            .map((value) => value.toString())
            .firstOrNull ?? '';
      }
    } on ApiException catch (error) {
      if (AppUserSession.instance.accessToken == token) {
        remoteError = error.message;
      }
    } catch (_) {
      if (AppUserSession.instance.accessToken == token) {
        remoteError = 'Não foi possível carregar os dados acadêmicos.';
      }
    } finally {
      isLoadingRemote = false;
      notifyListeners();
    }
  }

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
          deliveries.insert(
            0,
            StudentDeliveryItem(
              id: delivery.id,
              sourceAssignmentId: delivery.sourceAssignmentId,
              title: delivery.title,
              disciplineCode: delivery.disciplineCode,
              disciplineName: delivery.disciplineName,
              dueDate: delivery.dueDate,
              dueHour: delivery.dueHour,
              status: delivery.status,
              weight: delivery.weight,
              score: delivery.score,
              feedback: delivery.feedback,
              protocol: delivery.protocol,
              rubrics: delivery.rubrics,
              activityCode: delivery.activityCode,
              description: delivery.description,
              professor: delivery.professor,
              deadlineBadge: delivery.deadlineBadge,
              isUrgent: delivery.isUrgent,
              allowedFormats: delivery.allowedFormats,
              submissionDate: delivery.submissionDate,
              feedbackDate: delivery.feedbackDate,
              maxScore: delivery.maxScore,
              attachmentCount: delivery.attachmentCount,
            ),
          );
          events.insert(
            0,
            StudentCalendarEvent(
              id: event.id,
              title: event.title,
              date: event.date,
              time: event.time,
              type: event.type,
              discipline: event.discipline,
              location: event.location,
            ),
          );

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

  Future<String> submitDelivery({
    required String deliveryId,
    required String fileName,
    required String fileSize,
    required String mimeType,
    required String contentBase64,
    String? gitUrl,
    String? comments,
  }) async {
    if (!AppUserSession.instance.hasRole('aluno')) {
      throw const ApiException('Apenas alunos podem enviar atividades.');
    }
    final response = await _remote.submitDelivery(
      assignmentId: deliveryId,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
      contentBase64: contentBase64,
      gitUrl: gitUrl,
      comments: comments,
    );
    final protocol = response['protocolCode'];
    if (protocol is! String || protocol.isEmpty) {
      throw const ApiException('A API não retornou o protocolo da entrega.');
    }
    final deliveryIndex = deliveries.indexWhere(
      (delivery) =>
          delivery.id == deliveryId || delivery.sourceAssignmentId == deliveryId,
    );
    if (deliveryIndex != -1) {
      final delivery = deliveries[deliveryIndex];
      final session = AppUserSession.instance;
      AcademicBridgeService.instance.notifySubmissionToDocente(
        deliveryId: delivery.id,
        assignmentId: delivery.sourceAssignmentId ?? deliveryId,
        courseCode: delivery.disciplineCode,
        studentName: session.effectiveName,
        studentRa: session.identity ?? '',
        fileName: fileName,
        protocol: protocol,
        comments: comments,
      );
    }
    await loadRemote(force: true);
    return protocol;
  }

  StudentDisciplineModel _legacyDiscipline(remote_models.StudentDisciplineModel value) => StudentDisciplineModel(
    code: value.code,
    fullCode: value.fullCode,
    name: value.name,
    professor: value.professor,
    time: value.time,
    location: value.location,
    progress: value.progress,
    n1: value.n1,
    n2: value.n2,
    p1: value.p1,
    p2: value.p2,
    trab: value.trab,
    partialAverage: value.partialAverage,
    attendancePercentage: value.attendancePercentage,
    absences: value.absences,
    totalHours: value.totalHours,
    completedHours: value.completedHours,
    maxAbsenceHours: value.maxAbsenceHours,
    hasPendingTask: value.hasPendingTask,
  );

  StudentDeliveryItem _legacyDelivery(remote_models.StudentDeliveryItem value) => StudentDeliveryItem(
    id: value.id,
    sourceAssignmentId: value.sourceAssignmentId,
    title: value.title,
    disciplineCode: value.disciplineCode,
    disciplineName: value.disciplineName,
    dueDate: value.dueDate,
    dueHour: value.dueHour,
    status: value.status,
    weight: value.weight,
    score: value.score,
    feedback: value.feedback,
    protocol: value.protocol,
    rubrics: value.rubrics,
    description: value.description,
    professor: value.professor,
    submissionDate: value.submissionDate,
    maxScore: value.maxScore,
  );

  StudentCalendarEvent _legacyEvent(remote_models.StudentCalendarEvent value) => StudentCalendarEvent(
    id: value.id,
    title: value.title,
    date: value.date,
    time: value.time,
    type: value.type,
    discipline: value.discipline,
    location: value.location,
  );

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
    if (!AppUserSession.instance.hasRole('aluno') ||
        !StudentMockData.ownsDemoRecords(
          AppUserSession.instance.identity ?? '',
        )) {
      return;
    }
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
    if (!AppUserSession.instance.hasPermission('participate_course_forum') ||
        !StudentMockData.ownsDemoRecords(
          AppUserSession.instance.identity ?? '',
        ) ||
        title.trim().isEmpty ||
        description.trim().isEmpty) {
      return;
    }
    forumTopics.insert(0, {
      'autor': StudentMockData.studentName,
      'tempo': 'Agora mesmo',
      'titulo': title.trim(),
      'respostas': '0 respostas (Aguardando monitoria)',
    });
    notifyListeners();
  }

  void updatePersonalNotes(String text) {
    if (!AppUserSession.instance.hasRole('aluno') ||
        !StudentMockData.ownsDemoRecords(
          AppUserSession.instance.identity ?? '',
        )) {
      return;
    }
    studentPersonalNotes = text;
    notifyListeners();
  }
}
