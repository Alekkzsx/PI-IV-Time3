// Desenvolvido por Marcelo Zarpelon - RA: 25015323

/// Modelos de dados e repositório simulado (mock) para a Visão do Administrador (Coordenação & Secretaria).
class AdminUserModel {
  final String id;
  final String name;
  final String email;
  final String profile; // 'Discente', 'Docente', 'Administrador'
  final String departmentOrCourse;
  String status; // 'Ativo', 'Suspenso'
  final bool twoFactorRequired;
  int activeSessionsCount;
  String? suspensionReason;
  String lastLogin;
  String roleLevel;
  String? linkedInfo;

  AdminUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.profile,
    required this.departmentOrCourse,
    required this.status,
    required this.twoFactorRequired,
    this.activeSessionsCount = 1,
    this.suspensionReason,
    this.lastLogin = 'Hoje às 14:10',
    this.roleLevel = 'Padrão',
    this.linkedInfo,
  });
}

class AdminCourseModel {
  final String code;
  final String name;
  final String matrix;
  final String workload;
  final int studentsCount;
  final String formula;
  final String department;
  final String modality;
  final List<Map<String, dynamic>> components;

  const AdminCourseModel({
    required this.code,
    required this.name,
    required this.matrix,
    required this.workload,
    required this.studentsCount,
    required this.formula,
    this.department = 'Departamento de Computação e Sistemas',
    this.modality = 'Graduação',
    required this.components,
  });
}

class AdminClassModel {
  final String code;
  final String subjectName;
  final String courseName;
  final String semester;
  final String shift;
  final String courseAndTerm;
  final String location;
  final int enrolled;
  final int maxCapacity;
  final List<String> enrolledStudentRas;
  String professor;
  String formulaRegime; // 'Impor pelo Admin', 'Autonomia Docente'

  AdminClassModel({
    required this.code,
    required this.subjectName,
    String? courseName,
    String? semester,
    String? shift,
    String? courseAndTerm,
    required this.location,
    required this.enrolled,
    required this.maxCapacity,
    this.enrolledStudentRas = const [],
    required this.professor,
    required this.formulaRegime,
  }) : courseName =
           courseName ??
           (courseAndTerm?.split('•').first.trim() ?? 'Engenharia de Software'),
       semester = semester ?? '2026/2 - 4º Semestre',
       shift = shift ?? '• Noturno',
       courseAndTerm =
           courseAndTerm ??
           '${courseName ?? "Engenharia de Software"} • ${semester ?? "2026/2 - 4º Semestre"} • ${shift ?? "• Noturno"}';
}

class AdminProtocolModel {
  final String id;
  final String studentName;
  final String studentRa;
  final String requestType;
  final String targetComponent;
  final String date;
  String status; // 'Aguardando', 'Deferido', 'Indeferido'
  final String attachmentName;
  final String justification;
  String? decisionNote;
  String? immediateImpact;
  String? signedBy;

  AdminProtocolModel({
    required this.id,
    required this.studentName,
    required this.studentRa,
    required this.requestType,
    String? targetComponent,
    required this.date,
    required this.status,
    required this.attachmentName,
    required this.justification,
    this.decisionNote,
    this.immediateImpact,
    this.signedBy,
  }) : targetComponent = targetComponent ?? 'Componente Curricular Geral';
}

class AdminAuditLogModel {
  final String id;
  final String timestamp;
  final String actor;
  final String? actorRole;
  final String actionType;
  final String description;
  final String ipAddress;
  final String severity; // 'INFO', 'ATENCAO', 'CRITICO'
  final String? targetUserId;
  final String? targetUserName;
  final Map<String, dynamic>? diffBefore;
  final Map<String, dynamic>? diffAfter;

  const AdminAuditLogModel({
    required this.id,
    required this.timestamp,
    required this.actor,
    this.actorRole,
    required this.actionType,
    required this.description,
    required this.ipAddress,
    required this.severity,
    this.targetUserId,
    this.targetUserName,
    this.diffBefore,
    this.diffAfter,
  });
}

