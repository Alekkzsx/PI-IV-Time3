// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/foundation.dart';
import '../../../../core/state/academic_bridge_service.dart';
import '../data/docente_mock_data.dart';
import '../domain/models/academic_event.dart';
import '../domain/models/academic_notice.dart';
import '../domain/models/assignment_model.dart';
import '../domain/models/attendance_record.dart';
import '../domain/models/docente_course.dart';
import '../domain/models/docente_profile.dart';
import '../domain/models/grade_record.dart';
import '../domain/models/rubric_model.dart';

/// Available tabs in the Docente Portal sidebar navigation.
enum DocenteNavTab {
  painel,
  turmas,
  diario,
  atividades,
  notas,
  agenda,
  comunicados,
  configuracoes,
}

/// Reactive controller managing all frontend state for the Docente Portal.
class DocenteController extends ChangeNotifier {
  DocenteNavTab _activeTab = DocenteNavTab.painel;
  bool _isSidebarCollapsed = false;

  List<DocenteCourse> _courses = [];
  String _selectedCourseId = 'course-aps2';

  ClassSession _currentSession = DocenteMockData.initialClassSession;
  List<ClassSession> _sessions = [];
  List<AssignmentItem> _assignments = [];
  String _selectedAssignmentId = 'asg-1';

  List<StudentGrade> _gradebook = [];
  List<AcademicEvent> _events = [];
  List<AcademicNotice> _notices = [];
  DocenteProfile _profile = DocenteMockData.initialProfile;

  String _settingsSubtab =
      'perfil'; // 'perfil', 'seguranca', 'notificacoes', 'preferencias', 'privacidade'

  // Homologação de Pauta & Chancela Digital do Docente Titular
  final Map<String, bool> _pautaHomologada = {
    'course-aps2': false,
    'course-bd2': true,
    'course-fso': false,
  };

  final Map<String, String> _pautaChancelaCodes = {
    'course-bd2': 'DOC-CHANCELA-2026/88410-BD2',
  };

  final List<Map<String, dynamic>> _retificacaoRequests = [];

  // Canal Contextual de Dúvidas de Atividades (assignmentId -> studentRa -> list of messages)
  final Map<String, Map<String, List<Map<String, String>>>>
  _assignmentDoubts = {
    'asg-1': {
      '2024.1.00892': [
        {
          'sender': 'Gabriel Soares (Discente)',
          'time': 'Ontem às 16:30',
          'text':
              'Professora, no diagrama de sequência para o caso de uso de Checkout, devemos instanciar o Gateway de Pagamento síncrono ou modelar como chamada assíncrona?',
        },
        {
          'sender': 'Profa. Dra. Helena Bittencourt',
          'time': 'Hoje às 09:15',
          'text':
              'Olá Gabriel! Como acordado na aula 26, modele a chamada síncrona com mensagem com resposta imediata (<<return>>) e trate a confirmação do webhook na esteira assíncrona.',
        },
      ],
      '2024.1.00901': [
        {
          'sender': 'Mariana Rios Costa (Discente)',
          'time': 'Hoje às 11:20',
          'text':
              'Profa. Helena, a rubrica considera perda de nota se usarmos nomes em inglês nos estereótipos dos diagramas?',
        },
      ],
    },
  };

  DocenteController() {
    _courses = List.from(DocenteMockData.initialCourses);
    _sessions = List.from(DocenteMockData.defaultSessions);
    _assignments = _addMissingAssignmentSubmissions(
      DocenteMockData.initialAssignments,
    );
    _gradebook = List.from(DocenteMockData.initialGradebook);
    _events = List.from(DocenteMockData.initialEvents);
    _notices = List.from(DocenteMockData.initialNotices);
    _currentSession = _sessions.firstWhere(
      (s) => s.courseId == _selectedCourseId && s.sessionNumber == 27,
      orElse: () => _sessions.firstWhere(
        (s) => s.courseId == _selectedCourseId,
        orElse: () => DocenteMockData.initialClassSession,
      ),
    );

    // Registro da ponte institucional para receber submissões e arquivos do Aluno
    AcademicBridgeService.instance.onDocenteSubmissionReceived = (assignmentId, submission) {
      final asgIndex = _assignments.indexWhere((a) => a.id == assignmentId || a.courseId == 'course-aps2');
      if (asgIndex != -1) {
        final assignment = _assignments[asgIndex];
        final exists = assignment.submissions.any((s) => s.ra == submission.ra);
        final updatedSubmissions = exists
            ? assignment.submissions.map((s) => s.ra == submission.ra ? submission : s).toList()
            : [submission, ...assignment.submissions];
        _assignments[asgIndex] = assignment.copyWith(submissions: updatedSubmissions);
        notifyListeners();
      }
    };
  }

