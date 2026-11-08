// Desenvolvido por Time 3 - PI IV (Integração Ecossistema Real MongoDB)
import "../config/local-environment.js";
import { fileURLToPath } from "node:url";
import bcrypt from "bcryptjs";
import { MongoClient, ObjectId, type Db, type Document } from "mongodb";
import { loadEnvironment } from "../config/environment.js";

const SEED_TAG = "ecosystem-v1";

export async function seedEcosystem(
  database: Db,
  password: string,
): Promise<Record<string, { created: number; reused: number }>> {
  if (!password || password.trim().length < 8) {
    throw new Error("Informe SEED_DEMO_PASSWORD com ao menos 8 caracteres.");
  }

  const now = new Date();
  const summary: Record<string, { created: number; reused: number }> = {};
  const recordStat = (col: string, created: boolean) => {
    const bucket = (summary[col] ??= { created: 0, reused: 0 });
    if (created) bucket.created++;
    else bucket.reused++;
  };

  const upsertOnInsert = async (collection: string, filter: Document, doc: Document): Promise<Document> => {
    const existing = await database.collection(collection).findOne(filter);
    if (existing) {
      recordStat(collection, false);
      return existing;
    }
    const toInsert: Document = { _id: new ObjectId(), ...doc };
    const res = await database
      .collection(collection)
      .updateOne(filter, { $setOnInsert: toInsert }, { upsert: true });
    recordStat(collection, res.upsertedCount === 1);
    return (await database.collection(collection).findOne(filter)) ?? toInsert;
  };

  const upsertSync = async (collection: string, filter: Document, doc: Document): Promise<Document> => {
    const { _id: _ignoreId, createdAt, ...mutableFields } = doc;
    const res = await database
      .collection(collection)
      .updateOne(
        filter,
        {
          $set: mutableFields,
          $setOnInsert: { _id: new ObjectId(), createdAt: createdAt ?? now },
        },
        { upsert: true },
      );
    recordStat(collection, res.upsertedCount === 1);
    return (await database.collection(collection).findOne(filter)) ?? doc;
  };

  const passwordHash = await bcrypt.hash(password, 12);

  // 1. Garante contas verificáveis sem jamais sobrescrever senhas de contas existentes
  const accountsToEnsure = [
    {
      identity: "coord.agmrm",
      normalizedIdentity: "coord.agmrm",
      email: "coord.agmrm@agmrm.edu.br",
      normalizedEmail: "coord.agmrm@agmrm.edu.br",
      displayName: "Coordenação Acadêmica AGMRM",
      profile: "admin",
      departmentOrCourse: "Coordenação de Engenharia de Software",
      campus: "Unidade Sede",
    },
    {
      identity: "docente.agmrm",
      normalizedIdentity: "docente.agmrm",
      email: "docente.agmrm@agmrm.edu.br",
      normalizedEmail: "docente.agmrm@agmrm.edu.br",
      displayName: "Prof. Dr. Ricardo Vasconcelos",
      profile: "docente",
      departmentOrCourse: "Engenharia de Software e Sistemas Distribuídos",
      campus: "Unidade Sede",
    },
    {
      identity: "helena.bittencourt",
      normalizedIdentity: "helena.bittencourt",
      email: "helena.bittencourt@agmrm.edu.br",
      normalizedEmail: "helena.bittencourt@agmrm.edu.br",
      displayName: "Profa. Dra. Helena Bittencourt",
      profile: "docente",
      departmentOrCourse: "Engenharia de Software",
      campus: "Unidade Sede",
    },
    {
      identity: "202610401",
      normalizedIdentity: "202610401",
      email: "mariana.ferreira@aluno.agmrm.edu.br",
      normalizedEmail: "mariana.ferreira@aluno.agmrm.edu.br",
      displayName: "Mariana Costa Ferreira",
      profile: "aluno",
      departmentOrCourse: "Engenharia de Software",
      semester: "2026/2 - 4º Semestre",
      shift: "Noturno",
      campus: "Unidade Sede",
    },
    {
      identity: "202610402",
      normalizedIdentity: "202610402",
      email: "lucas.prado@aluno.agmrm.edu.br",
      normalizedEmail: "lucas.prado@aluno.agmrm.edu.br",
      displayName: "Lucas Henrique Prado",
      profile: "aluno",
      departmentOrCourse: "Engenharia de Software",
      semester: "2026/2 - 4º Semestre",
      shift: "Noturno",
      campus: "Unidade Sede",
    },
    {
      identity: "aluno.test",
      normalizedIdentity: "aluno.test",
      email: "aluno.test@agmrm.edu.br",
      normalizedEmail: "aluno.test@agmrm.edu.br",
      displayName: "Aluno Teste AGMRM",
      profile: "aluno",
      departmentOrCourse: "Engenharia de Software",
      semester: "2026/2 - 4º Semestre",
      shift: "Noturno",
      campus: "Unidade Sede",
    },
    {
      identity: "docente.test",
      normalizedIdentity: "docente.test",
      email: "docente.test@agmrm.edu.br",
      normalizedEmail: "docente.test@agmrm.edu.br",
      displayName: "Docente Teste AGMRM",
      profile: "docente",
      departmentOrCourse: "Engenharia de Software",
      campus: "Unidade Sede",
    },
    {
      identity: "admin.test",
      normalizedIdentity: "admin.test",
      email: "admin.test@agmrm.edu.br",
      normalizedEmail: "admin.test@agmrm.edu.br",
      displayName: "Administrador Teste AGMRM",
      profile: "admin",
      departmentOrCourse: "Administração Central",
      campus: "Unidade Sede",
    },
  ];

  const ensuredUsers = new Map<string, Document>();
  for (const acc of accountsToEnsure) {
    const userDoc = await upsertOnInsert(
      "auth_users",
      { normalizedIdentity: acc.normalizedIdentity },
      {
        ...acc,
        passwordHash,
        active: true,
        twoFactorRequired: false,
        sessionVersion: 0,
        createdAt: now,
        updatedAt: now,
        seedTag: SEED_TAG,
      },
    );
    ensuredUsers.set(acc.normalizedIdentity, userDoc);
  }

  // Busca também contas já existentes da equipe (se presentes) sem tocar em senhas
  const existingTeamUsers = await database
    .collection("auth_users")
    .find({
      normalizedIdentity: {
        $in: ["admin.demo", "prof.demo", "aluno.demo1", "aluno.demo2", "doc", "aluno", "alu"],
      },
    })
    .toArray();
  for (const u of existingTeamUsers) {
    ensuredUsers.set(String(u.normalizedIdentity ?? u.identity).toLowerCase(), u);
  }

  const adminActor = ensuredUsers.get("coord.agmrm")!;
  const mainTeacher = ensuredUsers.get("docente.agmrm")!;
  const profHelena = ensuredUsers.get("helena.bittencourt") ?? mainTeacher;
  const stMariana = ensuredUsers.get("202610401")!;
  const stLucas = ensuredUsers.get("202610402")!;
  const stTest = ensuredUsers.get("aluno.test")!;

  // 2. Curso principal Engenharia de Software
  const courseMain = await upsertOnInsert(
    "academic_courses",
    { code: "ES-2026" },
    {
      code: "ES-2026",
      name: "Engenharia de Software",
      matrix: "Matriz 2026 - DCN Computação",
      workload: "3.200h",
      studentsCount: 2,
      formula: "(N1 × 0.4) + (N2 × 0.6)",
      department: "Computação e Engenharia",
      modality: "Presencial / Híbrido Síncrono",
      active: true,
      components: [
        { code: "PI-IV", name: "Projeto Integrador IV", workloadHours: 80, semester: 4 },
        { code: "ARQ-SW", name: "Arquitetura de Software e Nuvem", workloadHours: 80, semester: 4 },
        { code: "BD-NOSQL", name: "Bancos de Dados Distribuídos", workloadHours: 60, semester: 4 },
      ],
      createdBy: String(adminActor._id),
      createdAt: now,
      updatedAt: now,
      seedTag: SEED_TAG,
    },
  );

  // 3. Turmas reais para o docente principal
  const classesToEnsure = [
    {
      code: "218131 - APS-II",
      subjectName: "Análise e Projeto de Sistemas II",
      courseCode: courseMain.code,
      courseName: courseMain.name,
      professor: profHelena,
      semester: "2026/2",
      shift: "Noturno",
      schedule: "Noturno (19:10 - 22:40)",
      location: "Laboratório de Informática 04 - Bloco C",
      totalHours: 80,
      credits: 4,
      completedHours: 54,
      officeHours: "Terças-feiras • 18:00 às 19:00",
      officeLocation: "Sala dos Professores (Bloco C) ou Sala Virtual Teams",
      syllabusUnits: [
        {
          id: "unit-aps-1",
          unitNumber: 1,
          tag: "UNIDADE 1 • SEMANAS 1 A 4 • 20 HORAS LETIVAS",
          title: "Unidade 1: Engenharia de Requisitos & Processos Ágeis de Software",
          topics: ["Processo Unificado", "Elicitação de Requisitos", "Casos de Uso"],
          hours: 20,
          completedClasses: 10,
          totalClasses: 10,
          items: [
            {
              id: "item-aps-1-1",
              type: "pdf",
              title: "Plano de Ensino & Contrato Pedagógico da Disciplina",
              subtitle: "Pdf • 420 KB",
              actionType: "access",
              fileName: "plano-de-ensino-aps2.pdf",
              fileSize: "420 KB",
            },
            {
              id: "item-aps-1-2",
              type: "pdf",
              title: "Slides da Aula 01: Processo Unificado e Engenharia de Software Moderna",
              subtitle: "Pdf • 3.8 MB",
              actionType: "access",
              fileName: "slides-aula-01-processo-unificado.pdf",
              fileSize: "3.8 MB",
            },
            {
              id: "item-aps-1-3",
              type: "video",
              title: "Gravação da Aula Síncrona: Elicitação de Requisitos e Casos de Uso",
              subtitle: "Vídeo • 1h 35min",
              actionType: "access",
            },
            {
              id: "item-aps-1-4",
              type: "task",
              title: "Exercício 01: Mapeamento de Requisitos e Especificação de Casos de Uso",
              subtitle: "Tarefa • Prazo: 05 Set às 23:59",
              actionType: "delivery",
              assignmentKey: "assign-aps-ex1",
            },
          ],
        },
        {
          id: "unit-aps-2",
          unitNumber: 2,
          tag: "UNIDADE 2 • SEMANAS 5 A 9 • 24 HORAS LETIVAS • EM ANDAMENTO",
          title: "Unidade 2: Modelagem Orientada a Objetos com Notação UML 2.5",
          topics: ["Diagrama de Classes", "Template Oficial", "Diagrama de Sequência"],
          hours: 24,
          completedClasses: 12,
          totalClasses: 12,
          status: "EM ANDAMENTO",
          items: [
            {
              id: "item-aps-2-1",
              type: "pdf",
              title: "Slides da Aula 03: Diagrama de Classes, Multiplicidades e Visibilidade",
              subtitle: "Pdf • 4.2 MB",
              actionType: "access",
              fileName: "slides-aula-03-classes.pdf",
              fileSize: "4.2 MB",
            },
            {
              id: "item-aps-2-2",
              type: "archive",
              title: "Template Oficial de Diagramação (.drawio e .uml)",
              subtitle: "Arquivo • 180 KB",
              actionType: "access",
              fileName: "template-diagramacao-oficial.drawio",
              fileSize: "180 KB",
            },
            {
              id: "item-aps-2-3",
              type: "pdf",
              title: "Slides da Aula 04: Diagrama de Sequência e Interações Temporais",
              subtitle: "Pdf • 2.9 MB",
              actionType: "access",
              fileName: "slides-aula-04-sequencia.pdf",
              fileSize: "2.9 MB",
            },
            {
              id: "item-aps-2-4",
              type: "task",
              title: "Entrega da Sprint 1: Diagrama de Classes e Sequência do AVA",
              subtitle: "Tarefa • Prazo: Hoje às 23:59",
              actionType: "delivery",
              assignmentKey: "assign-aps-sprint1",
            },
          ],
        },
        {
          id: "unit-aps-3",
          unitNumber: 3,
          tag: "UNIDADE 3 • SEMANAS 10 A 14 • 24 HORAS LETIVAS • PRÓXIMA ETAPA",
          title: "Unidade 3: Padrões de Projeto (Design Patterns GRASP & GoF)",
          topics: ["Padrões GRASP", "Padrões GoF em TypeScript", "Refatoração"],
          hours: 24,
          completedClasses: 0,
          totalClasses: 12,
          status: "PRÓXIMA ETAPA",
          items: [
            {
              id: "item-aps-3-1",
              type: "reading",
              title: "Material Teórico: Padrões de Atribuição de Responsabilidade (GRASP)",
              subtitle: "Leitura • 15 páginas",
              actionType: "access",
            },
            {
              id: "item-aps-3-2",
              type: "code",
              title: "Repositório de Exemplos: Padrões GoF Criacionais e Estruturais em TypeScript",
              subtitle: "Código • GitHub Repo",
              actionType: "access",
            },
            {
              id: "item-aps-3-3",
              type: "task",
              title: "Atividade Prática: Refatoração Orientada a Padrões de Projeto",
              subtitle: "Tarefa • Prazo: 18 Out às 23:59",
              actionType: "delivery",
              assignmentKey: "assign-aps-refactor",
            },
          ],
        },
        {
          id: "unit-aps-4",
          unitNumber: 4,
          tag: "UNIDADE 4 • SEMANAS 15 A 18 • 12 HORAS LETIVAS • FECHAMENTO",
          title: "Unidade 4: Arquitetura Limpa, Microsserviços e Projeto Integrador",
          topics: ["Diretrizes da Banca", "Submissão Final"],
          hours: 12,
          completedClasses: 0,
          totalClasses: 6,
          status: "FECHAMENTO",
          items: [
            {
              id: "item-aps-4-1",
              type: "pdf",
              title: "Diretrizes Oficiais da Banca do Projeto Integrador",
              subtitle: "Pdf • 510 KB",
              actionType: "access",
              fileName: "diretrizes-banca-pi.pdf",
              fileSize: "510 KB",
            },
            {
              id: "item-aps-4-2",
              type: "task",
              title: "Submissão Final: Relatório Técnico da Arquitetura e Código-Fonte",
              subtitle: "Tarefa • Prazo: 25 Nov às 23:59",
              actionType: "delivery",
              assignmentKey: "assign-aps-final",
            },
          ],
        },
      ],
    },
    {
      code: "PI4-2026-4N",
      subjectName: "Projeto Integrador IV - Sistemas Integrados",
      courseCode: courseMain.code,
      courseName: courseMain.name,
      professor: mainTeacher,
      semester: "2026/2 - 4º Semestre",
      shift: "Noturno",
      schedule: "Quartas-feiras, 19:00 - 22:30",
      location: "Lab. Engenharia 304 / Sala Síncrona",
      totalHours: 80,
      completedHours: 40,
      ementa: "Concepção, arquitetura e entrega contínua de sistemas distribuídos full-stack com persistência NoSQL, autenticação segura em múltiplos fatores, comunicação em tempo real via WebRTC e observabilidade ponta a ponta.",
      objectives: "1. Projetar e homologar contratos REST/WebSocket desacoplados.\n2. Operar persistência transacional auditável no MongoDB Atlas.\n3. Integrar interfaces reativas Flutter Web/Mobile sem mocks estáticos.",
      methodology: "Aprendizagem Baseada em Projetos (PBL) organizada em Sprints quinzenais com code-review docente, integração contínua e banca integradora final.",
      syllabusUnits: [
        {
          id: "unit-pi4-1",
          unitNumber: 1,
          tag: "UNIDADE 1 • 20 HORAS LETIVAS • CONCLUÍDA",
          title: "Unidade I — Arquitetura Modular e Contratos REST/WebSocket",
          topics: ["Camadas limpas", "Autenticação JWT e 2FA", "Sinalização WebSocket"],
          hours: 20,
          completedClasses: 10,
          totalClasses: 10,
          items: [
            { id: "item-pi4-1-1", type: "pdf", title: "Plano de Ensino & Regulamento do Projeto Integrador IV", subtitle: "PDF • 1.2 MB", actionType: "access", fileName: "Plano_de_Ensino_Oficial_2026_2.pdf", fileSize: "1.2 MB" },
            { id: "item-pi4-1-2", type: "pdf", title: "Slides Aula 01: Contratos REST, DTOs e Autenticação em 2 Fatores", subtitle: "PDF • 4.8 MB", actionType: "access", fileName: "Aula_01_Introducao_Arquitetura_Software.pdf", fileSize: "4.8 MB" },
            { id: "item-pi4-1-3", type: "video", title: "Gravação Síncrona: Sinalização WebSocket & Salas Ao Vivo", subtitle: "Vídeo • 1h 42min", actionType: "access" },
          ],
        },
        {
          id: "unit-pi4-2",
          unitNumber: 2,
          tag: "UNIDADE 2 • 20 HORAS LETIVAS • EM ANDAMENTO",
          title: "Unidade II — Persistência Distribuída com MongoDB Atlas",
          topics: ["Transações ACID", "Trilhas de auditoria", "Protocolos SHA-256"],
          hours: 20,
          completedClasses: 10,
          totalClasses: 10,
          items: [
            { id: "item-pi4-2-1", type: "pdf", title: "Guia Prático: Modelagem de Agregados e Índices no MongoDB", subtitle: "PDF • 3.1 MB", actionType: "access", fileName: "Guia_Pratico_Diagramacao_UML_2.5.pdf", fileSize: "3.1 MB" },
            { id: "item-pi4-2-2", type: "code", title: "Laboratório Prático: Repositórios, Mappers e Hash SHA-256", subtitle: "ZIP • 14.5 MB", actionType: "access", fileName: "Template_Projeto_Camadas_Spring_Domain.zip", fileSize: "14.5 MB" },
            { id: "item-pi4-2-3", type: "task", title: "Atividade Prática 03: Implementação de API REST", subtitle: "Tarefa • Entrega via AVA", actionType: "delivery" },
          ],
        },
        {
          id: "unit-pi4-3",
          unitNumber: 3,
          tag: "UNIDADE 3 • 40 HORAS LETIVAS • PRÓXIMA ETAPA",
          title: "Unidade III — Integração Full-Stack Flutter e Homologação",
          topics: ["Consumo reativo sem mocks", "Videochamada síncrona", "Banca final"],
          hours: 40,
          completedClasses: 4,
          totalClasses: 20,
          items: [
            { id: "item-pi4-3-1", type: "reading", title: "Artigo Técnico: Estado Reativo e Arquitetura Modular em Flutter", subtitle: "PDF • 2.4 MB", actionType: "access", fileName: "Artigo_Referencia_Microservices_Clean_Arch.pdf", fileSize: "2.4 MB" },
            { id: "item-pi4-3-2", type: "pdf", title: "Checklist de Homologação e Rubrica Oficial da Banca", subtitle: "PDF • 850 KB", actionType: "access", fileName: "Lista_Exercicios_Padroes_GoF_Grasp.pdf", fileSize: "850 KB" },
            { id: "item-pi4-3-3", type: "task", title: "Submissão Integrada da Sprint: Repositório & Evidências", subtitle: "Tarefa • Entrega em Equipe", actionType: "delivery" },
          ],
        },
      ],
    },
    {
      code: "ARQ-2026-4N",
      subjectName: "Arquitetura de Software e Microsserviços",
      courseCode: courseMain.code,
      courseName: courseMain.name,
      professor: mainTeacher,
      semester: "2026/2 - 4º Semestre",
      shift: "Noturno",
      schedule: "Segundas-feiras, 19:00 - 22:30",
      location: "Auditório B-12 / Sala Síncrona",
      totalHours: 80,
      completedHours: 30,
      ementa: "Estilos e padrões arquiteturais contemporâneos: Clean Architecture, Arquitetura Hexagonal (Ports & Adapters), Domain-Driven Design (DDD), decomposição em microsserviços, resiliência (Circuit Breaker, Retry, Outbox) e observabilidade distribuída.",
      objectives: "1. Estruturar domínios ricos isolados de infraestrutura com Clean Architecture e DDD.\n2. Projetar comunicação síncrona e assíncrona resiliente a falhas de rede.\n3. Instrumentar telemetria, rate-limiting, revogação de sessão e conformidade LGPD.",
      methodology: "Aulas expositivas dialogadas com estudos de caso reais de engenharia de produção, laboratórios de refatoração arquitetural e Architecture Decision Records (ADRs).",
      syllabusUnits: [
        {
          id: "unit-arq-1",
          unitNumber: 1,
          tag: "UNIDADE 1 • 30 HORAS LETIVAS • EM ANDAMENTO",
          title: "Unidade I — Clean Architecture & Domain-Driven Design",
          topics: ["Apresentação, Aplicação, Domínio e Infraestrutura", "Agregados, Entidades e Inversão de Dependência"],
          hours: 30,
          completedClasses: 15,
          totalClasses: 15,
          items: [
            { id: "item-arq-1-1", type: "pdf", title: "Plano de Ensino e Guia Arquitetural — ARQ-2026-4N", subtitle: "PDF • 1.2 MB", actionType: "access", fileName: "Plano_de_Ensino_Oficial_2026_2.pdf", fileSize: "1.2 MB" },
            { id: "item-arq-1-2", type: "pdf", title: "Slides Aula 01: Clean Architecture, Ports & Adapters e DDD Estratégico", subtitle: "PDF • 4.8 MB", actionType: "access", fileName: "Aula_01_Introducao_Arquitetura_Software.pdf", fileSize: "4.8 MB" },
            { id: "item-arq-1-3", type: "reading", title: "Material Complementar: Estudo de Caso de Microsserviços", subtitle: "PDF • 2.4 MB", actionType: "access", fileName: "estudo-de-caso-microsservicos.pdf", fileSize: "2.4 MB" },
            { id: "item-arq-1-4", type: "code", title: "Template de Projeto em Camadas Limpas & Agregados de Domínio", subtitle: "ZIP • 14.5 MB", actionType: "access", fileName: "Template_Projeto_Camadas_Spring_Domain.zip", fileSize: "14.5 MB" },
          ],
        },
        {
          id: "unit-arq-2",
          unitNumber: 2,
          tag: "UNIDADE 2 • 30 HORAS LETIVAS • CONTEÚDO LIBERADO",
          title: "Unidade II — Resiliência, Observabilidade e Segurança",
          topics: ["Circuit Breaker, Outbox Pattern & Rate Limiting", "Sessões Revogáveis & Conformidade LGPD"],
          hours: 30,
          completedClasses: 4,
          totalClasses: 15,
          items: [
            { id: "item-arq-2-1", type: "pdf", title: "Apostila Técnica: Padrões de Resiliência (Circuit Breaker, Retry & Transactional Outbox)", subtitle: "PDF • 3.1 MB", actionType: "access", fileName: "Guia_Pratico_Diagramacao_UML_2.5.pdf", fileSize: "3.1 MB" },
            { id: "item-arq-2-2", type: "video", title: "Videoaula Síncrona: Observabilidade com OpenTelemetry, Logs Estruturados e LGPD", subtitle: "Vídeo • 1h 48min", actionType: "access" },
            { id: "item-arq-2-3", type: "pdf", title: "Lista de Exercícios: Arquitetura Resiliente, Rate Limiting e Zero-Trust", subtitle: "PDF • 850 KB", actionType: "access", fileName: "Lista_Exercicios_Padroes_GoF_Grasp.pdf", fileSize: "850 KB" },
            { id: "item-arq-2-4", type: "task", title: "Entrega Prática: Especificação de ADR e Resiliência de Serviços", subtitle: "Tarefa • Submissão com Protocolo SHA-256", actionType: "delivery" },
          ],
        },
        {
          id: "unit-arq-3",
          unitNumber: 3,
          tag: "UNIDADE 3 • 20 HORAS LETIVAS • PRÓXIMA ETAPA",
          title: "Unidade III — Mensageria Assíncrona, Event-Driven & Governança de APIs",
          topics: ["Coreografia vs Orquestração (Saga)", "API Gateway e Contratos Versionados"],
          hours: 20,
          completedClasses: 0,
          totalClasses: 10,
          items: [
            { id: "item-arq-3-1", type: "reading", title: "Leitura Obrigatória: Padrão Saga e Consistência Eventual em Sistemas Críticos", subtitle: "PDF • 2.4 MB", actionType: "access", fileName: "Artigo_Referencia_Microservices_Clean_Arch.pdf", fileSize: "2.4 MB" },
            { id: "item-arq-3-2", type: "code", title: "Laboratório Guiado: Mensageria Assíncrona e Idempotência de Consumidores", subtitle: "ZIP • 14.5 MB", actionType: "access", fileName: "Template_Projeto_Camadas_Spring_Domain.zip", fileSize: "14.5 MB" },
            { id: "item-arq-3-3", type: "video", title: "Seminário Arquitetural: Evolução de Monolitos Modulares para Microsserviços", subtitle: "Vídeo • 1h 30min", actionType: "access" },
          ],
        },
      ],
    },
    {
      code: "BD2-2026-4N",
      subjectName: "Estudos de Banco de Dados II",
      courseCode: courseMain.code,
      courseName: courseMain.name,
      professor: mainTeacher,
      semester: "2026/2 - 4º Semestre",
      shift: "Noturno",
      schedule: "Terças-feiras, 19:00 - 22:30",
      location: "Lab. 201 / Sala Síncrona",
      totalHours: 80,
      completedHours: 60,
      ementa: "Otimização de consultas e indexação avançada em SGBDs relacionais, controle de concorrência multiversão (MVCC), isolamento transacional ACID, bancos orientados a documentos (MongoDB) e modelagem híbrida.",
      objectives: "1. Analisar planos de execução e projetar índices compostos de alta seletividade.\n2. Dominar níveis de isolamento transacional, locks e recuperação a falhas.\n3. Modelar coleções, pipelines de agregação e replicação em MongoDB.",
      methodology: "Laboratórios práticos com datasets reais em PostgreSQL e MongoDB Atlas, tuning de queries e resolução de estudos de caso transacionais.",
      syllabusUnits: [
        {
          id: "unit-bd2-1",
          unitNumber: 1,
          tag: "UNIDADE 1 • 28 HORAS LETIVAS • CONCLUÍDA",
          title: "Unidade I — Indexação B-Tree, Planos de Execução e Tuning SQL",
          topics: ["Árvores B+ e Hash Indexes", "EXPLAIN ANALYZE", "Particionamento de Tabelas"],
          hours: 28,
          completedClasses: 14,
          totalClasses: 14,
          items: [
            { id: "item-bd2-1-1", type: "pdf", title: "Plano de Ensino & Guia de Laboratório de Bancos de Dados II", subtitle: "PDF • 1.2 MB", actionType: "access", fileName: "Plano_de_Ensino_Oficial_2026_2.pdf", fileSize: "1.2 MB" },
            { id: "item-bd2-1-2", type: "pdf", title: "Slides Aula 01: Estruturas Internas de Armazenamento e Índices Compostos", subtitle: "PDF • 4.8 MB", actionType: "access", fileName: "Aula_01_Introducao_Arquitetura_Software.pdf", fileSize: "4.8 MB" },
            { id: "item-bd2-1-3", type: "task", title: "Entrega: Atividade 2 - Modelagem de Banco de Dados Relacional", subtitle: "Tarefa • Avaliada", actionType: "delivery" },
          ],
        },
        {
          id: "unit-bd2-2",
          unitNumber: 2,
          tag: "UNIDADE 2 • 28 HORAS LETIVAS • EM ANDAMENTO",
          title: "Unidade II — Transações ACID, Concorrência MVCC e Recuperação WAL",
          topics: ["Isolamento Read Committed vs Serializable", "Deadlocks", "Write-Ahead Logging"],
          hours: 28,
          completedClasses: 12,
          totalClasses: 14,
          items: [
            { id: "item-bd2-2-1", type: "pdf", title: "Apostila: Controle de Concorrência Multiversão (MVCC) e Isolamento", subtitle: "PDF • 3.1 MB", actionType: "access", fileName: "Guia_Pratico_Diagramacao_UML_2.5.pdf", fileSize: "3.1 MB" },
            { id: "item-bd2-2-2", type: "code", title: "Scripts de Laboratório: Simulação de Anomalias Transacionais e Locks", subtitle: "ZIP • 14.5 MB", actionType: "access", fileName: "Template_Projeto_Camadas_Spring_Domain.zip", fileSize: "14.5 MB" },
            { id: "item-bd2-2-3", type: "pdf", title: "Lista de Exercícios: Serializabilidade e Recuperação por Log", subtitle: "PDF • 850 KB", actionType: "access", fileName: "Lista_Exercicios_Padroes_GoF_Grasp.pdf", fileSize: "850 KB" },
          ],
        },
        {
          id: "unit-bd2-3",
          unitNumber: 3,
          tag: "UNIDADE 3 • 24 HORAS LETIVAS • CONTEÚDO LIBERADO",
          title: "Unidade III — Bancos NoSQL Orientados a Documentos e Aggregation Pipeline",
          topics: ["Schema Design em MongoDB", "Aggregation Framework", "Replica Sets e Sharding"],
          hours: 24,
          completedClasses: 4,
          totalClasses: 12,
          items: [
            { id: "item-bd2-3-1", type: "reading", title: "Artigo Técnico: Padrões de Modelagem Documental e Consistência Distribuída", subtitle: "PDF • 2.4 MB", actionType: "access", fileName: "Artigo_Referencia_Microservices_Clean_Arch.pdf", fileSize: "2.4 MB" },
            { id: "item-bd2-3-2", type: "video", title: "Aula Gravada: Aggregation Pipelines de Alta Performance no MongoDB Atlas", subtitle: "Vídeo • 1h 38min", actionType: "access" },
            { id: "item-bd2-3-3", type: "task", title: "Projeto Prático N2: Otimização de Consultas e Índices Híbridos", subtitle: "Tarefa • Entrega via AVA", actionType: "delivery" },
          ],
        },
      ],
    },
    {
      code: "FIS-2026-4N",
      subjectName: "Filosofia, Informação e Sociedade",
      courseCode: courseMain.code,
      courseName: courseMain.name,
      professor: mainTeacher,
      semester: "2026/2 - 4º Semestre",
      shift: "Noturno",
      schedule: "Quintas-feiras, 19:00 - 22:30",
      location: "Sala 105",
      totalHours: 60,
      completedHours: 50,
      ementa: "Epistemologia da computação, ética algorítmica, governança de Inteligência Artificial, capitalismo de vigilância, proteção de dados pessoais (LGPD / Marco Civil da Internet) e responsabilidade socioambiental na engenharia de software.",
      objectives: "1. Analisar criticamente os impactos éticos, políticos e sociais de sistemas algorítmicos.\n2. Aplicar princípios de Privacy by Design, transparência e não-discriminação em projetos de TI.\n3. Compreender o arcabouço jurídico brasileiro de proteção de dados e direitos digitais.",
      methodology: "Seminários socráticos orientados por textos clássicos e contemporâneos, análise de casos reais de governança de IA e fóruns avaliativos.",
      syllabusUnits: [
        {
          id: "unit-fis-1",
          unitNumber: 1,
          tag: "UNIDADE 1 • 20 HORAS LETIVAS • CONCLUÍDA",
          title: "Unidade 1: Ética na Sociedade da Informação e Cultura Algorítmica",
          topics: ["Filosofia da Técnica", "Economia da Atenção", "Transparência Algorítmica"],
          hours: 20,
          completedClasses: 10,
          totalClasses: 10,
          items: [
            { id: "item-fis-1-1", type: "reading", title: "Texto Base: O Dilema das Redes e a Arquitetura da Persuasão Digital", subtitle: "PDF • 2.4 MB", actionType: "access", fileName: "Artigo_Referencia_Microservices_Clean_Arch.pdf", fileSize: "2.4 MB" },
            { id: "item-fis-1-2", type: "pdf", title: "Plano de Ensino Oficial — Filosofia, Informação e Sociedade", subtitle: "PDF • 1.2 MB", actionType: "access", fileName: "Plano_de_Ensino_Oficial_2026_2.pdf", fileSize: "1.2 MB" },
            { id: "item-fis-1-3", type: "video", title: "Aula Magna Gravada: Epistemologia Cibernética e Sociedade em Rede", subtitle: "Vídeo • 1h 28min", actionType: "access" },
          ],
        },
        {
          id: "unit-fis-2",
          unitNumber: 2,
          tag: "UNIDADE 2 • 20 HORAS LETIVAS • EM ANDAMENTO",
          title: "Unidade 2: Governança de Inteligência Artificial e Responsabilidade Civil",
          topics: ["Viés Algorítmico", "Explicabilidade (XAI)", "Sistemas Autônomos Críticos"],
          hours: 20,
          completedClasses: 10,
          totalClasses: 10,
          items: [
            { id: "item-fis-2-1", type: "pdf", title: "Slides Aula 04: Ética Aplicada à IA Generativa e Decisão Automatizada", subtitle: "PDF • 4.8 MB", actionType: "access", fileName: "Aula_01_Introducao_Arquitetura_Software.pdf", fileSize: "4.8 MB" },
            { id: "item-fis-2-2", type: "pdf", title: "Guia de Estudo: Diretrizes Internacionais de Confiabilidade em IA", subtitle: "PDF • 3.1 MB", actionType: "access", fileName: "Guia_Pratico_Diagramacao_UML_2.5.pdf", fileSize: "3.1 MB" },
            { id: "item-fis-2-3", type: "task", title: "Fórum Temático: Ética na Inteligência Artificial", subtitle: "Tarefa • Ensaio Crítico", actionType: "delivery" },
          ],
        },
        {
          id: "unit-fis-3",
          unitNumber: 3,
          tag: "UNIDADE 3 • 20 HORAS LETIVAS • CONTEÚDO LIBERADO",
          title: "Unidade 3: Direitos Digitais, Soberania de Dados e Conformidade LGPD",
          topics: ["Autodeterminação Informativa", "Marco Civil da Internet", "Cidadania Digital"],
          hours: 20,
          completedClasses: 5,
          totalClasses: 10,
          items: [
            { id: "item-fis-3-1", type: "pdf", title: "Caderno de Casos Práticos: Relatório de Impacto à Proteção de Dados (RIPD)", subtitle: "PDF • 850 KB", actionType: "access", fileName: "Lista_Exercicios_Padroes_GoF_Grasp.pdf", fileSize: "850 KB" },
            { id: "item-fis-3-2", type: "video", title: "Debate Gravado: Privacidade por Padrão na Engenharia de Software", subtitle: "Vídeo • 1h 20min", actionType: "access" },
            { id: "item-fis-3-3", type: "code", title: "Kit Documental: Templates de Governança, Termos e Auditoria LGPD", subtitle: "ZIP • 14.5 MB", actionType: "access", fileName: "Template_Projeto_Camadas_Spring_Domain.zip", fileSize: "14.5 MB" },
          ],
        },
      ],
    },
    {
      code: "FSO-2026-4N",
      subjectName: "Fundamentos de Sistemas Operacionais",
      courseCode: courseMain.code,
      courseName: courseMain.name,
      professor: mainTeacher,
      semester: "2026/2 - 4º Semestre",
      shift: "Noturno",
      schedule: "Sextas-feiras, 19:00 - 22:30",
      location: "Lab. 102",
      totalHours: 80,
      completedHours: 43,
      ementa: "Arquitetura de núcleos monolíticos e microkernels, gerência de processos e threads POSIX, escalonamento de CPU, sincronização e semáforos, gerência de memória virtual paginada, sistemas de arquivos e virtualização em contêineres Linux.",
      objectives: "1. Compreender chamadas de sistema, troca de contexto e escalonamento preemptivo.\n2. Resolver problemas clássicos de concorrência sem condições de corrida ou deadlocks.\n3. Analisar paginação sob demanda, substituição de páginas e isolamento via namespaces/cgroups.",
      methodology: "Aulas teóricas integradas a experimentos práticos em ambiente Linux POSIX (C/Rust e shell) e análise de telemetria do kernel.",
      syllabusUnits: [
        {
          id: "unit-fso-1",
          unitNumber: 1,
          tag: "UNIDADE 1 • 28 HORAS LETIVAS • CONCLUÍDA",
          title: "Unidade I — Kernel, Processos, Threads e Escalonamento de CPU",
          topics: ["Syscalls POSIX", "Troca de Contexto", "Escalonador CFS Linux"],
          hours: 28,
          completedClasses: 14,
          totalClasses: 14,
          items: [
            { id: "item-fso-1-1", type: "pdf", title: "Plano de Ensino & Roteiro de Laboratório Linux — FSO", subtitle: "PDF • 1.2 MB", actionType: "access", fileName: "Plano_de_Ensino_Oficial_2026_2.pdf", fileSize: "1.2 MB" },
            { id: "item-fso-1-2", type: "pdf", title: "Slides Aula 01: Modo Usuário vs Modo Kernel, Fork/Exec e Threads", subtitle: "PDF • 4.8 MB", actionType: "access", fileName: "Aula_01_Introducao_Arquitetura_Software.pdf", fileSize: "4.8 MB" },
            { id: "item-fso-1-3", type: "code", title: "Laboratório 01: Implementação de Shell e Pool de Threads POSIX", subtitle: "ZIP • 14.5 MB", actionType: "access", fileName: "Template_Projeto_Camadas_Spring_Domain.zip", fileSize: "14.5 MB" },
          ],
        },
        {
          id: "unit-fso-2",
          unitNumber: 2,
          tag: "UNIDADE 2 • 28 HORAS LETIVAS • EM ANDAMENTO",
          title: "Unidade II — Concorrência, Exclusão Mútua e Memória Virtual Paginada",
          topics: ["Mutexes, Semáforos e Monitores", "TLB e Page Faults", "Algoritmo LRU/Clock"],
          hours: 28,
          completedClasses: 8,
          totalClasses: 14,
          items: [
            { id: "item-fso-2-1", type: "pdf", title: "Apostila: Sincronização de Processos, Deadlocks e Paginação Hierárquica", subtitle: "PDF • 3.1 MB", actionType: "access", fileName: "Guia_Pratico_Diagramacao_UML_2.5.pdf", fileSize: "3.1 MB" },
            { id: "item-fso-2-2", type: "pdf", title: "Lista de Exercícios: Tabelas de Páginas, TLB e Substituição", subtitle: "PDF • 850 KB", actionType: "access", fileName: "Lista_Exercicios_Padroes_GoF_Grasp.pdf", fileSize: "850 KB" },
            { id: "item-fso-2-3", type: "task", title: "Gerenciamento de Memória Virtual", subtitle: "Tarefa • Simulador de Paginação", actionType: "delivery" },
          ],
        },
        {
          id: "unit-fso-3",
          unitNumber: 3,
          tag: "UNIDADE 3 • 24 HORAS LETIVAS • PRÓXIMA ETAPA",
          title: "Unidade III — Sistemas de Arquivos, I/O Assíncrono e Contêineres Linux",
          topics: ["Inodes e Journaling (ext4)", "epoll / io_uring", "Namespaces e Cgroups"],
          hours: 24,
          completedClasses: 0,
          totalClasses: 12,
          items: [
            { id: "item-fso-3-1", type: "reading", title: "Artigo Base: Isolamento de Recursos no Kernel Linux para Contêineres", subtitle: "PDF • 2.4 MB", actionType: "access", fileName: "Artigo_Referencia_Microservices_Clean_Arch.pdf", fileSize: "2.4 MB" },
            { id: "item-fso-3-2", type: "video", title: "Videoaula: Subsistemas de E/S, Descritores de Arquivo e Virtualização", subtitle: "Vídeo • 1h 35min", actionType: "access" },
            { id: "item-fso-3-3", type: "code", title: "Experimento Prático: Construindo um Mini-Container com Namespaces", subtitle: "ZIP • 14.5 MB", actionType: "access", fileName: "Template_Projeto_Camadas_Spring_Domain.zip", fileSize: "14.5 MB" },
          ],
        },
      ],
    },
    {
      code: "MAT-2026-4N",
      subjectName: "Cálculo Diferencial e Integral",
      courseCode: courseMain.code,
      courseName: courseMain.name,
      professor: mainTeacher,
      semester: "2026/2 - 4º Semestre",
      shift: "Noturno",
      schedule: "Quartas-feiras, 19:00 - 22:30",
      location: "Sala 204",
      totalHours: 80,
      completedHours: 40,
      ementa: "Funções reais de uma e múltiplas variáveis, limites e continuidade, derivadas e otimização não-linear (gradiente), integrais definidas e impróprias, séries numéricas e aplicações computacionais em ciência de dados e algoritmos.",
      objectives: "1. Dominar taxas de variação, aproximações lineares e problemas de otimização.\n2. Calcular integrais definidas/múltiplas aplicadas a probabilidades e grandezas contínuas.\n3. Relacionar derivadas parciais e gradiente com algoritmos numéricos de aprendizado de máquina.",
      methodology: "Resolução estruturada de problemas em sala, listas graduais de exercícios analíticos e visualização geométrica computacional em Python/GeoGebra.",
      syllabusUnits: [
        {
          id: "unit-mat-1",
          unitNumber: 1,
          tag: "UNIDADE 1 • 28 HORAS LETIVAS • CONCLUÍDA",
          title: "Unidade I — Limites, Continuidade e Diferenciação de Funções Reais",
          topics: ["Limites Fundamentais", "Regra da Cadeia", "Derivação Implícita"],
          hours: 28,
          completedClasses: 14,
          totalClasses: 14,
          items: [
            { id: "item-mat-1-1", type: "pdf", title: "Plano de Ensino & Formulário Oficial de Cálculo — MAT-2026-4N", subtitle: "PDF • 1.2 MB", actionType: "access", fileName: "Plano_de_Ensino_Oficial_2026_2.pdf", fileSize: "1.2 MB" },
            { id: "item-mat-1-2", type: "pdf", title: "Notas de Aula 01: Limites, Assíntotas e Taxa Instantânea de Variação", subtitle: "PDF • 4.8 MB", actionType: "access", fileName: "Aula_01_Introducao_Arquitetura_Software.pdf", fileSize: "4.8 MB" },
            { id: "item-mat-1-3", type: "pdf", title: "Lista Resolvida A1: Derivadas, Regra da Cadeia e L'Hôpital", subtitle: "PDF • 850 KB", actionType: "access", fileName: "Lista_Exercicios_Padroes_GoF_Grasp.pdf", fileSize: "850 KB" },
          ],
        },
        {
          id: "unit-mat-2",
          unitNumber: 2,
          tag: "UNIDADE 2 • 28 HORAS LETIVAS • EM ANDAMENTO",
          title: "Unidade II — Otimização, Polinômios de Taylor e Integração Definida",
          topics: ["Máximos e Mínimos", "Teorema Fundamental do Cálculo", "Integração por Partes"],
          hours: 28,
          completedClasses: 6,
          totalClasses: 14,
          items: [
            { id: "item-mat-2-1", type: "pdf", title: "Apostila: Otimização Analítica, Séries de Taylor e Métodos de Integração", subtitle: "PDF • 3.1 MB", actionType: "access", fileName: "Guia_Pratico_Diagramacao_UML_2.5.pdf", fileSize: "3.1 MB" },
            { id: "item-mat-2-2", type: "video", title: "Videoaula de Revisão: Técnicas de Substituição Trigonométrica e Frações Parciais", subtitle: "Vídeo • 1h 40min", actionType: "access" },
            { id: "item-mat-2-3", type: "code", title: "Notebooks Computacionais: Integração Numérica (Simpson/Trapézio) e Gradiente", subtitle: "ZIP • 14.5 MB", actionType: "access", fileName: "Template_Projeto_Camadas_Spring_Domain.zip", fileSize: "14.5 MB" },
          ],
        },
        {
          id: "unit-mat-3",
          unitNumber: 3,
          tag: "UNIDADE 3 • 24 HORAS LETIVAS • PRÓXIMA ETAPA",
          title: "Unidade III — Derivadas Parciais, Vetor Gradiente e Integrais Múltiplas",
          topics: ["Curvas de Nível", "Descida do Gradiente", "Integrais Duplas"],
          hours: 24,
          completedClasses: 0,
          totalClasses: 12,
          items: [
            { id: "item-mat-3-1", type: "reading", title: "Leitura Aplicada: O Papel do Cálculo Multivariável na Otimização de Redes Neurais", subtitle: "PDF • 2.4 MB", actionType: "access", fileName: "Artigo_Referencia_Microservices_Clean_Arch.pdf", fileSize: "2.4 MB" },
            { id: "item-mat-3-2", type: "pdf", title: "Lista Preparatória A2: Gradiente, Multiplicadores de Lagrange e Integrais", subtitle: "PDF • 850 KB", actionType: "access", fileName: "Lista_Exercicios_Padroes_GoF_Grasp.pdf", fileSize: "850 KB" },
            { id: "item-mat-3-3", type: "task", title: "Entrega Avaliativa: Modelagem Matemática e Otimização Computacional", subtitle: "Tarefa • Entrega Individual", actionType: "delivery" },
          ],
        },
      ],
    },
  ];

  for (const clsSpec of classesToEnsure) {
    const existingClassDoc = await database.collection("academic_classes").findOne({ code: clsSpec.code });
    const defaultEmenta =
      (clsSpec as Document).ementa ??
      "Engenharia de requisitos avançada, modelagem orientada a objetos com UML 2.5, padrões de projeto GRASP e GoF, arquitetura limpa e integração de sistemas corporativos.";
    const defaultObjectives =
      (clsSpec as Document).objectives ??
      "1. Dominar a especificação formal de requisitos e modelagem arquitetural.\n2. Aplicar padrões GRASP, GoF e princípios SOLID em software sustentável.\n3. Conduzir entregas iterativas auditáveis em equipe.";
    const defaultMethodology =
      (clsSpec as Document).methodology ??
      "Aulas expositivas dialogadas combinadas a estudos de caso arquiteturais, laboratórios guiados e entregas práticas incrementais com feedback contínuo.";
    const defaultBibliography = [
      {
        type: "Básica",
        title: `Fundamentos e Práticas Avançadas em ${clsSpec.subjectName}`,
        authors: "MARTIN, Robert C.; EVANS, Eric",
        publisher: "Bookman / Alta Books",
        year: "2024",
      },
      {
        type: "Básica",
        title: "Arquitetura Limpa, Padrões de Projeto e Sistemas Distribuídos Modernos",
        authors: "RICHARDS, Mark; FORD, Neal",
        publisher: "O'Reilly / Novatec",
        year: "2023",
      },
      {
        type: "Complementar",
        title: "Engenharia de Software Moderna: Princípios, Qualidade e Escala",
        authors: "VALENTE, Marco Tulio; SOMMERVILLE, Ian",
        publisher: "Pearson Universidades",
        year: "2024",
      },
      {
        type: "Complementar",
        title: "Confiabilidade, Segurança e Governança de Dados em Plataformas Digitais",
        authors: "KLEPPMANN, Martin",
        publisher: "Novatec Editora",
        year: "2023",
      },
    ];
    const defaultRecordedSessions = [
      {
        id: `rec-${clsSpec.code.toLowerCase()}-1`,
        category: "GRAVAÇÃO SÍNCRONA",
        title: `Aula 01 — Contrato Pedagógico e Fundamentos de ${clsSpec.subjectName}`,
        date: "12/08/2026",
        duration: "1h 45min",
        instructor: clsSpec.professor.displayName,
        summary: "Apresentação do plano de ensino, critérios de avaliação N1/N2 e arquitetura base da disciplina.",
      },
      {
        id: `rec-${clsSpec.code.toLowerCase()}-2`,
        category: "GRAVAÇÃO SÍNCRONA",
        title: `Aula 02 — Estudo de Caso Guiado e Modelagem Estrutural (${clsSpec.code})`,
        date: "26/08/2026",
        duration: "1h 52min",
        instructor: clsSpec.professor.displayName,
        summary: "Resolução comentada de problemas reais e demonstração prática em ambiente de laboratório.",
      },
      {
        id: `rec-${clsSpec.code.toLowerCase()}-3`,
        category: "GRAVAÇÃO SÍNCRONA",
        title: `Aula 03 — Laboratório Prático, Padrões e Revisão N1 (${clsSpec.code})`,
        date: "09/09/2026",
        duration: "1h 40min",
        instructor: clsSpec.professor.displayName,
        summary: "Implementação passo a passo, revisão de dúvidas frequentes da turma e preparação avaliativa.",
      },
      {
        id: `rec-${clsSpec.code.toLowerCase()}-4`,
        category: "GRAVAÇÃO SÍNCRONA",
        title: `Aula 04 — Tópicos Avançados da Unidade II & Orientações de Entrega`,
        date: "23/09/2026",
        duration: "1h 48min",
        instructor: clsSpec.professor.displayName,
        summary: "Aprofundamento nos temas centrais da Unidade II e checklist técnico para submissão com hash SHA-256.",
      },
    ];
    const defaultChatMessages =
      Array.isArray(existingClassDoc?.chatMessages) && existingClassDoc.chatMessages.length > 0
        ? existingClassDoc.chatMessages
        : [
            {
              id: `chat-${clsSpec.code.toLowerCase()}-1`,
              authorName: clsSpec.professor.displayName,
              authorRole: "docente",
              authorProfile: "Docente Titular",
              message: `Bem-vindos ao canal oficial da turma ${clsSpec.code} (${clsSpec.subjectName})! Os materiais das Unidades I, II e III já estão publicados e atualizados.`,
              body: `Bem-vindos ao canal oficial da turma ${clsSpec.code} (${clsSpec.subjectName})! Os materiais das Unidades I, II e III já estão publicados e atualizados.`,
              timestamp: "10/09/2026",
              createdAt: now.toISOString(),
            },
            {
              id: `chat-${clsSpec.code.toLowerCase()}-2`,
              authorName: "Gabriel Almeida (Monitoria)",
              authorRole: "monitor",
              authorProfile: "Monitor Acadêmico",
              message: "Pessoal, plantão de dúvidas técnicas e apoio aos laboratórios confirmado às quintas das 18h00 às 19h00 na Sala Virtual!",
              body: "Pessoal, plantão de dúvidas técnicas e apoio aos laboratórios confirmado às quintas das 18h00 às 19h00 na Sala Virtual!",
              timestamp: "15/09/2026",
              createdAt: now.toISOString(),
            },
            {
              id: `chat-${clsSpec.code.toLowerCase()}-3`,
              authorName: String(stMariana.displayName),
              authorRole: "aluno",
              authorProfile: "Estudante",
              message: "Excelente! Nosso Squad já sincronizou o repositório e concluiu os exercícios da Unidade I.",
              body: "Excelente! Nosso Squad já sincronizou o repositório e concluiu os exercícios da Unidade I.",
              timestamp: "18/09/2026",
              createdAt: now.toISOString(),
            },
          ];

    await upsertSync(
      "academic_classes",
      { code: clsSpec.code },
      {
        code: clsSpec.code,
        subjectName: clsSpec.subjectName,
        courseCode: clsSpec.courseCode,
        courseName: clsSpec.courseName,
        professorId: String(clsSpec.professor._id),
        professorIdentity: clsSpec.professor.normalizedIdentity,
        professorName: clsSpec.professor.displayName,
        professorEmail: clsSpec.professor.email,
        semester: clsSpec.semester,
        shift: clsSpec.shift,
        schedule: clsSpec.schedule,
        location: clsSpec.location,
        totalHours: clsSpec.totalHours,
        completedHours: clsSpec.completedHours,
        credits: (clsSpec as Document).credits ?? 4,
        officeHours: (clsSpec as Document).officeHours ?? "Terças-feiras • 18:00 às 19:00",
        officeLocation:
          (clsSpec as Document).officeLocation ?? "Sala dos Professores (Bloco C) ou Sala Virtual Teams",
        maxCapacity: 45,
        formulaRegime: "autonomia_docente",
        evaluationFormula: "(N1 × 0.4) + (N2 × 0.6)",
        gradeLocked: false,
        pautaHomologated: false,
        active: true,
        ementa: defaultEmenta,
        objectives: defaultObjectives,
        methodology: defaultMethodology,
        bibliography: defaultBibliography,
        syllabusUnits: clsSpec.syllabusUnits,
        recordedSessions: defaultRecordedSessions,
        monitors: [
          {
            id: `mon-${clsSpec.code.toLowerCase()}`,
            name: "Gabriel Almeida",
            ra: "202510890",
            email: "monitoria.engenharia@agmrm.edu.br",
            schedule: "Quintas • 18:00 às 19:00",
          },
        ],
        squads:
          Array.isArray(existingClassDoc?.squads) && existingClassDoc.squads.length >= 2
            ? existingClassDoc.squads
            : [
                {
                  id: `sq-${clsSpec.code.toLowerCase()}-1`,
                  name: "Squad Time 3 — Arquitetura & Integração",
                  projectTitle: `Projeto Semestral Aplicado — ${clsSpec.subjectName}`,
                  sprintStatus: "Sprint 3 • Em Homologação",
                  repoUrl: "https://github.com/PI-IV-Time3",
                  members: [
                    String(stMariana.displayName),
                    String(stLucas.displayName),
                    String(stTest.displayName),
                  ],
                },
                {
                  id: `sq-${clsSpec.code.toLowerCase()}-2`,
                  name: "Squad Nexus — Engenharia Distribuída",
                  projectTitle: `Estudo Experimental & Observabilidade (${clsSpec.code})`,
                  sprintStatus: "Sprint 3 • Em Desenvolvimento",
                  repoUrl: "https://github.com/agmrm-academico/squad-nexus",
                  members: ["Beatriz Cavalcante", "Rafael Nogueira", "Camila Azevedo"],
                },
              ],
        chatMessages: defaultChatMessages,
        createdBy: String(adminActor._id),
        createdAt: now,
        updatedAt: now,
        seedTag: SEED_TAG,
      },
    );

    const studentsForClass = [stMariana, stLucas];
    if (stTest) studentsForClass.push(stTest);
    const demoStudent1 = ensuredUsers.get("aluno.demo1");
    if (demoStudent1) studentsForClass.push(demoStudent1);

    for (const st of studentsForClass) {
      await upsertOnInsert(
        "academic_enrollments",
        { classCode: clsSpec.code, studentId: String(st._id) },
        {
          classCode: clsSpec.code,
          courseCode: clsSpec.courseCode,
          studentId: String(st._id),
          studentIdentity: st.normalizedIdentity ?? st.identity,
          displayName: st.displayName,
          status: "active",
          enrolledAt: now,
          createdBy: String(adminActor._id),
          seedTag: SEED_TAG,
        },
      );

      const isMariana = st._id.equals(stMariana._id);
      await upsertOnInsert(
        "academic_grades",
        { classCode: clsSpec.code, studentId: String(st._id) },
        {
          classCode: clsSpec.code,
          studentId: String(st._id),
          studentIdentity: st.normalizedIdentity ?? st.identity,
          studentName: st.displayName,
          assignmentsScore: isMariana ? 9.0 : 8.0,
          p1Score: isMariana ? 8.8 : 7.5,
          projectsScore: isMariana ? 9.5 : 8.5,
          p2Score: clsSpec.code === "PI4-2026-4N" ? (isMariana ? 9.2 : 8.0) : 7.8,
          absences: isMariana ? 2 : 4,
          attendanceRate: isMariana ? 97.5 : 95.0,
          updatedBy: String(clsSpec.professor._id),
          updatedAt: now,
          seedTag: SEED_TAG,
        },
      );
    }

    await upsertOnInsert(
      "academic_class_sessions",
      { classCode: clsSpec.code, seedKey: `sess-1-${clsSpec.code}` },
      {
        seedKey: `sess-1-${clsSpec.code}`,
        classCode: clsSpec.code,
        courseCode: clsSpec.courseCode,
        sessionNumber: 1,
        hours: 2,
        title: `Aula 01 — Abertura e Arquitetura (${clsSpec.code})`,
        contentProgram: "Definição dos requisitos arquiteturais, contratos de API e cronograma.",
        methodology: "Exposição dialogada e laboratório prático conectado ao cluster.",
        location: clsSpec.location,
        startsAt: new Date("2026-10-21T22:00:00.000Z"),
        endsAt: new Date("2026-10-22T00:00:00.000Z"),
        isHomologated: true,
        cancelled: false,
        attendanceList: studentsForClass.map((st) => ({
          studentId: String(st._id),
          name: st.displayName,
          ra: st.identity,
          status: "presente",
          isConnected: false,
        })),
        createdBy: String(clsSpec.professor._id),
        createdAt: now,
        seedTag: SEED_TAG,
      },
    );

    const guiaContent = [
      `GUIA OFICIAL DA DISCIPLINA: ${clsSpec.subjectName} (${clsSpec.code})`,
      `Docente Responsável: ${clsSpec.professor.displayName}`,
      `Semestre: ${clsSpec.semester} | Horário: ${clsSpec.schedule}`,
      "",
      "1. Objetivo: Construção e operação de sistemas distribuídos reais sem dados estáticos.",
      "2. Critério de Avaliação: Média Final = (N1 * 0.4) + (N2 * 0.6), aprovação >= 6.0 e frequência >= 75%.",
      "3. Entregas com protocolo criptográfico SHA-256 auditável.",
    ].join("\n");

    await upsertSync(
      "academic_materials",
      { classCode: clsSpec.code, seedKey: `mat-1-${clsSpec.code}` },
      {
        seedKey: `mat-1-${clsSpec.code}`,
        classCode: clsSpec.code,
        category: "INSTITUCIONAL",
        unitAssociated: "Unidade 1",
        dateLabel: "01/08/2026",
        title: `Plano de Ensino e Guia Arquitetural — ${clsSpec.code}`,
        fileName: `plano-ensino-${clsSpec.code.toLowerCase()}.txt`,
        mimeType: "text/plain; charset=utf-8",
        type: "TXT",
        size: "1.2 KB",
        contentBase64: Buffer.from(guiaContent, "utf8").toString("base64"),
        uploadedBy: String(clsSpec.professor._id),
        uploadedByName: clsSpec.professor.displayName,
        isTimelineItem: false,
        createdAt: now,
        seedTag: SEED_TAG,
      },
    );

    await upsertOnInsert(
      "academic_assignments",
      { classCode: clsSpec.code, seedKey: `assign-1-${clsSpec.code}` },
      {
        seedKey: `assign-1-${clsSpec.code}`,
        classCode: clsSpec.code,
        title:
          clsSpec.code === "PI4-2026-4N"
            ? "Diagrama de Classes e Sequência"
            : clsSpec.code === "BD2-2026-4N"
              ? "Modelagem Relacional e Normalização"
              : clsSpec.code === "FIS-2026-4N"
                ? "Fórum Temático: Ética na Inteligência Artificial"
                : "Gerenciamento de Memória Virtual",
        description:
          "Submeta o relatório técnico ou pacote de evidências da entrega. O sistema gerará protocolo institucional e hash SHA-256.",
        stage: "N1",
        dueDate: new Date(Date.now() + 86400000 * 2),
        dueDateFormatted: "20/09 às 23:59",
        modality: "Individual",
        allowLateWithPenalty: true,
        weight: 4.0,
        isTimelineItem: false,
        rubricCriteria: [
          {
            id: "crit-1",
            title: "Qualidade Técnica",
            maxPoints: 5.0,
            description: "Aderência às especificações do projeto.",
          },
          {
            id: "crit-2",
            title: "Conformidade e Protocolo",
            maxPoints: 5.0,
            description: "Submissão com integridade e pontualidade.",
          },
        ],
        doubts: [],
        createdBy: String(clsSpec.professor._id),
        createdAt: now,
        updatedAt: now,
        seedTag: SEED_TAG,
      },
    );

    await upsertOnInsert(
      "academic_forum_topics",
      { classCode: clsSpec.code, seedKey: `forum-1-${clsSpec.code}` },
      {
        seedKey: `forum-1-${clsSpec.code}`,
        classCode: clsSpec.code,
        title: `Boas-vindas e Dúvidas de Arquitetura (${clsSpec.code})`,
        body: "Utilizem este tópico oficial para discutir decisões técnicas do semestre e compartilhar referências.",
        category: "Arquitetura",
        isPinned: true,
        isTimelineItem: false,
        authorId: String(clsSpec.professor._id),
        authorName: clsSpec.professor.displayName,
        authorRole: "docente",
        replies: [
          {
            id: `rep-${clsSpec.code.toLowerCase()}-1`,
            authorId: String(stMariana._id),
            authorName: stMariana.displayName,
            authorRole: "aluno",
            body: "Ambiente configurado e conectado ao cluster MongoDB Atlas com sucesso!",
            createdAt: now,
          },
        ],
        createdAt: now,
        updatedAt: now,
        seedTag: SEED_TAG,
      },
    );
  }

  // Enriquecimento com materiais didáticos (6 categorias) e tópicos de fórum do cockpit AVA para todas as disciplinas
  const avaEnrichedClasses = [
    "218131 - APS-II",
    "PI4-2026-4N",
    "ARQ-2026-4N",
    "BD2-2026-4N",
    "FIS-2026-4N",
    "FIS",
    "FSO-2026-4N",
    "MAT-2026-4N",
  ];
  for (const fisCode of avaEnrichedClasses) {
    const safeSlug = fisCode.replace(/[^a-zA-Z0-9_-]/g, "_");
    // 1. Materiais do repositório (6 categorias canônicas)
    const repoMaterials = [
      {
        seedKey: `mat-fis-repo-1-${fisCode}`,
        classCode: fisCode,
        title: `Plano_de_Ensino_Oficial_${safeSlug}_2026_2.pdf`,
        fileName: `Plano_de_Ensino_Oficial_${safeSlug}_2026_2.pdf`,
        category: "INSTITUCIONAL",
        unitAssociated: "Geral",
        dateLabel: "01/08/2026",
        size: "1.2 MB",
        type: "PDF",
      },
      {
        seedKey: `mat-fis-repo-2-${fisCode}`,
        classCode: fisCode,
        title: `Aula_01_Fundamentos_e_Arquitetura_${safeSlug}.pdf`,
        fileName: `Aula_01_Fundamentos_e_Arquitetura_${safeSlug}.pdf`,
        category: "SLIDES DE AULA",
        unitAssociated: "Unidade 1",
        dateLabel: "12/08/2026",
        size: "4.8 MB",
        type: "PDF",
      },
      {
        seedKey: `mat-fis-repo-3-${fisCode}`,
        classCode: fisCode,
        title: `Guia_Pratico_Estudo_de_Caso_${safeSlug}.pdf`,
        fileName: `Guia_Pratico_Estudo_de_Caso_${safeSlug}.pdf`,
        category: "MATERIAL COMPLEMENTAR",
        unitAssociated: "Unidade 2",
        dateLabel: "25/08/2026",
        size: "3.1 MB",
        type: "PDF",
      },
      {
        seedKey: `mat-fis-repo-4-${fisCode}`,
        classCode: fisCode,
        title: `Laboratorio_Pratico_Workspace_${safeSlug}.zip`,
        fileName: `Laboratorio_Pratico_Workspace_${safeSlug}.zip`,
        category: "LABORATÓRIOS & CÓDIGOS",
        unitAssociated: "Unidade 2",
        dateLabel: "10/09/2026",
        size: "14.5 MB",
        type: "ZIP",
      },
      {
        seedKey: `mat-fis-repo-5-${fisCode}`,
        classCode: fisCode,
        title: `Lista_Exercicios_Avaliacao_Formativa_${safeSlug}.pdf`,
        fileName: `Lista_Exercicios_Avaliacao_Formativa_${safeSlug}.pdf`,
        category: "EXERCÍCIOS",
        unitAssociated: "Unidade 3",
        dateLabel: "22/09/2026",
        size: "850 KB",
        type: "PDF",
      },
      {
        seedKey: `mat-fis-repo-6-${fisCode}`,
        classCode: fisCode,
        title: `Artigo_Referencia_Leitura_Obrigatoria_${safeSlug}.pdf`,
        fileName: `Artigo_Referencia_Leitura_Obrigatoria_${safeSlug}.pdf`,
        category: "LEITURAS OBRIGATÓRIAS",
        unitAssociated: "Unidade 3",
        dateLabel: "02/10/2026",
        size: "2.4 MB",
        type: "PDF",
      },
    ];

    for (const m of repoMaterials) {
      await upsertSync(
        "academic_materials",
        { classCode: fisCode, seedKey: m.seedKey },
        {
          ...m,
          mimeType: m.type === "ZIP" ? "application/zip" : "application/pdf",
          contentBase64: Buffer.from(
            `Material Pedagógico Oficial do AVA — Turma ${fisCode} — ${m.title}`,
            "utf8",
          ).toString("base64"),
          uploadedBy: String(mainTeacher._id),
          uploadedByName: mainTeacher.displayName,
          isTimelineItem: false,
          createdAt: now,
          seedTag: SEED_TAG,
        },
      );
    }

    // 2. Tópicos de fórum de dúvidas e discussões
    await upsertOnInsert(
      "academic_forum_topics",
      { classCode: fisCode, seedKey: `forum-fis-top-1-${fisCode}` },
      {
        seedKey: `forum-fis-top-1-${fisCode}`,
        classCode: fisCode,
        title: "Dúvida sobre a modelagem de agregados no Trabalho Prático 2",
        body: "Professor, na modelagem do agregado de Pedido, a entidade ItemPedido deve ser acessada unicamente pela raiz do agregado ou o repositório...",
        authorName: "Lucas Silveira",
        authorRole: "aluno",
        authorProfile: "Estudante",
        category: "Trabalho Prático",
        status: "Respondido",
        isResolved: true,
        timeAgo: "Há 2 dias",
        replies: [
          {
            id: `rep-fis-1-${fisCode}`,
            authorName: mainTeacher.displayName,
            authorRole: "docente",
            body: "Exatamente! Toda mutação e acesso ao ItemPedido deve transitar pela raiz do agregado Pedido para resguardar as invariantes.",
            createdAt: now,
          },
          {
            id: `rep-fis-2-${fisCode}`,
            authorName: "Mariana Campos",
            authorRole: "aluno",
            body: "Isso também facilita a persistência atômica com o padrão Unit of Work.",
            createdAt: now,
          },
          {
            id: `rep-fis-3-${fisCode}`,
            authorName: "Carlos Eduardo",
            authorRole: "aluno",
            body: "Excelente esclarecimento, agora ficou claro o escopo da transação.",
            createdAt: now,
          },
          {
            id: `rep-fis-4-${fisCode}`,
            authorName: "Lucas Silveira",
            authorRole: "aluno",
            body: "Obrigado, professor e colegas!",
            createdAt: now,
          },
        ],
        createdAt: now,
        updatedAt: now,
        seedTag: SEED_TAG,
      },
    );

    await upsertOnInsert(
      "academic_forum_topics",
      { classCode: fisCode, seedKey: `forum-fis-top-2-${fisCode}` },
      {
        seedKey: `forum-fis-top-2-${fisCode}`,
        classCode: fisCode,
        title: "Data da prova substitutiva (P2) e conteúdo programático",
        body: "A prova substitutiva abordará apenas o conteúdo da P2 ou será cumulativa de todo o semestre?",
        authorName: "Marina Campos",
        authorRole: "aluno",
        authorProfile: "Estudante",
        category: "Avaliações",
        status: "Respondido",
        isResolved: true,
        timeAgo: "Há 5 dias",
        replies: [
          {
            id: `rep-fis-sub-1-${fisCode}`,
            authorName: mainTeacher.displayName,
            authorRole: "docente",
            body: "A substitutiva terá ênfase no conteúdo de N2, com conceitos transversais de modelagem.",
            createdAt: now,
          },
          {
            id: `rep-fis-sub-2-${fisCode}`,
            authorName: "Marina Campos",
            authorRole: "aluno",
            body: "Perfeito, vou revisar o módulo 2!",
            createdAt: now,
          },
        ],
        createdAt: now,
        updatedAt: now,
        seedTag: SEED_TAG,
      },
    );
  }

  // Enriquecimento adicional de ES-DEMO-4N (se existente)
  const esDemoClass = await database.collection("academic_classes").findOne({ code: "ES-DEMO-4N" });
  const profDemo = ensuredUsers.get("prof.demo");
  if (esDemoClass && profDemo) {
    const demoText = "Material Oficial da Turma ES-DEMO-4N — Engenharia de Software.";
    await upsertOnInsert(
      "academic_materials",
      { classCode: "ES-DEMO-4N", seedKey: "mat-es-demo-4n" },
      {
        seedKey: "mat-es-demo-4n",
        classCode: "ES-DEMO-4N",
        unitAssociated: "Unidade 1",
        title: "Apostila Introdutória — Engenharia de Software",
        fileName: "apostila-es-demo-4n.txt",
        mimeType: "text/plain; charset=utf-8",
        type: "TXT",
        size: "1.0 KB",
        contentBase64: Buffer.from(demoText, "utf8").toString("base64"),
        uploadedBy: String(profDemo._id),
        uploadedByName: profDemo.displayName,
        createdAt: now,
        seedTag: SEED_TAG,
      },
    );
    await upsertOnInsert(
      "academic_assignments",
      { classCode: "ES-DEMO-4N", seedKey: "assign-es-demo-4n" },
      {
        seedKey: "assign-es-demo-4n",
        classCode: "ES-DEMO-4N",
        title: "Entrega Prática 01 — Modelagem de Domínio",
        description: "Envie o artefato da modelagem de domínio da equipe.",
        stage: "N1",
        dueDate: new Date("2026-12-08T23:59:00.000Z"),
        dueDateFormatted: "08/12/2026 às 23:59",
        modality: "Individual",
        allowLateWithPenalty: true,
        weight: 5.0,
        rubricCriteria: [
          { id: "c1", title: "Clareza Conceitual", maxPoints: 5.0 },
          { id: "c2", title: "aderência aos Requisitos", maxPoints: 5.0 },
        ],
        doubts: [],
        createdBy: String(profDemo._id),
        createdAt: now,
        updatedAt: now,
        seedTag: SEED_TAG,
      },
    );
  }

  // Vincula turma "10101" a "doc" e "aluno" caso ainda sem docente
  const legacyDoc = ensuredUsers.get("doc");
  const legacyStudent = ensuredUsers.get("aluno");
  const class10101 = await database.collection("academic_classes").findOne({ code: "10101" });
  if (class10101 && legacyDoc && !class10101.professorIdentity) {
    await database.collection("academic_classes").updateOne(
      { _id: class10101._id },
      {
        $set: {
          professorId: String(legacyDoc._id),
          professorIdentity: legacyDoc.normalizedIdentity ?? legacyDoc.identity,
          professorName: legacyDoc.displayName,
          subjectName: class10101.subjectName ?? "Engenharia de Requisitos e Processos",
        },
      },
    );
    if (legacyStudent) {
      await upsertOnInsert(
        "academic_enrollments",
        { classCode: "10101", studentId: String(legacyStudent._id) },
        {
          classCode: "10101",
          courseCode: class10101.courseCode ?? "0001",
          studentId: String(legacyStudent._id),
          studentIdentity: legacyStudent.normalizedIdentity ?? legacyStudent.identity,
          displayName: legacyStudent.displayName,
          status: "active",
          enrolledAt: now,
          createdBy: String(adminActor._id),
          seedTag: SEED_TAG,
        },
      );
    }
  }

  // 4. Comunicados institucionais e de turma
  await upsertOnInsert(
    "academic_announcements",
    { seedKey: "ann-ecosystem-1" },
    {
      seedKey: "ann-ecosystem-1",
      title: "Calendário Oficial de Bancas de Projeto Integrador IV — 2026/2",
      body: "As bancas integradas ocorrerão na primeira quinzena de dezembro. Verifiquem a submissão com protocolo SHA-256 no portal.",
      audience: "Todos",
      category: "Acadêmico",
      priority: "alta",
      isInstitutional: true,
      createdBy: String(adminActor._id),
      authorName: adminActor.displayName,
      readBy: [],
      createdAt: now,
      seedTag: SEED_TAG,
    },
  );

  await upsertOnInsert(
    "academic_announcements",
    { seedKey: "ann-ecosystem-2" },
    {
      seedKey: "ann-ecosystem-2",
      title: "Sala Síncrona Habilitada — Projeto Integrador IV (PI4-2026-4N)",
      body: "A sala de videochamada com apuração automática de frequência estará aberta às quartas-feiras a partir das 19h00.",
      audience: "Alunos Matriculados",
      classCode: "PI4-2026-4N",
      category: "Aula Síncrona",
      priority: "normal",
      isInstitutional: false,
      createdBy: String(mainTeacher._id),
      authorName: mainTeacher.displayName,
      readBy: [],
      createdAt: now,
      seedTag: SEED_TAG,
    },
  );

  // 5. Marcos do Calendário Institucional
  const calendarMilestones = [
    {
      seedKey: "cal-eco-closing-1",
      title: "Término das avaliações semestrais",
      description: "Término das avaliações semestrais",
      startsAt: new Date("2026-12-13T23:59:00.000Z"),
      customDateLabel: "domingo, 13 de dezembro",
      type: "closing",
      scope: "Institucional",
      isMilestone: true,
    },
    {
      seedKey: "cal-eco-vacation-1",
      title: "Férias e encerramento de notas",
      description: "Férias e encerramento de notas",
      startsAt: new Date("2026-12-14T00:00:00.000Z"),
      endsAt: new Date("2027-01-10T23:59:00.000Z"),
      customDateLabel: "segunda-feira, 14 de dezembro a janeiro 10",
      type: "closing",
      scope: "Institucional",
      isMilestone: true,
    },
    {
      seedKey: "cal-eco-next-semester-1",
      title: "Início das aulas do próximo período letivo",
      description: "Início das aulas do próximo período letivo",
      startsAt: new Date("2027-02-01T08:00:00.000Z"),
      customDateLabel: "fevereiro 2027",
      type: "closing",
      scope: "Institucional",
      isMilestone: true,
    },
  ];

  for (const ev of calendarMilestones) {
    await database.collection("academic_calendar").updateOne(
      { seedKey: ev.seedKey },
      {
        $set: {
          ...ev,
          createdBy: String(adminActor._id),
          createdAt: now,
          seedTag: SEED_TAG,
        },
      },
      { upsert: true },
    );
  }

  // -------------------------------------------------------------
  // SEÇÃO DEDICADA: TIMELINE DO ALUNO (Idêntica ao Mockup Oficial)
  // -------------------------------------------------------------
  // Desativa itens genéricos e remove marcos que conflitem com o hiato de 83 dias da linha do tempo
  await database.collection("academic_assignments").updateMany(
    { seedKey: { $regex: /^assign-1-/ } },
    { $set: { isTimelineItem: false } },
  );
  await database.collection("academic_assignments").deleteMany({
    seedKey: { $in: ["assign-eco-pi4-2026-4n", "assign-eco-bd2-2026-4n", "assign-eco-fis-2026-4n", "assign-eco-fso-2026-4n"] },
  });
  await database.collection("academic_forum_topics").updateMany(
    { seedKey: { $regex: /^forum-1-/ } },
    { $set: { isTimelineItem: false } },
  );
  await database.collection("academic_materials").updateMany(
    { seedKey: { $regex: /^mat-1-/ } },
    { $set: { isTimelineItem: false } },
  );
  await database.collection("academic_calendar").deleteMany({
    seedKey: { $in: ["cal-eco-1", "cal-eco-2", "cal-eco-3"] },
  });

  // 1. Quinta-feira, 17/09: Entrega: Atividade 2 - Modelagem de Banco de Dados Relacional (BD2)
  const asgTimeline1 = await database.collection("academic_assignments").findOneAndUpdate(
    { seedKey: "asg-timeline-bd2" },
    {
      $set: {
        seedKey: "asg-timeline-bd2",
        classCode: "BD2-2026-4N",
        title: "Entrega: Atividade 2 - Modelagem de Banco de Dados Relacional",
        customSubtitle: "Banco de Dados II • Profª. Dra. Eliane Ramos",
        description: "Envio da modelagem conceitual e lógica do banco de dados relacional.",
        dueDate: new Date("2026-09-17T23:59:00.000Z"),
        stage: "N1",
        modality: "Individual",
        weight: 10.0,
        createdAt: new Date("2026-09-10T10:00:00.000Z"),
        updatedAt: new Date("2026-09-17T23:59:00.000Z"),
        seedTag: SEED_TAG,
      },
    },
    { upsert: true, returnDocument: "after" },
  );

  // Submissão avaliada para aluno.test (gera status "Concluído" com checkbox preenchido)
  if (stTest && asgTimeline1) {
    await database.collection("academic_submissions").updateOne(
      { assignmentId: String(asgTimeline1._id), studentId: String(stTest._id) },
      {
        $set: {
          assignmentId: String(asgTimeline1._id),
          studentId: String(stTest._id),
          studentIdentity: stTest.identity,
          studentName: stTest.displayName,
          classCode: "BD2-2026-4N",
          status: "avaliada",
          grade: 10.0,
          submittedAt: new Date("2026-09-17T21:40:00.000Z"),
          updatedAt: new Date("2026-09-17T22:00:00.000Z"),
          seedTag: SEED_TAG,
        },
      },
      { upsert: true },
    );
  }

  // 2. Sexta-feira, 18/09: Fórum Avaliativo: Impactos éticos da IA em Sistemas Críticos (FIS, 3 participações)
  await database.collection("academic_forum_topics").updateOne(
    { seedKey: "forum-timeline-fis" },
    {
      $set: {
        seedKey: "forum-timeline-fis",
        classCode: "FIS-2026-4N",
        title: "Fórum Avaliativo: Impactos éticos da IA em Sistemas Críticos",
        customSubtitle: "Ética e Legislação • Prof. Marcos Vinícius",
        body: "Debatam as implicações éticas e de conformidade legal de agentes autônomos em missões críticas.",
        createdAt: new Date("2026-09-18T10:00:00.000Z"),
        updatedAt: new Date("2026-09-18T18:00:00.000Z"),
        replies: [
          { id: "rep-1", authorName: "Lucas Henrique", body: "Relevante considerar responsabilidade civil.", createdAt: new Date("2026-09-18T11:00:00Z") },
          { id: "rep-2", authorName: "Mariana Costa", body: "A governança e rastreabilidade são fundamentais.", createdAt: new Date("2026-09-18T14:30:00Z") },
          { id: "rep-3", authorName: "Carlos Eduardo", body: "O marco civil e a LGPD estabelecem limites claros.", createdAt: new Date("2026-09-18T16:15:00Z") },
        ],
        seedTag: SEED_TAG,
      },
    },
    { upsert: true },
  );

  // 3. Ontem, 19/09: Material Complementar: Estudo de Caso de Microsserviços (ARQ, Concluído)
  await database.collection("academic_materials").updateOne(
    { seedKey: "mat-timeline-arq" },
    {
      $set: {
        seedKey: "mat-timeline-arq",
        classCode: "ARQ-2026-4N",
        title: "Material Complementar: Estudo de Caso de Microsserviços",
        customSubtitle: "Arquitetura de Software • Prof. Carlos Eduardo",
        unitAssociated: "Unidade 1",
        fileName: "estudo-de-caso-microsservicos.pdf",
        mimeType: "application/pdf",
        type: "PDF",
        size: "2.4 MB",
        isTimelineItem: true,
        timelineDate: new Date("2026-09-19T10:00:00.000Z"),
        completed: true,
        customTrailingText: "Concluído",
        createdAt: new Date("2026-09-19T10:00:00.000Z"),
        seedTag: SEED_TAG,
      },
    },
    { upsert: true },
  );

  // 4. Hoje, 20/09: Atividade Prática 03: Implementação de API REST (PI4, até 23:59)
  await database.collection("academic_assignments").updateOne(
    { seedKey: "asg-timeline-pi4" },
    {
      $set: {
        seedKey: "asg-timeline-pi4",
        classCode: "PI4-2026-4N",
        title: "Atividade Prática 03: Implementação de API REST",
        customSubtitle: "Engenharia de Software • Envio pelo AVA até 23:59",
        description: "Envio do repositório Git com os endpoints da API REST implementados e testados.",
        dueDate: new Date("2026-09-20T10:00:00.000Z"),
        dueHour: "23:59",
        stage: "N1",
        modality: "Individual",
        weight: 10.0,
        createdAt: new Date("2026-09-15T08:00:00.000Z"),
        updatedAt: new Date("2026-09-20T08:00:00.000Z"),
        seedTag: SEED_TAG,
      },
    },
    { upsert: true },
  );

  // 5. Hoje, 20/09: Fórum Temático: Desafios da Concorrência em Sistemas Distribuídos (FSO, Tópico aberto)
  await database.collection("academic_forum_topics").updateOne(
    { seedKey: "forum-timeline-fso" },
    {
      $set: {
        seedKey: "forum-timeline-fso",
        classCode: "FSO-2026-4N",
        title: "Fórum Temático: Desafios da Concorrência em Sistemas Distribuídos",
        customSubtitle: "Sistemas Distribuídos • 12 novas respostas no tópico",
        body: "Compartilhem estratégias de resolução de concorrência com locks distribuídos e bancos NoSQL.",
        createdAt: new Date("2026-09-20T14:00:00.000Z"),
        updatedAt: new Date("2026-09-20T17:00:00.000Z"),
        customTrailingText: "Tópico aberto",
        customTrailingType: "text",
        replies: new Array(12).fill(null).map((_, idx) => ({
          id: `rep-fso-${idx + 1}`,
          authorName: `Aluno ${idx + 1}`,
          body: `Discussão técnica número ${idx + 1}`,
          createdAt: new Date("2026-09-20T15:00:00Z"),
        })),
        seedTag: SEED_TAG,
      },
    },
    { upsert: true },
  );

  // 6. Amanhã, 21/09: Fórum de Dúvidas: Preparação para a Avaliação A1 (MAT, até 18:00)
  await database.collection("academic_forum_topics").updateOne(
    { seedKey: "forum-timeline-mat" },
    {
      $set: {
        seedKey: "forum-timeline-mat",
        classCode: "MAT-2026-4N",
        title: "Fórum de Dúvidas: Preparação para a Avaliação A1",
        customSubtitle: "Cálculo Diferencial e Integral • Profª. Sandra Helena",
        body: "Envie suas dúvidas referentes à lista de exercícios preparatória para a prova A1.",
        createdAt: new Date("2026-09-21T09:00:00.000Z"),
        dueHour: "18:00",
        replies: [],
        seedTag: SEED_TAG,
      },
    },
    { upsert: true },
  );

  // 6. Protocolo acadêmico de exemplo na Secretaria
  await upsertOnInsert(
    "academic_protocols",
    { seedKey: "prot-eco-1" },
    {
      seedKey: "prot-eco-1",
      code: "PROT-2026-0401",
      studentId: String(stMariana._id),
      studentIdentity: stMariana.identity,
      studentRa: stMariana.identity,
      studentName: stMariana.displayName,
      requestType: "Aproveitamento de Estudos",
      targetComponent: "ARQ-2026-4N",
      justification: "Solicitação de análise de certificado internacional Cloud Architect para carga complementar.",
      status: "pending",
      createdBy: String(stMariana._id),
      createdAt: now,
      updatedAt: now,
      seedTag: SEED_TAG,
    },
  );

  // 7. Parâmetros institucionais padrão se ainda não configurados + recursos acadêmicos de apoio
  await upsertOnInsert(
    "admin_settings",
    { _id: "institutional" as unknown as ObjectId },
    {
      institutionName: "AGMRM — Plataforma Universitária Integrada",
      academicPeriod: "2026/2",
      minimumAttendance: 75,
      passingGrade: 6.0,
      defaultFormula: "(N1 × 0.4) + (N2 × 0.6)",
      regimentalLockActive: false,
      campusAlertsEnabled: true,
      lgpdRetentionMonths: 60,
      dpoEmail: "dpo@agmrm.edu.br",
      updatedAt: now,
    },
  );
  await database.collection("admin_settings").updateOne(
    { _id: "institutional" as unknown as ObjectId },
    {
      $set: {
        academicResources: [
          {
            id: "res-biblioteca-virtual",
            title: "Biblioteca Virtual Pearson & Minha Biblioteca",
            subtitle: "Acervo completo de Engenharia, Arquitetura e Computação",
            category: "ACERVO DIGITAL",
            actionLabel: "Acessar Acervo",
            url: "https://biblioteca.agmrm.edu.br",
            icon: "menu_book",
          },
          {
            id: "res-labs-docker",
            title: "Laboratórios Remotos Cloud & Containers",
            subtitle: "Ambientes Linux, Docker, PostgreSQL e MongoDB sob demanda",
            category: "INFRAESTRUTURA",
            actionLabel: "Provisionar Lab",
            url: "https://labs.agmrm.edu.br",
            icon: "terminal",
          },
          {
            id: "res-monitoria-nivelamento",
            title: "Central de Monitoria & Nivelamento Acadêmico",
            subtitle: "Plantões semanais com monitores bolsistas das disciplinas",
            category: "SUPORTE DISCENTE",
            actionLabel: "Ver Horários",
            url: "https://monitoria.agmrm.edu.br",
            icon: "groups",
          },
          {
            id: "res-templates-abnt",
            title: "Guias Regimentais, Normas ABNT & Templates",
            subtitle: "Modelos oficiais LaTeX/DOCX para relatórios técnicos e PI",
            category: "INSTITUCIONAL",
            actionLabel: "Baixar Modelos",
            url: "https://normas.agmrm.edu.br",
            icon: "description",
          },
        ],
      },
    },
  );

  // -------------------------------------------------------------
  // SEÇÃO DEDICADA: TAREFAS E ENTREGAS DO AVA — 218131 - APS-II
  // -------------------------------------------------------------
  // Remove atribuições genéricas de 218131 - APS-II para manter exatamente as 4 do AVA oficial
  await database.collection("academic_assignments").deleteMany({
    classCode: "218131 - APS-II",
    seedKey: { $regex: /^assign-1-/ },
  });

  // 1. MÓDULO 2 • MODELAGEM UML — Pendente
  await database.collection("academic_assignments").updateOne(
    { seedKey: "assign-aps-diagrama-uml" },
    {
      $set: {
        seedKey: "assign-aps-diagrama-uml",
        classCode: "218131 - APS-II",
        moduleTag: "MÓDULO 2 • MODELAGEM UML",
        title: "Entrega do Diagrama de Casos de Uso e Especificação Suplementar",
        description:
          "Submeter o diagrama consolidado em formato PDF acompanhado da descrição textual dos fluxos principal, alternativos e de exceção.",
        dueDate: new Date("2026-10-15T23:59:00.000Z"),
        dueDateFormatted: "15/10/2026",
        dueHour: "23:59",
        weight: 2.0,
        stage: "N1",
        modality: "Individual",
        allowLateWithPenalty: true,
        createdBy: String(profHelena._id),
        createdAt: now,
        updatedAt: now,
        seedTag: SEED_TAG,
      },
    },
    { upsert: true },
  );

  // 2. MÓDULO 1 • FUNDAMENTOS DE ARQUITETURA — Avaliado (Nota 9.5)
  const asgAps2 = await database.collection("academic_assignments").findOneAndUpdate(
    { seedKey: "assign-aps-estudo-caso" },
    {
      $set: {
        seedKey: "assign-aps-estudo-caso",
        classCode: "218131 - APS-II",
        moduleTag: "MÓDULO 1 • FUNDAMENTOS DE ARQUITETURA",
        title: "Estudo de Caso 01: Arquitetura em Camadas vs Hexagonal",
        description:
          "Redigir síntese técnica de até 3 laudas demonstrando os trade-offs de acoplamento na arquitetura hexagonal.",
        dueDate: new Date("2026-09-28T22:00:00.000Z"),
        dueDateFormatted: "28/09/2026",
        dueHour: "22:00",
        weight: 1.5,
        stage: "N1",
        modality: "Individual",
        allowLateWithPenalty: true,
        createdBy: String(profHelena._id),
        createdAt: now,
        updatedAt: now,
        seedTag: SEED_TAG,
      },
    },
    { upsert: true, returnDocument: "after" },
  );

  if (asgAps2) {
    const studentsWithSubmission = [stTest, stMariana].filter(Boolean);
    for (const student of studentsWithSubmission) {
      await database.collection("academic_submissions").updateOne(
        { assignmentId: String(asgAps2._id), studentId: String(student._id) },
        {
          $set: {
            assignmentId: String(asgAps2._id),
            studentId: String(student._id),
            studentIdentity: student.identity,
            studentName: student.displayName,
            classCode: "218131 - APS-II",
            status: "avaliada",
            grade: 9.5,
            score: 9.5,
            feedback:
              "Excelente análise comparativa. Muito bem estruturada a segregação de portas e adaptadores.",
            submittedAt: new Date("2026-09-28T20:15:00.000Z"),
            updatedAt: new Date("2026-09-29T10:00:00.000Z"),
            seedTag: SEED_TAG,
          },
        },
        { upsert: true },
      );
    }
  }

  // 3. MÓDULO 3 • PERSISTÊNCIA E DOMÍNIO — Pendente
  await database.collection("academic_assignments").updateOne(
    { seedKey: "assign-aps-prototipo-orm" },
    {
      $set: {
        seedKey: "assign-aps-prototipo-orm",
        classCode: "218131 - APS-II",
        moduleTag: "MÓDULO 3 • PERSISTÊNCIA E DOMÍNIO",
        title: "Protótipo de Mapeamento Objeto-Relacional e Validação de Domínio",
        description:
          "Disponibilizar o repositório GitHub contendo as entidades mapeadas com validação de invariantes nos agregados.",
        dueDate: new Date("2026-10-22T23:59:00.000Z"),
        dueDateFormatted: "22/10/2026",
        dueHour: "23:59",
        weight: 2.5,
        stage: "N2",
        modality: "Individual",
        allowLateWithPenalty: true,
        createdBy: String(profHelena._id),
        createdAt: now,
        updatedAt: now,
        seedTag: SEED_TAG,
      },
    },
    { upsert: true },
  );

  // 4. MÓDULO 4 • ARQUITETURAS DISTRIBUÍDAS — Pendente
  await database.collection("academic_assignments").updateOne(
    { seedKey: "assign-aps-artigo-pesquisa" },
    {
      $set: {
        seedKey: "assign-aps-artigo-pesquisa",
        classCode: "218131 - APS-II",
        moduleTag: "MÓDULO 4 • ARQUITETURAS DISTRIBUÍDAS",
        title: "Artigo de Pesquisa: Microsserviços e Event-Driven Design",
        description:
          "Artigo em formato IEEE sobre resiliência em mensageria com Apache Kafka e RabbitMQ.",
        dueDate: new Date("2026-11-05T23:59:00.000Z"),
        dueDateFormatted: "05/11/2026",
        dueHour: "23:59",
        weight: 4.0,
        stage: "N2",
        modality: "Individual",
        allowLateWithPenalty: true,
        createdBy: String(profHelena._id),
        createdAt: now,
        updatedAt: now,
        seedTag: SEED_TAG,
      },
    },
    { upsert: true },
  );

  return summary;
}

