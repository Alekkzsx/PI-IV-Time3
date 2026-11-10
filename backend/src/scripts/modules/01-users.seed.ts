// Desenvolvido por Time 3 - PI IV
import bcrypt from "bcryptjs";
import type { Db, Document } from "mongodb";
import { createSeedHelpers, SEED_TAG } from "../shared/seed.runner.js";
import type { SeedModule, SeedSummary } from "../shared/seed.types.js";

// Lista com 36 alunos reais com RAs e e-mails institucionais
export const studentAccounts = [
  { identity: "aluno.test", name: "Alex Gabriel Soares Sousa", email: "alex.soares.gabriel111@gmail.com" },
  { identity: "202610401", name: "Mariana Costa Ferreira", email: "mariana.ferreira@aluno.agmrm.edu.br" },
  { identity: "202610402", name: "Lucas Henrique Prado", email: "lucas.prado@aluno.agmrm.edu.br" },
  { identity: "202610403", name: "Beatriz Lima Albuquerque", email: "beatriz.albuquerque@aluno.agmrm.edu.br" },
  { identity: "202610404", name: "Carlos Eduardo Silveira", email: "carlos.silveira@aluno.agmrm.edu.br" },
  { identity: "202610405", name: "Daniel Ramos Barbosa", email: "daniel.barbosa@aluno.agmrm.edu.br" },
  { identity: "202610406", name: "Eduarda Meireles Rocha", email: "eduarda.rocha@aluno.agmrm.edu.br" },
  { identity: "202610407", name: "Felipe Nogueira Castro", email: "felipe.castro@aluno.agmrm.edu.br" },
  { identity: "202610408", name: "Gabriela Siqueira Moraes", email: "gabriela.moraes@aluno.agmrm.edu.br" },
  { identity: "202610409", name: "Henrique Duarte Valença", email: "henrique.valenca@aluno.agmrm.edu.br" },
  { identity: "202610410", name: "Isabela Correia Guimarães", email: "isabela.guimaraes@aluno.agmrm.edu.br" },
  { identity: "202610411", name: "João Pedro Vasconcelos", email: "joao.vasconcelos@aluno.agmrm.edu.br" },
  { identity: "202610412", name: "Karen Ribeiro Antunes", email: "karen.antunes@aluno.agmrm.edu.br" },
  { identity: "202610413", name: "Leonardo Santana Paiva", email: "leonardo.paiva@aluno.agmrm.edu.br" },
  { identity: "202610414", name: "Manuela Teixeira Fonseca", email: "manuela.fonseca@aluno.agmrm.edu.br" },
  { identity: "202610415", name: "Nicolas Brandão Aguiar", email: "nicolas.aguiar@aluno.agmrm.edu.br" },
  { identity: "202610416", name: "Olivia Campos Medeiros", email: "olivia.medeiros@aluno.agmrm.edu.br" },
  { identity: "202610417", name: "Paulo Roberto Vianna", email: "paulo.vianna@aluno.agmrm.edu.br" },
  { identity: "202610418", name: "Quésia Borges Toledo", email: "quesia.toledo@aluno.agmrm.edu.br" },
  { identity: "202610419", name: "Rodrigo Faria Pacheco", email: "rodrigo.pacheco@aluno.agmrm.edu.br" },
  { identity: "202610420", name: "Sofia Carmo Rezende", email: "sofia.rezende@aluno.agmrm.edu.br" },
  { identity: "202610421", name: "Thiago Mendonça Teles", email: "thiago.teles@aluno.agmrm.edu.br" },
  { identity: "202610422", name: "Ursula Cavalcanti Pires", email: "ursula.pires@aluno.agmrm.edu.br" },
  { identity: "202610423", name: "Vinicius Neves Camargo", email: "vinicius.camargo@aluno.agmrm.edu.br" },
  { identity: "202610424", name: "Yasmin Fontes Barreto", email: "yasmin.barreto@aluno.agmrm.edu.br" },
  { identity: "202610425", name: "Arthur Magalhães Peixoto", email: "arthur.peixoto@aluno.agmrm.edu.br" },
  { identity: "202610426", name: "Brenda Queiroz Diniz", email: "brenda.diniz@aluno.agmrm.edu.br" },
  { identity: "202610427", name: "Caio Cesar Lacerda", email: "caio.lacerda@aluno.agmrm.edu.br" },
  { identity: "202610428", name: "Diana Moreira Chaves", email: "diana.chaves@aluno.agmrm.edu.br" },
  { identity: "202610429", name: "Enzo Gabriel Figueiredo", email: "enzo.figueiredo@aluno.agmrm.edu.br" },
  { identity: "202610430", name: "Fernanda Bastos Sales", email: "fernanda.sales@aluno.agmrm.edu.br" },
  { identity: "202610431", name: "Guilherme Henrique Moreira", email: "guilherme.moreira@aluno.agmrm.edu.br" },
  { identity: "202610432", name: "Helena Martins Gusmão", email: "helena.gusmao@aluno.agmrm.edu.br" },
  { identity: "202610433", name: "Igor Vinicius Maciel", email: "igor.maciel@aluno.agmrm.edu.br" },
  { identity: "202610434", name: "Juliana Frota Linhares", email: "juliana.linhares@aluno.agmrm.edu.br" },
  { identity: "202610435", name: "Kleber Dorneles Prado", email: "kleber.prado@aluno.agmrm.edu.br" },
];