  List<AssignmentItem> _addMissingAssignmentSubmissions(
    List<AssignmentItem> assignments,
  ) {
    return assignments.map((assignment) {
      final roster = _sessions
          .where((session) => session.courseId == assignment.courseId)
          .expand((session) => session.attendanceList)
          .fold<Map<String, AttendanceStudent>>(
            {},
            (students, student) {
              students[student.studentId] = student;
              return students;
            },
          )
          .values;
      final existingByStudent = {
        for (final submission in assignment.submissions)
          submission.studentId: submission,
      };
      final submissions = <StudentSubmission>[
        for (final student in roster)
          existingByStudent.remove(student.studentId) ??
              StudentSubmission(
                id: 'sub-${assignment.id}-${student.studentId}',
                studentId: student.studentId,
                ra: student.ra,
                studentName: student.name,
                status: SubmissionStatus.naoEntregue,
              ),
        ...existingByStudent.values,
      ];
      return assignment.copyWith(submissions: submissions);
    }).toList();
  }

  // --- Getters ---
  DocenteNavTab get activeTab => _activeTab;
  bool get isSidebarCollapsed => _isSidebarCollapsed;
  List<DocenteCourse> get courses => List.unmodifiable(_courses);
  String get selectedCourseId => _selectedCourseId;
  ClassSession get currentSession => _currentSession;
  List<ClassSession> get sessions => List.unmodifiable(_sessions);
  List<ClassSession> get sessionsForSelectedCourse =>
      (_sessions.where((s) => s.courseId == _selectedCourseId).toList()
        ..sort((a, b) {
          final dateOrder = a.sessionDate.compareTo(b.sessionDate);
          return dateOrder != 0
              ? dateOrder
              : a.sessionNumber.compareTo(b.sessionNumber);
        }));
  List<AssignmentItem> get assignments => List.unmodifiable(_assignments);
  String get selectedAssignmentId => _selectedAssignmentId;
  List<StudentGrade> get gradebook => List.unmodifiable(_gradebook);
  List<AcademicEvent> get events => List.unmodifiable(_events);
  List<AcademicNotice> get notices => List.unmodifiable(_notices);
  DocenteProfile get profile => _profile;
  String get settingsSubtab => _settingsSubtab;

  DocenteCourse get selectedCourse => _courses.firstWhere(
    (c) => c.id == _selectedCourseId,
    orElse: () => _courses.first,
  );

  AssignmentItem get selectedAssignment => _assignments.firstWhere(
    (a) => a.id == _selectedAssignmentId,
    orElse: () => _assignments.first,
  );

  bool isPautaHomologada(String courseId) =>
      _pautaHomologada[courseId] ?? false;
  String? getChancelaCode(String courseId) => _pautaChancelaCodes[courseId];
  List<Map<String, dynamic>> get retificacaoRequests =>
      List.unmodifiable(_retificacaoRequests);

  // --- Navigation Methods ---
  void navigateToTab(DocenteNavTab tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    notifyListeners();
  }

  void toggleSidebarCollapse() {
    _isSidebarCollapsed = !_isSidebarCollapsed;
    notifyListeners();
  }

  void selectCourse(String courseId) {
    if (!_courses.any((course) => course.id == courseId)) return;
    _selectedCourseId = courseId;
    final courseSessions = _sessions
        .where((s) => s.courseId == courseId)
        .toList();
    if (courseSessions.isNotEmpty) {
      _currentSession = courseSessions.firstWhere(
        (s) => s.sessionNumber == 27,
        orElse: () => courseSessions.first,
      );
    }
    notifyListeners();
  }

  void setSettingsSubtab(String subtab) {
    _settingsSubtab = subtab;
    notifyListeners();
  }

