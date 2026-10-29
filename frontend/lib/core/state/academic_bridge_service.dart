// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
// Barramento Central de Sincronização e Regras de Negócio Multiperfil (Aluno, Docente, Admin)

import 'package:flutter/foundation.dart';
import 'app_user_session.dart';
import 'role_permission_policy.dart';
import '../../features/student/shared/data/student_mock_data.dart';
import '../../features/teacher/shared/domain/models/assignment_model.dart';
import '../../features/teacher/shared/domain/models/rubric_model.dart';
import '../../features/teacher/shared/data/docente_mock_data.dart';
import '../../features/admin/shared/data/admin_mock_data.dart';
import '../../features/student/secretariat/domain/entities/protocol_request.dart';

/// Modelo de sessão de aula / vídeo chamada de uma turma.
class AcademicLiveSession {
  final String courseCode; // Ex: '218131 - APS-II' ou 'APS-II'
  final String courseTitle;
  final String professorName;
  final String roomCode;
  bool isOpen;
  String? openedByRole; // 'docente', 'admin'
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

/// Ouvinte para atualização de protocolos entre Aluno e Admin.
typedef ProtocolUpdateCallback = void Function(ProtocolRequest request);

/// Serviço Singleton responsável pela ponte em tempo real entre visões do Aluno, Docente e Admin.
class AcademicBridgeService extends ChangeNotifier {
  static final AcademicBridgeService instance =
      AcademicBridgeService._internal();

  AcademicBridgeService._internal() {
    _initLiveSessions();
  }

  factory AcademicBridgeService() => instance;

  // ===========================================================================
  // 1. GESTÃO E PERMISSÕES DE VÍDEO CHAMADAS POR TURMA
  // ===========================================================================
  final Map<String, AcademicLiveSession> _liveSessions = {};
  final Map<String, String> _courseCodeAliases = {};

  void _initLiveSessions() {
    for (final classModel in AdminMockData.classes) {
      final classCode = classModel.code.trim().toUpperCase();
      final shortCode = classCode.split(' - ').last.trim();
      _courseCodeAliases[classCode] = shortCode;
      _courseCodeAliases[shortCode] = shortCode;
      _liveSessions.putIfAbsent(
        shortCode,
        () => AcademicLiveSession(
          courseCode: shortCode,
          courseTitle: classModel.subjectName,
          professorName: classModel.professor,
          roomCode: shortCode,
        ),
      );
    }
  }

  /// Retorna as informações da sessão de uma turma ou cria um placeholder.
  AcademicLiveSession getSession(String rawCode) {
    final cleanCode = _normalizeCourseCode(rawCode);
    return _liveSessions[cleanCode] ??
        AcademicLiveSession(
          courseCode: cleanCode,
          courseTitle: 'Turma $cleanCode',
          professorName: 'Docente Responsável',
          roomCode: cleanCode,
          isOpen: false,
        );
  }

  /// Verifica se a sessão de uma turma está aberta no momento.
  bool isSessionOpen(String rawCode) {
    final cleanCode = _normalizeCourseCode(rawCode);
    return _liveSessions[cleanCode]?.isOpen ?? false;
  }

  bool hasSession(String rawCode) {
    return _liveSessions.containsKey(_normalizeCourseCode(rawCode));
  }

  /// Valida se o perfil do usuário possui autorização institucional para ABRIR a vídeo chamada.
  /// A autorização por turma é verificada em [canUserOpenSessionForCourse].
  bool canUserOpenSession({required String role}) {
    final normalized = role.toLowerCase().trim();
    return normalized == RolePermissionPolicy.teacher ||
        normalized == RolePermissionPolicy.admin;
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
    return DocenteMockData.coursesForIdentity(
      teacherIdentity ?? '',
    ).any((course) => _normalizeCourseCode(course.code) == courseCode);
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
    final normalizedRa = studentRa?.trim();
    if (normalizedRa != StudentMockData.studentRa) return false;
    return StudentMockData.disciplines.any(
      (discipline) => _normalizeCourseCode(discipline.code) == courseCode,
    );
  }

