// Desenvolvido por Marcelo Zarpelon - RA: 25015323

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
  final String? fullCode;
  final bool hasPendingTask;
  final int maxAbsenceHours;

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
    this.fullCode,
    this.hasPendingTask = false,
    this.maxAbsenceHours = 20,
  });
}

class StudentDeliveryItem {
  final String id;
  final String? sourceAssignmentId;
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
  final String? activityCode; // e.g. 'APS - ATV - 04'
  final String? description;
  final String? professor;
  final String? deadlineBadge; // e.g. 'Prazo fatal: em 2 dias'
  final bool isUrgent;
  final String? allowedFormats; // e.g. '.pdf, .zip • Max: 25MB'
  final String? submissionDate;
  final String? feedbackDate;
  final double maxScore;
  final int attachmentCount;

  const StudentDeliveryItem({
    required this.id,
    this.sourceAssignmentId,
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
    this.activityCode,
    this.description,
    this.professor,
    this.deadlineBadge,
    this.isUrgent = false,
    this.allowedFormats,
    this.submissionDate,
    this.feedbackDate,
    this.maxScore = 10.0,
    this.attachmentCount = 1,
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

  const StudentBoletimPeriod({required this.period, required this.items});
}

class StudentMockData {
  static const String studentName = 'Gabriel Soares de Oliveira';
  static const String studentRa = '2024.1.00892';
  static const String studentEmail =
      'gabriel.oliveira@aluno.universidade.edu.br';
  static const String studentCourse =
      'Engenharia de Software (5º Semestre • Matutino)';
  static const double studentCr = 8.8;
  static const double studentGlobalAttendance = 95.7;
  static const int studentAbsences = 12;
  static const int studentComplementaryHours = 140;
  static const int studentComplementaryHoursTotal = 180;

  static bool ownsDemoRecords(String identity) {
    final normalizedIdentity = identity.trim().toLowerCase();
    return normalizedIdentity == studentRa.toLowerCase() ||
        normalizedIdentity == studentEmail;
  }

  static final List<StudentDisciplineModel> disciplines = [
    const StudentDisciplineModel(
      code: 'APS-II',
      fullCode: '218131 - APS-II',
      name: 'Análise e Projeto de Sistemas II',
      professor: 'Profa. Dra. Helena Bittencourt',
      time: 'Segundas-feiras, 19:00 às 22:30',
      location: 'Lab 04 - Bloco C (Noturno)',
      progress: 0.68,
      n1: 8.5,
      n2: 9.0,
      p1: 8.5,
      p2: 9.0,
      trab: 9.5,
      partialAverage: 8.8,
      attendancePercentage: 97.5,
      absences: 2,
      totalHours: 80,
      completedHours: 54,
      maxAbsenceHours: 20,
      hasPendingTask: true,
    ),
    const StudentDisciplineModel(
      code: 'BD-II',
      fullCode: '218131 - BD-II',
      name: 'Estudos de Banco de Dados II',
      professor: 'Profa. Dra. Helena Bittencourt',
      time: 'Terças-feiras, 19:00 às 22:30',
      location: 'Lab 02 - Bloco B (Noturno)',
      progress: 0.75,
      n1: 9.0,
      n2: 8.5,
      p1: 9.0,
      p2: 8.5,
      trab: 9.0,
      partialAverage: 8.7,
      attendancePercentage: 95.0,
      absences: 4,
      totalHours: 80,
      completedHours: 60,
      maxAbsenceHours: 20,
      hasPendingTask: true,
    ),
    const StudentDisciplineModel(
      code: 'FIS',
      fullCode: '218131 - FIS',
      name: 'Filosofia, Informação e Sociedade',
      professor: 'Prof. Dr. Marcos Vinícius Ferreira',
      time: 'Quartas-feiras, 19:00 às 21:00',
      location: 'Sala 204 - Bloco A (Noturno)',
      progress: 0.80,
      n1: 9.5,
      n2: 9.0,
      p1: 9.5,
      p2: 9.0,
      trab: 9.8,
      partialAverage: 9.2,
      attendancePercentage: 100.0,
      absences: 0,
      totalHours: 40,
      completedHours: 32,
      maxAbsenceHours: 10,
      hasPendingTask: true,
    ),
    const StudentDisciplineModel(
      code: 'FSO',
      fullCode: '218131 - FSO',
      name: 'Fundamentos de Sistemas Operacionais',
      professor: 'Prof. Esp. André Luiz Silveira',
      time: 'Quintas-feiras, 19:00 às 22:30',
      location: 'Anfiteatro 101 - Bloco Central (Noturno)',
      progress: 0.55,
      n1: 7.5,
      n2: 8.0,
      p1: 7.5,
      p2: 8.0,
      trab: 8.5,
      partialAverage: 7.8,
      attendancePercentage: 92.5,
      absences: 6,
      totalHours: 80,
      completedHours: 44,
      maxAbsenceHours: 20,
      hasPendingTask: false,
    ),
  ];

  static final List<StudentDeliveryItem> deliveries = [
    const StudentDeliveryItem(
      id: 'DEL-01',
      sourceAssignmentId: 'asg-1',
      activityCode: 'APS - ATV - 04',
      title: 'Modelagem de Domínio e Diagramas de Casos de Uso com Padrões GoF',
      disciplineCode: 'APS-II',
      disciplineName: 'Análise e Projeto de Sistemas II',
      description:
          'Elaboração de documento técnico contendo a especificação detalhada de 3 casos de uso do sistema acadêmico, o diagrama de classes de domínio com cardinalidades e justificativa técnica da aplicação de pelo menos dois padrões de projeto GoF (Factory Method e Strategy).',
      dueDate: '02 de Outubro',
      dueHour: '23:59',
      deadlineBadge: 'Prazo fatal: em 2 dias',
      isUrgent: true,
      professor: 'Profa. Dra. Helena Bittencourt',
      weight: 2.5,
      maxScore: 10.0,
      allowedFormats: 'Formatos aceitos: .pdf, .zip • Max: 25MB',
      status: 'Pendente',
    ),
    const StudentDeliveryItem(
      id: 'DEL-02',
      activityCode: 'BD2 - LAB - 03',
      title:
          'Otimização de Índices B-Tree, Explain Plan e Triggers no PostgreSQL',
      disciplineCode: 'BD-II',
      disciplineName: 'Banco de Dados II',
      description:
          'Prática de laboratório com execução de planos de consulta (EXPLAIN ANALYZE) sobre dataset com 1 milhão de tuplas, criação de índices parciais e implementação de trigger para auditoria de alterações sensíveis.',
      dueDate: '05 de Outubro',
      dueHour: '23:59',
      deadlineBadge: 'Prazo em 5 dias',
      isUrgent: false,
      professor: 'Prof. Me. Carlos Eduardo Silva',
      weight: 2.0,
      maxScore: 10.0,
      allowedFormats: 'Formatos aceitos: .sql, .pdf, .zip • Max: 30MB',
      status: 'Pendente',
    ),
    const StudentDeliveryItem(
      id: 'DEL-03',
      activityCode: 'DVP - PROJ - 02',
      title:
          'Pipeline Declarativa GitHub Actions com Deploy Automatizado e Testes',
      disciplineCode: 'DVP',
      disciplineName: 'DevOps e Integração Contínua',
      description:
          'Construção de workflow YAML automatizando as etapas de linting, execução de testes unitários com cobertura mínima de 80%, build da imagem Docker multi-stage e publicação em container registry.',
      dueDate: '09 de Outubro',
      dueHour: '23:59',
      deadlineBadge: 'Prazo em 9 dias',
      isUrgent: false,
      professor: 'Prof. Dr. Marcelo Sato',
      weight: 3.0,
      maxScore: 10.0,
      allowedFormats: 'Formatos aceitos: .zip, .pdf, .yaml, .yml • Max: 15MB',
      status: 'Pendente',
    ),
    const StudentDeliveryItem(
      id: 'DEL-04',
      activityCode: 'MIC - SPEC - 01',
      title: 'Especificação OpenAPI 3.0 e Mensageria com RabbitMQ / Kafka',
      disciplineCode: 'MIC',
      disciplineName: 'Arquitetura de Microsserviços',
      description:
          'Modelagem dos contratos de API RESTful em formato OpenAPI/Swagger 3.0 para o serviço de pagamentos e especificação dos tópicos/filas assíncronas para propagação de eventos de domínio.',
      dueDate: '15 de Outubro',
      dueHour: '23:59',
      deadlineBadge: 'Prazo em 15 dias',
      isUrgent: false,
      professor: 'Profa. Me. Fernanda Albuquerque',
      weight: 2.5,
      maxScore: 10.0,
      allowedFormats: 'Formatos aceitos: .yaml, .json, .pdf, .zip • Max: 20MB',
      status: 'Pendente',
    ),
    const StudentDeliveryItem(
      id: 'DEL-05',
      activityCode: 'APS - ATV - 03',
      title: 'Documento de Visão e Requisitos de Software v1.2',
      disciplineCode: 'APS-II',
      disciplineName: 'Análise e Projeto de Sistemas II',
      description:
          'Revisão completa do documento de requisitos incorporando as regras de negócio de fechamento contábil e autenticação federada com OAuth 2.0 / SAML.',
      dueDate: '28 de Setembro',
      dueHour: '23:59',
      submissionDate: '28/09/2026',
      professor: 'Profa. Dra. Helena Bittencourt',
      weight: 2.0,
      maxScore: 10.0,
      protocol: 'AGR-2026-0928-8472',
      attachmentCount: 1,
      status: 'Em Análise',
      feedback:
          'Submissão recebida com sucesso. Em fila para conferência regimental.',
    ),
    const StudentDeliveryItem(
      id: 'DEL-06',
      activityCode: 'BD2 - LAB - 02',
      title: 'Modelagem Conceitual Avançada e Criação de Índices Compostos',
      disciplineCode: 'BD-II',
      disciplineName: 'Banco de Dados II',
      description:
          'Relatório comparativo de consultas analíticas com e sem indexação composta em tabelas transacionais de grande volume.',
      dueDate: '25 de Setembro',
      dueHour: '23:59',
      submissionDate: '25/09/2026',
      professor: 'Prof. Me. Carlos Eduardo Silva',
      weight: 1.5,
      maxScore: 10.0,
      protocol: 'AGR-2026-0925-6321',
      attachmentCount: 1,
      status: 'Em Análise',
      feedback: 'Arquivo compactado íntegro. Em fila de avaliação prática.',
    ),
    const StudentDeliveryItem(
      id: 'DEL-07',
      activityCode: 'APS - ATV - 01',
      title: 'Estudo de Caso 01: Análise de Viabilidade Técnica e Econômica',
      disciplineCode: 'APS-II',
      disciplineName: 'Análise e Projeto de Sistemas II',
      description:
          'Elaboração de parecer técnico sobre a substituição de sistema legado monolítico por arquitetura distribuída, com cálculo de TCO (Total Cost of Ownership), ROI estimado e análise de riscos.',
      dueDate: '14 de Setembro',
      dueHour: '23:59',
      submissionDate: '14/09/2026',
      feedbackDate: '17/09/2026',
      professor: 'Profa. Dra. Helena Bittencourt',
      weight: 2.0,
      maxScore: 10.0,
      score: 9.8,
      protocol: 'AGR-2026-0914-1092',
      attachmentCount: 1,
      status: 'Avaliada',
      feedback:
          'Excelente rigor na fundamentação técnica e estimativa financeira de TCO. As matrizes de risco apresentaram soluções mitigadoras bastante maduras para o contexto corporativo avaliado.',
      rubrics: [
        {
          'criterio': 'Fundamentação Teórica & Metodologia',
          'pontos': 3.0,
          'nota': 3.0,
        },
        {
          'criterio': 'Cálculo de TCO e Retorno de Investimento (ROI)',
          'pontos': 3.0,
          'nota': 3.0,
        },
        {
          'criterio': 'Matriz de Riscos & Planos de Contingência',
          'pontos': 2.5,
          'nota': 2.3,
        },
        {
          'criterio': 'Normas ABNT e Apresentação Executiva',
          'pontos': 1.5,
          'nota': 1.5,
        },
      ],
    ),
    const StudentDeliveryItem(
      id: 'DEL-08',
      activityCode: 'DVP - PROJ - 01',
      title: 'Configuração de Ambientes com Docker Compose Multi-Containers',
      disciplineCode: 'DVP',
      disciplineName: 'DevOps e Integração Contínua',
      description:
          'Configuração de ambiente orquestrado com aplicação web Node.js, banco de dados PostgreSQL com healthcheck e serviço de cache Redis em rede interna isolada com volumes persistentes.',
      dueDate: '18 de Setembro',
      dueHour: '23:59',
      submissionDate: '18/09/2026',
      feedbackDate: '21/09/2026',
      professor: 'Prof. Dr. Marcelo Sato',
      weight: 2.0,
      maxScore: 10.0,
      score: 9.4,
      protocol: 'AGR-2026-0918-2041',
      attachmentCount: 1,
      status: 'Avaliada',
      feedback:
          'Arquivo Compose perfeitamente parametrizado com variáveis de ambiente e volumes nomeados. Apenas atentar para a ordem estrita de healthcheck no serviço dependente.',
      rubrics: [
        {
          'criterio': 'Estrutura do docker-compose.yml',
          'pontos': 4.0,
          'nota': 4.0,
        },
        {
          'criterio': 'Isolamento de Redes e Persistência de Dados',
          'pontos': 3.0,
          'nota': 2.8,
        },
        {
          'criterio': 'Documentação e Script de Inicialização',
          'pontos': 3.0,
          'nota': 2.6,
        },
      ],
    ),
    const StudentDeliveryItem(
      id: 'DEL-09',
      activityCode: 'MIC - ENSAIO - 01',
      title: 'Monólito Modular vs. Microsserviços: Ensaio Arquitetural',
      disciplineCode: 'MIC',
      disciplineName: 'Arquitetura de Microsserviços',
      description:
          'Análise crítica e comparativa entre o padrão de monólito modular e a decomposição em microsserviços orientados a eventos, considerando latência de rede, consistência eventual e custo operacional.',
      dueDate: '10 de Setembro',
      dueHour: '23:59',
      submissionDate: '10/09/2026',
      feedbackDate: '12/09/2026',
      professor: 'Profa. Me. Fernanda Albuquerque',
      weight: 1.5,
      maxScore: 10.0,
      score: 10.0,
      protocol: 'AGR-2026-0910-5012',
      attachmentCount: 1,
      status: 'Avaliada',
      feedback:
          'Trabalho impecável! O contraste entre complexidade acidental e complexidade essencial foi brilhantemente articulado com exemplos práticos da indústria.',
      rubrics: [
        {
          'criterio': 'Profundidade da Análise Conceitual',
          'pontos': 4.0,
          'nota': 4.0,
        },
        {
          'criterio': 'Trade-offs de Latência e Consistência',
          'pontos': 3.0,
          'nota': 3.0,
        },
        {
          'criterio': 'Rigor Argumentativo e Referências Bibliográficas',
          'pontos': 3.0,
          'nota': 3.0,
        },
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
        {
          'codigo': '218131',
          'disciplina': 'Análise e Projeto de Sistemas II',
          'n1': 8.5,
          'n2': 9.0,
          'media': 8.9,
          'faltas': 4,
          'situacao': 'Cursando',
        },
        {
          'codigo': '218132',
          'disciplina': 'Banco de Dados II',
          'n1': 9.0,
          'n2': 8.5,
          'media': 8.8,
          'faltas': 2,
          'situacao': 'Cursando',
        },
        {
          'codigo': '218133',
          'disciplina': 'Fundamentos de Inteligência Artificial',
          'n1': 9.5,
          'n2': 9.0,
          'media': 9.3,
          'faltas': 3,
          'situacao': 'Cursando',
        },
        {
          'codigo': '218134',
          'disciplina': 'Fundamentos de Sistemas Operacionais',
          'n1': 7.5,
          'n2': 8.0,
          'media': 7.9,
          'faltas': 5,
          'situacao': 'Cursando',
        },
      ],
    ),
    const StudentBoletimPeriod(
      period: '2026/1',
      items: [
        {
          'codigo': '218121',
          'disciplina': 'Análise e Projeto de Sistemas I',
          'n1': 8.8,
          'n2': 9.2,
          'media': 9.0,
          'faltas': 2,
          'situacao': 'Aprovado',
        },
        {
          'codigo': '218122',
          'disciplina': 'Banco de Dados I',
          'n1': 9.0,
          'n2': 8.8,
          'media': 8.9,
          'faltas': 0,
          'situacao': 'Aprovado',
        },
        {
          'codigo': '218123',
          'disciplina': 'Estruturas de Dados Avançadas',
          'n1': 8.0,
          'n2': 8.5,
          'media': 8.3,
          'faltas': 4,
          'situacao': 'Aprovado',
        },
      ],
    ),
  ];
}
