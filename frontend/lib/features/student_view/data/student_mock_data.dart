// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

/// Modelos e repositório de dados simulados (mock) em memória para a Visão do Aluno.
/// Fornece fidelidade aos fluxos de disciplinas, AVA, entregas, calendário e histórico.
class StudentDisciplineModel {
  final String code;
  final String name;
  final String professor;
  final String time;
  final String location;
  final double progress;
  final double n1;
  final double n2;
  final double p1;
  final double p2;
  final double trab;
  final double partialAverage;
  final double attendancePercentage;
  final int absences;
  final int totalHours;
  final int completedHours;

  const StudentDisciplineModel({
    required this.code,
    required this.name,
    required this.professor,
    required this.time,
    required this.location,
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
  });
}

class StudentDeliveryItem {
  final String id;
  final String title;
  final String disciplineCode;
  final String disciplineName;
  final String dueDate;
  final String dueHour;
  final String status; // 'Pendente', 'Em Análise', 'Avaliada'
  final double weight;
  final double? score;
  final String? feedback;
  final String? protocol;
  final List<Map<String, dynamic>> rubrics;

  const StudentDeliveryItem({
    required this.id,
    required this.title,
    required this.disciplineCode,
    required this.disciplineName,
    required this.dueDate,
    required this.dueHour,
    required this.status,
    required this.weight,
    this.score,
    this.feedback,
    this.protocol,
    this.rubrics = const [],
  });
}

class StudentCalendarEvent {
  final String id;
  final String title;
  final String date;
  final String time;
  final String type; // 'Entrega', 'Aula', 'Fórum', 'Avaliação'
  final String discipline;
  final String location;

  const StudentCalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.type,
    required this.discipline,
    required this.location,
  });
}

class StudentBoletimPeriod {
  final String period;
  final List<Map<String, dynamic>> items;

  const StudentBoletimPeriod({
    required this.period,
    required this.items,
  });
}

class StudentMockData {
  static const String studentName = 'Gabriel Soares de Oliveira';
  static const String studentRa = '2024.1.00892';
  static const String studentCourse = 'Engenharia de Software (4º Semestre • Matutino)';
  static const double studentCr = 8.8;
  static const double studentGlobalAttendance = 95.7;
  static const int studentAbsences = 12;
  static const int studentComplementaryHours = 140;
  static const int studentComplementaryHoursTotal = 180;

  static final List<StudentDisciplineModel> disciplines = [
    const StudentDisciplineModel(
      code: 'APS-II',
      name: 'Análise e Projeto de Sistemas II',
      professor: 'Profa. Dra. Helena Bittencourt',
      time: '19:00 - 20:40',
      location: 'Lab Informática 04 - Bloco C',
      progress: 0.68,
      n1: 8.5,
      n2: 9.0,
      p1: 8.5,
      p2: 9.0,
      trab: 9.5,
      partialAverage: 8.90,
      attendancePercentage: 95.0,
      absences: 4,
      totalHours: 80,
      completedHours: 54,
    ),
    const StudentDisciplineModel(
      code: 'BD-II',
      name: 'Banco de Dados II',
      professor: 'Prof. Dr. Marcos Vinicius',
      time: '20:50 - 22:30',
      location: 'Lab Informática 02 - Bloco B',
      progress: 0.75,
      n1: 9.0,
      n2: 8.5,
      p1: 9.0,
      p2: 8.5,
      trab: 9.0,
      partialAverage: 8.80,
      attendancePercentage: 97.5,
      absences: 2,
      totalHours: 80,
      completedHours: 60,
    ),
    const StudentDisciplineModel(
      code: 'FIS',
      name: 'Fundamentos de Inteligência Artificial',
      professor: 'Profa. Dra. Camila Santos',
      time: '19:00 - 20:40',
      location: 'Sala 302 - Bloco A',
      progress: 0.82,
      n1: 9.5,
      n2: 9.0,
      p1: 9.5,
      p2: 9.0,
      trab: 9.8,
      partialAverage: 9.30,
      attendancePercentage: 96.0,
      absences: 3,
      totalHours: 60,
      completedHours: 49,
    ),
    const StudentDisciplineModel(
      code: 'FSO',
      name: 'Fundamentos de Sistemas Operacionais',
      professor: 'Prof. Me. Lucas Ribeiro',
      time: '20:50 - 22:30',
      location: 'Lab Informática 01 - Bloco C',
      progress: 0.54,
      n1: 7.5,
      n2: 8.0,
      p1: 7.5,
      p2: 8.0,
      trab: 8.5,
      partialAverage: 7.90,
      attendancePercentage: 94.0,
      absences: 5,
      totalHours: 60,
      completedHours: 32,
    ),
  ];

