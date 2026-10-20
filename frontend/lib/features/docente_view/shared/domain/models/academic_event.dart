// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

/// Type of institutional or academic event in the professor's agenda.
enum EventType {
  aula,
  avaliacao,
  plantao,
  colegiado,
  reuniao,
}

/// Represents an event or appointment in the academic calendar.
class AcademicEvent {
  final String id;
  final String title;
  final String date; // YYYY-MM-DD
  final String time; // e.g., '19:10 - 20:50'
  final EventType type;
  final String location;
  final bool isSynced;

  const AcademicEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.type,
    required this.location,
    this.isSynced = true,
  });

  String get typeLabel {
    switch (type) {
      case EventType.aula:
        return 'Aula / Laboratório';
      case EventType.avaliacao:
        return 'Avaliação Regimental';
      case EventType.plantao:
        return 'Plantão Docente';
      case EventType.colegiado:
      case EventType.reuniao:
        return 'Colegiado / Reunião';
    }
  }

  AcademicEvent copyWith({
    String? id,
    String? title,
    String? date,
    String? time,
    EventType? type,
    String? location,
    bool? isSynced,
  }) {
    return AcademicEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      time: time ?? this.time,
      type: type ?? this.type,
      location: location ?? this.location,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

