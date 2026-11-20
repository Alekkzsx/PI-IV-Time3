// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702
import type { Db } from "mongodb";
import { createSeedHelpers, SEED_TAG } from "../shared/seed.runner.js";
import type { SeedModule, SeedSummary } from "../shared/seed.types.js";

export async function seedStudent(
  database: Db,
  _password: string,
  _context?: Record<string, any>,
): Promise<SeedSummary> {
  const summary: SeedSummary = {};
  const { now, upsertOnInsert, upsertSync } = createSeedHelpers(database, summary);

  const students = await database.collection("auth_users").find({ profile: "aluno" }).toArray();
  const assignments = await database.collection("academic_assignments").find({}).toArray();

  const defaultStudent = students[0]!;

  // 1. PELO MENOS 35 SUBMISSÕES DE ATIVIDADES (academic_submissions)
  for (let i = 0; i < Math.max(35, assignments.length); i++) {
    const asg = assignments[i % assignments.length]!;
    const st = students[i % students.length] ?? defaultStudent;

    const isGraded = i % 2 === 0;
    const grade = 8.0 + (i % 20) * 0.1; // Notas entre 8.0 e 9.9
    const subDate = new Date(Date.UTC(2026, 8, 10 + (i % 20), 20, 15, 0));

    await upsertSync(
      "academic_submissions",
      { assignmentId: String(asg._id), studentId: String(st._id) },
      {
        assignmentId: String(asg._id),
        studentId: String(st._id),
        studentIdentity: st.identity,
        studentName: st.displayName,
        classCode: asg.classCode,
        status: isGraded ? "avaliada" : "entregue",
        grade: isGraded ? grade : undefined,
        score: isGraded ? grade : undefined,
        feedback: isGraded
          ? `Excelente entrega técnica de ${st.displayName}. Demonstrou domínio das boas práticas de engenharia de software e arquitetura.`
          : undefined,
        submittedAt: subDate,
        updatedAt: subDate,
        seedTag: SEED_TAG,
      },
    );
  }

  // 2. PELO MENOS 35 REGISTROS DE NOTAS CONSOLIDADAS (academic_grades)
  const classes = await database.collection("academic_classes").find({ active: true }).toArray();
  let gradeIndex = 0;
  for (const classroom of classes) {
    const isFourthSem = String(classroom.code).includes("4N") || String(classroom.code).includes("APS-II");
    const targetStudents = isFourthSem ? students : students.slice(0, 6);
    for (const st of targetStudents) {
      gradeIndex++;
      const assignmentsScore = Number((8.0 + (gradeIndex % 15) * 0.1).toFixed(1));
      const p1Score = Number((7.5 + (gradeIndex % 20) * 0.1).toFixed(1));
      const projectsScore = Number((8.2 + (gradeIndex % 12) * 0.1).toFixed(1));
      const p2Score = Number((7.8 + (gradeIndex % 18) * 0.1).toFixed(1));
      const n1 = Number(((assignmentsScore + p1Score) / 2).toFixed(1));
      const n2 = Number(((projectsScore + p2Score) / 2).toFixed(1));
      const finalGrade = Math.round((n1 * 0.4 + n2 * 0.6) * 10) / 10;
      const attendanceRate = 85 + (gradeIndex % 15);

      await upsertSync(
        "academic_grades",
        { classCode: classroom.code, studentId: String(st._id) },
        {
          classCode: classroom.code,
          courseCode: "ES-2026",
          studentId: String(st._id),
          studentIdentity: st.identity,
          studentName: st.displayName,
          grades: { n1, n2 },
          assignmentsScore,
          p1Score,
          projectsScore,
          p2Score,
          finalGrade,
          finalAverage: finalGrade,
          attendancePercentage: attendanceRate,
          attendanceRate,
          status: "Em curso",
          updatedAt: now,
          seedTag: SEED_TAG,
        },
      );
    }
  }

  // 3. PELO MENOS 30 PROTOCOLOS NA SECRETARIA ACADÊMICA (academic_protocols)
  const protocolTypes = [
    { type: "Atestado Médico", desc: "APS-II e BD-II (Afastamento 29 a 30/09)" },
    { type: "Segunda Chamada", desc: "APS-II - Prova Substitutiva" },
    { type: "Revisão de Avaliação A1", desc: "Solicitação de revisão técnica de nota e critério da avaliação teórica." },
    { type: "Aproveitamento de Estudos", desc: "Análise de certificação em nuvem AWS/Azure para horas complementares." },
    { type: "Declaração de Matrícula com Histórico", desc: "Comprovação acadêmica oficial para processo seletivo de estágio." },
    { type: "Trancamento Parcial de Disciplina", desc: "Requerimento regimental de desmatrícula tempestiva de componente optativo." },
  ];

  const allClassCodes = classes.length > 0
    ? classes.map((c) => String(c.code))
    : ["218131 - APS-II", "PI4-2026-4N", "BD2-2026-4N", "ARQ-2026-4N", "FIS-2026-4N", "MAT-2026-4N"];

  for (let i = 0; i < 30; i++) {
    const protoType = protocolTypes[i % protocolTypes.length]!;
    const st = students[i % students.length] ?? defaultStudent;
    const targetClassCode = allClassCodes[i % allClassCodes.length]!;
    const protoCode = `PROT - 2026/${String(541 + i).padStart(4, "0")}`;
    const status = i % 2 === 0 ? "deferido" : "pendente";

    await upsertSync(
      "academic_protocols",
      { seedKey: `prot-eco-${i + 1}` },
      {
        seedKey: `prot-eco-${i + 1}`,
        code: protoCode,
        studentId: String(st._id),
        studentIdentity: st.identity,
        studentRa: st.identity,
        studentName: st.displayName,
        requestType: protoType.type,
        targetComponent: targetClassCode,
        classCode: targetClassCode,
        classCodes: allClassCodes,
        description: protoType.desc,
        justification: protoType.desc,
        status,
        slaDays: 5,
        resolution: status === "deferido" ? "Requerimento deferido e homologado eletronicamente pela secretaria." : undefined,
        createdBy: String(st._id),
        createdAt: now,
        updatedAt: now,
        seedTag: SEED_TAG,
      },
    );
  }

  // 4. PELO MENOS 30 DECLARAÇÕES DE MATRÍCULA COM VERIFICAÇÃO PÚBLICA (academic_enrollment_declarations)
  for (let i = 0; i < 30; i++) {
    const st = students[i % students.length] ?? defaultStudent;
    const key = `DEC-2026-${st.identity}-${String(100 + i)}`;

    await upsertOnInsert(
      "academic_enrollment_declarations",
      { verificationKey: key },
      {
        verificationKey: key,
        studentId: String(st._id),
        studentIdentity: st.identity,
        studentName: st.displayName,
        courseCode: "ES-2026",
        courseName: "Engenharia de Software",
        semester: "2026/2 - 4º Semestre",
        shift: "Noturno",
        status: "valida",
        issuedAt: now,
        seedTag: SEED_TAG,
      },
    );
  }

  // 5. PELO MENOS 30 ANOTAÇÕES DE ESTUDO (student_notes)
  const noteTitles = [
    "Revisão de Padrões GRASP e Princípios SOLID",
    "Comandos essenciais do MongoDB: find, aggregate e explain",
    "Diagrama de Classes: Segregação de Interfaces e Injeção de Dependência",
    "Arquitetura Hexagonal: Criando adaptadores e portas desacopladas",
    "Como funciona o Outbox Pattern na prevenção de perda de mensagens",
    "Fluxo de autenticação JWT e armazenamento de refresh token",
    "Dicas de estudo para a prova A1 de Cálculo Diferencial",
    "Sincronização de Threads com Semáforos e Evitando Deadlocks",
    "Passo a passo da modelagem de casos de uso com fluxos de exceção",
    "Resumo da LGPD: Consentimento, Finalidade e Direitos do Titular",
  ];

  const fourthSemCodes = [
    "218131 - APS-II",
    "PI4-2026-4N",
    "ARQ-2026-4N",
    "BD2-2026-4N",
    "FIS-2026-4N",
    "MAT-2026-4N",
  ];

  for (let i = 0; i < 30; i++) {
    const title = `${noteTitles[i % noteTitles.length]!} (Parte ${(i % 3) + 1})`;
    const st = students[i % students.length] ?? defaultStudent;
    const classCode = fourthSemCodes[i % fourthSemCodes.length]!;

    await upsertSync(
      "student_notes",
      { studentId: String(st._id), title },
      {
        studentId: String(st._id),
        studentIdentity: st.identity,
        classCode,
        title,
        content: `Anotações detalhadas de estudo feitas pelo discente ${st.displayName} sobre ${title}.`,
        tags: ["Engenharia", "Estudo", "2026/2"],
        updatedAt: now,
        seedTag: SEED_TAG,
      },
    );
  }

  // 6. PELO MENOS 30 LEMBRETES DE ESTUDOS (student_reminders)
  const reminderTitles = [
    "Revisar entrega da Sprint 1 de Projeto Integrador IV",
    "Estudar lista de exercícios de Árvores B+ e Índices SQL",
    "Enviar formulário do estudo de caso de Arquitetura",
    "Assistir gravação síncrona de WebSockets e Videochamada",
    "Ler artigo sobre Governança de IA e Responsabilidade Algorítmica",
    "Finalizar simulador de Memória Virtual Paginada em Python",
    "Resolver lista de derivadas parciais e gradiente para A1",
    "Agendar reunião de alinhamento com a equipe do PI-IV",
    "Baixar template oficial da ABNT para relatório técnico",
    "Revisar pull request do colega no repositório do projeto",
  ];

  for (let i = 0; i < 30; i++) {
    const title = `${reminderTitles[i % reminderTitles.length]!} #${i + 1}`;
    const st = students[i % students.length] ?? defaultStudent;
    const dueDate = new Date(Date.UTC(2026, 8 + Math.floor(i / 15), 10 + (i % 20), 18, 0, 0));

    await upsertSync(
      "student_reminders",
      { studentId: String(st._id), title },
      {
        studentId: String(st._id),
        studentIdentity: st.identity,
        title,
        date: dueDate.toISOString().slice(0, 10),
        dueDate,
        completed: i % 4 === 0,
        createdAt: now,
        seedTag: SEED_TAG,
      },
    );
  }

  await database.collection("academic_protocols").createIndex({ code: 1 }, { unique: true });
  await database.collection("academic_enrollment_declarations").createIndex(
    { verificationKey: 1 },
    { unique: true },
  );

  return summary;
}

export const studentSeed: SeedModule = {
  id: "student",
  name: "05-student",
  description: "Popula 35+ submissões, 35+ notas, 30+ protocolos, 30+ declarações, 30+ anotações e 30+ lembretes",
  execute: seedStudent,
};
