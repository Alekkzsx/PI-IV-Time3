// Desenvolvido por Murillo Caravita - RA: 25014012

import '../../../../core/network/authenticated_api_client.dart';
import '../domain/models/academic_event.dart';
import '../domain/models/academic_notice.dart';
import '../domain/models/assignment_model.dart';
import '../domain/models/attendance_record.dart';
import '../domain/models/docente_course.dart';
import '../domain/models/docente_profile.dart';
import '../domain/models/grade_record.dart';
import '../domain/models/rubric_model.dart';

class TeacherDashboardSnapshot {
  final DocenteProfile profile;
  final bool regimentalLockActive;
  final List<DocenteCourse> courses;
  final List<ClassSession> sessions;
  final List<AssignmentItem> assignments;
  final List<StudentGrade> grades;
  final List<AcademicEvent> events;
  final List<AcademicNotice> notices;

  const TeacherDashboardSnapshot({
    required this.profile,
    required this.regimentalLockActive,
    required this.courses,
    required this.sessions,
    required this.assignments,
    required this.grades,
    required this.events,
    required this.notices,
  });

  factory TeacherDashboardSnapshot.fromJson(Map<String, dynamic> json) {
    return TeacherDashboardSnapshot(
      profile: _profile(_map(json['profile'])),
      regimentalLockActive: json['regimentalLockActive'] == true,
      courses: _maps(json['courses']).map(_course).toList(),
      sessions: _maps(json['sessions']).map(_session).toList(),
      assignments: _maps(json['assignments']).map(_assignment).toList(),
      grades: _maps(json['grades']).map(_grade).toList(),
      events: _maps(json['events']).map(_event).toList(),
      notices: _maps(json['notices']).map(_notice).toList(),
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
    required bool isHomologated,
    required List<Map<String, Object?>> attendanceList,
  }) async {
    await _api.patchMap('/api/teacher/sessions/${Uri.encodeComponent(sessionId)}', {
      'contentProgram': contentProgram,
      'methodology': methodology,
      'isHomologated': isHomologated,
      'attendanceList': attendanceList,
    });
  }
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
    registrationId: _string(json['registrationId'], _string(json['teacherIdentity'])),
    department: _string(json['department']),
    semester: _string(json['semester']),
    campus: _string(json['campus']),
    status: _string(json['status']),
    academicEmail: _string(json['academicEmail']),
    personalEmail: _string(json['personalEmail']),
    twoFactorEnabled: json['twoFactorEnabled'] == true,
    activeSessions: _maps(json['activeSessions'])
        .map((item) => ActiveSession(
              id: _string(item['id']),
              device: _string(item['device']),
              location: _string(item['location']),
              ip: _string(item['ip']),
              lastActive: _string(item['lastActive']),
              isCurrent: item['isCurrent'] == true,
            ))
        .toList(),
    loginAudits: _maps(json['loginAudits'])
        .map((item) => LoginAudit(
              date: _string(item['date']),
              time: _string(item['time']),
              device: _string(item['device']),
              location: _string(item['location']),
              ip: _string(item['ip']),
              status: _string(item['status']),
            ))
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
    completedHours: _int(json['completedHours']),
    totalHours: _int(json['totalHours']),
    gradeLocked: json['classGradeLocked'] == true || json['gradeLocked'] == true,
    pautaHomologated: json['pautaHomologated'] == true,
    chancelaCode: json['chancelaCode']?.toString(),
    syllabusUnits: syllabus
        .map((unit) => SyllabusUnit(
              id: _string(unit['id']),
              unitNumber: _int(unit['unitNumber']),
              title: _string(unit['title']),
              topics: _strings(unit['topics']),
              completedClasses: _int(unit['completedClasses']),
              totalClasses: _int(unit['totalClasses']),
            ))
        .toList(),
    materials: materials
        .map((material) => CourseMaterial(
              id: _string(material['id']),
              courseId: _string(material['courseId']),
              title: _string(material['title']),
              date: _string(material['date']),
              size: _string(material['size']),
              type: _string(material['type']),
            ))
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
    'aguardandocorrecao' || 'aguardando correção' => SubmissionStatus.aguardandoCorrecao,
    'atrasado' => SubmissionStatus.atrasado,
    'pendente' || 'naoentregue' || 'não entregue' => SubmissionStatus.naoEntregue,
    _ => SubmissionStatus.entregue,
  };
  return StudentSubmission(
    id: _string(json['id']),
    studentId: _string(json['studentId']),
    ra: _string(json['ra']),
    studentName: _string(json['studentName']),
    fileName: json['fileName']?.toString(),
    submittedAtFormatted: (json['submittedAtFormatted'] ?? json['submittedAt'])?.toString(),
    fileSize: json['fileSize']?.toString(),
    grade: json['finalGrade'] == null ? null : _double(json['finalGrade']),
    status: status,
    teacherFeedback: json['teacherFeedback']?.toString(),
    rubricEvaluations: _maps(json['rubricEvaluations']).map(_rubric).toList(),
  );
}

StudentGrade _grade(Map<String, dynamic> json) => StudentGrade(
      studentId: _string(json['studentId']),
      courseId: _string(json['courseId'], _string(json['classCode'])),
      ra: _string(json['ra']),
      studentName: _string(json['studentName']),
      assignmentsScore: _double(json['assignmentsScore']),
      p1Score: _double(json['p1Score']),
      projectsScore: _double(json['projectsScore']),
      p2Score: _double(json['p2Score']),
      attendanceRate: _double(json['attendanceRate'], 100),
    );

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
  final classification = switch (_string(json['classification']).toLowerCase()) {
    'urgencia' || 'urgência' => NoticeClassification.urgencia,
    'convocacao' || 'convocação' || 'secretaria' => NoticeClassification.convocacao,
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
