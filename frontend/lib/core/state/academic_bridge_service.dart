// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
// Barramento Central de Sincronização e Regras de Negócio Multiperfil (Aluno, Docente, Admin)

import 'package:flutter/foundation.dart';
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
  DateTime? openedAt;

  AcademicLiveSession({
    required this.courseCode,
    required this.courseTitle,
    required this.professorName,
    required this.roomCode,
    this.isOpen = false,
    this.openedByRole,
    this.openedByName,
    this.openedAt,
  });

  AcademicLiveSession copyWith({
    bool? isOpen,
    String? openedByRole,
    String? openedByName,
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
    return normalized == 'docente' ||
        normalized == 'teacher' ||
        normalized == 'admin';
  }

  bool canUserOpenSessionForCourse({
    required String role,
    required String rawCourseCode,
  }) {
    final normalizedRole = role.toLowerCase().trim();
    final courseCode = _normalizeCourseCode(rawCourseCode);
    if (!_liveSessions.containsKey(courseCode) ||
        !canUserOpenSession(role: normalizedRole)) {
      return false;
    }
    if (normalizedRole == 'admin') return true;
    return DocenteMockData.initialCourses.any(
      (course) => _normalizeCourseCode(course.code) == courseCode,
    );
  }

  bool canUserJoinSession({
    required String role,
    required String rawCourseCode,
    String? studentRa,
  }) {
    final normalizedRole = role.toLowerCase().trim();
    final courseCode = _normalizeCourseCode(rawCourseCode);
    if (!_liveSessions.containsKey(courseCode) || !isSessionOpen(courseCode)) {
      return false;
    }
    if (canUserOpenSessionForCourse(
      role: normalizedRole,
      rawCourseCode: courseCode,
    )) {
      return true;
    }
    if (normalizedRole != 'aluno' && normalizedRole != 'student') {
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
  }) {
    final cleanCode = _normalizeCourseCode(rawCourseCode);
    if (!canUserOpenSessionForCourse(
          role: openedByRole,
          rawCourseCode: cleanCode,
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
  void closeSession(String rawCourseCode) {
    final cleanCode = _normalizeCourseCode(rawCourseCode);
    if (_liveSessions.containsKey(cleanCode)) {
      _liveSessions[cleanCode]!.isOpen = false;
      _liveSessions[cleanCode]!.openedAt = null;
      notifyListeners();
      debugPrint('[AcademicBridge] Sala $cleanCode ENCERRADA.');
    }
  }

  String _normalizeCourseCode(String raw) {
    final trimmed = raw.trim().toUpperCase();
    return _courseCodeAliases[trimmed] ?? trimmed;
  }

  // ===========================================================================
  // 2. ATIVIDADES, TAREFAS, UPLOADS E AVALIAÇÃO COM RUBRICA (DOCENTE <-> ALUNO)
  // ===========================================================================

  /// Callback registrado pelo DocenteController para receber notificações de novas submissões do aluno.
  void Function(String assignmentId, StudentSubmission submission)?
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
    final cleanDiscCode = courseCode.contains('APS')
        ? 'APS-II'
        : (courseCode.contains('BD') ? 'BD-II' : 'FSO');
    final delivery = StudentDeliveryItem(
      id: assignmentId,
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
  void notifySubmissionToDocente({
    required String deliveryId,
    required String studentName,
    required String studentRa,
    required String fileName,
    required String protocol,
    String? comments,
  }) {
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

    if (onDocenteSubmissionReceived != null) {
      onDocenteSubmissionReceived!(deliveryId, submission);
    }
    notifyListeners();
    debugPrint(
      '[AcademicBridge] Aluno $studentName submeteu arquivo "$fileName" com protocolo $protocol.',
    );
  }

  /// O Docente avalia a atividade com rubricas e notas, sincronizando a visão do Aluno.
  void notifyGradedToStudent({
    required String deliveryId,
    required double finalScore,
    required String feedback,
    required List<RubricCriterion> evaluatedRubrics,
  }) {
    if (onGradedReceivedByStudent != null) {
      onGradedReceivedByStudent!(
        deliveryId,
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

  void Function(Map<String, dynamic> notice)? onNoticeBroadcasted;

  void broadcastNotice({
    required String title,
    required String content,
    required String senderRole, // 'docente' ou 'admin'
    required String senderName,
    String? targetCourse,
  }) {
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
    if (onAttendanceHomologated != null) {
      onAttendanceHomologated!(courseCode, sessionDate, attendances);
    }
    notifyListeners();
    debugPrint(
      '[AcademicBridge] Diário de classe homologado para $courseCode com ${attendances.length} discentes.',
    );
  }
}