  /// Abre a vídeo chamada da turma. Retorna `true` se autorizado, `false` se negado.
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
      debugPrint(
        '[AcademicBridge] Abertura negada para papel/turma sem autorização válida.',
      );
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
    debugPrint(
      '[AcademicBridge] Sala ${session.roomCode} ABERTA com sucesso por $openedByName ($openedByRole).',
    );
    return true;
  }

  /// Encerra a vídeo chamada da turma.
  bool closeSession(String rawCourseCode) {
    final cleanCode = _normalizeCourseCode(rawCourseCode);
    final session = _liveSessions[cleanCode];
    final user = AppUserSession.instance;
    if (session == null ||
        !session.isOpen ||
        !(user.hasRole(RolePermissionPolicy.admin) &&
                user.hasPermission('manage_video_calls') ||
            user.hasRole(RolePermissionPolicy.teacher) &&
                session.openedByRole == RolePermissionPolicy.teacher &&
                session.openedByIdentity == user.identity)) {
      debugPrint('[AcademicBridge] Encerramento negado para o perfil atual.');
      return false;
    }
    session.isOpen = false;
    session.openedByRole = null;
    session.openedByName = null;
    session.openedByIdentity = null;
    session.openedAt = null;
    notifyListeners();
    debugPrint('[AcademicBridge] Sala $cleanCode ENCERRADA.');
    return true;
  }

  String _normalizeCourseCode(String raw) {
    final trimmed = raw.trim().toUpperCase();
    return _courseCodeAliases[trimmed] ?? trimmed;
  }

  bool courseCodesMatch(String first, String second) =>
      _normalizeCourseCode(first) == _normalizeCourseCode(second);

  // ===========================================================================
  // 2. ATIVIDADES, TAREFAS, UPLOADS E AVALIAÇÃO COM RUBRICA (DOCENTE <-> ALUNO)
  // ===========================================================================

  /// Callback registrado pelo DocenteController para receber notificações de novas submissões do aluno.
  bool Function(
    String assignmentId,
    String courseCode,
    StudentSubmission submission,
  )?
  onDocenteSubmissionReceived;

  /// Callback registrado pelo StudentPortalController para incorporar nova atividade do professor.
  void Function(
    StudentDeliveryItem newDelivery,
    StudentCalendarEvent calendarEvent,
  )?
  onAssignmentPublishedToStudent;

  /// Callback registrado pelo StudentPortalController para atualizar nota e rubricas avaliadas pelo docente.
  void Function(
    String deliveryId,
    double finalScore,
    String feedback,
    List<RubricCriterion> evaluatedRubrics,
  )?
  onGradedReceivedByStudent;

  /// Callback registrado pelo StudentPortalController para receber atividades publicadas ou notas.
  VoidCallback? onStudentDataChanged;
  final Map<String, String> _deliveryIdsByAssignment = {};

  /// Publica uma nova atividade do Docente para a visão do Aluno.
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
    final teachesCourse = DocenteMockData.coursesForIdentity(
      session.identity ?? '',
    ).any((course) => courseCodesMatch(course.code, courseCode));
    if (!session.hasPermission('manage_assignments') ||
        !teachesCourse ||
        !_liveSessions.containsKey(cleanDiscCode) ||
        assignmentId.trim().isEmpty ||
        title.trim().isEmpty ||
        weight <= 0 ||
        !weight.isFinite ||
        rubricCriteria.isEmpty) {
      debugPrint(
        '[AcademicBridge] Publicação de atividade recusada por perfil, turma ou dados inválidos.',
      );
      return;
    }
    final delivery = StudentDeliveryItem(
      id: assignmentId,
      sourceAssignmentId: assignmentId,
      activityCode: '${cleanDiscCode.split('-').first} - ATV - 05',
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
      allowedFormats: '.pdf, .zip, .drawio • Max: 50MB',
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

    if (onAssignmentPublishedToStudent != null) {
      onAssignmentPublishedToStudent!(delivery, event);
    }

    notifyListeners();
    if (onStudentDataChanged != null) {
      onStudentDataChanged!();
    }
    debugPrint(
      '[AcademicBridge] Atividade "$title" publicada pelo professor para a turma $courseCode.',
    );
  }

