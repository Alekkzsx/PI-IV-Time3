// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

/// Represents a syllabus unit within a course curriculum.
class SyllabusUnit {
  final String id;
  final int unitNumber;
  final String title;
  final List<String> topics;
  final int completedClasses;
  final int totalClasses;

  const SyllabusUnit({
    required this.id,
    required this.unitNumber,
    required this.title,
    required this.topics,
    required this.completedClasses,
    required this.totalClasses,
  });

  double get progress => totalClasses == 0 ? 0.0 : completedClasses / totalClasses;

  SyllabusUnit copyWith({
    String? id,
    int? unitNumber,
    String? title,
    List<String>? topics,
    int? completedClasses,
    int? totalClasses,
  }) {
    return SyllabusUnit(
      id: id ?? this.id,
      unitNumber: unitNumber ?? this.unitNumber,
      title: title ?? this.title,
      topics: topics ?? this.topics,
      completedClasses: completedClasses ?? this.completedClasses,
      totalClasses: totalClasses ?? this.totalClasses,
    );
  }
}

/// Represents educational support material uploaded by the professor.
class CourseMaterial {
  final String id;
  final String courseId;
  final String title;
  final String date;
  final String size;
  final String type;

  const CourseMaterial({
    required this.id,
    required this.courseId,
    required this.title,
    required this.date,
    required this.size,
    required this.type,
  });
}

/// Represents a course/class taught by the professor.
class DocenteCourse {
  final String id;
  final String code;
  final String title;
  final String term;
  final String shift;
  final String room;
  final String schedule;
  final int enrolledCount;
  final int completedHours;
  final int totalHours;
  final List<SyllabusUnit> syllabusUnits;
  final List<CourseMaterial> materials;

  const DocenteCourse({
    required this.id,
    required this.code,
    required this.title,
    required this.term,
    required this.shift,
    required this.room,
    required this.schedule,
    required this.enrolledCount,
    required this.completedHours,
    required this.totalHours,
    required this.syllabusUnits,
    required this.materials,
  });

  double get progressPercentage => totalHours == 0 ? 0.0 : (completedHours / totalHours) * 100;

  DocenteCourse copyWith({
    String? id,
    String? code,
    String? title,
    String? term,
    String? shift,
    String? room,
    String? schedule,
    int? enrolledCount,
    int? completedHours,
    int? totalHours,
    List<SyllabusUnit>? syllabusUnits,
    List<CourseMaterial>? materials,
  }) {
    return DocenteCourse(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      term: term ?? this.term,
      shift: shift ?? this.shift,
      room: room ?? this.room,
      schedule: schedule ?? this.schedule,
      enrolledCount: enrolledCount ?? this.enrolledCount,
      completedHours: completedHours ?? this.completedHours,
      totalHours: totalHours ?? this.totalHours,
      syllabusUnits: syllabusUnits ?? this.syllabusUnits,
      materials: materials ?? this.materials,
    );
  }
}
