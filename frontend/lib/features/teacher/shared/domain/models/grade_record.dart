// Desenvolvido por Murillo Caravita - RA: 25014012

/// Academic standing of a student in the official gradebook.
enum AcademicStatus { aprovado, exame, reprovadoPorNota, reprovadoPorFalta }

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

  /// Alias for n1Total.
  double get n1Score => n1Total;

  /// N2 = (projectsScore * 0.4) + (p2Score * 0.6)
  double get n2Total => double.parse(
    ((projectsScore * 0.4) + (p2Score * 0.6)).toStringAsFixed(1),
  );

  /// Alias for n2Total.
  double get n2Score => n2Total;

  /// Final semester average: MS = (N1 * 0.4) + (N2 * 0.6)
  double get finalAverage =>
      double.parse(((n1Total * 0.4) + (n2Total * 0.6)).toStringAsFixed(1));

  /// Academic standing as an enum according to institutional regulation (PPC)
  AcademicStatus get status {
    if (attendanceRate < 75.0) {
      return AcademicStatus.reprovadoPorFalta;
    }
    if (finalAverage >= 7.0) {
      return AcademicStatus.aprovado;
    }
    if (finalAverage >= 4.0) {
      return AcademicStatus.exame;
    }
    return AcademicStatus.reprovadoPorNota;
  }

  /// Academic standing as string.
  String get statusLabel {
    switch (status) {
      case AcademicStatus.aprovado:
        return 'Aprovado';
      case AcademicStatus.exame:
        return 'Em Exame';
      case AcademicStatus.reprovadoPorNota:
        return 'Reprovado por Nota';
      case AcademicStatus.reprovadoPorFalta:
        return 'Reprovado por Falta';
    }
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