  /// O Aluno realiza o upload de uma entrega e notifica o Docente responsável.
  bool notifySubmissionToDocente({
    required String deliveryId,
    required String assignmentId,
    required String courseCode,
    required String studentName,
    required String studentRa,
    required String fileName,
    required String protocol,
    String? comments,
  }) {
    final cleanCourseCode = _normalizeCourseCode(courseCode);
    final session = AppUserSession.instance;
    if (!session.hasPermission('submit_assignments') ||
        !StudentMockData.ownsDemoRecords(session.identity ?? '') ||
        studentRa != StudentMockData.studentRa ||
        cleanCourseCode.isEmpty ||
        assignmentId.trim().isEmpty ||
        deliveryId.trim().isEmpty ||
        fileName.trim().isEmpty) {
      debugPrint(
        '[AcademicBridge] Submissão recusada: atividade ou turma inválida.',
      );
      return false;
    }
    final submission = StudentSubmission(
      id: 'sub-$deliveryId-$studentRa',
      studentId: 'st-1',
      ra: studentRa,
      studentName: studentName,
      fileName: fileName,
      submittedAtFormatted:
          'Hoje às ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      fileSize: '2.8 MB',
      grade: null,
      status: SubmissionStatus.aguardandoCorrecao,
      teacherFeedback: comments != null
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
        false;
    if (!accepted) {
      debugPrint(
        '[AcademicBridge] Submissão recusada: atividade, turma ou matrícula não conferem.',
      );
      return false;
    }
    _deliveryIdsByAssignment[assignmentId] = deliveryId;
    notifyListeners();
    debugPrint(
      '[AcademicBridge] Aluno $studentName submeteu arquivo "$fileName" com protocolo $protocol.',
    );
    return true;
  }

  /// O Docente avalia a atividade com rubricas e notas, sincronizando a visão do Aluno.
  void notifyGradedToStudent({
    required String deliveryId,
    required String courseCode,
    required double finalScore,
    required String feedback,
    required List<RubricCriterion> evaluatedRubrics,
  }) {
    final session = AppUserSession.instance;
    final teachesCourse = DocenteMockData.coursesForIdentity(
      session.identity ?? '',
    ).any((course) => courseCodesMatch(course.code, courseCode));
    if (!session.hasPermission('manage_assignments') ||
        !teachesCourse ||
        !finalScore.isFinite ||
        finalScore < 0 ||
        finalScore > 10) {
      debugPrint('[AcademicBridge] Avaliação negada para o perfil atual.');
      return;
    }
    final studentDeliveryId =
        _deliveryIdsByAssignment[deliveryId] ?? deliveryId;
    if (onGradedReceivedByStudent != null) {
      onGradedReceivedByStudent!(
        studentDeliveryId,
        finalScore,
        feedback,
        evaluatedRubrics,
      );
    }
    notifyListeners();
    if (onStudentDataChanged != null) {
      onStudentDataChanged!();
    }
    debugPrint(
      '[AcademicBridge] Submissão $deliveryId avaliada pelo docente com nota $finalScore.',
    );
  }

  // ===========================================================================
  // 3. SECRETARIA ACADÊMICA GERAL E PROTOCOLOS (ALUNO <-> ADMIN)
  // ===========================================================================

  /// Callback registrado pelo AdminPortalController para receber novos requerimentos protocolados pelo aluno.
  void Function(AdminProtocolModel protocol)? onAdminProtocolReceived;

  /// Callback registrado pelo StudentSecretariatController para receber despachos homologados pelo admin.
  void Function(
    String protocolCode,
    bool isApproved,
    String officialNote,
    String approverName,
  )?
  onStudentProtocolUpdated;

  /// O Aluno cadastra um novo requerimento formal na Secretaria Virtual.
  void submitProtocolFromStudent({
    required String protocolCode,
    required String studentName,
    required String studentRa,
    required String studentCourse,
    required String subjectType,
    required String justification,
    String? attachmentName,
  }) {
    if (!AppUserSession.instance.hasPermission('submit_protocols') ||
        !StudentMockData.ownsDemoRecords(
          AppUserSession.instance.identity ?? '',
        ) ||
        studentRa != StudentMockData.studentRa ||
        protocolCode.trim().isEmpty) {
      debugPrint('[AcademicBridge] Protocolo recusado para o perfil atual.');
      return;
    }
    final adminProtocol = AdminProtocolModel(
      id: protocolCode,
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

    if (onAdminProtocolReceived != null) {
      onAdminProtocolReceived!(adminProtocol);
    }
    notifyListeners();
    debugPrint(
      '[AcademicBridge] Novo protocolo $protocolCode de $studentName encaminhado à Mesa da Secretaria.',
    );
  }

  /// O Administrador analisa o requerimento e emite despacho oficial (Deferimento/Indeferimento).
  void dispatchProtocolDecision({
    required String protocolCode,
    required bool isApproved,
    required String decisionNote,
    required String approverName,
  }) {
    if (!AppUserSession.instance.hasPermission('dispatch_protocols')) {
      debugPrint('[AcademicBridge] Despacho negado para o perfil atual.');
      return;
    }
    if (onStudentProtocolUpdated != null) {
      onStudentProtocolUpdated!(
        protocolCode,
        isApproved,
        decisionNote,
        approverName,
      );
    }
    notifyListeners();
    debugPrint(
      '[AcademicBridge] Protocolo $protocolCode decidido pelo Admin: ${isApproved ? 'DEFERIDO' : 'INDEFERIDO'}.',
    );
  }

  // ===========================================================================
  // 4. MATERIAIS DE AULA (DOCENTE -> ALUNO)
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
  }) {
    final session = AppUserSession.instance;
    final teachesCourse = DocenteMockData.coursesForIdentity(
      session.identity ?? '',
    ).any((course) => courseCodesMatch(course.code, courseCode));
    if (!session.hasPermission('manage_materials') ||
        !teachesCourse ||
        title.trim().isEmpty) {
      debugPrint('[AcademicBridge] Publicação de material negada.');
      return;
    }
    final item = {
      'id': 'mat-${DateTime.now().millisecondsSinceEpoch}',
      'courseCode': courseCode,
      'title': title,
      'fileType': fileType,
      'fileSize': fileSize,
      'date':
          'Hoje às ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
    };
    _sharedMaterials.insert(0, item);
    if (onMaterialAdded != null) {
      onMaterialAdded!(item);
    }
    notifyListeners();
    if (onStudentDataChanged != null) {
      onStudentDataChanged!();
    }
  }