  static final List<StudentDeliveryItem> deliveries = [
    const StudentDeliveryItem(
      id: 'DEL-01',
      title: 'Implementação de Padrões Estruturais (Adapter & Facade)',
      disciplineCode: 'APS-II',
      disciplineName: 'Análise e Projeto de Sistemas II',
      dueDate: 'Hoje',
      dueHour: '23:59',
      status: 'Pendente',
      weight: 3.0,
      feedback: null,
      protocol: null,
    ),
    const StudentDeliveryItem(
      id: 'DEL-02',
      title: 'Modelagem Conceitual e Normalização 3FN',
      disciplineCode: 'BD-II',
      disciplineName: 'Banco de Dados II',
      dueDate: '24/10/2026',
      dueHour: '23:59',
      status: 'Pendente',
      weight: 2.5,
      feedback: null,
      protocol: null,
    ),
    const StudentDeliveryItem(
      id: 'DEL-03',
      title: 'Artigo Comparativo: Busca Heurística A* vs Dijkstra',
      disciplineCode: 'FIS',
      disciplineName: 'Fundamentos de Inteligência Artificial',
      dueDate: '13/10/2026',
      dueHour: '23:59',
      status: 'Avaliada',
      weight: 4.0,
      score: 9.8,
      feedback: 'Excelente rigor na fundamentação teórica e nas análises de complexidade temporal O(b^d). Código bem estruturado e documentado.',
      protocol: 'AGR-2026-0913-1092',
      rubrics: [
        {'criterio': 'Fundamentação Teórica', 'pontos': 3.0, 'nota': 3.0},
        {'criterio': 'Implementação dos Algoritmos', 'pontos': 4.0, 'nota': 4.0},
        {'criterio': 'Análise Comparativa e Gráficos', 'pontos': 2.0, 'nota': 1.8},
        {'criterio': 'Normas ABNT e Formatação', 'pontos': 1.0, 'nota': 1.0},
      ],
    ),
    const StudentDeliveryItem(
      id: 'DEL-04',
      title: 'Simulador de Escalonamento Round-Robin e Prioridade',
      disciplineCode: 'FSO',
      disciplineName: 'Fundamentos de Sistemas Operacionais',
      dueDate: '10/10/2026',
      dueHour: '23:59',
      status: 'Avaliada',
      weight: 3.5,
      score: 9.5,
      feedback: 'Simulação precisa com medição de turnaround e waiting time corretos. Parabéns.',
      protocol: 'AGR-2026-0881-3041',
      rubrics: [
        {'criterio': 'Corretude da Fila Circular', 'pontos': 4.0, 'nota': 4.0},
        {'criterio': 'Cálculo de Métricas do S.O.', 'pontos': 3.0, 'nota': 2.8},
        {'criterio': 'Interface de Log no Console', 'pontos': 3.0, 'nota': 2.7},
      ],
    ),
  ];

  static final List<StudentCalendarEvent> calendarEvents = [
    const StudentCalendarEvent(
      id: 'EV-01',
      title: 'Aula Síncrona: Padrões de Projeto GoF',
      date: '2026-10-20',
      time: '19:00 - 20:40',
      type: 'Aula',
      discipline: 'APS-II',
      location: 'Sala Virtual AVA / Lab 04',
    ),
    const StudentCalendarEvent(
      id: 'EV-02',
      title: 'Entrega: Padrões Adapter e Facade',
      date: '2026-10-20',
      time: '23:59',
      type: 'Entrega',
      discipline: 'APS-II',
      location: 'Portal AVA',
    ),
    const StudentCalendarEvent(
      id: 'EV-03',
      title: 'Avaliação Parcial N1: Álgebra Relacional e SQL',
      date: '2026-10-22',
      time: '20:50 - 22:30',
      type: 'Avaliação',
      discipline: 'BD-II',
      location: 'Lab Informática 02',
    ),
    const StudentCalendarEvent(
      id: 'EV-04',
      title: 'Fórum Temático: Ética na I.A. Generativa',
      date: '2026-10-23',
      time: '18:00',
      type: 'Fórum',
      discipline: 'FIS',
      location: 'Fórum da Disciplina',
    ),
  ];

  static final List<StudentBoletimPeriod> historicalBoletim = [
    const StudentBoletimPeriod(
      period: '2026/2 (Período Vigente)',
      items: [
        {'codigo': '218131', 'disciplina': 'Análise e Projeto de Sistemas II', 'n1': 8.5, 'n2': 9.0, 'media': 8.9, 'faltas': 4, 'situacao': 'Cursando'},
        {'codigo': '218132', 'disciplina': 'Banco de Dados II', 'n1': 9.0, 'n2': 8.5, 'media': 8.8, 'faltas': 2, 'situacao': 'Cursando'},
        {'codigo': '218133', 'disciplina': 'Fundamentos de Inteligência Artificial', 'n1': 9.5, 'n2': 9.0, 'media': 9.3, 'faltas': 3, 'situacao': 'Cursando'},
        {'codigo': '218134', 'disciplina': 'Fundamentos de Sistemas Operacionais', 'n1': 7.5, 'n2': 8.0, 'media': 7.9, 'faltas': 5, 'situacao': 'Cursando'},
      ],
    ),
    const StudentBoletimPeriod(
      period: '2026/1',
      items: [
        {'codigo': '218121', 'disciplina': 'Análise e Projeto de Sistemas I', 'n1': 8.8, 'n2': 9.2, 'media': 9.0, 'faltas': 2, 'situacao': 'Aprovado'},
        {'codigo': '218122', 'disciplina': 'Banco de Dados I', 'n1': 9.0, 'n2': 8.8, 'media': 8.9, 'faltas': 0, 'situacao': 'Aprovado'},
        {'codigo': '218123', 'disciplina': 'Estruturas de Dados Avançadas', 'n1': 8.0, 'n2': 8.5, 'media': 8.3, 'faltas': 4, 'situacao': 'Aprovado'},
      ],
    ),
  ];
}