  // --- Course & Syllabus Methods ---
  void advanceSyllabusClasses(String courseId, String unitId) {
    final courseIndex = _courses.indexWhere((c) => c.id == courseId);
    if (courseIndex == -1) return;

    final course = _courses[courseIndex];
    final updatedUnits = course.syllabusUnits.map((u) {
      if (u.id == unitId) {
        // The control cycles the progress marker so a teacher can correct a
        // mistaken advance without editing the teaching plan itself.
        final newClasses = u.completedClasses >= u.totalClasses
            ? (u.completedClasses - 2).clamp(0, u.totalClasses)
            : (u.completedClasses + 2).clamp(0, u.totalClasses);
        return u.copyWith(completedClasses: newClasses);
      }
      return u;
    }).toList();

    _courses[courseIndex] = course.copyWith(syllabusUnits: updatedUnits);
    notifyListeners();
  }

  void publishMaterial(String courseId, String title) {
    if (title.trim().isEmpty) return;
    final courseIndex = _courses.indexWhere((c) => c.id == courseId);
    if (courseIndex == -1) return;

    final now = DateTime.now();
    final formattedDate =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final newMaterial = CourseMaterial(
      id: 'mat-${DateTime.now().millisecondsSinceEpoch}',
      courseId: courseId,
      title: title.trim(),
      date: 'Hoje, $formattedDate',
      size: '1.5 MB',
      type: 'PDF',
    );

    final updatedMaterials = [newMaterial, ..._courses[courseIndex].materials];
    _courses[courseIndex] = _courses[courseIndex].copyWith(
      materials: updatedMaterials,
    );

    // Propaga institucionalmente para o AVA discente
    AcademicBridgeService.instance.addCourseMaterial(
      courseCode: _courses[courseIndex].code,
      title: newMaterial.title,
      fileType: newMaterial.type,
      fileSize: newMaterial.size,
    );

    notifyListeners();
  }

  // --- Attendance & Diary Methods ---
  void _syncSessionInList() {
    final idx = _sessions.indexWhere((s) => s.id == _currentSession.id);
    if (idx != -1) {
      _sessions[idx] = _currentSession;
    }
  }

