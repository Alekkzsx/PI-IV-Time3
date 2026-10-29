// Desenvolvido por Murillo Caravita - RA: 25014012

/// Classification of academic announcements.
enum NoticeClassification { informativo, urgencia, convocacao }

/// Represents an institutional or class-targeted notice.
class AcademicNotice {
  final String id;
  final String author;
  final String targetCourse;
  final String targetAudience; // e.g., 'Turma B (Noturno)', 'Toda a Turma'
  final NoticeClassification classification;
  final String publishedAt;
  final String title;
  final String message;
  final int readCount;
  final int totalRecipients;
  final bool isFromSecretaria;

  const AcademicNotice({
    required this.id,
    required this.author,
    required this.targetCourse,
    required this.targetAudience,
    required this.classification,
    required this.publishedAt,
    required this.title,
    required this.message,
    required this.readCount,
    required this.totalRecipients,
    this.isFromSecretaria = false,
  });

  int get readPercentage =>
      totalRecipients == 0 ? 0 : ((readCount / totalRecipients) * 100).round();

  /// Decimal percentage of students who acknowledged reading the notice (0.0 to 1.0).
  double get sciencePercentage =>
      totalRecipients == 0 ? 0.0 : readCount / totalRecipients;

  String get classificationLabel {
    switch (classification) {
      case NoticeClassification.informativo:
        return 'Informativo';
      case NoticeClassification.urgencia:
        return 'Urgência / Mudança';
      case NoticeClassification.convocacao:
        return 'Convocação Formal';
    }
  }

  AcademicNotice copyWith({
    String? id,
    String? author,
    String? targetCourse,
    String? targetAudience,
    NoticeClassification? classification,
    String? publishedAt,
    String? title,
    String? message,
    int? readCount,
    int? totalRecipients,
    bool? isFromSecretaria,
  }) {
    return AcademicNotice(
      id: id ?? this.id,
      author: author ?? this.author,
      targetCourse: targetCourse ?? this.targetCourse,
      targetAudience: targetAudience ?? this.targetAudience,
      classification: classification ?? this.classification,
      publishedAt: publishedAt ?? this.publishedAt,
      title: title ?? this.title,
      message: message ?? this.message,
      readCount: readCount ?? this.readCount,
      totalRecipients: totalRecipients ?? this.totalRecipients,
      isFromSecretaria: isFromSecretaria ?? this.isFromSecretaria,
    );
  }
}
