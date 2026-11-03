// Modelos de domínio reais do Portal Administrativo (Coordenação & Secretaria).

class AdminUserModel {
  final String id;
  final String identity;
  final String name;
  final String email;
  final String profile; // 'aluno', 'docente', 'admin'
  final String departmentOrCourse;
  String status; // 'Ativo', 'Suspenso'
  final bool twoFactorRequired;
  int activeSessionsCount;
  String? suspensionReason;
  String lastLogin;
  String roleLevel;
  String? linkedInfo;

  AdminUserModel({
    required this.id,
    String? identity,
    required this.name,
    required this.email,
    required this.profile,
    required this.departmentOrCourse,
    required this.status,
    required this.twoFactorRequired,
    this.activeSessionsCount = 0,
    this.suspensionReason,
    this.lastLogin = 'Sem registro recente',
    this.roleLevel = 'Padrão',
    this.linkedInfo,
  }) : identity = identity ?? id;
}

class AdminCourseModel {
  final String code;
  final String name;
  final String matrix;
  final String workload;
  final int studentsCount;
  final String formula;
  final String department;
  final String modality;
  final List<Map<String, dynamic>> components;

  const AdminCourseModel({
    required this.code,
    required this.name,
    required this.matrix,
    required this.workload,
    required this.studentsCount,
    required this.formula,
    this.department = 'Departamento de Computação e Sistemas',
    this.modality = 'Graduação',
    required this.components,
  });
}

class AdminEnrolledStudent {
  final String enrollmentId;
  final String studentId;
  final String ra;
  final String displayName;
  final String enrolledAt;

  const AdminEnrolledStudent({
    required this.enrollmentId,
    required this.studentId,
    required this.ra,
    required this.displayName,
    this.enrolledAt = '',
  });

  factory AdminEnrolledStudent.fromJson(Map<String, dynamic> json) {
    return AdminEnrolledStudent(
      enrollmentId: (json['enrollmentId'] ?? json['id'])?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      ra: (json['ra'] ?? json['studentIdentity'])?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? 'Discente',
      enrolledAt: json['enrolledAt']?.toString() ?? '',
    );
  }
}

class AdminGradeAuditRow {
  final String studentId;
  final String ra;
  final String studentName;
  final double assignmentsScore;
  final double p1Score;
  final double projectsScore;
  final double p2Score;
  final double n1;
  final double n2;
  final double finalAverage;
  final double attendanceRate;
  final int absences;
  final bool hasGrades;

  const AdminGradeAuditRow({
    required this.studentId,
    required this.ra,
    required this.studentName,
    required this.assignmentsScore,
    required this.p1Score,
    required this.projectsScore,
    required this.p2Score,
    required this.n1,
    required this.n2,
    required this.finalAverage,
    required this.attendanceRate,
    required this.absences,
    required this.hasGrades,
  });

  factory AdminGradeAuditRow.fromJson(Map<String, dynamic> json) {
    double d(Object? v) =>
        v is num ? v.toDouble() : (double.tryParse('$v') ?? 0.0);
    return AdminGradeAuditRow(
      studentId: json['studentId']?.toString() ?? '',
      ra: json['ra']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? 'Aluno',
      assignmentsScore: d(json['assignmentsScore']),
      p1Score: d(json['p1Score']),
      projectsScore: d(json['projectsScore']),
      p2Score: d(json['p2Score']),
      n1: d(json['n1']),
      n2: d(json['n2']),
      finalAverage: d(json['finalAverage']),
      attendanceRate: json['attendanceRate'] == null
          ? 100.0
          : d(json['attendanceRate']),
      absences: json['absences'] is num ? (json['absences'] as num).toInt() : 0,
      hasGrades: json['hasGrades'] == true,
    );
  }
}