class AdminMockData {
  static final List<AdminUserModel> users = [
    AdminUserModel(
      id: '2024.1.00892',
      name: 'Gabriel Soares de Oliveira',
      email: 'gabriel.oliveira@aluno.universidade.edu.br',
      profile: 'Discente',
      departmentOrCourse: 'Engenharia de Software (5º Semestre)',
      status: 'Ativo',
      twoFactorRequired: true,
      activeSessionsCount: 2,
      lastLogin: 'Hoje às 14:10',
      roleLevel: 'Discente Regular',
      linkedInfo: '6 disciplinas cursadas • CR 8.85 • Matrícula Ativa',
    ),
    AdminUserModel(
      id: 'DOC-88410',
      name: 'Profa. Dra. Helena Bittencourt',
      email: 'helena.bittencourt@docente.universidade.edu.br',
      profile: 'Docente',
      departmentOrCourse: 'Departamento de Computação e Sistemas',
      status: 'Ativo',
      twoFactorRequired: true,
      activeSessionsCount: 1,
      lastLogin: 'Hoje às 14:15',
      roleLevel: 'Docente Titular / Pesquisadora',
      linkedInfo: '3 turmas ativas • 101 alunos vinculados • Regime DE',
    ),
    AdminUserModel(
      id: '2024.1.00901',
      name: 'Mariana Rios Costa',
      email: 'mariana.costa@aluno.universidade.edu.br',
      profile: 'Discente',
      departmentOrCourse: 'Engenharia de Software (5º Semestre)',
      status: 'Ativo',
      twoFactorRequired: true,
      activeSessionsCount: 1,
      lastLogin: 'Hoje às 13:40',
      roleLevel: 'Discente Regular / Monitora',
      linkedInfo: '5 disciplinas cursadas • CR 9.20 • Monitora de BD-II',
    ),
    AdminUserModel(
      id: 'DOC-88392',
      name: 'Prof. Me. Carlos Eduardo Silva',
      email: 'carlos.silva@docente.universidade.edu.br',
      profile: 'Docente',
      departmentOrCourse: 'Departamento de Computação e Sistemas',
      status: 'Ativo',
      twoFactorRequired: true,
      activeSessionsCount: 2,
      lastLogin: 'Hoje às 11:05',
      roleLevel: 'Docente Adjunto',
      linkedInfo: '2 turmas ativas • 68 alunos vinculados • Regime CLT 40h',
    ),
    AdminUserModel(
      id: '2024.1.00915',
      name: 'Lucas Mendes Santos',
      email: 'lucas.santos@aluno.universidade.edu.br',
      profile: 'Discente',
      departmentOrCourse: 'Sistemas de Informação (4º Semestre)',
      status: 'Ativo',
      twoFactorRequired: true,
      activeSessionsCount: 1,
      lastLogin: 'Ontem às 19:22',
      roleLevel: 'Discente Regular',
      linkedInfo:
          '4 disciplinas cursadas • CR 7.60 • Pedido de Trancamento FSO',
    ),
    AdminUserModel(
      id: 'ADM-00129',
      name: 'Carlos Eduardo Mendes',
      email: 'carlos.mendes@secretaria.universidade.edu.br',
      profile: 'Administrador',
      departmentOrCourse: 'Secretaria Geral Acadêmica & Auditoria',
      status: 'Ativo',
      twoFactorRequired: true,
      activeSessionsCount: 1,
      lastLogin: 'Hoje às 08:00',
      roleLevel: 'Super Administrador / Secretaria Geral',
      linkedInfo: 'Acesso Irrestrito • Auditor Master • Emissor de Diplomas',
    ),
    AdminUserModel(
      id: '2024.1.00962',
      name: 'Camila Duarte Fagundes',
      email: 'camila.fagundes@aluno.universidade.edu.br',
      profile: 'Discente',
      departmentOrCourse: 'Engenharia de Software (5º Semestre)',
      status: 'Ativo',
      twoFactorRequired: true,
      activeSessionsCount: 0,
      lastLogin: 'Ontem às 22:15',
      roleLevel: 'Discente Regular',
      linkedInfo: '6 disciplinas cursadas • CR 8.40 • Atestado Médico Deferido',
    ),
  ];