// Lista com 10 docentes mestres e doutores com titulações e departamentos
export const teacherAccounts = [
  { identity: "professor.test", name: "Prof. Dr. Ricardo Vasconcelos", email: "professor.test@agmrm.edu.br", dept: "Sistemas Distribuídos e Nuvem" },
  { identity: "helena.bittencourt", name: "Profa. Dra. Helena Bittencourt", email: "helena.bittencourt@agmrm.edu.br", dept: "Engenharia de Requisitos e Processos Ágeis" },
  { identity: "carlos.menezes", name: "Prof. Dr. Carlos Eduardo Menezes", email: "carlos.menezes@agmrm.edu.br", dept: "Bancos de Dados e NoSQL" },
  { identity: "patricia.abreu", name: "Profa. Dra. Patricia Abreu Miranda", email: "patricia.abreu@agmrm.edu.br", dept: "Compiladores e Teoria da Computação" },
  { identity: "marcos.vinicius", name: "Prof. Me. Marcos Vinicius Faria", email: "marcos.vinicius@agmrm.edu.br", dept: "Redes de Computadores e Segurança" },
  { identity: "fernanda.castro", name: "Profa. Dra. Fernanda Castro Rezende", email: "fernanda.castro@agmrm.edu.br", dept: "Interface Humano-Computador e UX" },
  { identity: "alberto.gentil", name: "Prof. Dr. Alberto Gentil Fontes", email: "alberto.gentil@agmrm.edu.br", dept: "Inteligência Artificial e Big Data" },
  { identity: "juliana.porto", name: "Profa. Me. Juliana Porto Sampaio", email: "juliana.porto@agmrm.edu.br", dept: "Metodologia Científica e Ética" },
  { identity: "roberto.calheiros", name: "Prof. Dr. Roberto Calheiros Ramos", email: "roberto.calheiros@agmrm.edu.br", dept: "Sistemas Operacionais e Kernel Linux" },
  { identity: "renata.vasconcelos", name: "Profa. Dra. Renata Vasconcelos Prado", email: "renata.vasconcelos@agmrm.edu.br", dept: "Cálculo Diferencial e Métodos Numéricos" },
];

export const realAccounts = [
  ...studentAccounts.map((s) => ({ ...s, profile: "aluno" as const, displayName: s.name })),
  ...teacherAccounts.map((t) => ({ ...t, profile: "docente" as const, displayName: t.name })),
  { identity: "coord.agmrm", email: "coord.agmrm@agmrm.edu.br", profile: "admin" as const, displayName: "Coordenação Acadêmica AGMRM" },
];

