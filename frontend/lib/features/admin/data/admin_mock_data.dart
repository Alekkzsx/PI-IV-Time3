// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

/// Modelos de dados e repositório simulado (mock) para a Visão do Administrador (Coordenação & Secretaria).
class AdminUserModel {
  final String id;
  final String name;
  final String email;
  final String profile; // 'Discente', 'Docente', 'Administrador'
  final String departmentOrCourse;
  String status; // 'Ativo', 'Suspenso'
  final bool twoFactorRequired;

  AdminUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.profile,
    required this.departmentOrCourse,
    required this.status,
    required this.twoFactorRequired,
  });
}

class AdminCourseModel {
  final String code;
  final String name;
  final String matrix;
  final String workload;
  final int studentsCount;
  final String formula;
  final List<Map<String, dynamic>> components;

  const AdminCourseModel({
    required this.code,
    required this.name,
    required this.matrix,
    required this.workload,
    required this.studentsCount,
    required this.formula,
    required this.components,
  });
}

class AdminClassModel {
  final String code;
  final String subjectName;
  final String courseAndTerm;
  final String location;
  final int enrolled;
  final int maxCapacity;
  String professor;
  String formulaRegime; // 'Impor pelo Admin', 'Autonomia Docente'

  AdminClassModel({
    required this.code,
    required this.subjectName,
    required this.courseAndTerm,
    required this.location,
    required this.enrolled,
    required this.maxCapacity,
    required this.professor,
    required this.formulaRegime,
  });
}

class AdminProtocolModel {
  final String id;
  final String studentName;
  final String studentRa;
  final String requestType;
  final String date;
  String status; // 'Aguardando Parecer', 'Deferido', 'Indeferido'
  final String attachmentName;
  final String justification;
  String? decisionNote;
  String? signedBy;

  AdminProtocolModel({
    required this.id,
    required this.studentName,
    required this.studentRa,
    required this.requestType,
    required this.date,
    required this.status,
    required this.attachmentName,
    required this.justification,
    this.decisionNote,
    this.signedBy,
  });
}

class AdminAuditLogModel {
  final String id;
  final String timestamp;
  final String actor;
  final String actionType;
  final String description;
  final String ipAddress;
  final String severity; // 'INFO', 'ATENCAO', 'CRITICO'

  const AdminAuditLogModel({
    required this.id,
    required this.timestamp,
    required this.actor,
    required this.actionType,
    required this.description,
    required this.ipAddress,
    required this.severity,
  });
}

class AdminMockData {
  static final List<AdminUserModel> users = [
    AdminUserModel(
      id: '2024.1.00892',
      name: 'Gabriel Soares de Oliveira',
      email: 'gabriel.oliveira@aluno.universidade.edu.br',
      profile: 'Discente',
      departmentOrCourse: 'Engenharia de Software (4º Semestre)',
      status: 'Ativo',
      twoFactorRequired: true,
    ),
    AdminUserModel(
      id: 'DOC-88410',
      name: 'Profa. Dra. Helena Bittencourt',
      email: 'helena.bittencourt@docente.universidade.edu.br',
      profile: 'Docente',
      departmentOrCourse: 'Departamento de Computação e Sistemas',
      status: 'Ativo',
      twoFactorRequired: true,
    ),
    AdminUserModel(
      id: 'DOC-88411',
      name: 'Prof. Dr. Marcos Vinicius',
      email: 'marcos.vinicius@docente.universidade.edu.br',
      profile: 'Docente',
      departmentOrCourse: 'Departamento de Banco de Dados',
      status: 'Ativo',
      twoFactorRequired: true,
    ),
    AdminUserModel(
      id: 'ADM-00129',
      name: 'Carlos Eduardo Mendes',
      email: 'carlos.mendes@secretaria.universidade.edu.br',
      profile: 'Administrador',
      departmentOrCourse: 'Secretaria Geral Acadêmica & Auditoria',
      status: 'Ativo',
      twoFactorRequired: true,
    ),
    AdminUserModel(
      id: '2024.1.00912',
      name: 'Mariana Rios Costa',
      email: 'mariana.rios@aluno.universidade.edu.br',
      profile: 'Discente',
      departmentOrCourse: 'Engenharia de Software (4º Semestre)',
      status: 'Ativo',
      twoFactorRequired: false,
    ),
    AdminUserModel(
      id: '2024.1.00940',
      name: 'Lucas Silva Santos',
      email: 'lucas.silva@aluno.universidade.edu.br',
      profile: 'Discente',
      departmentOrCourse: 'Engenharia de Software (4º Semestre)',
      status: 'Ativo',
      twoFactorRequired: false,
    ),
  ];