  static final List<AdminCourseModel> courses = [
    const AdminCourseModel(
      code: 'ENG-SOFT-2024',
      name: 'Bacharelado em Engenharia de Software',
      modality: 'Graduação',
      department: 'Departamento de Computação e Sistemas',
      matrix: 'Matriz 2024/1 (PPC Atualizado)',
      workload: '3200h / 210 créditos',
      studentsCount: 420,
      formula: 'Média = (N1 × 0.4) + (N2 × 0.6) • Freq. ≥ 75%',
      components: [
        {
          'semestre': '4º Semestre',
          'disciplina': 'Análise e Projeto de Sistemas II',
          'carga': '80h',
          'docente': 'Profa. Dra. Helena Bittencourt',
        },
        {
          'semestre': '4º Semestre',
          'disciplina': 'Banco de Dados II',
          'carga': '80h',
          'docente': 'Prof. Dr. Marcos Vinicius',
        },
        {
          'semestre': '4º Semestre',
          'disciplina': 'Fundamentos de Inteligência Artificial',
          'carga': '60h',
          'docente': 'Profa. Dra. Camila Santos',
        },
        {
          'semestre': '4º Semestre',
          'disciplina': 'Fundamentos de Sistemas Operacionais',
          'carga': '60h',
          'docente': 'Prof. Me. Lucas Ribeiro',
        },
      ],
    ),
    const AdminCourseModel(
      code: 'SIS-INFO-2023',
      name: 'Bacharelado em Sistemas de Informação',
      modality: 'Graduação',
      department: 'Departamento de Computação e Sistemas',
      matrix: 'Matriz 2023/1',
      workload: '3000h / 195 créditos',
      studentsCount: 380,
      formula: 'Média = (N1 × 0.4) + (N2 × 0.6) • Freq. ≥ 75%',
      components: [
        {
          'semestre': '4º Semestre',
          'disciplina': 'Gestão de Processos de Negócio',
          'carga': '80h',
          'docente': 'Profa. Me. Carla Dias',
        },
        {
          'semestre': '4º Semestre',
          'disciplina': 'Sistemas Integrados de Gestão (ERP)',
          'carga': '80h',
          'docente': 'Prof. Dr. Fernando Rocha',
        },
        {
          'semestre': '4º Semestre',
          'disciplina': 'Engenharia de Software Corporativa',
          'carga': '80h',
          'docente': 'Prof. Esp. André Luiz Silveira',
        },
      ],
    ),
    const AdminCourseModel(
      code: 'CIEN-COMP-2022',
      name: 'Bacharelado em Ciência da Computação',
      modality: 'Graduação',
      department: 'Departamento de Computação e Sistemas',
      matrix: 'Matriz 2022/2',
      workload: '3400h / 220 créditos',
      studentsCount: 310,
      formula: 'Média = (N1 × 0.5) + (N2 × 0.5) • Freq. ≥ 75%',
      components: [
        {
          'semestre': '4º Semestre',
          'disciplina': 'Algoritmos Avançados e Grafos',
          'carga': '80h',
          'docente': 'Prof. Dr. Marcelo Carvalho',
        },
        {
          'semestre': '4º Semestre',
          'disciplina': 'Teoria dos Autômatos e Linguagens Formais',
          'carga': '80h',
          'docente': 'Profa. Dra. Renata Toledo',
        },
        {
          'semestre': '4º Semestre',
          'disciplina': 'Compiladores e Tradutores',
          'carga': '80h',
          'docente': 'Prof. Dr. Ricardo Fontes',
        },
      ],
    ),
    const AdminCourseModel(
      code: 'TEC-ADS-2025',
      name: 'Tecnologia em Análise e Desenvolvimento de Sistemas',
      modality: 'Tecnólogo',
      department: 'Departamento de Tecnologia Aplicada',
      matrix: 'Matriz 2025/1',
      workload: '2400h / 140 créditos',
      studentsCount: 130,
      formula: 'Média = (N1 × 0.4) + (N2 × 0.6) • Freq. ≥ 75%',
      components: [
        {
          'semestre': '3º Semestre',
          'disciplina': 'Desenvolvimento Web Full-Stack',
          'carga': '80h',
          'docente': 'Prof. Me. Gabriel Duarte',
        },
        {
          'semestre': '3º Semestre',
          'disciplina': 'Engenharia de Requisitos e Métodos Ágeis',
          'carga': '80h',
          'docente': 'Profa. Esp. Juliana Mendes',
        },
      ],
    ),
  ];

