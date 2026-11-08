// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/foundation.dart';
import 'material_item.dart';

/// Modelo de domínio que representa uma disciplina acadêmica matriculada pelo estudante.
///
/// Agrupa informações pedagógicas completas: código regimental, horários de aula, sala física
/// ou virtual, dados do docente responsável, progresso do semestre, notas parciais (N1, N2, P1, P2, Trabalhos),
/// média calculada via fórmula institucional, controle de frequência e ausências, repositório de arquivos/slides,
/// unidades programáticas do syllabus e squads de projetos práticos.
@immutable
class DisciplineModel {
  /// Código oficial da disciplina na matriz curricular (ex: "MAT101").
  final String code;

  /// Código da sala física ou identificador da turma no sistema.
  final String roomCode;

  /// Nome por extenso da disciplina (ex: "Arquitetura de Software e Padrões GoF").
  final String name;

  /// Nome e titulação acadêmica do professor responsável.
  final String professor;

  /// Descrição textual dos dias e horários de aula.
  final String schedule;

  /// Faixa horária das aulas semanais (ex: "19:00 - 22:30").
  final String time;

  /// Bloco e sala física ou link da sala virtual de transmissão.
  final String location;

  /// Estado atual da sala de aula: `'Ao Vivo'` ou `'Sala Fechada'`.
  final String roomStatus;

  /// Sinaliza se há uma aula ao vivo ou videoconferência em andamento no momento.
  final bool isLive;

  /// Índice percentual de progressão no conteúdo programático (0.0 a 1.0).
  final double progress;

  /// Nota da primeira avaliação bimestral regular (N1).
  final double n1;

  /// Nota da segunda avaliação bimestral regular (N2).
  final double n2;

  /// Nota da primeira prova presencial individual (P1).
  final double p1;

  /// Nota da segunda prova presencial individual (P2).
  final double p2;

  /// Nota ponderada de trabalhos práticos e projetos integradores.
  final double trab;

  /// Média parcial consolidada até o momento.
  final double partialAverage;

  /// Taxa de assiduidade do estudante calculada em porcentagem (0.0 a 100.0).
  final double attendancePercentage;

  /// Quantidade acumulada de faltas regimentais registradas em horas-aula.
  final int absences;

  /// Carga horária total obrigatória da disciplina em horas-relógio.
  final int totalHours;

  /// Total de horas letivas já ministradas e cumpridas no semestre.
  final int completedHours;

  /// Número de créditos acadêmicos conferidos pela conclusão da matéria.
  final int credits;

  /// Horários fixos para atendimento individual ou monitoria pelo docente.
  final String officeHours;

  /// Local de atendimento individual com o professor (sala de docentes ou Teams).
  final String officeLocation;

  /// Código completo composto por departamento e turma (ex: "DCC-MAT101-A").
  final String? fullCode;

  /// Sinaliza se existe alguma entrega ou avaliação pendente para esta matéria.
  final bool hasPendingTask;

  /// Limite máximo regimental de faltas antes da reprovação por infrequência.
  final int maxAbsenceHours;

  /// Fórmula regimental institucional utilizada para cômputo da média final.
  final String evaluationFormula;

  /// Período letivo correspondente (ex: "2026/1").
  final String semester;

  /// Indica se a matéria é ministrada em ambiente de laboratório prático.
  final bool isLab;

  /// Unidades programáticas, módulos e tópicos descritos no Plano de Ensino.
  final List<Map<String, dynamic>> syllabusUnits;

  /// Equipes e grupos de trabalho integrador registrados para a turma.
  final List<Map<String, dynamic>> squads;

  /// Coleção de materiais didáticos, apostilas e slides disponibilizados para download.
  final List<MaterialItem> materials;

  /// Cria uma nova instância imutável de [DisciplineModel].
  const DisciplineModel({
    required this.code,
    String? roomCode,
    required this.name,
    required this.professor,
    String? schedule,
    required this.time,
    required this.location,
    this.roomStatus = 'Sala Fechada',
    this.isLive = false,
    required this.progress,
    required this.n1,
    required this.n2,
    required this.p1,
    required this.p2,
    required this.trab,
    required this.partialAverage,
    required this.attendancePercentage,
    required this.absences,
    required this.totalHours,
    required this.completedHours,
    this.credits = 4,
    this.officeHours = 'Terças-feiras • 18:00 às 19:00',
    this.officeLocation = 'Sala dos Professores (Bloco C) ou Sala Virtual Teams',
    this.fullCode,
    this.hasPendingTask = false,
    this.maxAbsenceHours = 20,
    this.evaluationFormula = '(N1 × 0.4) + (N2 × 0.6)',
    this.semester = '',
    this.isLab = false,
    this.syllabusUnits = const [],
    this.squads = const [],
    this.materials = const [],
  }) : roomCode = roomCode ?? code,
       schedule = schedule ?? time;

