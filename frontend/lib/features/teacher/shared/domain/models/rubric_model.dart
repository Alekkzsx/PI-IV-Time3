// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

/// Representa um critério individual de avaliação em uma matriz de rubrica.
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

  /// Alias para maxPoints para uso conveniente na interface.
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