  static final List<AdminClassModel> classes = [
    AdminClassModel(
      code: '218131 - APS-II',
      subjectName: 'Análise e Projeto de Sistemas II',
      courseName: 'Engenharia de Software',
      semester: '2026/2 - 4º Semestre',
      shift: '• Noturno',
      courseAndTerm: 'Engenharia de Software • 2026/2 • Noturno',
      location: 'Lab Informática 04 - Bloco C',
      enrolled: 34,
      maxCapacity: 40,
      enrolledStudentRas: const [
        '2024.1.00892',
        '2024.1.00901',
        '2024.1.00962',
      ],
      professor: 'Profa. Dra. Helena Bittencourt',
      formulaRegime: 'Autonomia Docente',
    ),
    AdminClassModel(
      code: '218131 - BD-II',
      subjectName: 'Estudos de Banco de Dados II',
      courseName: 'Engenharia de Software',
      semester: '2026/2 - 4º Semestre',
      shift: '• Noturno',
      courseAndTerm: 'Engenharia de Software • 2026/2 • Noturno',
      location: 'Lab Banco de Dados 02 - Bloco B',
      enrolled: 31,
      maxCapacity: 35,
      enrolledStudentRas: const ['2024.1.00901', '2024.1.00915'],
      professor: 'Profa. Dra. Helena Bittencourt',
      formulaRegime: 'Autonomia Docente',
    ),
    AdminClassModel(
      code: '218131 - FSO',
      subjectName: 'Fundamentos de Sistemas Operacionais',
      courseName: 'Sistemas de Informação',
      semester: '2026/2 - 4º Semestre',
      shift: '• Noturno',
      courseAndTerm: 'Sistemas de Informação • 2026/2 • Noturno',
      location: 'Anfiteatro 101 - Bloco Central',
      enrolled: 36,
      maxCapacity: 50,
      enrolledStudentRas: const ['2024.1.00915', '2024.1.00962'],
      professor: 'Profa. Dra. Helena Bittencourt',
      formulaRegime: 'Autonomia Docente',
    ),
    AdminClassModel(
      code: '218131 - FIS',
      subjectName: 'Filosofia, Informação e Sociedade',
      courseName: 'Engenharia de Software',
      semester: '2026/2 - 4º Semestre',
      shift: '• Noturno',
      courseAndTerm: 'Engenharia de Software • 2026/2 • Noturno',
      location: 'Sala 204 - Bloco A',
      enrolled: 38,
      maxCapacity: 45,
      enrolledStudentRas: const ['2024.1.00892', '2024.1.00915'],
      professor: 'Prof. Dr. Marcos Vinícius Ferreira',
      formulaRegime: 'Autonomia Docente',
    ),
  ];

  static final List<AdminProtocolModel> protocols = [
    AdminProtocolModel(
      id: 'PROT-2026/8841',
      studentName: 'Camila Duarte Fagundes',
      studentRa: '2024.1.00962',
      requestType: 'ATESTADO MÉDICO',
      targetComponent: 'APS-II e BD-II (Afastamento 29 a 30/09)',
      date: 'Hoje, 09:15',
      status: 'Deferido',
      attachmentName: 'atestado_medico_camila_fagundes.pdf',
      justification:
          'Apresentação de atestado médico com CID-10 J06.9 para abono e justificativa legal de ausências.',
      decisionNote:
          'Deferido. Falta justificada lançada no Diário de Classe dos docentes para as aulas do período informado.',
      immediateImpact:
          'Ao deferir atestado médico, o sistema automaticamente marca a falta como justificada no diário de classe do docente responsável pelas aulas do período.',
      signedBy: 'Carlos Eduardo Mendes - Secretaria Geral',
    ),
    AdminProtocolModel(
      id: 'PROT-2026/8835',
      studentName: 'Gabriel Soares de Oliveira',
      studentRa: '2024.1.00892',
      requestType: 'HORAS COMPLEMENTARES',
      targetComponent: 'Validação de Curso Extracurricular (40h)',
      date: 'Ontem, 16:40',
      status: 'Deferido',
      attachmentName: 'certificado_curso_extracurricular.pdf',
      justification:
          'Comprovação de curso extracurricular de 40 horas em Cibersegurança Aplicada.',
      decisionNote:
          'Deferido formalmente. 40h computadas no prontuário estudantil.',
      immediateImpact:
          'Ao deferir horas complementares, a carga horária é creditada diretamente nas atividades extracurriculares do discente.',
      signedBy: 'Carlos Eduardo Mendes - Secretaria Geral',
    ),
    AdminProtocolModel(
      id: 'PROT-2026/8850',
      studentName: 'Rodrigo Antunes Nogueira',
      studentRa: '2024.1.00938',
      requestType: 'SEGUNDA CHAMADA',
      targetComponent: 'APS-II - Prova Substitutiva',
      date: 'Hoje, 11:20',
      status: 'Aguardando',
      attachmentName: 'declaracao_viagem_trabalho.pdf',
      justification:
          'Discente em viagem de trabalho comprovada no dia da prova teórica P1 de APS-II.',
      decisionNote:
          'Documentação idônea conferida perante os critérios da Resolução CONSEPE. Deferimento concedido com reflexo no diário.',
      immediateImpact:
          'Ao deferir segunda chamada, o professor regente é notificado para disponibilizar a avaliação substitutiva.',
    ),
    AdminProtocolModel(
      id: 'PROT-2026/8820',
      studentName: 'Lucas Mendes Santos',
      studentRa: '2024.1.00915',
      requestType: 'TRANCAMENTO',
      targetComponent: 'Fundamentos de Sistemas Operacionais',
      date: '18/10/2026',
      status: 'Aguardando',
      attachmentName: 'requerimento_trancamento_disciplina.pdf',
      justification:
          'Solicitação de trancamento tempestivo da disciplina dentro do prazo regimental CONSEPE.',
      decisionNote: null,
      immediateImpact:
          'Ao deferir trancamento, a matrícula na disciplina é suspensa sem prejuízo no coeficiente de rendimento escolar.',
    ),
  ];

