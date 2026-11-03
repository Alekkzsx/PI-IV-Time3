// Desenvolvido por Guilherme Henrique Moreira

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

  double get progress =>
      totalClasses == 0 ? 0.0 : completedClasses / totalClasses;

  /// Whether all planned classes for this unit have been given.
  bool get isCompleted => totalClasses > 0 && completedClasses >= totalClasses;

  /// Human readable description of topics.
  String get description => topics.join(' • ');

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
  final String teacherIdentity;
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
  final bool gradeLocked;
  final bool pautaHomologated;
  final String? chancelaCode;

  const DocenteCourse({
    required this.id,
    required this.teacherIdentity,
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
    this.gradeLocked = false,
    this.pautaHomologated = false,
    this.chancelaCode,
  });

  String get name => title;
  String get semester => term;
  int get workloadHours => totalHours;
  double get progress => totalHours == 0 ? 0.0 : completedHours / totalHours;
  double get progressPercentage =>
      totalHours == 0 ? 0.0 : (completedHours / totalHours) * 100;

  List<int> get classWeekdays {
    final lower = schedule.toLowerCase();
    final days = <int>[];
    if (lower.contains('segunda')) days.add(DateTime.monday);
    if (lower.contains('terça') || lower.contains('terca')) days.add(DateTime.tuesday);
    if (lower.contains('quarta')) days.add(DateTime.wednesday);
    if (lower.contains('quinta')) days.add(DateTime.thursday);
    if (lower.contains('sexta')) days.add(DateTime.friday);
    if (lower.contains('sábado') || lower.contains('sabado')) days.add(DateTime.saturday);
    return days.isEmpty ? [DateTime.monday, DateTime.wednesday] : days;
  }

  String get classDaysLabel {
    final labels = <String>[];
    final weekdays = classWeekdays;
    if (weekdays.contains(DateTime.monday)) labels.add('Segundas');
    if (weekdays.contains(DateTime.tuesday)) labels.add('Terças');
    if (weekdays.contains(DateTime.wednesday)) labels.add('Quartas');
    if (weekdays.contains(DateTime.thursday)) labels.add('Quintas');
    if (weekdays.contains(DateTime.friday)) labels.add('Sextas');
    if (weekdays.contains(DateTime.saturday)) labels.add('Sábados');
    return labels.join(' e ');
  }

  DocenteCourse copyWith({
    String? id,
    String? teacherIdentity,
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
    bool? gradeLocked,
    bool? pautaHomologated,
    String? chancelaCode,
  }) {
    return DocenteCourse(
      id: id ?? this.id,
      teacherIdentity: teacherIdentity ?? this.teacherIdentity,
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
      gradeLocked: gradeLocked ?? this.gradeLocked,
      pautaHomologated: pautaHomologated ?? this.pautaHomologated,
      chancelaCode: chancelaCode ?? this.chancelaCode,
    );
  }
}