  // ===========================================================================
  // 5. COMUNICADOS E AVISOS (DOCENTE/ADMIN -> ALUNO)
  // ===========================================================================
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
              normalizedCourses.contains(_normalizeCourseCode(target));
        })
        .toList(growable: false);
  }

  void Function(Map<String, dynamic> notice)? onNoticeBroadcasted;

  void broadcastNotice({
    required String title,
    required String content,
    required String senderRole, // 'docente' ou 'admin'
    required String senderName,
    String? targetCourse,
  }) {
    final session = AppUserSession.instance;
    final canPublish = senderRole == RolePermissionPolicy.admin
        ? session.hasPermission('publish_announcements')
        : senderRole == RolePermissionPolicy.teacher &&
              session.hasPermission('publish_course_announcements') &&
              DocenteMockData.coursesForIdentity(session.identity ?? '').any(
                (course) => courseCodesMatch(course.code, targetCourse ?? ''),
              );
    if (!session.hasRole(senderRole) ||
        !canPublish ||
        title.trim().isEmpty ||
        content.trim().isEmpty) {
      debugPrint('[AcademicBridge] Publicação de comunicado negada.');
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
    if (onNoticeBroadcasted != null) {
      onNoticeBroadcasted!(notice);
    }
    notifyListeners();
  }

  // ===========================================================================
  // 6. FREQUÊNCIA & DIÁRIO DE CLASSE (DOCENTE -> ALUNO)
  // ===========================================================================
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
    final teachesCourse = DocenteMockData.coursesForIdentity(
      session.identity ?? '',
    ).any((course) => courseCodesMatch(course.code, courseCode));
    if (!session.hasPermission('manage_attendance') || !teachesCourse) {
      debugPrint('[AcademicBridge] Homologação de frequência negada.');
      return;
    }
    if (onAttendanceHomologated != null) {
      onAttendanceHomologated!(courseCode, sessionDate, attendances);
    }
    notifyListeners();
    debugPrint(
      '[AcademicBridge] Diário de classe homologado para $courseCode com ${attendances.length} discentes.',
    );
  }
}