  static final List<AdminAuditLogModel> auditLogs = [
    const AdminAuditLogModel(
      id: 'LOG-0912',
      timestamp: 'Hoje, 14:15:22',
      actor: 'Profa. Dra. Helena Bittencourt',
      actorRole: 'Docente (DOC-88410)',
      actionType: 'ALTERACAO NOTA',
      description:
          'Lançamento de nota de avaliação (9.5) para discente Mariana Rios Costa (RA 2024.1.00901) em APS-II.',
      ipAddress: '177.136.24.10',
      severity: 'INFO',
      targetUserId: '2024.1.00901',
      targetUserName: 'Mariana Rios Costa',
      diffBefore: {
        'disciplina': 'Análise e Projeto de Sistemas II',
        'avaliacao': 'P1',
        'nota': '8.0',
        'statusLancamento': 'Pendente de validação',
      },
      diffAfter: {
        'disciplina': 'Análise e Projeto de Sistemas II',
        'avaliacao': 'P1',
        'nota': '9.5',
        'statusLancamento': 'Homologado pelo docente',
      },
    ),
    const AdminAuditLogModel(
      id: 'LOG-0911',
      timestamp: 'Hoje, 11:30:05',
      actor: 'Carlos Eduardo Mendes',
      actorRole: 'Secretaria Geral (ADM-00129)',
      actionType: 'DEFERIMENTO PROTOCOLO',
      description:
          'Deferimento de atestado médico (PROT-2026/8841) para Camila Duarte Fagundes com anotação em diário.',
      ipAddress: '10.0.4.15 (Rede Interna)',
      severity: 'INFO',
      targetUserId: '2024.1.00962',
      targetUserName: 'Camila Duarte Fagundes',
      diffBefore: {
        'protocolo': 'PROT-2026/8841',
        'status': 'Aguardando Parecer',
        'abonoFalta': 'Não computado',
        'despachadoPor': 'Nenhum',
      },
      diffAfter: {
        'protocolo': 'PROT-2026/8841',
        'status': 'Deferido',
        'abonoFalta': 'Abono 29/09 e 30/09 lançado em diário',
        'despachadoPor': 'Carlos Eduardo Mendes - Secretaria Geral',
      },
    ),
    const AdminAuditLogModel(
      id: 'LOG-0910',
      timestamp: 'Ontem, 23:48:11',
      actor: 'Sistema de Segurança',
      actorRole: 'Automação WAF',
      actionType: 'RESET CREDENCIAIS',
      description:
          'Três tentativas incorretas de senha para o usuário DOC-88410. Bloqueio preventivo de 15 minutos ativado.',
      ipAddress: '189.40.112.5',
      severity: 'ATENCAO',
      targetUserId: 'DOC-88410',
      targetUserName: 'Profa. Dra. Helena Bittencourt',
      diffBefore: {
        'tentativasFalhas': 2,
        'estadoConta': 'Desbloqueada',
        'exigir2fa': true,
      },
      diffAfter: {
        'tentativasFalhas': 3,
        'estadoConta': 'Bloqueio preventivo (15 min)',
        'notificacaoEnviada': 'SMS & E-mail de alerta institucional',
      },
    ),
    const AdminAuditLogModel(
      id: 'LOG-0909',
      timestamp: '28/09/2026, 17:00:00',
      actor: 'Carlos Eduardo Mendes',
      actorRole: 'Secretaria Geral (ADM-00129)',
      actionType: 'FECHAMENTO ATA',
      description:
          'Homologação e chancela da ata final do período especial de férias 2026/1 perante o sistema acadêmico.',
      ipAddress: '10.0.4.15 (Rede Interna)',
      severity: 'INFO',
      targetUserId: 'TURMA-2026/ESP',
      targetUserName: 'Turma Especial de Férias 2026/1',
      diffBefore: {
        'statusAta': 'Em digitação pelos docentes',
        'travaRegimental': 'Aberta para retificações',
      },
      diffAfter: {
        'statusAta': 'Homologada e Lacrada digitalmente',
        'travaRegimental': 'Bloqueada CONSEPE (Irrevogável)',
      },
    ),
  ];
}
