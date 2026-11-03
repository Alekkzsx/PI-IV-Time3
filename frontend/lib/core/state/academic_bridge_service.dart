// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
// Barramento Reativo de Sincronização Multiperfil (Aluno, Docente, Admin) — 100% alimentado por dados reais da API/MongoDB.

import 'package:flutter/foundation.dart';
import 'app_user_session.dart';
import 'role_permission_policy.dart';
import '../../features/student/shared/models/student_models.dart';
import '../../features/teacher/shared/domain/models/assignment_model.dart';
import '../../features/teacher/shared/domain/models/rubric_model.dart';
import '../../features/admin/shared/models/admin_models.dart';
import '../../features/student/secretariat/domain/entities/protocol_request.dart';

/// Modelo de sessão síncrona / videochamada de uma turma registrada.
class AcademicLiveSession {
  final String courseCode;
  final String courseTitle;
  final String professorName;
  final String roomCode;
  bool isOpen;
  String? openedByRole;
  String? openedByName;
  String? openedByIdentity;
  DateTime? openedAt;

  AcademicLiveSession({
    required this.courseCode,
    required this.courseTitle,
    required this.professorName,
    required this.roomCode,
    this.isOpen = false,
    this.openedByRole,
    this.openedByName,
    this.openedByIdentity,
    this.openedAt,
  });

  AcademicLiveSession copyWith({
    bool? isOpen,
    String? openedByRole,
    String? openedByName,
    String? openedByIdentity,
    DateTime? openedAt,
  }) {
    return AcademicLiveSession(
      courseCode: courseCode,
      courseTitle: courseTitle,
      professorName: professorName,
      roomCode: roomCode,
      isOpen: isOpen ?? this.isOpen,
      openedByRole: openedByRole ?? this.openedByRole,
      openedByName: openedByName ?? this.openedByName,
      openedByIdentity: openedByIdentity ?? this.openedByIdentity,
      openedAt: openedAt ?? this.openedAt,
    );
  }
}

typedef ProtocolUpdateCallback = void Function(ProtocolRequest request);

/// Barramento reativo entre controladores ativos no cliente (sincronizado com a API e MongoDB, sem mocks estáticos).
class AcademicBridgeService extends ChangeNotifier {
  static final AcademicBridgeService instance =
      AcademicBridgeService._internal();

  AcademicBridgeService._internal();

  factory AcademicBridgeService() => instance;

  final Map<String, AcademicLiveSession> _liveSessions = {};
  final Map<String, String> _courseCodeAliases = {};
  final Map<String, Set<String>> _teacherCoursesByIdentity = {};
  final Map<String, Set<String>> _studentCoursesByIdentity = {};

  /// Registra uma turma real carregada do backend (Admin, Docente ou Aluno).
  void registerClassRoom({
    required String code,
    required String subjectName,
    required String professorName,
    String? professorIdentity,
    bool? isOpen,
    String? openedByName,
    String? openedByRole,
    String? openedByIdentity,
  }) {
    final fullUpper = code.trim().toUpperCase();
    if (fullUpper.isEmpty) return;
    final shortCode = fullUpper.contains(' - ')
        ? fullUpper.split(' - ').last.trim()
        : fullUpper;
    final sanitized = sanitizeRoomCode(shortCode);

    _courseCodeAliases[fullUpper] = shortCode;
    _courseCodeAliases[shortCode] = shortCode;
    _courseCodeAliases[sanitized] = shortCode;
    _courseCodeAliases[sanitizeRoomCode(fullUpper)] = shortCode;

    final existing = _liveSessions[shortCode];
    final session = AcademicLiveSession(
      courseCode: shortCode,
      courseTitle: subjectName,
      professorName: professorName,
      roomCode: sanitized,
      isOpen: isOpen ?? existing?.isOpen ?? false,
      openedByRole: openedByRole ?? existing?.openedByRole,
      openedByName: openedByName ?? existing?.openedByName,
      openedByIdentity: openedByIdentity ?? existing?.openedByIdentity,
      openedAt: (isOpen == true && existing?.openedAt == null)
          ? DateTime.now()
          : existing?.openedAt,
    );
    _liveSessions[shortCode] = session;
    _liveSessions[sanitized] = session;

    if (professorIdentity != null && professorIdentity.trim().isNotEmpty) {
      final norm = professorIdentity.trim().toLowerCase();
      (_teacherCoursesByIdentity[norm] ??= <String>{}).add(shortCode);
    }
  }

