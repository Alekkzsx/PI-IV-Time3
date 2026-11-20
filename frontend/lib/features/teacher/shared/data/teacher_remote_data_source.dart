// Desenvolvido por Murillo Caravita - RA: 25014012

import '../../../../core/academic/grade_calculator.dart';
import '../../../../core/network/authenticated_api_client.dart';
import '../domain/models/academic_event.dart';
import '../domain/models/academic_notice.dart';
import '../domain/models/assignment_model.dart';
import '../domain/models/attendance_record.dart';
import '../domain/models/docente_course.dart';
import '../domain/models/docente_profile.dart';
import '../domain/models/grade_record.dart';
import '../domain/models/rubric_model.dart';
import '../domain/models/teacher_dashboard_overview.dart';
import '../domain/models/teacher_protocol.dart';

class TeacherDashboardSnapshot {
  final DocenteProfile profile;
  final TeacherDashboardOverview dashboard;
  final bool regimentalLockActive;
  final AcademicThresholds academicThresholds;
  final List<DocenteCourse> courses;
  final List<ClassSession> sessions;
  final List<AssignmentItem> assignments;
  final List<StudentGrade> grades;
  final List<AcademicEvent> events;
  final List<AcademicNotice> notices;
  final List<TeacherProtocol> protocols;

  const TeacherDashboardSnapshot({
    required this.profile,
    this.dashboard = TeacherDashboardOverview.empty,
    required this.regimentalLockActive,
    this.academicThresholds = AcademicThresholds.defaults,
    required this.courses,
    required this.sessions,
    required this.assignments,
    required this.grades,
    required this.events,
    required this.notices,
    this.protocols = const [],
  });

  factory TeacherDashboardSnapshot.fromJson(Map<String, dynamic> json) {
    final thresholds = AcademicThresholds.fromJson(json['academicThresholds']);
    final courses = _maps(json['courses']).map(_course).toList();
    final formulaByCourse = <String, String>{
      for (final course in courses) ...{
        course.id: course.evaluationFormula,
        course.code: course.evaluationFormula,
      },
    };
    return TeacherDashboardSnapshot(
      profile: _profile(_map(json['profile'])),
      dashboard: _dashboardOverview(_map(json['dashboard'])),
      regimentalLockActive: json['regimentalLockActive'] == true,
      academicThresholds: thresholds,
      courses: courses,
      sessions: _maps(json['sessions']).map(_session).toList(),
      assignments: _maps(json['assignments']).map(_assignment).toList(),
      grades: _maps(json['grades'])
          .map(
            (g) => _grade(
              g,
              thresholds: thresholds,
              formulaByCourse: formulaByCourse,
            ),
          )
          .toList(),
      events: _maps(json['events']).map(_event).toList(),
      notices: _maps(json['notices']).map(_notice).toList(),
      protocols: _maps(json['protocols']).map(_protocol).toList(),
    );
  }
}

class TeacherRemoteDataSource {
  final AuthenticatedApiClient _api;

  TeacherRemoteDataSource({AuthenticatedApiClient? api})
    : _api = api ?? AuthenticatedApiClient();

  Future<TeacherDashboardSnapshot> getBootstrap() async =>
      TeacherDashboardSnapshot.fromJson(
        await _api.getMap('/api/teacher/bootstrap'),
      );

  Future<Map<String, dynamic>> createOrSelectSession({
    required String classCode,
    required DateTime date,
    int hours = 2,
  }) {
    return _api.postMap(
      '/api/teacher/courses/${Uri.encodeComponent(classCode)}/sessions',
      {'date': date.toIso8601String(), 'hours': hours},
    );
  }

  Future<void> updateSessionAttendance({
    required String sessionId,
    required String contentProgram,
    required String methodology,
    required String location,
    required bool isHomologated,
    required List<Map<String, Object?>> attendanceList,
  }) async {
    await _api
        .patchMap('/api/teacher/sessions/${Uri.encodeComponent(sessionId)}', {
          'contentProgram': contentProgram,
          'methodology': methodology,
          'location': location,
          'isHomologated': isHomologated,
          'attendanceList': attendanceList,
        });
  }