export async function seedUsers(
  database: Db,
  password: string,
  context?: Record<string, any>,
): Promise<SeedSummary> {
  const summary: SeedSummary = {};
  const { now, upsertOnInsert } = createSeedHelpers(database, summary);

  // Hash computado uma única vez
  const passwordHash = await bcrypt.hash(password, 10);
  const usersMap = new Map<string, Document>();

  // 1. ADMINS
  const adminAccounts = [
    {
      identity: "coord.agmrm",
      displayName: "Coordenação Acadêmica AGMRM",
      email: "coord.agmrm@agmrm.edu.br",
      profile: "admin",
      departmentOrCourse: "Coordenação de Engenharia de Software",
      campus: "Unidade Sede",
    },
    {
      identity: "secretaria.agmrm",
      displayName: "Secretaria Acadêmica Central",
      email: "secretaria.agmrm@agmrm.edu.br",
      profile: "admin",
      departmentOrCourse: "Secretaria de Registros Acadêmicos",
      campus: "Unidade Sede",
    },
    {
      identity: "admin.test",
      displayName: "Administrador Teste AGMRM",
      email: "admin.test@agmrm.edu.br",
      profile: "admin",
      departmentOrCourse: "Administração Central",
      campus: "Unidade Sede",
    },
    {
      identity: "admin.demo",
      displayName: "Administrador Demonstração",
      email: "admin.demo@example.com",
      profile: "admin",
      departmentOrCourse: "Administração",
      campus: "Unidade Sede",
    },
  ];

  for (const adm of adminAccounts) {
    const doc = await upsertOnInsert(
      "auth_users",
      { normalizedIdentity: adm.identity },
      {
        ...adm,
        normalizedIdentity: adm.identity,
        normalizedEmail: adm.email,
        passwordHash,
        active: true,
        twoFactorRequired: false,
        sessionVersion: 0,
        createdAt: now,
        updatedAt: now,
        seedTag: SEED_TAG,
      },
    );
    usersMap.set(adm.identity, doc);
  }

  // 2. DOCENTES (10 professores reais + testes)
  for (const t of teacherAccounts) {
    const doc = await upsertOnInsert(
      "auth_users",
      { normalizedIdentity: t.identity },
      {
        identity: t.identity,
        normalizedIdentity: t.identity,
        displayName: t.name,
        email: t.email,
        normalizedEmail: t.email,
        profile: "docente",
        departmentOrCourse: t.dept,
        campus: "Unidade Sede",
        passwordHash,
        active: true,
        twoFactorRequired: false,
        sessionVersion: 0,
        createdAt: now,
        updatedAt: now,
        seedTag: SEED_TAG,
      },
    );
    usersMap.set(t.identity, doc);
  }

  // Contas docentes adicionais de teste
  const extraTeachers = [
    { identity: "docente.agmrm", name: "Prof. Dr. Ricardo Vasconcelos", email: "docente.agmrm@agmrm.edu.br" },
    { identity: "docente.test", name: "Docente Teste AGMRM", email: "docente.test@agmrm.edu.br" },
    { identity: "prof.demo", name: "Professor Demonstração", email: "prof.demo@example.com" },
  ];
  for (const t of extraTeachers) {
    const doc = await upsertOnInsert(
      "auth_users",
      { normalizedIdentity: t.identity },
      {
        identity: t.identity,
        normalizedIdentity: t.identity,
        displayName: t.name,
        email: t.email,
        normalizedEmail: t.email,
        profile: "docente",
        departmentOrCourse: "Engenharia de Software",
        campus: "Unidade Sede",
        passwordHash,
        active: true,
        twoFactorRequired: false,
        sessionVersion: 0,
        createdAt: now,
        updatedAt: now,
        seedTag: SEED_TAG,
      },
    );
    usersMap.set(t.identity, doc);
  }

  // 3. ALUNOS (36 alunos reais + testes)
  // Evita conflito de índice único de e-mail caso 24802449 já possua o mesmo e-mail de aluno.test
  await database.collection("auth_users").updateOne(
    { normalizedIdentity: "24802449", email: "alex.soares.gabriel111@gmail.com" },
    { $set: { email: "alex.soares.24802449@aluno.agmrm.edu.br", normalizedEmail: "alex.soares.24802449@aluno.agmrm.edu.br" } },
  );

  for (const st of studentAccounts) {
    const doc = await upsertOnInsert(
      "auth_users",
      { normalizedIdentity: st.identity },
      {
        identity: st.identity,
        normalizedIdentity: st.identity,
        displayName: st.name,
        email: st.email,
        normalizedEmail: st.email,
        profile: "aluno",
        departmentOrCourse: "Engenharia de Software",
        semester: "2026/2 - 4º Semestre",
        shift: "Noturno",
        campus: "Unidade Sede",
        passwordHash,
        active: true,
        twoFactorRequired: false,
        sessionVersion: 0,
        createdAt: now,
        updatedAt: now,
        seedTag: SEED_TAG,
      },
    );
    usersMap.set(st.identity, doc);
  }

  // Contas alunos de teste / integração
  const extraStudents = [
    { identity: "24802449", name: "Alex Gabriel Soares Sousa", email: "alex.soares.24802449@aluno.agmrm.edu.br" },
    { identity: "aluno.demo1", name: "Aluno Demonstração Um", email: "aluno.demo1@example.com" },
    { identity: "aluno.demo2", name: "Aluno Demonstração Dois", email: "aluno.demo2@example.com" },
  ];
  for (const st of extraStudents) {
    const doc = await upsertOnInsert(
      "auth_users",
      { normalizedIdentity: st.identity },
      {
        identity: st.identity,
        normalizedIdentity: st.identity,
        displayName: st.name,
        email: st.email,
        normalizedEmail: st.email,
        profile: "aluno",
        departmentOrCourse: "Engenharia de Software",
        semester: "2026/2 - 4º Semestre",
        shift: "Noturno",
        campus: "Unidade Sede",
        passwordHash,
        active: true,
        twoFactorRequired: false,
        sessionVersion: 0,
        createdAt: now,
        updatedAt: now,
        seedTag: SEED_TAG,
      },
    );
    usersMap.set(st.identity, doc);
  }

  await database.collection("auth_users").createIndex({ normalizedIdentity: 1 }, { unique: true });
  await database.collection("auth_users").createIndex(
    { email: 1 },
    { unique: true, collation: { locale: "en", strength: 2 }, partialFilterExpression: { email: { $type: "string" } } },
  );

  if (context) {
    context.users = usersMap;
  }

  return summary;
}

export const usersSeed: SeedModule = {
  id: "users",
  name: "01-users",
  description: "Provisiona 50+ contas reais de autenticação (36 Alunos, 12 Docentes e 4 Admins)",
  execute: seedUsers,
};