  /// Registra vínculos reais de turmas lecionadas por um docente.
  void registerTeacherCourses(
    String teacherIdentity,
    Iterable<String> courseCodes, {
    String? teacherEmail,
  }) {
    final norm = teacherIdentity.trim().toLowerCase();
    if (norm.isEmpty) return;
    final normalizedSet = courseCodes.map(_normalizeCourseCode).toSet();
    _teacherCoursesByIdentity[norm] = normalizedSet;
    if (teacherEmail != null && teacherEmail.trim().isNotEmpty) {
      _teacherCoursesByIdentity[teacherEmail.trim().toLowerCase()] =
          normalizedSet;
    }
  }

  /// Registra vínculos reais de matrículas de um discente.
  void registerStudentEnrollments(
    String studentIdentity,
    Iterable<String> courseCodes, {
    String? studentEmail,
  }) {
    final norm = studentIdentity.trim().toLowerCase();
    if (norm.isEmpty) return;
    final normalizedSet = courseCodes.map(_normalizeCourseCode).toSet();
    _studentCoursesByIdentity[norm] = normalizedSet;
    if (studentEmail != null && studentEmail.trim().isNotEmpty) {
      _studentCoursesByIdentity[studentEmail.trim().toLowerCase()] =
          normalizedSet;
    }
  }

  /// Limpa os vínculos em memória ao deslogar ou redefinir suítes de teste.
  void clearRuntimeBindings() {
    _liveSessions.clear();
    _courseCodeAliases.clear();
    _teacherCoursesByIdentity.clear();
    _studentCoursesByIdentity.clear();
    _sharedMaterials.clear();
    _broadcastNotices.clear();
    _deliveryIdsByAssignment.clear();
  }

