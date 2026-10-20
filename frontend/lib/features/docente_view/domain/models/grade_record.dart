// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

/// Represents a student's grade record inside the official gradebook.
class StudentGrade {
  final String studentId;
  final String ra;
  final String studentName;
  final double assignmentsScore;
  final double p1Score;
  final double projectsScore;
  final double p2Score;
  final double attendanceRate;

  const StudentGrade({
    required this.studentId,
    required this.ra,
    required this.studentName,
    required this.assignmentsScore,
    required this.p1Score,
    required this.projectsScore,
    required this.p2Score,
    required this.attendanceRate,
  });

  /// N1 = (assignmentsScore * 0.4) + (p1Score * 0.6)
  double get n1Total => double.parse(
        ((assignmentsScore * 0.4) + (p1Score * 0.6)).toStringAsFixed(1),
      );

  /// N2 = (projectsScore * 0.4) + (p2Score * 0.6)
  double get n2Total => double.parse(
        ((projectsScore * 0.4) + (p2Score * 0.6)).toStringAsFixed(1),
      );

  /// Final semester average: MS = (N1 * 0.4) + (N2 * 0.6)
  double get finalAverage => double.parse(
        ((n1Total * 0.4) + (n2Total * 0.6)).toStringAsFixed(1),
      );

  /// Academic standing according to institutional regulation (PPC)
  String get status {
    if (attendanceRate < 75.0) {
      return 'Reprovado por Falta';
    }
    if (finalAverage >= 7.0) {
      return 'Aprovado';
    }
    if (finalAverage >= 4.0) {
      return 'Em Exame';
    }
    return 'Reprovado por Nota';
  }

  StudentGrade copyWith({
    String? studentId,
    String? ra,
    String? studentName,
    double? assignmentsScore,
    double? p1Score,
    double? projectsScore,
    double? p2Score,
    double? attendanceRate,
  }) {
    return StudentGrade(
      studentId: studentId ?? this.studentId,
      ra: ra ?? this.ra,
      studentName: studentName ?? this.studentName,
      assignmentsScore: assignmentsScore ?? this.assignmentsScore,
      p1Score: p1Score ?? this.p1Score,
      projectsScore: projectsScore ?? this.projectsScore,
      p2Score: p2Score ?? this.p2Score,
      attendanceRate: attendanceRate ?? this.attendanceRate,
    );
  }
}