async function main() {
  if (process.env.NODE_ENV === "production") {
    throw new Error("A seed de ecossistema não deve ser executada com NODE_ENV=production.");
  }
  const environment = loadEnvironment();
  const password = process.env.SEED_DEMO_PASSWORD?.trim() || "Agmrm@2026";

  const client = new MongoClient(environment.mongoUri, {
    serverSelectionTimeoutMS: 10_000,
    connectTimeoutMS: 5_000,
  });

  try {
    await client.connect();
    const database = client.db(environment.mongoDatabase);
    await database.command({ ping: 1 });
    console.log(`[seed:ecosystem] Conectado ao banco MongoDB: ${environment.mongoDatabase}`);
    const summary = await seedEcosystem(database, password);
    console.table(
      Object.entries(summary).map(([col, stats]) => ({
        colecao: col,
        criados: stats.created,
        reutilizados: stats.reused,
      })),
    );
    console.log("[seed:ecosystem] Concluído com sucesso (nenhuma senha existente foi alterada).");
  } finally {
    await client.close();
  }
}

const isMain =
  process.argv[1] &&
  fileURLToPath(import.meta.url).toLowerCase() === process.argv[1].toLowerCase();

if (isMain) {
  main().catch((err) => {
    console.error("[seed:ecosystem] Falha:", err);
    process.exitCode = 1;
  });
}
