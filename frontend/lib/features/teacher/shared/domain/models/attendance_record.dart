// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/// Status of student attendance in a class session.
enum AttendanceStatus { presente, ausente, justificada }

/// Risk level based on accumulated student absences.
enum AttendanceRiskLevel { regular, atencao, critico }

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
  final bool isConnected;

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
    this.isConnected = false,
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
    bool? isConnected,
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
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

/// Represents a formal class diary session complying with MEC regulations.
class ClassSession {
  final String id;
  final String courseId;
  final int sessionNumber;
  final int hours;
  final DateTime? date;
  final String dateFormatted;
  final String contentProgram;
  final String methodology;
  final String location;
  final bool isHomologated;
  final List<AttendanceStudent> attendanceList;

  const ClassSession({
    this.id = 'sess-27',
    this.courseId = 'course-aps2',
    required this.sessionNumber,
    required this.hours,
    this.date,
    required this.dateFormatted,
    required this.contentProgram,
    required this.methodology,
    this.location = 'Lab Informática 04 - Bloco C',
    required this.isHomologated,
    required this.attendanceList,
  });

  DateTime get sessionDate => date ?? DateTime(2026, 9, 30);

  ClassSession copyWith({
    String? id,
    String? courseId,
    int? sessionNumber,
    int? hours,
    DateTime? date,
    String? dateFormatted,
    String? contentProgram,
    String? methodology,
    String? location,
    bool? isHomologated,
    List<AttendanceStudent>? attendanceList,
  }) {
    return ClassSession(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      sessionNumber: sessionNumber ?? this.sessionNumber,
      hours: hours ?? this.hours,
      date: date ?? this.date,
      dateFormatted: dateFormatted ?? this.dateFormatted,
      contentProgram: contentProgram ?? this.contentProgram,
      methodology: methodology ?? this.methodology,
      location: location ?? this.location,
      isHomologated: isHomologated ?? this.isHomologated,
      attendanceList: attendanceList ?? this.attendanceList,
    );
  }
}