  Future<void> advanceSyllabus(String classCode, String unitId) async {
    await _api.request(
      'PATCH',
      '/api/teacher/courses/${Uri.encodeComponent(classCode)}/syllabus/${Uri.encodeComponent(unitId)}',
    );
  }

  Future<Map<String, dynamic>> updateSyllabusPlan({
    required String classCode,
    String? syllabus,
    String? objectives,
    String? methodology,
    String? evaluationFormula,
    List<Map<String, Object?>>? bibliography,
  }) => _api.patchMap(
    '/api/teacher/courses/${Uri.encodeComponent(classCode)}/syllabus-plan',
    {
      if (syllabus != null) 'syllabus': syllabus,
      if (objectives != null) 'objectives': objectives,
      if (methodology != null) 'methodology': methodology,
      if (evaluationFormula != null) 'evaluationFormula': evaluationFormula,
      if (bibliography != null) 'bibliography': bibliography,
    },
  );

  Future<Map<String, dynamic>> publishMaterial({
    required String classCode,
    required String title,
    required String fileName,
    required String mimeType,
    required String size,
    required String contentBase64,
    String? unitAssociated,
    String? category,
  }) => _api.postMap(
    '/api/teacher/courses/${Uri.encodeComponent(classCode)}/materials',
    {
      'title': title,
      'fileName': fileName,
      'mimeType': mimeType,
      'size': size,
      'type': fileName.contains('.') ? fileName.split('.').last : 'arquivo',
      'contentBase64': contentBase64,
      if (unitAssociated != null) 'unitAssociated': unitAssociated,
      if (category != null) 'category': category,
    },
  );

  Future<void> deleteMaterial(String classCode, String materialId) async {
    await _api.delete(
      '/api/teacher/courses/${Uri.encodeComponent(classCode)}/materials/${Uri.encodeComponent(materialId)}',
    );
  }

  Future<Map<String, dynamic>> downloadMaterial(String materialId) =>
      _api.getMap('/api/files/materials/${Uri.encodeComponent(materialId)}');

  Future<Map<String, dynamic>> createAssignment({
    required String classCode,
    required Map<String, Object?> assignment,
  }) => _api.postMap(
    '/api/teacher/courses/${Uri.encodeComponent(classCode)}/assignments',
    assignment,
  );

  Future<void> deleteAssignment(String assignmentId) async {
    await _api.delete(
      '/api/teacher/assignments/${Uri.encodeComponent(assignmentId)}',
    );
  }

  Future<Map<String, dynamic>> evaluateSubmission({
    required String assignmentId,
    required String studentId,
    required double calculatedGrade,
    required String feedback,
    required List<Map<String, Object?>> evaluatedCriteria,
  }) => _api.patchMap(
    '/api/teacher/assignments/${Uri.encodeComponent(assignmentId)}/evaluate',
    {
      'studentId': studentId,
      'calculatedGrade': calculatedGrade,
      'feedback': feedback,
      'evaluatedCriteria': evaluatedCriteria,
    },
  );

  Future<Map<String, dynamic>> replyDoubt({
    required String assignmentId,
    required String doubtId,
    required String reply,
  }) => _api.postMap(
    '/api/teacher/assignments/${Uri.encodeComponent(assignmentId)}/doubts/${Uri.encodeComponent(doubtId)}/reply',
    {'reply': reply},
  );

  Future<Map<String, dynamic>> updateGrade({
    required String classCode,
    required String studentId,
    double? assignmentsScore,
    double? p1Score,
    double? projectsScore,
    double? p2Score,
  }) => _api.patchMap(
    '/api/teacher/courses/${Uri.encodeComponent(classCode)}/grades/${Uri.encodeComponent(studentId)}',
    {
      if (assignmentsScore != null) 'assignmentsScore': assignmentsScore,
      if (p1Score != null) 'p1Score': p1Score,
      if (projectsScore != null) 'projectsScore': projectsScore,
      if (p2Score != null) 'p2Score': p2Score,
    },
  );

