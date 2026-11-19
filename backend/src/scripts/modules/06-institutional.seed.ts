// Desenvolvido por Time 3 - PI IV
import { ObjectId, type Db } from "mongodb";
import { createSeedHelpers, SEED_TAG } from "../shared/seed.runner.js";
import type { SeedModule, SeedSummary } from "../shared/seed.types.js";

export async function seedInstitutional(
  database: Db,
  _password: string,
  _context?: Record<string, any>,
): Promise<SeedSummary> {
  const summary: SeedSummary = {};
  const { now, upsertOnInsert, upsertSync } = createSeedHelpers(database, summary);

  const adminActor = await database.collection("auth_users").findOne({ normalizedIdentity: "coord.agmrm" });
  const teachers = await database.collection("auth_users").find({ profile: "docente" }).toArray();
  const defaultTeacher = teachers[0]!;
  const adminId = adminActor ? String(adminActor._id) : "admin";

  // 1. PELO MENOS 30 COMUNICADOS NO MURAL ACADÊMICO (academic_announcements)
  const announcementTemplates = [
    { title: "Calendário Oficial de Bancas de Projeto Integrador IV — 2026/2", category: "Bancas", isInst: true, priority: "alta" },
    { title: "Abertura do Período de Rematrícula e Ajuste de Grade Curricular", category: "Secretaria", isInst: true, priority: "alta" },
    { title: "Semana Acadêmica de Engenharia de Software e Inovação Tecnológica", category: "Eventos", isInst: true, priority: "normal" },
    { title: "Hackathon Universitário AGMRM 2026: Inteligência Artificial e Sociedade", category: "Competição", isInst: true, priority: "normal" },
    { title: "Biblioteca Digital Pearson: Mais de 500 Novos Títulos de Computação Adicionados", category: "Biblioteca", isInst: true, priority: "baixa" },
    { title: "Manutenção Preventiva nos Servidores de Laboratório Docker e MongoDB Atlas", category: "TI", isInst: true, priority: "normal" },
    { title: "Programa de Monitoria Acadêmica: Inscrições Abertas para Bolsistas", category: "Monitoria", isInst: true, priority: "normal" },
    { title: "Palestra Magna com Especialistas da Indústria: Arquiteturas Cloud-Native", category: "Palestra", isInst: true, priority: "normal" },
    { title: "Aviso de Feriado Nacional: Independência do Brasil e Recesso Escolar", category: "Calendário", isInst: true, priority: "alta" },
    { title: "Orientações sobre o Relatório de Estágio Curricular Supervisionado", category: "Estágio", isInst: true, priority: "normal" },
    { title: "Sala Síncrona Habilitada — Projeto Integrador IV (PI4-2026-4N)", category: "Aula Síncrona", isInst: false, priority: "normal" },
    { title: "Orientações para a Entrega da Sprint 1 de Modelagem UML (APS-II)", category: "Avaliação", isInst: false, priority: "alta" },
    { title: "Divulgação dos Gabaritos Preliminares da Lista de Exercícios de SQL", category: "Gabarito", isInst: false, priority: "normal" },
    { title: "Atendimento Docente Extraordinário para Dúvidas de Cálculo Diferencial", category: "Plantão", isInst: false, priority: "normal" },
    { title: "Material Complementar Disponibilizado: Slides de Clean Architecture", category: "Material", isInst: false, priority: "baixa" },
    { title: "Aviso de Segunda Chamada da Avaliação A1 de Sistemas Operacionais", category: "Secretaria", isInst: true, priority: "alta" },
    { title: "Inauguração do Espaço Maker e Laboratório de Prototipagem Ágil", category: "Infraestrutura", isInst: true, priority: "normal" },
    { title: "Workshops de Nivelamento em Algoritmos e Lógica de Programação", category: "Nivelamento", isInst: true, priority: "normal" },
    { title: "Campanha de Conscientização sobre Segurança Digital e Phishing", category: "Segurança", isInst: true, priority: "normal" },
    { title: "Resultado Final da Seleção para Iniciação Científica 2026", category: "Pesquisa", isInst: true, priority: "normal" },
    { title: "Prorrogação de Prazo: Submissão de Artigos para o Simpósio de TI", category: "Pesquisa", isInst: true, priority: "normal" },
    { title: "Acesso Gratuito à Plataforma de Cursos Certificados em Cloud", category: "Parcerias", isInst: true, priority: "normal" },
    { title: "Pesquisa Institucional de Clima Acadêmico e Avaliação Docente", category: "CPA", isInst: true, priority: "alta" },
    { title: "Horários de Funcionamento do Suporte Técnico durante a Semana de Provas", category: "TI", isInst: true, priority: "normal" },
    { title: "Orientações para Solicitação de Segunda Via de Carteirinha Estudantil", category: "Secretaria", isInst: true, priority: "baixa" },
    { title: "Lançamento do Portal de Vagas de Estágio e Oportunidades Conectadas", category: "Carreiras", isInst: true, priority: "normal" },
    { title: "Simulado Geral Preparatório para o ENADE 2026", category: "Avaliação", isInst: true, priority: "alta" },
    { title: "Normas para Uso dos Laboratórios de Informática no Período Noturno", category: "Regulamento", isInst: true, priority: "normal" },
    { title: "Aviso de Recesso Semestral e Atendimento Administrativo", category: "Secretaria", isInst: true, priority: "alta" },
    { title: "Boas-Vindas aos Novos Ingressantes do Semestre 2026/2", category: "Institucional", isInst: true, priority: "alta" },
  ];

  for (let i = 0; i < announcementTemplates.length; i++) {
    const ann = announcementTemplates[i]!;
    const teacher = teachers[i % teachers.length] ?? defaultTeacher;
    const authorRole = ann.isInst
      ? (ann.category === "Secretaria" || ann.category === "Calendário" ? "secretaria" : "coordenacao")
      : "docente";
    const authorName = ann.isInst
      ? (authorRole === "secretaria"
          ? "Secretaria Acadêmica AGMRM"
          : "Coordenação de Curso (Sistemas de Informação)")
      : teacher.displayName;

    const audience = ann.isInst
      ? (ann.category === "CPA" || ann.category === "Secretaria"
          ? "Toda a Comunidade Acadêmica"
          : ann.category === "Bancas" || ann.category === "Estágio"
            ? "Somente Discentes"
            : "Toda a Comunidade Acadêmica")
      : "Alunos Matriculados";
    const contextualBody = ann.isInst
      ? `${ann.title}. Consulte os prazos, regulamentos e orientações operacionais publicados pela ${authorName} diretamente no calendário e na aba de Secretaria.`
      : `${ann.title}. Documento e instruções publicados na sala virtual pelo docente ${authorName} para acompanhamento da turma.`;

    await upsertSync(
      "academic_announcements",
      { seedKey: `ann-eco-${i + 1}` },
      {
        seedKey: `ann-eco-${i + 1}`,
        title: ann.title,
        body: contextualBody,
        audience,
        classCode: ann.isInst ? undefined : "PI4-2026-4N",
        category: ann.category,
        priority: ann.priority,
        isInstitutional: ann.isInst,
        authorRole,
        createdBy: ann.isInst ? adminId : String(teacher._id),
        authorName,
        readBy: [],
        createdAt: new Date(now.getTime() - i * 18 * 3600 * 1000),
        seedTag: SEED_TAG,
      },
    );
  }

  // 2. PELO MENOS 35 MARCOS DO CALENDÁRIO ACADÊMICO OFICIAL (academic_calendar)
  const calendarMilestones = [
    { title: "Abertura Oficial do Semestre Letivo 2026/2", cat: "academic", startsAt: "2026-08-03" },
    { title: "Semana de Acolhimento e Integração dos Estudantes", cat: "academic", startsAt: "2026-08-04" },
    { title: "Início das Aulas Regulares do Ciclo Profissionalizante", cat: "academic", startsAt: "2026-08-10" },
    { title: "Prazo Final para Ajuste e Trancamento de Matrícula", cat: "administrative", startsAt: "2026-08-21" },
    { title: "Seminário de Alinhamento das Sprints do Projeto Integrador IV", cat: "academic", startsAt: "2026-08-26" },
    { title: "Feriado Nacional: Independência do Brasil", cat: "holiday", startsAt: "2026-09-07" },
    { title: "Abertura das Inscrições para o Programa de Monitoria", cat: "administrative", startsAt: "2026-09-14" },
    { title: "Entrega do Marco 1: Modelagem UML e Requisitos de Software", cat: "exam", startsAt: "2026-09-25" },
    { title: "Semana de Tecnologia e Inovação AGMRM 2026", cat: "event", startsAt: "2026-09-28" },
    { title: "Início do Período Oficial de Avaliações A1", cat: "exam", startsAt: "2026-10-05" },
    { title: "Término da Semana de Avaliações A1", cat: "exam", startsAt: "2026-10-09" },
    { title: "Feriado Nacional: Nossa Senhora Aparecida", cat: "holiday", startsAt: "2026-10-12" },
    { title: "Divulgação Oficial das Notas e Feedbacks da Avaliação A1", cat: "academic", startsAt: "2026-10-16" },
    { title: "Início das Aulas do Ciclo de Arquitetura e Persistência NoSQL", cat: "academic", startsAt: "2026-10-19" },
    { title: "Feriado: Dia do Professor e Funcionário Acadêmico", cat: "holiday", startsAt: "2026-10-23" },
    { title: "Prazo para Requerimento de Segunda Chamada de Provas A1", cat: "administrative", startsAt: "2026-10-27" },
    { title: "Feriado Nacional: Finados", cat: "holiday", startsAt: "2026-11-02" },
    { title: "Entrega do Marco 2: Protótipo Funcional e Videochamada WebRTC", cat: "exam", startsAt: "2026-11-06" },
    { title: "Hackathon 48h de Engenharia de Software e IA", cat: "event", startsAt: "2026-11-13" },
    { title: "Feriado Nacional: Proclamação da República", cat: "holiday", startsAt: "2026-11-15" },
    { title: "Feriado Nacional: Dia da Consciência Negra", cat: "holiday", startsAt: "2026-11-20" },
    { title: "Semana Preparatória para as Bancas Integradoras Finais", cat: "academic", startsAt: "2026-11-23" },
    { title: "Prazo Limite para Protocolo de Horas Complementares", cat: "administrative", startsAt: "2026-11-27" },
    { title: "Início do Período de Avaliações Finais A2", cat: "exam", startsAt: "2026-11-30" },
    { title: "Bancas de Apresentação Final do Projeto Integrador IV", cat: "exam", startsAt: "2026-12-04" },
    { title: "Divulgação Oficial das Médias Semestrais N1 e N2", cat: "academic", startsAt: "2026-12-09" },
    { title: "Período de Aplicação dos Exames Finais e Recuperação", cat: "exam", startsAt: "2026-12-11" },
    { title: "Término Oficial do Semestre Letivo 2026/2", cat: "academic", startsAt: "2026-12-13" },
    { title: "Conselho de Classe e Homologação dos Resultados Acadêmicos", cat: "administrative", startsAt: "2026-12-16" },
    { title: "Abertura do Período de Renovação de Matrícula para 2027/1", cat: "administrative", startsAt: "2026-12-18" },
    { title: "Início do Recesso Escolar de Fim de Ano", cat: "holiday", startsAt: "2026-12-21" },
    { title: "Feriado Nacional: Natal", cat: "holiday", startsAt: "2026-12-25" },
    { title: "Feriado Nacional: Confraternização Universal (Ano Novo)", cat: "holiday", startsAt: "2027-01-01" },
    { title: "Período de Férias Coletivas Docentes", cat: "holiday", startsAt: "2027-01-04" },
    { title: "Início do Planejamento Pedagógico para o Semestre 2027/1", cat: "administrative", startsAt: "2027-01-25" },
  ];

  for (let i = 0; i < calendarMilestones.length; i++) {
    const cal = calendarMilestones[i]!;
    const startsAt = new Date(`${cal.startsAt}T00:00:00.000Z`);

    await upsertOnInsert(
      "academic_calendar",
      { seedKey: `cal-eco-${i + 1}` },
      {
        seedKey: `cal-eco-${i + 1}`,
        title: cal.title,
        description: `Evento oficial do calendário institucional: ${cal.title}`,
        startsAt,
        category: cal.cat,
        scope: "all",
        createdBy: adminId,
        createdAt: now,
        seedTag: SEED_TAG,
      },
    );
  }

  // 3. PARÂMETROS INSTITUCIONAIS DO SISTEMA (admin_settings)
  await upsertSync(
    "admin_settings",
    { _id: "institutional" as unknown as ObjectId },
    {
      institutionName: "AGMRM — Plataforma Universitária Integrada",
      academicPeriod: "2026/2",
      currentSemesterLabel: "2026/2",
      currentWeekLabel: "Calendário Vigente 2026/2",
      resolutionCode: "RESOLUÇÃO CONSEPE 2026/04",
      minimumAttendance: 75,
      minimumGrade: 6.0,
      specialExamGrade: 4.0,
      evaluationFormula: "(N1 × 0.4) + (N2 × 0.6)",
      regimentalLockActive: false,
      campusAlertsEnabled: true,
      campusAlerts: {
        notifyPendingProtocols: true,
        notifyGradeRectifications: true,
        notifyRegimentalDeadlines: true,
        emailUrgentEscalations: false,
      },
      governanceLgpd: {
        showInstitutionalEmailInClassLists: false,
        showPeerPresenceStatus: true,
        lgpdRetentionMonths: 60,
        dpoEmail: "dpo@agmrm.edu.br",
      },
      lgpdRetentionMonths: 60,
      dpoEmail: "dpo@agmrm.edu.br",
      updatedAt: now,
      academicResources: [
        {
          id: "res-biblioteca-virtual",
          title: "Biblioteca Virtual Pearson & Minha Biblioteca",
          subtitle: "Acervo completo de Engenharia, Arquitetura e Computação",
          description: "Acervo completo de Engenharia, Arquitetura e Computação",
          category: "ACERVO DIGITAL",
          actionLabel: "Acessar Acervo",
          url: "https://biblioteca.agmrm.edu.br",
          icon: "menu_book",
        },
        {
          id: "res-labs-docker",
          title: "Laboratórios Remotos Cloud & Containers",
          subtitle: "Ambientes Linux, Docker, PostgreSQL e MongoDB sob demanda",
          description: "Ambientes Linux, Docker, PostgreSQL e MongoDB sob demanda",
          category: "INFRAESTRUTURA",
          actionLabel: "Provisionar Lab",
          url: "https://labs.agmrm.edu.br",
          icon: "terminal",
        },
        {
          id: "res-monitoria-nivelamento",
          title: "Central de Monitoria & Nivelamento Acadêmico",
          subtitle: "Plantões semanais com monitores bolsistas das disciplinas",
          description: "Plantões semanais com monitores bolsistas das disciplinas",
          category: "SUPORTE DISCENTE",
          actionLabel: "Ver Horários",
          url: "https://monitoria.agmrm.edu.br",
          icon: "groups",
        },
        {
          id: "res-templates-abnt",
          title: "Guias Regimentais, Normas ABNT & Templates",
          subtitle: "Modelos oficiais LaTeX/DOCX para relatórios técnicos e PI",
          description: "Modelos oficiais LaTeX/DOCX para relatórios técnicos e PI",
          category: "INSTITUCIONAL",
          actionLabel: "Baixar Modelos",
          url: "https://normas.agmrm.edu.br",
          icon: "description",
        },
      ],
    },
  );

  return summary;
}

export const institutionalSeed: SeedModule = {
  id: "institutional",
  name: "06-institutional",
  description: "Popula 35+ marcos do calendário acadêmico, 30+ comunicados no mural e configurações globais",
  execute: seedInstitutional,
};