  /// Constrói um [DisciplineModel] a partir de dados deserializados de payload JSON da API.
  ///
  /// Parâmetros:
  /// - [json]: Mapa JSON contendo dados da disciplina acadêmica.
  ///
  /// Executa:
  /// 1. Extração resiliente com conversão segura de valores numéricos para [double] e [int].
  /// 2. Normalização de códigos de sala e turma com fallbacks recíprocos.
  /// 3. Desserialização de materiais de apoio para objetos [MaterialItem].
  ///
  /// Retorna o modelo completo e validado de [DisciplineModel].
  factory DisciplineModel.fromJson(Map<String, dynamic> json) {
    double numOrZero(Object? v) =>
        v is num ? v.toDouble() : (double.tryParse('$v') ?? 0.0);
    int intOrZero(Object? v) =>
        v is num ? v.toInt() : (int.tryParse('$v') ?? 0);

    final code = json['code']?.toString() ?? '';
    final rawMats = json['materials'];
    final rawUnits = json['syllabusUnits'];
    final rawSquads = json['squads'];

    return DisciplineModel(
      code: code,
      roomCode: json['roomCode']?.toString() ?? code,
      fullCode: json['fullCode']?.toString() ?? code,
      name: json['name']?.toString() ?? code,
      professor: json['professor']?.toString() ?? '',
      schedule: json['schedule']?.toString() ?? json['time']?.toString() ?? '',
      time: json['time']?.toString() ?? json['schedule']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      roomStatus:
          json['roomStatus']?.toString() ??
          (json['isLive'] == true ? 'Ao Vivo' : 'Sala Fechada'),
      isLive: json['isLive'] == true,
      progress: numOrZero(json['progress']),
      n1: numOrZero(json['n1']),
      n2: numOrZero(json['n2']),
      p1: numOrZero(json['p1']),
      p2: numOrZero(json['p2']),
      trab: numOrZero(json['trab']),
      partialAverage: numOrZero(json['partialAverage']),
      attendancePercentage: json['attendancePercentage'] == null
          ? 0.0
          : numOrZero(json['attendancePercentage']),
      absences: intOrZero(json['absences']),
      totalHours: intOrZero(json['totalHours']),
      completedHours: intOrZero(json['completedHours']),
      credits: intOrZero(json['credits'] ?? 4),
      officeHours: json['officeHours']?.toString() ?? 'Terças-feiras • 18:00 às 19:00',
      officeLocation: json['officeLocation']?.toString() ?? 'Sala dos Professores (Bloco C) ou Sala Virtual Teams',
      maxAbsenceHours: intOrZero(json['maxAbsenceHours']),
      hasPendingTask: json['hasPendingTask'] == true,
      evaluationFormula:
          json['evaluationFormula']?.toString() ?? '(N1 × 0.4) + (N2 × 0.6)',
      semester: json['semester']?.toString() ?? '',
      isLab: json['isLab'] == true,
      syllabusUnits: rawUnits is List
          ? rawUnits
                .whereType<Map>()
                .map((u) => Map<String, dynamic>.from(u))
                .toList()
          : const [],
      squads: rawSquads is List
          ? rawSquads
                .whereType<Map>()
                .map((s) => Map<String, dynamic>.from(s))
                .toList()
          : const [],
      materials: rawMats is List
          ? rawMats
                .whereType<Map>()
                .map(
                  (m) => MaterialItem.fromJson(
                    Map<String, dynamic>.from(m),
                  ),
                )
                .toList()
          : const [],
    );
  }

  /// Retorna uma cópia modificada da disciplina preservando os atributos não informados.
  DisciplineModel copyWith({
    bool? isLive,
    String? roomStatus,
    List<MaterialItem>? materials,
  }) {
    return DisciplineModel(
      code: code,
      roomCode: roomCode,
      fullCode: fullCode,
      name: name,
      professor: professor,
      schedule: schedule,
      time: time,
      location: location,
      roomStatus: roomStatus ?? this.roomStatus,
      isLive: isLive ?? this.isLive,
      progress: progress,
      n1: n1,
      n2: n2,
      p1: p1,
      p2: p2,
      trab: trab,
      partialAverage: partialAverage,
      attendancePercentage: attendancePercentage,
      absences: absences,
      totalHours: totalHours,
      completedHours: completedHours,
      hasPendingTask: hasPendingTask,
      maxAbsenceHours: maxAbsenceHours,
      evaluationFormula: evaluationFormula,
      semester: semester,
      isLab: isLab,
      syllabusUnits: syllabusUnits,
      squads: squads,
      materials: materials ?? this.materials,
    );
  }
}

/// Alias de tipo retrocompatível para testes automatizados existentes.
typedef StudentDisciplineModel = DisciplineModel;
