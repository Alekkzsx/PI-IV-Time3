// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702
import type { Db, Document } from "mongodb";
import { createSeedHelpers, SEED_TAG } from "../shared/seed.runner.js";
import type { SeedModule, SeedSummary } from "../shared/seed.types.js";

// Matriz curricular completa com 36 disciplinas oficiais
export const curriculumComponents = [
  // Semestre 1
  { code: "ALG-101", name: "Algoritmos e Lógica de Programação", workloadHours: 80, semester: 1 },
  { code: "FSI-102", name: "Fundamentos de Sistemas de Informação", workloadHours: 60, semester: 1 },
  { code: "MAT-103", name: "Matemática Discreta para Computação", workloadHours: 80, semester: 1 },
  { code: "IES-104", name: "Introdução à Engenharia de Software", workloadHours: 60, semester: 1 },
  { code: "COM-105", name: "Comunicação e Expressão Técnica", workloadHours: 40, semester: 1 },

  // Semestre 2
  { code: "ED-201", name: "Estruturas de Dados e Algoritmos Avançados", workloadHours: 80, semester: 2 },
  { code: "POO-202", name: "Programação Orientada a Objetos em TypeScript/Java", workloadHours: 80, semester: 2 },
  { code: "AOC-203", name: "Arquitetura e Organização de Computadores", workloadHours: 60, semester: 2 },
  { code: "CDI-204", name: "Cálculo Diferencial e Integral I", workloadHours: 80, semester: 2 },
  { code: "ETC-205", name: "Ética, Sociedade e Cidadania", workloadHours: 40, semester: 2 },

  // Semestre 3
  { code: "BD1-301", name: "Banco de Dados Relacional e Modelagem SQL", workloadHours: 80, semester: 3 },
  { code: "REQ-302", name: "Engenharia de Requisitos e Modelagem Ágil", workloadHours: 80, semester: 3 },
  { code: "FSO-303", name: "Fundamentos de Sistemas Operacionais", workloadHours: 80, semester: 3 },
  { code: "EST-304", name: "Probabilidade e Estatística Aplicada", workloadHours: 60, semester: 3 },
  { code: "IHC-305", name: "Interação Humano-Computador e Design de Experiência (UX)", workloadHours: 60, semester: 3 },

  // Semestre 4 (atual)
  { code: "PI-IV", name: "Projeto Integrador IV - Sistemas Integrados", workloadHours: 80, semester: 4 },
  { code: "218131 - APS-II", name: "Análise e Projeto de Sistemas II", workloadHours: 80, semester: 4 },
  { code: "ARQ-2026-4N", name: "Arquitetura de Software e Microsserviços", workloadHours: 80, semester: 4 },
  { code: "BD2-2026-4N", name: "Estudos de Banco de Dados II e NoSQL", workloadHours: 80, semester: 4 },
  { code: "FIS-2026-4N", name: "Filosofia, Informação e Sociedade", workloadHours: 60, semester: 4 },
  { code: "MAT-2026-4N", name: "Cálculo Diferencial e Integral", workloadHours: 80, semester: 4 },

  // Semestre 5
  { code: "TQS-501", name: "Testes Automatizados e Qualidade de Software", workloadHours: 80, semester: 5 },
  { code: "RED-502", name: "Redes de Computadores e Protocolos de Internet", workloadHours: 80, semester: 5 },
  { code: "WEB-503", name: "Desenvolvimento Web Full-Stack Reativo", workloadHours: 80, semester: 5 },
  { code: "IA-504", name: "Inteligência Artificial e Aprendizado de Máquina", workloadHours: 80, semester: 5 },
  { code: "GP-505", name: "Gerenciamento Ágil de Projetos de Software", workloadHours: 60, semester: 5 },

  // Semestre 6
  { code: "SEG-601", name: "Segurança da Informação e Criptografia Aplicada", workloadHours: 80, semester: 6 },
  { code: "CLD-602", name: "Computação em Nuvem e Infraestrutura DevOps", workloadHours: 80, semester: 6 },
  { code: "MOB-603", name: "Desenvolvimento Mobile Multiplataforma com Flutter", workloadHours: 80, semester: 6 },
  { code: "PI5-604", name: "Projeto Integrador V - Soluções Cloud-Native", workloadHours: 80, semester: 6 },
  { code: "DVP-605", name: "Observabilidade e Governança de Sistemas", workloadHours: 60, semester: 6 },

  // Semestre 7
  { code: "SD-701", name: "Sistemas Distribuídos e Computação de Alto Desempenho", workloadHours: 80, semester: 7 },
  { code: "BIG-702", name: "Engenharia de Dados e Big Data Streaming", workloadHours: 80, semester: 7 },
  { code: "TCC1-703", name: "Trabalho de Conclusão de Curso I", workloadHours: 60, semester: 7 },

  // Semestre 8
  { code: "TCC2-801", name: "Trabalho de Conclusão de Curso II", workloadHours: 80, semester: 8 },
  { code: "EMP-802", name: "Empreendedorismo Tecnológico e Inovação", workloadHours: 60, semester: 8 },
];

export async function seedCourses(
  database: Db,
  _password: string,
  context?: Record<string, any>,
): Promise<SeedSummary> {
  const summary: SeedSummary = {};
  const { now, upsertOnInsert } = createSeedHelpers(database, summary);

  const adminActor = context?.users?.get("coord.agmrm") ??
    (await database.collection("auth_users").findOne({ normalizedIdentity: "coord.agmrm" }));

  const adminId = adminActor ? String(adminActor._id) : "admin";

  // Curso principal com todos os 36 componentes
  const courseMain = await upsertOnInsert(
    "academic_courses",
    { code: "ES-2026" },
    {
      code: "ES-2026",
      name: "Engenharia de Software",
      matrix: "Matriz 2026 - DCN Computação",
      workload: "3.200h",
      studentsCount: 36,
      formula: "(N1 × 0.4) + (N2 × 0.6)",
      department: "Computação e Engenharia de Sistemas",
      modality: "Presencial / Híbrido Síncrono",
      active: true,
      components: curriculumComponents,
      createdBy: adminId,
      createdAt: now,
      updatedAt: now,
      seedTag: SEED_TAG,
    },
  );

  await database.collection("academic_courses").createIndex({ code: 1 }, { unique: true });

  if (context) {
    const coursesMap = context.courses ?? new Map<string, Document>();
    coursesMap.set("ES-2026", courseMain);
    context.courses = coursesMap;
  }

  return summary;
}

export const coursesSeed: SeedModule = {
  id: "courses",
  name: "02-courses",
  description: "Provisiona o curso real de Engenharia de Software (ES-2026) com 36 componentes curriculares completos",
  execute: seedCourses,
};
