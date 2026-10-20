// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

/// Status of student attendance in a class session.
enum AttendanceStatus {
  presente,
  ausente,
  justificada,
}

/// Risk level based on accumulated student absences.
enum AttendanceRiskLevel {
  regular,
  atencao,
  critico,
}

/// Represents a student's attendance record for a specific class session.
class AttendanceStudent {
  final String studentId;
  final String ra;
  final String name;
  final AttendanceStatus status;
  final int accumulatedAbsences;
  final int maxAbsences;
  final double attendanceRate;
  final AttendanceRiskLevel riskLevel;
  final String? observation;

  const AttendanceStudent({
    required this.studentId,
    required this.ra,
    required this.name,
    required this.status,
    required this.accumulatedAbsences,
    this.maxAbsences = 20,
    required this.attendanceRate,
    required this.riskLevel,
    this.observation,
  });

  AttendanceStudent copyWith({
    String? studentId,
    String? ra,
    String? name,
    AttendanceStatus? status,
    int? accumulatedAbsences,
    int? maxAbsences,
    double? attendanceRate,
    AttendanceRiskLevel? riskLevel,
    String? observation,
  }) {
    return AttendanceStudent(
      studentId: studentId ?? this.studentId,
      ra: ra ?? this.ra,
      name: name ?? this.name,
      status: status ?? this.status,
      accumulatedAbsences: accumulatedAbsences ?? this.accumulatedAbsences,
      maxAbsences: maxAbsences ?? this.maxAbsences,
      attendanceRate: attendanceRate ?? this.attendanceRate,
      riskLevel: riskLevel ?? this.riskLevel,
      observation: observation ?? this.observation,
    );
  }
}

/// Represents a formal class diary session complying with MEC regulations.
class ClassSession {
  final int sessionNumber;
  final int hours;
  final String dateFormatted;
  final String contentProgram;
  final String methodology;
  final bool isHomologated;
  final List<AttendanceStudent> attendanceList;

  const ClassSession({
    required this.sessionNumber,
    required this.hours,
    required this.dateFormatted,
    required this.contentProgram,
    required this.methodology,
    required this.isHomologated,
    required this.attendanceList,
  });

  ClassSession copyWith({
    int? sessionNumber,
    int? hours,
    String? dateFormatted,
    String? contentProgram,
    String? methodology,
    bool? isHomologated,
    List<AttendanceStudent>? attendanceList,
  }) {
    return ClassSession(
      sessionNumber: sessionNumber ?? this.sessionNumber,
      hours: hours ?? this.hours,
      dateFormatted: dateFormatted ?? this.dateFormatted,
      contentProgram: contentProgram ?? this.contentProgram,
      methodology: methodology ?? this.methodology,
      isHomologated: isHomologated ?? this.isHomologated,
      attendanceList: attendanceList ?? this.attendanceList,
    );
  }
}
