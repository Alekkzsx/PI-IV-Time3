// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/core/state/academic_bridge_service.dart';
import 'package:pi_iv_time3/features/student/shell/presentation/models/student_nav_item.dart';
import 'package:pi_iv_time3/core/network/auth_profile_remote_data_source.dart';
import 'package:pi_iv_time3/core/utils/platform_file_helper.dart';
import '../../../../core/network/authenticated_api_client.dart';
import '../data/student_remote_data_source.dart';
import '../models/student_models.dart';

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
  final AuthProfileRemoteDataSource _profileRemote =
      AuthProfileRemoteDataSource();

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
        isTwoFactorEnabled = result.studentInfo['twoFactorRequired'] == true;
        AcademicBridgeService.instance.registerStudentEnrollments(
          result.studentInfo['ra']?.toString() ??
              AppUserSession.instance.identity ??
              '',
          result.disciplines.map((discipline) => discipline.code),
          studentEmail: result.studentInfo['email']?.toString(),
        );
        disciplines = result.disciplines;
        deliveries = result.deliveries;
        events = result.events;
        if (disciplines.isNotEmpty) {
          final firstDiscipline = disciplines.first;
          selectedDiscipline = firstDiscipline;
          studentPersonalNotes =
              result.personalNotes[firstDiscipline.code]?.toString() ?? '';
        } else {
          selectedDiscipline = null;
          studentPersonalNotes = '';
        }
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
  List<StudentDisciplineModel> disciplines = [];

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
  StudentDisciplineModel? selectedDiscipline;

  // Calendário
  String calendarViewMode = 'Mês'; // 'Mês' ou 'Agenda'
  DateTime calendarFocusedDate = _today();
  final Set<String> activeEventTypes = {
    'Entrega',
    'Aula',
    'Fórum',
    'Avaliação',
  };
  final Set<String> activeDisciplineFilters = {};
  List<StudentCalendarEvent> events = [];

  // Entregas
  List<StudentDeliveryItem> deliveries = [];
  String activeDeliveryFilter = 'Todas';

  // Configurações
  int selectedSettingsTabIndex = 0;
  bool isTwoFactorEnabled = false;
  bool emailNotifications = true;
  bool pushNotifications = true;
  bool smsNotifications = false;

  // Cockpit do AVA
  int activeAvaTabIndex = 0;
  String studentPersonalNotes = '';

  Map<String, dynamic> get studentInfo =>
      remoteDashboard?.studentInfo ?? const {};
  Map<String, dynamic> get stats => remoteDashboard?.stats ?? const {};
  Map<String, dynamic> get recordSummary =>
      remoteDashboard?.recordSummary ?? const {};
  Map<String, dynamic>? get todayClass => remoteDashboard?.todayClass;
  List<Map<String, dynamic>> get messages =>
      remoteDashboard?.messages ?? const [];
  List<Map<String, dynamic>> get protocols =>
      remoteDashboard?.protocols ?? const [];
  Future<List<StudentBoletimPeriod>> loadBoletim() async {
    if (!AppUserSession.instance.hasRole('aluno')) {
      throw const ApiException('Apenas alunos podem consultar o boletim.');
    }
    return _remote.getBoletim();
  }

  List<Map<String, dynamic>> forumTopics(String classCode) =>
      remoteDashboard?.forumTopics
          .where((topic) => topic['classCode']?.toString() == classCode)
          .toList(growable: false) ??
      const [];

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

  // Métodos de Modificação de Estado

  void toggleDashboardView(bool grid) {
    if (isGridView != grid) {
      isGridView = grid;
      notifyListeners();
    }
  }

  void selectDiscipline(StudentDisciplineModel discipline) {
    selectedDiscipline = discipline;
    studentPersonalNotes =
        remoteDashboard?.personalNotes[discipline.code]?.toString() ?? '';
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
        (activeDisciplineFilters.isEmpty ||
            activeDisciplineFilters.contains(event.discipline));
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
          if (a['ra']?.toString() == AppUserSession.instance.identity) {
            myRecord = a;
            break;
          }
        }
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

        if (selectedDiscipline?.code == oldDisc.code) {
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
              if (selectedDiscipline?.code == oldDisc.code) {
                selectedDiscipline = disciplines[discIdx];
              }
              notifyListeners();
            }
          }
        };
  }

  Future<Map<String, dynamic>> submitDelivery({
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
          delivery.id == deliveryId ||
          delivery.sourceAssignmentId == deliveryId,
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
    return response;
  }

  Future<String?> downloadMaterial(StudentMaterialItem material) async {
    final response = await _remote.downloadMaterial(material.id);
    return _saveDownloadedFile(response, material.fileName, material.fileType);
  }

  Future<String?> downloadSubmission(String id) async {
    final response = await _remote.downloadSubmission(id);
    return _saveDownloadedFile(
      response,
      response['fileName']?.toString() ?? 'submissao.txt',
      'application/octet-stream',
    );
  }

  Future<String?> downloadProtocol(String id) async {
    final response = await _remote.downloadProtocol(id);
    return _saveDownloadedFile(
      response,
      response['attachmentName']?.toString() ?? 'protocolo.txt',
      'text/plain',
    );
  }

  Future<String?> _saveDownloadedFile(
    Map<String, dynamic> response,
    String fileName,
    String mimeType,
  ) {
    return PlatformFileHelper.saveOrDownloadFile(
      fileName: fileName,
      bytes: _remote.decodeFileContent(response),
      mimeType: mimeType,
    );
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

  Future<void> toggleTwoFactor(String password) async {
    if (!AppUserSession.instance.hasRole('aluno')) {
      throw const ApiException(
        'Apenas alunos podem alterar esta configuração.',
      );
    }
    await _profileRemote.toggleTwoFactor(
      password: password,
      enabled: !isTwoFactorEnabled,
    );
    setTwoFactorEnabled(!isTwoFactorEnabled);
  }

  void setTwoFactorEnabled(bool enabled) {
    if (isTwoFactorEnabled == enabled) return;
    isTwoFactorEnabled = enabled;
    notifyListeners();
  }

  void setAvaTab(int index) {
    activeAvaTabIndex = index;
    notifyListeners();
  }

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
