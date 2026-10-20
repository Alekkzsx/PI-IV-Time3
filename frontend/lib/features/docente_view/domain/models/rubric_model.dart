// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

/// Represents a single grading criterion in an evaluation rubric matrix.
class RubricCriterion {
  final String id;
  final String title;
  final double maxPoints;
  final String description;
  final double? assignedScore;

  const RubricCriterion({
    required this.id,
    required this.title,
    required this.maxPoints,
    required this.description,
    this.assignedScore,
  });

  /// Alias for maxPoints for convenient UI usage.
  double get maxScore => maxPoints;

  RubricCriterion copyWith({
    String? id,
    String? title,
    double? maxPoints,
    String? description,
    double? assignedScore,
  }) {
    return RubricCriterion(
      id: id ?? this.id,
      title: title ?? this.title,
      maxPoints: maxPoints ?? this.maxPoints,
      description: description ?? this.description,
      assignedScore: assignedScore ?? this.assignedScore,
    );
  }
}