  static final List<AdminCourseModel> courses = [
    const AdminCourseModel(
      code: 'ENG-SOFT-2024',
      name: 'Bacharelado em Engenharia de Software',
      matrix: 'Matriz 2024/1 (PPC Atualizado)',
      workload: '3200h / 210 créditos',
      studentsCount: 420,
      formula: 'Média = (N1 x 0.4) + (N2 x 0.6) • Freq. ≥ 75%',
      components: [
        {'semestre': '4º Semestre', 'disciplina': 'Análise e Projeto de Sistemas II', 'carga': '80h', 'docente': 'Profa. Dra. Helena Bittencourt'},
        {'semestre': '4º Semestre', 'disciplina': 'Banco de Dados II', 'carga': '80h', 'docente': 'Prof. Dr. Marcos Vinicius'},
        {'semestre': '4º Semestre', 'disciplina': 'Fundamentos de Inteligência Artificial', 'carga': '60h', 'docente': 'Profa. Dra. Camila Santos'},
        {'semestre': '4º Semestre', 'disciplina': 'Fundamentos de Sistemas Operacionais', 'carga': '60h', 'docente': 'Prof. Me. Lucas Ribeiro'},
      ],
    ),
    const AdminCourseModel(
      code: 'SIS-INFO-2023',
      name: 'Bacharelado em Sistemas de Informação',
      matrix: 'Matriz 2023/1',
      workload: '3000h / 195 créditos',
      studentsCount: 380,
      formula: 'Média = (N1 x 0.4) + (N2 x 0.6) • Freq. ≥ 75%',
      components: [
        {'semestre': '4º Semestre', 'disciplina': 'Gestão de Processos de Negócio', 'carga': '80h', 'docente': 'Profa. Me. Carla Dias'},
        {'semestre': '4º Semestre', 'disciplina': 'Sistemas Integrados de Gestão (ERP)', 'carga': '80h', 'docente': 'Prof. Dr. Fernando Rocha'},
      ],
    ),
  ];

  static final List<AdminClassModel> classes = [
    AdminClassModel(
      code: '218131 - APS-II',
      subjectName: 'Análise e Projeto de Sistemas II',
      courseAndTerm: 'Engenharia de Software • 2026/2 • Noturno',
      location: 'Lab Informática 04 - Bloco C',
      enrolled: 34,
      maxCapacity: 40,
      professor: 'Profa. Dra. Helena Bittencourt',
      formulaRegime: 'Impor pelo Admin',
    ),
    AdminClassModel(
      code: '218132 - BD-II',
      subjectName: 'Banco de Dados II',
      courseAndTerm: 'Engenharia de Software • 2026/2 • Noturno',
      location: 'Lab Informática 02 - Bloco B',
      enrolled: 32,
      maxCapacity: 40,
      professor: 'Prof. Dr. Marcos Vinicius',
      formulaRegime: 'Impor pelo Admin',
    ),
    AdminClassModel(
      code: '218133 - FIS',
      subjectName: 'Fundamentos de Inteligência Artificial',
      courseAndTerm: 'Engenharia de Software • 2026/2 • Noturno',
      location: 'Sala 302 - Bloco A',
      enrolled: 38,
      maxCapacity: 45,
      professor: 'Profa. Dra. Camila Santos',
      formulaRegime: 'Autonomia Docente',
    ),
    AdminClassModel(
      code: '218134 - FSO',
      subjectName: 'Fundamentos de Sistemas Operacionais',
      courseAndTerm: 'Engenharia de Software • 2026/2 • Noturno',
      location: 'Lab Informática 01 - Bloco C',
      enrolled: 35,
      maxCapacity: 40,
      professor: 'Prof. Me. Lucas Ribeiro',
      formulaRegime: 'Impor pelo Admin',
    ),
  ];