class AdminClassModel {
  final bool gradeLocked;
  final bool pautaHomologated;
  final String? chancelaCode;
  final String code;
  final String courseCode;
  final String subjectName;
  final String courseName;
  final String semester;
  final String shift;
  final String schedule;
  final String courseAndTerm;
  final String location;
  final int enrolled;
  final int maxCapacity;
  final List<String> enrolledStudentRas;
  final List<AdminEnrolledStudent> enrolledStudents;
  String professor;
  String? professorIdentity;
  String formulaRegime; // 'Impor pelo Admin', 'Autonomia Docente'
  String evaluationFormula;
  final bool isLive;

  AdminClassModel({
    required this.code,
    this.courseCode = '',
    this.gradeLocked = false,
    this.pautaHomologated = false,
    this.chancelaCode,
    required this.subjectName,
    String? courseName,
    String? semester,
    String? shift,
    this.schedule = '',
    String? courseAndTerm,
    required this.location,
    required this.enrolled,
    required this.maxCapacity,
    this.enrolledStudentRas = const [],
    this.enrolledStudents = const [],
    required this.professor,
    this.professorIdentity,
    required this.formulaRegime,
    this.evaluationFormula = '(N1 × 0.4) + (N2 × 0.6)',
    this.isLive = false,
  }) : courseName =
           courseName ??
           (courseAndTerm?.split('•').first.trim() ?? 'Curso Superior'),
       semester = semester ?? '',
       shift = shift ?? '',
       courseAndTerm =
           courseAndTerm ??
           '${courseName ?? "Curso"} • ${semester ?? ""} • ${(shift ?? "").replaceFirst("• ", "")}';
}

class AdminProtocolModel {
  final String id;
  final String code;
  final String studentName;
  final String studentRa;
  final String requestType;
  final String targetComponent;
  final String date;
  String status; // 'Aguardando', 'Deferido', 'Indeferido'
  final String attachmentName;
  final String justification;
  String? decisionNote;
  String? immediateImpact;
  String? signedBy;

  AdminProtocolModel({
    required this.id,
    String? code,
    required this.studentName,
    required this.studentRa,
    required this.requestType,
    String? targetComponent,
    required this.date,
    required this.status,
    required this.attachmentName,
    required this.justification,
    this.decisionNote,
    this.immediateImpact,
    this.signedBy,
  }) : code = code ?? id,
       targetComponent = targetComponent ?? 'Componente Curricular Geral';
}

class AdminAuditLogModel {
  final String id;
  final String timestamp;
  final String actor;
  final String? actorRole;
  final String actionType;
  final String description;
  final String ipAddress;
  final String severity; // 'INFO', 'ATENCAO', 'CRITICO'
  final String? targetUserId;
  final String? targetUserName;
  final Map<String, dynamic>? diffBefore;
  final Map<String, dynamic>? diffAfter;

  const AdminAuditLogModel({
    required this.id,
    required this.timestamp,
    required this.actor,
    this.actorRole,
    required this.actionType,
    required this.description,
    required this.ipAddress,
    required this.severity,
    this.targetUserId,
    this.targetUserName,
    this.diffBefore,
    this.diffAfter,
  });
}

class AdminCalendarMilestone {
  final String id;
  final String title;
  final String description;
  final String startsAt;
  final String? endsAt;
  final String type;
  final String scope;
  final String? classCode;

  const AdminCalendarMilestone({
    required this.id,
    required this.title,
    this.description = '',
    required this.startsAt,
    this.endsAt,
    this.type = 'academic',
    this.scope = 'Institucional',
    this.classCode,
  });

  factory AdminCalendarMilestone.fromJson(Map<String, dynamic> json) {
    return AdminCalendarMilestone(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      startsAt: json['startsAt']?.toString() ?? '',
      endsAt: json['endsAt']?.toString(),
      type: json['type']?.toString() ?? 'academic',
      scope: json['scope']?.toString() ?? 'Institucional',
      classCode: json['classCode']?.toString(),
    );
  }
}