  Future<Map<String, dynamic>> updateGradesBatch({
    required String classCode,
    required List<Map<String, Object?>> grades,
  }) => _api.patchMap(
    '/api/teacher/courses/${Uri.encodeComponent(classCode)}/grades',
    {'grades': grades},
  );

  Future<Map<String, dynamic>> homologate(String classCode) => _api.postMap(
    '/api/teacher/courses/${Uri.encodeComponent(classCode)}/grades/homologate',
  );

  Future<Map<String, dynamic>> rectify({
    required String classCode,
    required String studentId,
    required String stage,
    required double newScore,
    required String justification,
  }) => _api.postMap(
    '/api/teacher/courses/${Uri.encodeComponent(classCode)}/grades/rectify',
    {
      'studentId': studentId,
      'stage': stage,
      'newScore': newScore,
      'justification': justification,
    },
  );

  Future<Map<String, dynamic>> createForumTopic({
    required String classCode,
    required String title,
    required String body,
    String? category,
  }) => _api.postMap(
    '/api/teacher/courses/${Uri.encodeComponent(classCode)}/forum',
    {'title': title, 'body': body, if (category != null) 'category': category},
  );

  Future<Map<String, dynamic>> replyForumTopic({
    required String classCode,
    required String topicId,
    required String body,
  }) => _api.postMap(
    '/api/teacher/courses/${Uri.encodeComponent(classCode)}/forum/${Uri.encodeComponent(topicId)}/reply',
    {'body': body},
  );

  Future<Map<String, dynamic>> resolveForumTopic({
    required String classCode,
    required String topicId,
    required bool isResolved,
  }) => _api.patchMap(
    '/api/teacher/courses/${Uri.encodeComponent(classCode)}/forum/${Uri.encodeComponent(topicId)}/resolve',
    {'isResolved': isResolved},
  );

  Future<List<Map<String, dynamic>>> saveSquads({
    required String classCode,
    required List<Map<String, Object?>> squads,
  }) async {
    final result = await _api.putMap(
      '/api/teacher/courses/${Uri.encodeComponent(classCode)}/squads',
      {'squads': squads},
    );
    final values = result['squads'];
    return values is List
        ? values
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : const [];
  }

  Future<Map<String, dynamic>> createEvent({
    required String title,
    required String date,
    required String time,
    required String type,
    required String location,
  }) => _api.postMap('/api/teacher/events', {
    'title': title,
    'date': date,
    'time': time,
    'type': type,
    'location': location,
  });

  Future<Map<String, dynamic>> publishNotice({
    required String targetCourse,
    required String targetAudience,
    required String classification,
    required String title,
    required String message,
  }) => _api.postMap('/api/teacher/notices', {
    'targetCourse': targetCourse,
    'targetAudience': targetAudience,
    'classification': classification,
    'title': title,
    'message': message,
  });

  Future<Map<String, dynamic>> downloadSubmission(String id) =>
      _api.getMap('/api/files/submissions/${Uri.encodeComponent(id)}');

  Future<Map<String, dynamic>> noticeReads(String id) =>
      _api.getMap('/api/teacher/notices/${Uri.encodeComponent(id)}/reads');