  static String sanitizeRoomCode(String raw) {
    return raw
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'\s*-\s*'), '-')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^A-Z0-9._-]'), '');
  }

  AcademicLiveSession getSession(String rawCode) {
    final cleanCode = _normalizeCourseCode(rawCode);
    return _liveSessions[cleanCode] ??
        AcademicLiveSession(
          courseCode: cleanCode,
          courseTitle: 'Turma $cleanCode',
          professorName: 'Docente Responsável',
          roomCode: sanitizeRoomCode(cleanCode),
          isOpen: false,
        );
  }

  bool isSessionOpen(String rawCode) {
    final cleanCode = _normalizeCourseCode(rawCode);
    return _liveSessions[cleanCode]?.isOpen ?? false;
  }

  bool hasSession(String rawCode) {
    return _liveSessions.containsKey(_normalizeCourseCode(rawCode));
  }

  bool canUserOpenSession({required String role}) {
    final normalized = role.toLowerCase().trim();
    return normalized == RolePermissionPolicy.teacher ||
        normalized == RolePermissionPolicy.admin;
  }

  bool _teacherOwnsCourse(String? teacherIdentity, String normalizedCode) {
    final norm = (teacherIdentity ?? '').trim().toLowerCase();
    if (norm.isEmpty) return false;
    final set = _teacherCoursesByIdentity[norm];
    return set != null && set.contains(normalizedCode);
  }

  bool _studentEnrolledInCourse(String? studentIdentity, String normalizedCode) {
    final norm = (studentIdentity ?? '').trim().toLowerCase();
    if (norm.isEmpty) return false;
    final set = _studentCoursesByIdentity[norm];
    return set != null && set.contains(normalizedCode);
  }

  bool canUserOpenSessionForCourse({
    required String role,
    required String rawCourseCode,
    String? teacherIdentity,
  }) {
    final normalizedRole = role.toLowerCase().trim();
    final courseCode = _normalizeCourseCode(rawCourseCode);
    if (!_liveSessions.containsKey(courseCode) ||
        !canUserOpenSession(role: normalizedRole)) {
      return false;
    }
    if (normalizedRole == 'admin') return true;
    return _teacherOwnsCourse(teacherIdentity, courseCode);
  }

  bool canUserJoinSession({
    required String role,
    required String rawCourseCode,
    String? studentRa,
    String? teacherIdentity,
  }) {
    final normalizedRole = role.toLowerCase().trim();
    final courseCode = _normalizeCourseCode(rawCourseCode);
    if (!_liveSessions.containsKey(courseCode) || !isSessionOpen(courseCode)) {
      return false;
    }
    if (canUserOpenSessionForCourse(
      role: normalizedRole,
      rawCourseCode: courseCode,
      teacherIdentity: teacherIdentity,
    )) {
      return true;
    }
    if (normalizedRole != RolePermissionPolicy.student) {
      return false;
    }
    return _studentEnrolledInCourse(studentRa, courseCode);
  }

  bool openSession({
    required String rawCourseCode,
    required String openedByRole,
    required String openedByName,
    String? roomCode,
    String? openedByIdentity,
  }) {
    final cleanCode = _normalizeCourseCode(rawCourseCode);
    final userSession = AppUserSession.instance;
    if (!userSession.hasRole(openedByRole) ||
        userSession.identity != openedByIdentity ||
        !canUserOpenSessionForCourse(
          role: openedByRole,
          rawCourseCode: cleanCode,
          teacherIdentity: openedByIdentity,
        ) ||
        (roomCode != null && _normalizeCourseCode(roomCode) != cleanCode)) {
      return false;
    }

    final session = _liveSessions[cleanCode]!;
    session.isOpen = true;
    session.openedByRole = openedByRole;
    session.openedByName = openedByName;
    session.openedByIdentity = openedByIdentity;
    session.openedAt = DateTime.now();

    _liveSessions[cleanCode] = session;
    _liveSessions[session.roomCode] = session;

    notifyListeners();
    return true;
  }

  bool closeSession(String rawCourseCode) {
    final cleanCode = _normalizeCourseCode(rawCourseCode);
    final session = _liveSessions[cleanCode];
    final user = AppUserSession.instance;
    if (session == null ||
        !session.isOpen ||
        !((user.hasRole(RolePermissionPolicy.admin) &&
                user.hasPermission('manage_video_calls')) ||
            (user.hasRole(RolePermissionPolicy.teacher) &&
                session.openedByRole == RolePermissionPolicy.teacher &&
                session.openedByIdentity == user.identity))) {
      return false;
    }
    session.isOpen = false;
    session.openedByRole = null;
    session.openedByName = null;
    session.openedByIdentity = null;
    session.openedAt = null;
    notifyListeners();
    return true;
  }

  /// Sincroniza estado real vindo de `/api/video-call/rooms` sem exigir regras de clique local.
  void syncServerRoomStatus({
    required String classCode,
    required String title,
    required String professorName,
    required bool isOpen,
    String? openedByName,
  }) {
    registerClassRoom(
      code: classCode,
      subjectName: title,
      professorName: professorName,
      isOpen: isOpen,
      openedByName: openedByName,
      openedByRole: isOpen ? 'docente' : null,
    );
    notifyListeners();
  }

  String _normalizeCourseCode(String raw) {
    final trimmed = raw.trim().toUpperCase();
    return _courseCodeAliases[trimmed] ??
        _courseCodeAliases[sanitizeRoomCode(trimmed)] ??
        trimmed;
  }

  bool courseCodesMatch(String first, String second) =>
      _normalizeCourseCode(first) == _normalizeCourseCode(second);

  // ===========================================================================
  // 2. ATIVIDADES, SUBMISSÕES E AVALIAÇÕES (DOCENTE <-> ALUNO)
  // ===========================================================================
  bool Function(
    String assignmentId,
    String courseCode,
    StudentSubmission submission,
  )?
  onDocenteSubmissionReceived;

  void Function(
    StudentDeliveryItem newDelivery,
    StudentCalendarEvent calendarEvent,
  )?
  onAssignmentPublishedToStudent;

  void Function(
    String deliveryId,
    double finalScore,
    String feedback,
    List<RubricCriterion> evaluatedRubrics,
  )?
  onGradedReceivedByStudent;

  VoidCallback? onStudentDataChanged;
  final Map<String, String> _deliveryIdsByAssignment = {};

  void publishAssignmentToStudent({
    required String courseCode,
    required String courseTitle,
    required String professorName,
    required String assignmentId,
    required String title,
    required String description,
    required double weight,
    required String dueDateFormatted,
    required List<RubricCriterion> rubricCriteria,
    required String modality,
  }) {
    final session = AppUserSession.instance;
    final cleanDiscCode = _normalizeCourseCode(courseCode);
    final teachesCourse =
        session.hasRole('admin') ||
        _teacherOwnsCourse(session.identity, cleanDiscCode);
    if (!session.hasPermission('manage_assignments') ||
        !teachesCourse ||
        !_liveSessions.containsKey(cleanDiscCode) ||
        assignmentId.trim().isEmpty ||
        title.trim().isEmpty ||
        weight <= 0 ||
        !weight.isFinite ||
        rubricCriteria.isEmpty) {
      return;
    }
    final delivery = StudentDeliveryItem(
      id: assignmentId,
      sourceAssignmentId: assignmentId,
      activityCode: '${cleanDiscCode.split('-').first} - ATV',
      title: title,
      disciplineCode: cleanDiscCode,
      disciplineName: courseTitle,
      dueDate: dueDateFormatted.split(' ').first,
      dueHour: dueDateFormatted.contains('às')
          ? dueDateFormatted.split('às').last.trim()
          : '23:59',
      status: 'Pendente',
      weight: weight,
      maxScore: 10.0,
      description: description,
      professor: professorName,
      deadlineBadge: 'Prazo: $dueDateFormatted',
      isUrgent: false,
      allowedFormats: '.pdf, .zip, .txt • Max: 10MB',
      rubrics: rubricCriteria
          .map(
            (r) => {
              'id': r.id,
              'title': r.title,
              'maxPoints': r.maxPoints,
              'description': r.description,
            },
          )
          .toList(),
    );

    final event = StudentCalendarEvent(
      id: 'EV-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Entrega: $title',
      date: dueDateFormatted.split(' ').first,
      time: dueDateFormatted.contains('às')
          ? dueDateFormatted.split('às').last.trim()
          : '23:59',
      type: 'Entrega',
      discipline: cleanDiscCode,
      location: 'Ambiente Virtual de Aprendizagem (AVA)',
    );

    onAssignmentPublishedToStudent?.call(delivery, event);
    notifyListeners();
    onStudentDataChanged?.call();
  }

  bool notifySubmissionToDocente({
    required String deliveryId,
    required String assignmentId,
    required String courseCode,
    required String studentName,
    required String studentRa,
    required String fileName,
    required String protocol,
    String? comments,
    String? studentId,
  }) {
    final cleanCourseCode = _normalizeCourseCode(courseCode);
    final session = AppUserSession.instance;
    final activeIdentity = (session.identity ?? '').trim().toLowerCase();
    final matchesAuthenticatedStudent =
        activeIdentity.isNotEmpty &&
        (activeIdentity == studentRa.trim().toLowerCase() ||
            activeIdentity == (session.email ?? '').trim().toLowerCase()) &&
        _studentEnrolledInCourse(studentRa, cleanCourseCode);
    if (!session.hasPermission('submit_assignments') ||
        !matchesAuthenticatedStudent ||
        cleanCourseCode.isEmpty ||
        assignmentId.trim().isEmpty ||
        deliveryId.trim().isEmpty ||
        fileName.trim().isEmpty) {
      return false;
    }
    final submission = StudentSubmission(
      id: 'sub-$deliveryId-$studentRa',
      studentId: studentId ?? session.userId ?? studentRa,
      ra: studentRa,
      studentName: studentName,
      fileName: fileName,
      submittedAtFormatted:
          'Hoje às ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      fileSize: '',
      grade: null,
      status: SubmissionStatus.aguardandoCorrecao,
      teacherFeedback: comments != null && comments.isNotEmpty
          ? 'Comentário do Aluno: $comments [Prot: $protocol]'
          : null,
      rubricEvaluations: const [],
    );

    final accepted =
        onDocenteSubmissionReceived?.call(
          assignmentId,
          cleanCourseCode,
          submission,
        ) ??
        true;
    if (!accepted) return false;
    _deliveryIdsByAssignment[assignmentId] = deliveryId;
    notifyListeners();
    return true;
  }

  void notifyGradedToStudent({
    required String deliveryId,
    required String courseCode,
    required double finalScore,
    required String feedback,
    required List<RubricCriterion> evaluatedRubrics,
  }) {
    final session = AppUserSession.instance;
    final cleanCode = _normalizeCourseCode(courseCode);
    final teachesCourse =
        session.hasRole('admin') ||
        _teacherOwnsCourse(session.identity, cleanCode);
    if (!session.hasPermission('manage_assignments') ||
        !teachesCourse ||
        !finalScore.isFinite ||
        finalScore < 0 ||
        finalScore > 10) {
      return;
    }
    final studentDeliveryId =
        _deliveryIdsByAssignment[deliveryId] ?? deliveryId;
    onGradedReceivedByStudent?.call(
      studentDeliveryId,
      finalScore,
      feedback,
      evaluatedRubrics,
    );
    notifyListeners();
    onStudentDataChanged?.call();
  }

  // ===========================================================================
  // 3. SECRETARIA ACADÊMICA E PROTOCOLOS (ALUNO <-> ADMIN)
  // ===========================================================================
  void Function(AdminProtocolModel protocol)? onAdminProtocolReceived;

  void Function(
    String protocolCode,
    bool isApproved,
    String officialNote,
    String approverName,
  )?
  onStudentProtocolUpdated;

  void submitProtocolFromStudent({
    required String protocolCode,
    required String studentName,
    required String studentRa,
    required String studentCourse,
    required String subjectType,
    required String justification,
    String? attachmentName,
  }) {
    final session = AppUserSession.instance;
    final activeIdentity = (session.identity ?? '').trim().toLowerCase();
    final isSameStudent =
        activeIdentity.isNotEmpty &&
        (activeIdentity == studentRa.trim().toLowerCase() ||
            activeIdentity == (session.email ?? '').trim().toLowerCase());
    if (!session.hasPermission('submit_protocols') ||
        !isSameStudent ||
        protocolCode.trim().isEmpty) {
      return;
    }
    final adminProtocol = AdminProtocolModel(
      id: protocolCode,
      code: protocolCode,
      studentName: studentName,
      studentRa: studentRa,
      requestType: subjectType,
      targetComponent: studentCourse,
      date:
          'Hoje, ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      status: 'Aguardando Parecer',
      attachmentName: attachmentName ?? 'Requerimento_Digital.pdf',
      justification: justification,
      decisionNote: 'Aguardando despacho técnico da secretaria',
      signedBy: 'Mesa Receptora Central',
    );

    onAdminProtocolReceived?.call(adminProtocol);
    notifyListeners();
  }

  void dispatchProtocolDecision({
    required String protocolCode,
    required bool isApproved,
    required String decisionNote,
    required String approverName,
  }) {
    if (!AppUserSession.instance.hasPermission('dispatch_protocols')) {
      return;
    }
    onStudentProtocolUpdated?.call(
      protocolCode,
      isApproved,
      decisionNote,
      approverName,
    );
    notifyListeners();
  }

  // ===========================================================================
  // 4. MATERIAIS DE AULA E COMUNICADOS
  // ===========================================================================
  final List<Map<String, dynamic>> _sharedMaterials = [];
  List<Map<String, dynamic>> get materials =>
      List.unmodifiable(_sharedMaterials);
  void Function(Map<String, dynamic> material)? onMaterialAdded;

  void addCourseMaterial({
    required String courseCode,
    required String title,
    required String fileType,
    required String fileSize,
    String? id,
  }) {
    final session = AppUserSession.instance;
    final cleanCode = _normalizeCourseCode(courseCode);
    final teachesCourse =
        session.hasRole('admin') ||
        _teacherOwnsCourse(session.identity, cleanCode);
    if (!session.hasPermission('manage_materials') ||
        !teachesCourse ||
        title.trim().isEmpty) {
      return;
    }
    final item = {
      'id': id ?? 'mat-${DateTime.now().millisecondsSinceEpoch}',
      'courseCode': courseCode,
      'title': title,
      'fileType': fileType,
      'fileSize': fileSize,
      'date':
          'Hoje às ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
    };
    _sharedMaterials.insert(0, item);
    onMaterialAdded?.call(item);
    notifyListeners();
    onStudentDataChanged?.call();
  }

  final List<Map<String, dynamic>> _broadcastNotices = [];
  List<Map<String, dynamic>> get broadcastNotices =>
      List.unmodifiable(_broadcastNotices);

  List<Map<String, dynamic>> noticesForCourses(Iterable<String> courseCodes) {
    final normalizedCourses = courseCodes.map(_normalizeCourseCode).toSet();
    return _broadcastNotices
        .where((notice) {
          final target = (notice['targetCourse'] as String? ?? 'GERAL')
              .trim()
              .toUpperCase();
          return target == 'GERAL' ||
              target == 'INSTITUCIONAL' ||
              target == 'TODOS' ||
              normalizedCourses.contains(_normalizeCourseCode(target));
        })
        .toList(growable: false);
  }

  void Function(Map<String, dynamic> notice)? onNoticeBroadcasted;

  void broadcastNotice({
    required String title,
    required String content,
    required String senderRole,
    required String senderName,
    String? targetCourse,
  }) {
    final session = AppUserSession.instance;
    final cleanTarget = _normalizeCourseCode(targetCourse ?? '');
    final canPublish = senderRole == RolePermissionPolicy.admin
        ? session.hasPermission('publish_announcements')
        : senderRole == RolePermissionPolicy.teacher &&
              session.hasPermission('publish_course_announcements') &&
              _teacherOwnsCourse(session.identity, cleanTarget);
    if (!session.hasRole(senderRole) ||
        !canPublish ||
        title.trim().isEmpty ||
        content.trim().isEmpty) {
      return;
    }
    final notice = {
      'id': 'ntc-${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'content': content,
      'senderRole': senderRole,
      'senderName': senderName,
      'targetCourse': targetCourse ?? 'Geral',
      'date':
          'Hoje às ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
    };
    _broadcastNotices.insert(0, notice);
    onNoticeBroadcasted?.call(notice);
    notifyListeners();
  }

  void Function(
    String courseCode,
    String sessionDate,
    List<Map<String, dynamic>> attendances,
  )?
  onAttendanceHomologated;

  void registerAttendanceHomologation({
    required String courseCode,
    required String sessionDate,
    required List<Map<String, dynamic>> attendances,
  }) {
    final session = AppUserSession.instance;
    final cleanCode = _normalizeCourseCode(courseCode);
    final teachesCourse =
        session.hasRole('admin') ||
        _teacherOwnsCourse(session.identity, cleanCode);
    if (!session.hasPermission('manage_attendance') || !teachesCourse) {
      return;
    }
    onAttendanceHomologated?.call(courseCode, sessionDate, attendances);
    notifyListeners();
  }
}