  String formatSessionDate(DateTime date) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    const weekdays = [
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
      'Domingo',
    ];
    final dayStr = date.day.toString().padLeft(2, '0');
    final monthStr = months[date.month - 1];
    final weekdayStr = weekdays[date.weekday - 1];
    return '$dayStr de $monthStr de ${date.year} ($weekdayStr)';
  }

  void selectSession(String sessionId) {
    final found = _sessions
        .where((s) => s.id == sessionId && s.courseId == _selectedCourseId)
        .firstOrNull;
    if (found == null || found.id == _currentSession.id) return;
    _currentSession = found;
    notifyListeners();
  }

  void selectSessionByDate(DateTime pickedDate) {
    if (!selectedCourse.classWeekdays.contains(pickedDate.weekday)) return;

    final normalizedDate = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
    );
    final existing = _sessions.firstWhere(
      (s) =>
          s.courseId == _selectedCourseId &&
          s.sessionDate.year == normalizedDate.year &&
          s.sessionDate.month == normalizedDate.month &&
          s.sessionDate.day == normalizedDate.day,
      orElse: () => _createSessionForDate(normalizedDate),
    );
    if (existing.id == _currentSession.id) return;
    _currentSession = existing;
    notifyListeners();
  }

  ClassSession _createSessionForDate(DateTime pickedDate) {
    final list = sessionsForSelectedCourse;
    final insertionIndex = list.indexWhere(
      (session) => session.sessionDate.isAfter(pickedDate),
    );
    final nextNumber = insertionIndex == -1
        ? (list
                  .map((s) => s.sessionNumber)
                  .fold<int>(0, (max, n) => n > max ? n : max)) +
              1
        : insertionIndex == 0
        ? list.first.sessionNumber - 1
        : list[insertionIndex - 1].sessionNumber + 1;

    if (insertionIndex != -1 &&
        list.any((session) => session.sessionNumber == nextNumber)) {
      final sessionsToShift = list.skip(insertionIndex);
      for (final session in sessionsToShift) {
        if (session.sessionNumber < nextNumber) continue;
        final index = _sessions.indexWhere((item) => item.id == session.id);
        if (index != -1) {
          _sessions[index] = session.copyWith(
            sessionNumber: session.sessionNumber + 1,
          );
        }
      }
    }

    final formatted = formatSessionDate(pickedDate);
    final courseAttendance = list.isEmpty
        ? const <AttendanceStudent>[]
        : list.first.attendanceList;
    final newSession = ClassSession(
      id: 'sess-${pickedDate.millisecondsSinceEpoch}',
      courseId: _selectedCourseId,
      sessionNumber: nextNumber,
      hours: 2,
      date: pickedDate,
      dateFormatted: formatted,
      contentProgram:
          'Planejamento de aula para ${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}',
      methodology: 'Aula expositiva dialogada e atividades práticas.',
      location: selectedCourse.room,
      isHomologated: false,
      attendanceList: courseAttendance
          .map((st) => st.copyWith(status: AttendanceStatus.presente))
          .toList(),
    );
    _sessions.add(newSession);
    return newSession;
  }

  bool get canGoToPreviousSession {
    final list = sessionsForSelectedCourse;
    final index = list.indexWhere((s) => s.id == _currentSession.id);
    return index > 0;
  }

  bool get canGoToNextSession {
    final list = sessionsForSelectedCourse;
    final index = list.indexWhere((s) => s.id == _currentSession.id);
    return index != -1 && index < list.length - 1;
  }

  void goToPreviousSession() {
    final list = sessionsForSelectedCourse;
    final index = list.indexWhere((s) => s.id == _currentSession.id);
    if (index > 0) {
      _currentSession = list[index - 1];
      notifyListeners();
    }
  }

  void goToNextSession() {
    final list = sessionsForSelectedCourse;
    final index = list.indexWhere((s) => s.id == _currentSession.id);
    if (index != -1 && index < list.length - 1) {
      _currentSession = list[index + 1];
      notifyListeners();
    }
  }

  void updateSessionContent(
    String content,
    String methodology, [
    String? location,
  ]) {
    final normalizedContent = content.trim();
    final normalizedMethodology = methodology.trim();
    final normalizedLocation = location?.trim();
    if (normalizedContent.isEmpty || normalizedMethodology.isEmpty) return;
    _currentSession = _currentSession.copyWith(
      contentProgram: normalizedContent,
      methodology: normalizedMethodology,
      location: normalizedLocation?.isEmpty == false
          ? normalizedLocation
          : _currentSession.location,
      // Any edit after approval requires a new homologation.
      isHomologated: false,
    );
    _syncSessionInList();
    notifyListeners();
  }

  void markAllPresent() {
    if (_currentSession.attendanceList.every(
      (student) => student.status == AttendanceStatus.presente,
    )) {
      return;
    }
    final updatedAttendance = _currentSession.attendanceList
        .map(
          (student) =>
              _attendanceWithStatus(student, AttendanceStatus.presente),
        )
        .toList();
    _currentSession = _currentSession.copyWith(
      attendanceList: updatedAttendance,
      isHomologated: false,
    );
    _syncSessionInList();
    notifyListeners();
  }

  AttendanceStudent _attendanceWithStatus(
    AttendanceStudent record,
    AttendanceStatus newStatus,
  ) {
    final wasAbsent = record.status == AttendanceStatus.ausente;
    final willBeAbsent = newStatus == AttendanceStatus.ausente;
    final delta = wasAbsent == willBeAbsent ? 0 : (willBeAbsent ? 1 : -1);
    final newAbsences = (record.accumulatedAbsences + delta)
        .clamp(0, record.maxAbsences)
        .toInt();
    const totalClassesHeld = 38;
    final newRate = double.parse(
      (((totalClassesHeld - newAbsences) / totalClassesHeld) * 100)
          .clamp(0, 100)
          .toStringAsFixed(1),
    );
    final risk = newRate < 75
        ? AttendanceRiskLevel.critico
        : newRate < 80
        ? AttendanceRiskLevel.atencao
        : AttendanceRiskLevel.regular;
    return record.copyWith(
      status: newStatus,
      accumulatedAbsences: newAbsences,
      attendanceRate: newRate,
      riskLevel: risk,
    );
  }

  void toggleAttendance(String studentId, AttendanceStatus newStatus) {
    final updatedAttendance = _currentSession.attendanceList.map((record) {
      if (record.studentId == studentId) {
        return _attendanceWithStatus(record, newStatus);
      }
      return record;
    }).toList();

    _currentSession = _currentSession.copyWith(
      attendanceList: updatedAttendance,
      isHomologated: false,
    );
    _syncSessionInList();
    notifyListeners();
  }

  void homologateSession() {
    _currentSession = _currentSession.copyWith(isHomologated: true);
    _syncSessionInList();

    // Propaga o fechamento da chamada e presenças para os discentes
    AcademicBridgeService.instance.registerAttendanceHomologation(
      courseCode: selectedCourse.code,
      sessionDate: _currentSession.date?.toIso8601String() ?? 'Hoje',
      attendances: _currentSession.attendanceList.map((att) => {
        'ra': att.ra,
        'studentName': att.name,
        'status': att.status.name,
        'accumulatedAbsences': att.accumulatedAbsences,
        'attendanceRate': att.attendanceRate,
      }).toList(),
    );

    notifyListeners();
  }

  // --- Assignments & Rubric Methods ---
  void selectAssignment(String assignmentId) {
    if (!_assignments.any((assignment) => assignment.id == assignmentId) ||
        _selectedAssignmentId == assignmentId) {
      return;
    }
    _selectedAssignmentId = assignmentId;
    notifyListeners();
  }

  void createAssignment({
    required String courseId,
    required String courseCode,
    required String title,
    String description = '',
    required double weight,
    required String stage,
    required String dueDateFormatted,
    required String modality,
    required bool allowLateWithPenalty,
    required List<RubricCriterion> rubricCriteria,
  }) {
    if (!_courses.any((course) => course.id == courseId) ||
        title.trim().isEmpty ||
        dueDateFormatted.trim().isEmpty ||
        !weight.isFinite ||
        weight <= 0 ||
        rubricCriteria.isEmpty) {
      return;
    }
    final courseSessions = _sessions
        .where((s) => s.courseId == courseId)
        .toList();
    final enrolledStudents = courseSessions.isEmpty
        ? const <AttendanceStudent>[]
        : courseSessions.first.attendanceList;
    final newAssignment = AssignmentItem(
      id: 'asg-${DateTime.now().millisecondsSinceEpoch}',
      courseId: courseId,
      courseCode: courseCode,
      title: title,
      description: description.trim(),
      weight: weight,
      stage: stage,
      dueDateFormatted: dueDateFormatted,
      isUrgent: false,
      modality: modality,
      allowLateWithPenalty: allowLateWithPenalty,
      rubricCriteria: rubricCriteria,
      submissions: enrolledStudents.map((st) {
        return StudentSubmission(
          id: 'sub-${st.studentId}',
          studentId: st.studentId,
          ra: st.ra,
          studentName: st.name,
          fileName: null,
          submittedAtFormatted: null,
          fileSize: null,
          grade: null,
          status: SubmissionStatus.naoEntregue,
          rubricEvaluations: rubricCriteria,
        );
      }).toList(),
    );

    _assignments = [newAssignment, ..._assignments];
    _selectedAssignmentId = newAssignment.id;

    // Publica no barramento institucional para sincronizar automaticamente com o Aluno
    final course = _courses.firstWhere(
      (c) => c.id == courseId,
      orElse: () => _courses.first,
    );
    AcademicBridgeService.instance.publishAssignmentToStudent(
      courseCode: courseCode,
      courseTitle: course.title,
      professorName: 'Profa. Dra. Helena Bittencourt',
      assignmentId: newAssignment.id,
      title: title,
      description: description,
      weight: weight,
      dueDateFormatted: dueDateFormatted,
      rubricCriteria: rubricCriteria,
      modality: modality,
    );

    notifyListeners();
  }

  void evaluateRubric({
    required String assignmentId,
    required String submissionId,
    required double calculatedGrade,
    required String feedback,
    required List<RubricCriterion> evaluatedCriteria,
  }) {
    final asgIndex = _assignments.indexWhere(
      (a) => a.id == assignmentId || a.id == 'asg-1',
    );
    if (asgIndex == -1) return;

    final assignment = _assignments[asgIndex];
    final updatedSubmissions = assignment.submissions.map((sub) {
      if (sub.id == submissionId) {
        return sub.copyWith(
          grade: calculatedGrade,
          status: SubmissionStatus.corrigido,
          teacherFeedback: feedback,
          rubricEvaluations: evaluatedCriteria,
        );
      }
      return sub;
    }).toList();

    _assignments[asgIndex] = assignment.copyWith(
      submissions: updatedSubmissions,
    );

    // Sincroniza nota, feedback e rubricas avaliadas diretamente com o Aluno
    AcademicBridgeService.instance.notifyGradedToStudent(
      deliveryId: assignmentId,
      finalScore: calculatedGrade,
      feedback: feedback,
      evaluatedRubrics: evaluatedCriteria,
    );

    notifyListeners();
  }

  // --- Gradebook Methods ---
  void updateStudentGrade(
    String studentId, {
    double? assignments,
    double? p1,
    double? projects,
    double? p2,
  }) {
    double? normalize(double? value) {
      if (value == null || !value.isFinite) return null;
      return value.clamp(0.0, 10.0).toDouble();
    }

    final normalizedAssignments = normalize(assignments);
    final normalizedP1 = normalize(p1);
    final normalizedProjects = normalize(projects);
    final normalizedP2 = normalize(p2);
    _gradebook = _gradebook.map((grade) {
      if (grade.studentId == studentId) {
        return grade.copyWith(
          assignmentsScore: normalizedAssignments ?? grade.assignmentsScore,
          p1Score: normalizedP1 ?? grade.p1Score,
          projectsScore: normalizedProjects ?? grade.projectsScore,
          p2Score: normalizedP2 ?? grade.p2Score,
        );
      }
      return grade;
    }).toList();
    notifyListeners();
  }

  // --- Métodos de Homologação, Chancela Digital & Retificação com Coordenação ---

  void homologarPautaComChancela(String courseId) {
    _pautaHomologada[courseId] = true;
    final course = _courses.firstWhere(
      (c) => c.id == courseId,
      orElse: () => _courses.first,
    );
    final codeSuffix = course.code
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    _pautaChancelaCodes[courseId] = 'DOC-CHANCELA-2026/88410-$codeSuffix';
    notifyListeners();
  }

  void solicitarRetificacaoNota({
    required String courseId,
    required String studentRa,
    required String studentName,
    required String avaliacao,
    required double notaAnterior,
    required double novaNota,
    required String justificativa,
  }) {
    _retificacaoRequests.insert(0, {
      'id':
          'RET-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      'courseId': courseId,
      'studentRa': studentRa,
      'studentName': studentName,
      'avaliacao': avaliacao,
      'notaAnterior': notaAnterior,
      'novaNota': novaNota,
      'justificativa': justificativa,
      'status': 'Aguardando Parecer da Coordenação',
      'dataSolicitacao':
          'Hoje às ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
    });
    notifyListeners();
  }

  // --- Métodos de Feedback Individual & Canal de Dúvidas de Atividades ---

  List<Map<String, String>> getDoubtThread(
    String assignmentId,
    String studentRa,
  ) {
    return _assignmentDoubts[assignmentId]?[studentRa] ?? [];
  }

  void enviarRespostaDuvida(
    String assignmentId,
    String studentRa,
    String reply,
  ) {
    if (reply.trim().isEmpty) return;
    _assignmentDoubts.putIfAbsent(assignmentId, () => {});
    _assignmentDoubts[assignmentId]!.putIfAbsent(studentRa, () => []);
    _assignmentDoubts[assignmentId]![studentRa]!.add({
      'sender': 'Profa. Dra. Helena Bittencourt (Docente)',
      'time': 'Agora mesmo',
      'text': reply.trim(),
    });
    notifyListeners();
  }

  void salvarFeedbackIndividual({
    required String assignmentId,
    required String studentRa,
    required double nota,
    required String feedback,
    String? teacherReply,
  }) {
    final asgIndex = _assignments.indexWhere((a) => a.id == assignmentId);
    if (asgIndex != -1) {
      final assignment = _assignments[asgIndex];
      final updatedSubmissions = assignment.submissions.map((sub) {
        if (sub.ra == studentRa) {
          return sub.copyWith(
            grade: nota,
            status: SubmissionStatus.corrigido,
            teacherFeedback: feedback.trim(),
          );
        }
        return sub;
      }).toList();
      _assignments[asgIndex] = assignment.copyWith(
        submissions: updatedSubmissions,
      );
    }

    if (teacherReply != null && teacherReply.trim().isNotEmpty) {
      enviarRespostaDuvida(assignmentId, studentRa, teacherReply);
    }
    notifyListeners();
  }

  void notificarAlunoInfrequencia(String studentId, String studentName) {
    publishNotice(
      targetCourse: selectedCourse.title,
      targetAudience: 'Discente: $studentName ($studentId)',
      classification: NoticeClassification.urgencia,
      title: 'Alerta Preventivo de Infrequência - Assiduidade Regimental',
      message:
          'Prezado(a) $studentName, identificamos que seu percentual de frequência na disciplina ${selectedCourse.title} atingiu o limite crítico regimental. Por gentileza, procure a docente durante o plantão de dúvidas ou regularize eventuais faltas com atestados perante a Secretaria Geral.',
    );
  }

  // --- Agenda & Events Methods ---
  void addEvent({
    required String title,
    required String date,
    required String time,
    required EventType type,
    required String location,
  }) {
    if (title.trim().isEmpty) return;
    final newEvent = AcademicEvent(
      id: 'ev-${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      date: date,
      time: time,
      type: type,
      location: location.trim(),
      isSynced: true,
    );

    _events = [newEvent, ..._events];
    notifyListeners();
  }

  // --- Notices & Announcements Methods ---
  void publishNotice({
    required String targetCourse,
    required String targetAudience,
    required NoticeClassification classification,
    required String title,
    required String message,
  }) {
    if (title.trim().isEmpty || message.trim().isEmpty) return;
    final normalizedTargetCourse = targetCourse.trim().toLowerCase();
    final recipientCourse = _courses.where((course) {
      return course.id.toLowerCase() == normalizedTargetCourse ||
          course.code.toLowerCase() == normalizedTargetCourse ||
          course.title.toLowerCase() == normalizedTargetCourse;
    }).firstOrNull;
    final newNotice = AcademicNotice(
      id: 'not-${DateTime.now().millisecondsSinceEpoch}',
      author: 'Você (Profa. Helena Bittencourt)',
      targetCourse: targetCourse,
      targetAudience: targetAudience,
      classification: classification,
      publishedAt:
          'Hoje, ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      title: title.trim(),
      message: message.trim(),
      readCount: 0,
      totalRecipients: (recipientCourse ?? selectedCourse).enrolledCount,
      isFromSecretaria: false,
    );

    _notices = [newNotice, ..._notices];

    // Propaga comunicado para a Central de Mensagens e Mural do Aluno
    AcademicBridgeService.instance.broadcastNotice(
      title: title.trim(),
      content: message.trim(),
      senderRole: 'docente',
      senderName: 'Profa. Helena Bittencourt (${recipientCourse?.code ?? targetCourse})',
      targetCourse: recipientCourse?.code ?? targetCourse,
    );

    notifyListeners();
  }

  // --- Settings & Profile Methods ---
  void updateProfile({String? socialName, String? personalEmail}) {
    _profile = _profile.copyWith(
      socialName: socialName ?? _profile.socialName,
      personalEmail: personalEmail ?? _profile.personalEmail,
    );
    notifyListeners();
  }

  void toggleTwoFactor() {
    _profile = _profile.copyWith(twoFactorEnabled: !_profile.twoFactorEnabled);
    notifyListeners();
  }

  void disconnectSession(String sessionId) {
    final updatedSessions = _profile.activeSessions
        .where((s) => s.id != sessionId)
        .toList();
    _profile = _profile.copyWith(activeSessions: updatedSessions);
    notifyListeners();
  }

  /// Ends all sessions except the device currently in use.
  void disconnectOtherSessions() {
    _profile = _profile.copyWith(
      activeSessions: _profile.activeSessions
          .where((session) => session.isCurrent)
          .toList(),
    );
    notifyListeners();
  }
}