  Future<Map<String, dynamic>> decideProtocol({
    required String protocolId,
    required String status,
    String? officialResponse,
  }) => _api.patchMap(
    '/api/teacher/protocols/${Uri.encodeComponent(protocolId)}/decide',
    {
      'status': status,
      if (officialResponse != null) 'officialResponse': officialResponse,
    },
  );
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<Map<String, dynamic>> _maps(dynamic value) => value is List
    ? value.whereType<Map>().map(_map).toList()
    : const <Map<String, dynamic>>[];

double _double(dynamic value, [double fallback = 0]) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? fallback;

int _int(dynamic value, [int fallback = 0]) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

String _string(dynamic value, [String fallback = '']) =>
    value == null ? fallback : value.toString();

List<String> _strings(dynamic value) => value is List
    ? value.map((item) => item.toString()).toList()
    : const <String>[];

DocenteProfile _profile(Map<String, dynamic> json) {
  return DocenteProfile(
    fullName: _string(json['fullName'], _string(json['teacherIdentity'])),
    socialName: _string(json['socialName']),
    registrationId: _string(
      json['registrationId'],
      _string(json['teacherIdentity']),
    ),
    department: _string(json['department']),
    semester: _string(json['semester']),
    campus: _string(json['campus']),
    status: _string(json['status']),
    academicEmail: _string(json['academicEmail']),
    personalEmail: _string(json['personalEmail']),
    twoFactorEnabled: json['twoFactorEnabled'] == true,
    activeSessions: _maps(json['activeSessions'])
        .map(
          (item) => ActiveSession(
            id: _string(item['id']),
            device: _string(item['device']),
            location: _string(item['location']),
            ip: _string(item['ip']),
            lastActive: _string(item['lastActive']),
            isCurrent: item['isCurrent'] == true,
          ),
        )
        .toList(),
    loginAudits: _maps(json['loginAudits'])
        .map(
          (item) => LoginAudit(
            date: _string(item['date']),
            time: _string(item['time']),
            device: _string(item['device']),
            location: _string(item['location']),
            ip: _string(item['ip']),
            status: _string(item['status']),
          ),
        )
        .toList(),
  );
}

DocenteCourse _course(Map<String, dynamic> json) {
  final syllabus = _maps(json['syllabusUnits']);
  final materials = _maps(json['materials']);
  return DocenteCourse(
    id: _string(json['id'], _string(json['code'])),
    teacherIdentity: _string(json['teacherIdentity']),
    code: _string(json['code']),
    title: _string(json['title']),
    term: _string(json['term']),
    shift: _string(json['shift']),
    room: _string(json['room']),
    schedule: _string(json['schedule']),
    enrolledCount: _int(json['enrolledCount']),
    enrolledStudentsLabelValue: json['enrolledStudentsLabel']?.toString(),
    completedHours: _int(json['completedHours']),
    totalHours: _int(json['totalHours']),
    progressValue: json['progress'] != null ? _double(json['progress']) : null,
    progressPercentageValue: json['progressPercentage'] != null
        ? _double(json['progressPercentage'])
        : null,
    progressPercentageFormattedValue: json['progressPercentageFormatted']
        ?.toString(),
    workloadCompletedLabelValue: json['workloadCompletedLabel']?.toString(),
    workloadTotalLabelValue: json['workloadTotalLabel']?.toString(),
    progressCaptionValue: json['progressCaption']?.toString(),
    gradeLocked:
        json['classGradeLocked'] == true || json['gradeLocked'] == true,
    pautaHomologated: json['pautaHomologated'] == true,
    chancelaCode: json['chancelaCode']?.toString(),
    syllabus: _string(json['syllabus'], _string(json['ementa'])),
    objectives: _string(json['objectives']),
    methodology: _string(json['methodology']),
    formulaRegime: _string(json['formulaRegime'], 'autonomia_docente'),
    evaluationFormula: _string(
      json['evaluationFormula'],
      '(N1 × 0.4) + (N2 × 0.6)',
    ),
    bibliography: _maps(json['bibliography']),
    enrolledStudents: _maps(json['enrolledStudents']),
    forumTopics: _maps(json['forumTopics']),
    squads: _maps(json['squads']),
    isLive: json['isLive'] == true,
    syllabusUnits: syllabus
        .map(
          (unit) => SyllabusUnit(
            id: _string(unit['id']),
            unitNumber: _int(unit['unitNumber']),
            title: _string(unit['title']),
            topics: _strings(unit['topics']),
            completedClasses: _int(unit['completedClasses']),
            totalClasses: _int(unit['totalClasses']),
          ),
        )
        .toList(),
    materials: materials
        .map(
          (material) => CourseMaterial(
            id: _string(material['id']),
            courseId: _string(material['courseId']),
            title: _string(material['title']),
            fileName: _string(material['fileName'], _string(material['title'])),
            date: _string(material['date']),
            size: _string(material['size']),
            type: _string(material['type']),
            unitAssociated: _string(material['unitAssociated'], 'Unidade 1'),
            category: _string(material['category'], 'Material Complementar'),
            downloadUrl: material['downloadUrl']?.toString(),
          ),
        )
        .toList(),
  );
}

ClassSession _session(Map<String, dynamic> json) {
  final dateValue = json['date']?.toString();
  final date = dateValue == null ? null : DateTime.tryParse(dateValue);
  return ClassSession(
    id: _string(json['id']),
    courseId: _string(json['courseId'], _string(json['classCode'])),
    sessionNumber: _int(json['sessionNumber']),
    hours: _int(json['hours'], 2),
    date: date,
    dateFormatted: _string(json['dateFormatted']),
    contentProgram: _string(json['contentProgram']),
    methodology: _string(json['methodology']),
    location: _string(json['location']),
    isHomologated: json['isHomologated'] == true,
    attendanceList: _maps(json['attendanceList']).map(_attendance).toList(),
  );
}

AttendanceStudent _attendance(Map<String, dynamic> json) {
  final status = switch (_string(json['status']).toLowerCase()) {
    'ausente' => AttendanceStatus.ausente,
    'justificada' => AttendanceStatus.justificada,
    _ => AttendanceStatus.presente,
  };
  final rate = _double(json['attendanceRate'], 100);
  final risk = switch (_string(json['riskLevel']).toLowerCase()) {
    'critico' => AttendanceRiskLevel.critico,
    'atencao' => AttendanceRiskLevel.atencao,
    _ => AttendanceRiskLevel.regular,
  };
  return AttendanceStudent(
    studentId: _string(json['studentId']),
    ra: _string(json['ra']),
    name: _string(json['name']),
    status: status,
    accumulatedAbsences: _int(json['accumulatedAbsences']),
    maxAbsences: _int(json['maxAbsences'], 20),
    attendanceRate: rate,
    riskLevel: risk,
    observation: _string(json['observation']),
    isConnected: json['isConnected'] == true,
  );
}

AssignmentItem _assignment(Map<String, dynamic> json) {
  return AssignmentItem(
    id: _string(json['id']),
    courseId: _string(json['courseId'], _string(json['courseCode'])),
    courseCode: _string(json['courseCode']),
    title: _string(json['title']),
    description: _string(json['description']),
    weight: _double(json['weight']),
    stage: _string(json['stage']),
    dueDateFormatted: _string(json['dueDateFormatted']),
    isUrgent: json['isUrgent'] == true,
    modality: _string(json['modality']),
    allowLateWithPenalty: json['allowLateWithPenalty'] != false,
    rubricCriteria: _maps(json['rubricCriteria']).map(_rubric).toList(),
    submissions: _maps(json['submissions']).map(_submission).toList(),
    doubts: _maps(json['doubts']),
  );
}

RubricCriterion _rubric(Map<String, dynamic> json) => RubricCriterion(
  id: _string(json['id']),
  title: _string(json['title']),
  maxPoints: _double(json['maxPoints']),
  description: _string(json['description']),
  assignedScore: json['assignedScore'] == null
      ? null
      : _double(json['assignedScore']),
);

StudentSubmission _submission(Map<String, dynamic> json) {
  final status = switch (_string(json['status']).toLowerCase()) {
    'avaliada' || 'corrigido' => SubmissionStatus.corrigido,
    'aguardandocorrecao' ||
    'aguardando correção' => SubmissionStatus.aguardandoCorrecao,
    'atrasado' => SubmissionStatus.atrasado,
    'pendente' ||
    'naoentregue' ||
    'não entregue' => SubmissionStatus.naoEntregue,
    _ => SubmissionStatus.entregue,
  };
  return StudentSubmission(
    id: _string(json['id']),
    studentId: _string(json['studentId']),
    ra: _string(json['ra']),
    studentName: _string(json['studentName']),
    fileName: json['fileName']?.toString(),
    submittedAtFormatted: (json['submittedAtFormatted'] ?? json['submittedAt'])
        ?.toString(),
    fileSize: json['fileSize']?.toString(),
    grade: json['finalGrade'] == null ? null : _double(json['finalGrade']),
    status: status,
    teacherFeedback: json['teacherFeedback']?.toString(),
    rubricEvaluations: _maps(json['rubricEvaluations']).map(_rubric).toList(),
  );
}

StudentGrade _grade(
  Map<String, dynamic> json, {
  AcademicThresholds thresholds = AcademicThresholds.defaults,
  Map<String, String> formulaByCourse = const {},
}) {
  final courseId = _string(json['courseId'], _string(json['classCode']));
  final rawFormula = json['evaluationFormula']?.toString().trim() ?? '';
  final effectiveFormula = rawFormula.isNotEmpty
      ? rawFormula
      : (formulaByCourse[courseId] ?? thresholds.evaluationFormula);
  return StudentGrade(
    studentId: _string(json['studentId']),
    courseId: courseId,
    ra: _string(json['ra']),
    studentName: _string(json['studentName']),
    assignmentsScore: _double(json['assignmentsScore']),
    p1Score: _double(json['p1Score']),
    projectsScore: _double(json['projectsScore']),
    p2Score: _double(json['p2Score']),
    attendanceRate: _double(json['attendanceRate'], 100),
    hasGrades: json.containsKey('hasGrades') ? json['hasGrades'] == true : true,
    evaluationFormula: effectiveFormula,
    thresholds: thresholds,
  );
}

AcademicEvent _event(Map<String, dynamic> json) {
  final type = switch (_string(json['type']).toLowerCase()) {
    'avaliacao' || 'entrega' => EventType.avaliacao,
    'plantao' => EventType.plantao,
    'colegiado' => EventType.colegiado,
    'reuniao' => EventType.reuniao,
    _ => EventType.aula,
  };
  return AcademicEvent(
    id: _string(json['id']),
    title: _string(json['title']),
    date: _string(json['date']),
    time: _string(json['time']),
    type: type,
    location: _string(json['location']),
    isSynced: json['isSynced'] != false,
  );
}

AcademicNotice _notice(Map<String, dynamic> json) {
  final classification = switch (_string(
    json['classification'],
  ).toLowerCase()) {
    'urgencia' || 'urgência' => NoticeClassification.urgencia,
    'convocacao' ||
    'convocação' ||
    'secretaria' => NoticeClassification.convocacao,
    _ => NoticeClassification.informativo,
  };
  return AcademicNotice(
    id: _string(json['id']),
    author: _string(json['author']),
    targetCourse: _string(json['targetCourse']),
    targetAudience: _string(json['targetAudience']),
    classification: classification,
    publishedAt: _string(json['publishedAt']),
    title: _string(json['title']),
    message: _string(json['message']),
    readCount: _int(json['readCount']),
    totalRecipients: _int(json['totalRecipients']),
    isFromSecretaria: json['isFromSecretaria'] == true,
  );
}

TeacherProtocol _protocol(Map<String, dynamic> json) {
  final statusStr = _string(json['status']).toLowerCase();
  final status = switch (statusStr) {
    'deferido' => TeacherProtocolStatus.deferido,
    'indeferido' => TeacherProtocolStatus.indeferido,
    _ => TeacherProtocolStatus.pendente,
  };
  return TeacherProtocol(
    id: _string(json['id']),
    code: _string(json['code']),
    studentName: _string(json['studentName']),
    studentRa: _string(json['studentRa']),
    requestType: _string(json['requestType']),
    targetComponent: _string(json['targetComponent']),
    description: _string(json['description'], _string(json['justification'])),
    status: status,
    createdAt: _string(json['createdAt']),
    documentUrl: json['documentUrl']?.toString(),
    officialResponse: json['officialResponse']?.toString(),
  );
}

TeacherDashboardKpiItem _kpiItem(Map<String, dynamic> json) {
  return TeacherDashboardKpiItem(
    label: _string(json['label']),
    valueFormatted: _string(json['valueFormatted'], '00'),
    unitLabel: _string(json['unitLabel']),
    footerLabel: _string(json['footerLabel']),
    footerValue: _string(json['footerValue']),
    progress: _double(json['progress']),
  );
}

TeacherDashboardOverview _dashboardOverview(Map<String, dynamic> json) {
  final hero = _map(json['hero']);
  final stats = _map(json['stats']);
  final todayClass = _map(json['todayClass']);
  final sessionRaw = todayClass['session'];
  final sessionMap = sessionRaw is Map ? _map(sessionRaw) : null;
  final officeHours = _map(todayClass['officeHours']);
  final upcoming = _map(json['upcomingDeadlines']);

  return TeacherDashboardOverview(
    hero: TeacherHeroInfo(
      greetingPrefix: _string(hero['greetingPrefix']),
      firstName: _string(hero['firstName']),
      department: _string(hero['department']),
      semester: _string(hero['semester']),
    ),
    stats: TeacherDashboardStats(
      activeClasses: _kpiItem(_map(stats['activeClasses'])),
      monthlyAssignments: _kpiItem(_map(stats['monthlyAssignments'])),
      workload: _kpiItem(_map(stats['workload'])),
      averageAttendance: _kpiItem(_map(stats['averageAttendance'])),
    ),
    todayClass: TeacherTodayClassInfo(
      todayBadge: _string(todayClass['todayBadge']),
      session: sessionMap == null
          ? null
          : TeacherLiveSessionPreview(
              courseId: _string(sessionMap['courseId']),
              code: _string(sessionMap['code']),
              roomCode: _string(sessionMap['roomCode']),
              title: _string(sessionMap['title']),
              timeRange: _string(sessionMap['timeRange']),
              isLive: sessionMap['isLive'] == true,
              statusLabel: _string(sessionMap['statusLabel']),
              connectedCount: _int(sessionMap['connectedCount']),
              connectedLabel: _string(sessionMap['connectedLabel']),
              locationLabel: _string(sessionMap['locationLabel']),
              buttonLabel: _string(sessionMap['buttonLabel']),
            ),
      officeHours: TeacherOfficeHoursInfo(
        title: _string(officeHours['title']),
        subtitle: _string(officeHours['subtitle']),
        location: _string(officeHours['location']),
      ),
    ),
    upcomingDeadlines: TeacherUpcomingDeadlines(
      totalCountFormatted: _string(upcoming['totalCountFormatted'], '00'),
      items: _maps(upcoming['items'])
          .map(
            (item) => TeacherDeadlinePreviewItem(
              id: _string(item['id']),
              courseId: _string(item['courseId']),
              typeLabel: _string(item['typeLabel']),
              displayTitle: _string(item['displayTitle']),
              courseName: _string(item['courseName']),
              dueLabel: _string(item['dueLabel']),
              isUrgent: item['isUrgent'] == true,
            ),
          )
          .toList(),
    ),
    recentNotices: _maps(json['recentNotices'])
        .map(
          (item) => TeacherNoticePreviewItem(
            id: _string(item['id']),
            authorLabel: _string(item['authorLabel']),
            timeLabel: _string(item['timeLabel']),
            title: _string(item['title']),
            message: _string(item['message']),
          ),
        )
        .toList(),
  );
}