  static final List<AdminProtocolModel> protocols = [
    AdminProtocolModel(
      id: 'PROT-2026/8850',
      studentName: 'Lucas Silva Santos',
      studentRa: '2024.1.00940',
      requestType: 'SEGUNDA CHAMADA DE PROVA N1',
      date: '18/10/2026',
      status: 'Aguardando Parecer',
      attachmentName: 'declaracao_empresa_trabalho.pdf',
      justification: 'Discente em viagem de trabalho comprovada no dia da prova teórica P1 de APS-II.',
    ),
    AdminProtocolModel(
      id: 'PROT-2026/8841',
      studentName: 'Camila Duarte Fagundes',
      studentRa: '2024.1.00962',
      requestType: 'ATESTADO MÉDICO COM ABONO',
      date: '15/10/2026',
      status: 'Deferido',
      attachmentName: 'atestado_medico_crm_19821.pdf',
      justification: 'Atestado médico de 3 dias por intervenção odontológica.',
      decisionNote: 'Deferido formalmente. Faltas abonadas em diário eletrônico.',
      signedBy: 'Carlos Eduardo Mendes - Secretaria Geral',
    ),
    AdminProtocolModel(
      id: 'PROT-2026/8829',
      studentName: 'Mariana Rios Costa',
      studentRa: '2024.1.00912',
      requestType: 'VALIDAÇÃO DE HORAS COMPLEMENTARES',
      date: '12/10/2026',
      status: 'Deferido',
      attachmentName: 'certificado_hackathon_2026.pdf',
      justification: 'Participação no Hackathon Universitário de Cibersegurança (40h).',
      decisionNote: '40h computadas no prontuário estudantil.',
      signedBy: 'Carlos Eduardo Mendes - Secretaria Geral',
    ),
  ];

  static final List<AdminAuditLogModel> auditLogs = [
    const AdminAuditLogModel(
      id: 'LOG-0912',
      timestamp: '20/10/2026 14:22:10',
      actor: 'Profa. Dra. Helena Bittencourt',
      actionType: 'LANÇAMENTO NOTA',
      description: 'Lançamento de nota de avaliação (9.5) para discente Mariana Rios Costa na disciplina APS-II.',
      ipAddress: '177.136.24.10',
      severity: 'INFO',
    ),
    const AdminAuditLogModel(
      id: 'LOG-0911',
      timestamp: '20/10/2026 11:05:42',
      actor: 'Carlos Eduardo Mendes',
      actionType: 'DEFERIMENTO PROTOCOLO',
      description: 'Homologação e deferimento do protocolo PROT-2026/8841 (Atestado Médico Camila Duarte).',
      ipAddress: '192.168.10.45',
      severity: 'INFO',
    ),
    const AdminAuditLogModel(
      id: 'LOG-0910',
      timestamp: '19/10/2026 18:30:19',
      actor: 'Sistema de Segurança WAF',
      actionType: 'ALERTA 2FA',
      description: 'Tentativa de login sem 2FA bloqueada na conta administrativa de coordenação.',
      ipAddress: '189.44.112.5',
      severity: 'ATENCAO',
    ),
    const AdminAuditLogModel(
      id: 'LOG-0909',
      timestamp: '18/10/2026 09:12:00',
      actor: 'Carlos Eduardo Mendes',
      actionType: 'TRAVA REGIMENTAL',
      description: 'Ativação do bloqueio de alterações em diários de classe para término da janela N1.',
      ipAddress: '192.168.10.45',
      severity: 'INFO',
    ),
  ];
}
