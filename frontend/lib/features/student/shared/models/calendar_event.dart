// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/foundation.dart';

/// Entidade de domínio imutável que representa um evento, aula ou compromisso na agenda do aluno.
///
/// Encapsula atributos essenciais de calendário como data, faixa de horário regimental,
/// classificação do evento (prova, entrega, aula presencial ou remota), disciplina e localização física.
@immutable
class CalendarEvent {
  /// Identificador único universal do evento acadêmico no sistema.
  final String id;

  /// Título descritivo do evento exibido em cabeçalhos, agendas e cards.
  final String title;

  /// Data de realização no formato ISO ou textual formatado (`AAAA-MM-DD`).
  final String date;

  /// Intervalo horário do compromisso (ex: "08:00 - 09:40").
  final String time;

  /// Categoria funcional do compromisso (ex: "AULA", "AVALIACAO", "ENTREGA", "LEMBRETE").
  final String type;

  /// Código ou sigla oficial da disciplina vinculada ao evento.
  final String discipline;

  /// Sala de aula, bloco predial ou URL da sessão virtual de transmissão.
  final String location;

  /// Cria uma nova instância imutável de [CalendarEvent].
  ///
  /// Parâmetros:
  /// - [id]: Identificador único do evento.
  /// - [title]: Nome descritivo da atividade.
  /// - [date]: Data de agendamento.
  /// - [time]: Horário formatado de início e término.
  /// - [type]: Categoria semântica do compromisso.
  /// - [discipline]: Código da disciplina associada.
  /// - [location]: Localização física ou virtual.
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.type,
    required this.discipline,
    required this.location,
  });

  /// Reconstrói um [CalendarEvent] a partir de um payload deserializado de resposta HTTP.
  ///
  /// Parâmetros:
  /// - [json]: Mapa JSON contendo atributos do evento.
  ///
  /// Executa:
  /// 1. Extração segura dos campos primitivos com fallback de segurança.
  /// 2. Compatibilização de aliases históricos da API (`timeRange`, `category`, `courseCode`).
  ///
  /// Retorna o compromisso acadêmico validado e imutável.
  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      time: (json['time'] ?? json['timeRange'])?.toString() ?? '',
      type: (json['type'] ?? json['category'])?.toString() ?? '',
      discipline: (json['discipline'] ?? json['courseCode'])?.toString() ?? '',
      location: json['location']?.toString() ?? '',
    );
  }

  /// Converte a entidade atual em um mapa compatível com JSON para persistência ou transmissão.
  ///
  /// Retorna um mapa contendo todos os atributos serializáveis de [CalendarEvent].
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date,
    'time': time,
    'type': type,
    'discipline': discipline,
    'location': location,
  };
}

/// Alias de tipo retrocompatível para testes automatizados existentes.
typedef StudentCalendarEvent = CalendarEvent;
