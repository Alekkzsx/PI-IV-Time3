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
      syllabusUnits: [
        {
          id: "unit-1",
          unitNumber: 1,
          title: "Unidade I — Arquitetura Modular e Contratos REST/WebSocket",
          topics: ["Camadas limpas", "Autenticação JWT e 2FA", "Sinalização WebSocket"],
          hours: 20,
          completedClasses: 10,
          totalClasses: 10,
        },
        {
          id: "unit-2",
          unitNumber: 2,
          title: "Unidade II — Persistência Distribuída com MongoDB Atlas",
          topics: ["Transações ACID", "Trilhas de auditoria", "Protocolos SHA-256"],
          hours: 20,
          completedClasses: 10,
          totalClasses: 10,
        },
        {
          id: "unit-3",
          unitNumber: 3,
          title: "Unidade III — Integração Full-Stack Flutter e Homologação",
          topics: ["Consumo reativo sem mocks", "Videochamada síncrona", "Banca final"],
          hours: 40,
          completedClasses: 4,
          totalClasses: 20,
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
      syllabusUnits: [
        {
          id: "unit-1",
          unitNumber: 1,
          title: "Unidade I — Clean Architecture & Domain-Driven Design",
          topics: ["Apresentação, Aplicação, Domínio e Infraestrutura", "Inversão de dependência"],
          hours: 40,
          completedClasses: 15,
          totalClasses: 20,
        },
        {
          id: "unit-2",
          unitNumber: 2,
          title: "Unidade II — Resiliência, Observabilidade e Segurança",
          topics: ["Rate limiting", "Sessões revogáveis", "Conformidade LGPD"],
          hours: 40,
          completedClasses: 0,
          totalClasses: 20,
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
      syllabusUnits: [],
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
      syllabusUnits: [],
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
      syllabusUnits: [],
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
      syllabusUnits: [],
    },
  ];

  for (const clsSpec of classesToEnsure) {
    await upsertOnInsert(
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
        semester: clsSpec.semester,
        shift: clsSpec.shift,
        schedule: clsSpec.schedule,
        location: clsSpec.location,
        totalHours: clsSpec.totalHours,
        completedHours: clsSpec.completedHours,
        maxCapacity: 45,
        formulaRegime: "autonomia_docente",
        evaluationFormula: "(N1 × 0.4) + (N2 × 0.6)",
        gradeLocked: false,
        pautaHomologated: false,
        active: true,
        syllabusUnits: clsSpec.syllabusUnits,
        squads: [
          {
            id: `sq-${clsSpec.code.toLowerCase()}-1`,
            name: "Squad Time 3 — Plataforma Acadêmica",
            projectTitle: "Integração Full-Stack Flutter + Node + Java + MongoDB",
            repoUrl: "https://github.com/PI-IV-Time3",
            members: [String(stMariana.displayName), String(stLucas.displayName)],
          },
        ],
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

    await upsertOnInsert(
      "academic_materials",
      { classCode: clsSpec.code, seedKey: `mat-1-${clsSpec.code}` },
      {
        seedKey: `mat-1-${clsSpec.code}`,
        classCode: clsSpec.code,
        unitAssociated: "Unidade 1",
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

  // Enriquecimento com materiais didáticos e tópicos de fórum do cockpit AVA (FIS)
  const fisClasses = ["FIS-2026-4N", "FIS"];
  for (const fisCode of fisClasses) {
    // 1. Materiais do repositório
    const mockMaterials = [
      {
        seedKey: `mat-fis-repo-1-${fisCode}`,
        classCode: fisCode,
        title: "Plano_de_Ensino_Oficial_2026_2.pdf",
        fileName: "Plano_de_Ensino_Oficial_2026_2.pdf",
        category: "INSTITUCIONAL",
        unitAssociated: "Geral",
        dateLabel: "01/08/2026",
        size: "1.2 MB",
        type: "PDF",
      },
      {
        seedKey: `mat-fis-repo-2-${fisCode}`,
        classCode: fisCode,
        title: "Aula_01_Introducao_Arquitetura_Software.pdf",
        fileName: "Aula_01_Introducao_Arquitetura_Software.pdf",
        category: "SLIDES DE AULA",
        unitAssociated: "Unidade 1",
        dateLabel: "12/08/2026",
        size: "4.8 MB",
        type: "PDF",
      },
      {
        seedKey: `mat-fis-repo-3-${fisCode}`,
        classCode: fisCode,
        title: "Guia_Pratico_Diagramacao_UML_2.5.pdf",
        fileName: "Guia_Pratico_Diagramacao_UML_2.5.pdf",
        category: "MATERIAL COMPLEMENTAR",
        unitAssociated: "Unidade 2",
        dateLabel: "25/08/2026",
        size: "3.1 MB",
        type: "PDF",
      },
      {
        seedKey: `mat-fis-repo-4-${fisCode}`,
        classCode: fisCode,
        title: "Template_Projeto_Camadas_Spring_Domain.zip",
        fileName: "Template_Projeto_Camadas_Spring_Domain.zip",
        category: "LABORATÓRIOS & CÓDIGOS",
        unitAssociated: "Laboratório",
        dateLabel: "10/09/2026",
        size: "14.5 MB",
        type: "ZIP",
      },
      {
        seedKey: `mat-fis-repo-5-${fisCode}`,
        classCode: fisCode,
        title: "Lista_Exercicios_Padroes_GoF_Grasp.pdf",
        fileName: "Lista_Exercicios_Padroes_GoF_Grasp.pdf",
        category: "EXERCÍCIOS",
        unitAssociated: "Exercícios",
        dateLabel: "22/09/2026",
        size: "850 KB",
        type: "PDF",
      },
      {
        seedKey: `mat-fis-repo-6-${fisCode}`,
        classCode: fisCode,
        title: "Artigo_Referencia_Microservices_Clean_Arch.pdf",
        fileName: "Artigo_Referencia_Microservices_Clean_Arch.pdf",
        category: "LEITURAS OBRIGATÓRIAS",
        unitAssociated: "Leituras",
        dateLabel: "02/10/2026",
        size: "2.4 MB",
        type: "PDF",
      },
    ];

    for (const m of mockMaterials) {
      await upsertOnInsert(
        "academic_materials",
        { classCode: fisCode, seedKey: m.seedKey },
        {
          ...m,
          mimeType: m.type === "ZIP" ? "application/zip" : "application/pdf",
          contentBase64: Buffer.from("Material Pedagógico Institucional do AVA", "utf8").toString("base64"),
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

  // 7. Parâmetros institucionais padrão se ainda não configurados
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
