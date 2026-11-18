// Desenvolvido por Time 3 - PI IV
import type { Db } from "mongodb";
import { createSeedHelpers, SEED_TAG } from "../shared/seed.runner.js";
import type { SeedModule, SeedSummary } from "../shared/seed.types.js";

export async function seedTeacher(
  database: Db,
  _password: string,
  _context?: Record<string, any>,
): Promise<SeedSummary> {
  const summary: SeedSummary = {};
  const { now, upsertOnInsert, upsertSync } = createSeedHelpers(database, summary);

  const teachers = await database.collection("auth_users").find({ profile: "docente" }).toArray();
  const students = await database.collection("auth_users").find({ profile: "aluno" }).toArray();
  const defaultTeacher = teachers[0]!;

  const allClassesDocs = await database.collection("academic_classes").find({ active: true }).toArray();
  const coreClasses = allClassesDocs.length > 0
    ? allClassesDocs.map((c) => String(c.code))
    : [
        "218131 - APS-II",
        "PI4-2026-4N",
        "ARQ-2026-4N",
        "BD2-2026-4N",
        "FIS-2026-4N",
        "MAT-2026-4N",
      ];

  // 1. PELO MENOS 35 DIÁRIOS DE AULAS COM CHAMADA (academic_class_sessions)
  const sessionTopics = [
    "Processo Unificado e Engenharia de Requisitos Ágeis",
    "Modelagem de Casos de Uso e Diagramas Comportamentais",
    "Diagrama de Classes, Multiplicidades e Visibilidade",
    "Diagrama de Sequência e Interações Temporais no AVA",
    "Padrões de Projeto GRASP: Especialista na Informação",
    "Padrões GoF Criacionais: Factory Method e Singleton",
    "Padrões GoF Estruturais: Adapter, Facade e Decorator",
    "Padrões GoF Comportamentais: Strategy e Observer",
    "Arquitetura em Camadas vs Arquitetura Hexagonal",
    "Domain-Driven Design: Entidades, Agregados e Value Objects",
    "Repositórios, Mappers e Isolamento de Infraestrutura",
    "Contratos RESTful, DTOs e Versionamento de APIs",
    "Autenticação Segura JWT e Controle de Sessão Revogável",
    "Autenticação em Dois Fatores (2FA) com Código OTP",
    "Observabilidade Distribuída, Logs Estruturados e LGPD",
    "Indexação B-Tree e Planos de Execução em Banco Relacional",
    "Controle de Concorrência Multiversão (MVCC) e Locks",
    "Transações ACID e Recuperação por Write-Ahead Log (WAL)",
    "Bancos NoSQL Orientados a Documentos: Schema Design",
    "Aggregation Pipelines de Alta Performance no MongoDB Atlas",
    "Sincronização em Tempo Real e WebSockets com Fallback",
    "Sinalização WebRTC e Autorização com Tickets Efêmeros",
    "Resiliência com Circuit Breaker, Retry e Outbox Pattern",
    "Testes de Unidade e Inversão de Dependência com Mocks",
    "Testes de Integração Ponta a Ponta com Banco Isolado",
    "Filosofia da Técnica e Economia da Atenção Digital",
    "Ética Algorítmica, Viés e Explicabilidade em IA",
    "Direitos Digitais, LGPD e Privacidade por Padrão",
    "Kernel Linux, Syscalls POSIX e Troca de Contexto",
    "Gerenciamento de Processos, Threads e Escalonador CFS",
    "Concorrência, Exclusão Mútua, Mutexes e Semáforos",
    "Memória Virtual Paginada, TLB e Algoritmos de Substituição",
    "Sistemas de Arquivos, Inodes e I/O Assíncrono (epoll)",
    "Limites, Continuidade e Taxa Instantânea de Variação",
    "Derivadas, Regra da Cadeia e Otimização com Gradiente",
  ];

  for (let i = 0; i < sessionTopics.length; i++) {
    const topic = sessionTopics[i]!;
    const classCode = coreClasses[i % coreClasses.length]!;
    const teacher = teachers[i % teachers.length] ?? defaultTeacher;

    const sessionDate = new Date(Date.UTC(2026, 7 + Math.floor(i / 10), 10 + (i % 20), 19, 10, 0));
    const endDate = new Date(sessionDate.getTime() + 3.5 * 3600 * 1000);

    const attendances = students.map((st, sIdx) => ({
      studentId: String(st._id),
      studentIdentity: st.identity,
      present: (i + sIdx) % 10 !== 0, // 90% presença realista
    }));
    const attendanceList = students.map((st, sIdx) => ({
      studentId: String(st._id),
      ra: st.identity,
      name: st.displayName,
      status: (i + sIdx) % 10 !== 0 ? "presente" : "ausente",
    }));
    const contentDescription = `Ministrado conteúdo aprofundado sobre ${topic}, com exemplos práticos e laboratório.`;

    await upsertSync(
      "academic_class_sessions",
      { classCode, title: `Aula ${i + 1}: ${topic}` },
      {
        classCode,
        courseCode: "ES-2026",
        title: `Aula ${i + 1}: ${topic}`,
        startsAt: sessionDate,
        endsAt: endDate,
        contentTaught: contentDescription,
        contentProgram: contentDescription,
        location: `Lab. 10${(i % 5) + 1}`,
        createdBy: String(teacher._id),
        status: i < 25 ? "completed" : "scheduled",
        attendances,
        attendanceList,
        createdAt: now,
        seedTag: SEED_TAG,
      },
    );
  }

  // 2. PELO MENOS 30 MATERIAIS DIDÁTICOS (academic_materials)
  const materialTitles = [
    { title: "Plano de Ensino & Contrato Pedagógico", type: "pdf", size: "420 KB" },
    { title: "Slides Aula 01: Processo Unificado e Engenharia de Requisitos", type: "pdf", size: "3.8 MB" },
    { title: "Template Oficial de Diagramação (.drawio e .uml)", type: "archive", size: "180 KB" },
    { title: "Slides Aula 02: Diagrama de Classes e Multiplicidades", type: "pdf", size: "4.2 MB" },
    { title: "Slides Aula 03: Diagrama de Sequência e Cenários de Interação", type: "pdf", size: "2.9 MB" },
    { title: "Apostila Técnica: Padrões GRASP e Princípios SOLID", type: "pdf", size: "5.1 MB" },
    { title: "Repositório de Código: Padrões GoF Criacionais em TypeScript", type: "code", size: "14.2 MB" },
    { title: "Guia Arquitetural: Clean Architecture e Ports & Adapters", type: "pdf", size: "1.2 MB" },
    { title: "Slides: Arquitetura Hexagonal e Inversão de Dependência", type: "pdf", size: "4.8 MB" },
    { title: "Estudo de Caso de Microsserviços e Clean Architecture", type: "reading", size: "2.4 MB" },
    { title: "Template de Projeto em Camadas Limpas & Agregados de Domínio", type: "code", size: "14.5 MB" },
    { title: "Guia Prático: Modelagem de Agregados e Índices no MongoDB Atlas", type: "pdf", size: "3.1 MB" },
    { title: "Apostila: Resiliência com Circuit Breaker e Outbox Pattern", type: "pdf", size: "2.7 MB" },
    { title: "Videoaula: Autenticação Segura JWT e Controle de Sessão", type: "video", size: "1h 35min" },
    { title: "Lista de Exercícios: Arquitetura Resiliente e Zero-Trust", type: "pdf", size: "850 KB" },
    { title: "Apostila: Planos de Execução e Indexação B-Tree em SQL", type: "pdf", size: "3.4 MB" },
    { title: "Guia de Laboratório: MVCC e Isolamento Transacional", type: "pdf", size: "1.9 MB" },
    { title: "Artigo Técnico: Modelagem Documental e Aggregation Pipeline", type: "reading", size: "2.1 MB" },
    { title: "Videoaula: Pipelines de Agregação no MongoDB", type: "video", size: "1h 40min" },
    { title: "Caderno de Casos Práticos: Ética Algorítmica e Governança de IA", type: "pdf", size: "850 KB" },
    { title: "Texto Base: Privacidade por Padrão e Conformidade LGPD", type: "reading", size: "1.6 MB" },
    { title: "Videoaula: Epistemologia Cibernética e Sociedade em Rede", type: "video", size: "1h 25min" },
    { title: "Roteiro de Laboratório: Syscalls POSIX e Shell em C/Rust", type: "pdf", size: "1.8 MB" },
    { title: "Apostila: Sincronização de Processos, Deadlocks e Semáforos", type: "pdf", size: "3.3 MB" },
    { title: "Simulador de Memória Virtual Paginada (Python/Shell)", type: "code", size: "450 KB" },
    { title: "Artigo: Isolamento por Namespaces e Cgroups no Linux", type: "reading", size: "2.4 MB" },
    { title: "Formulário Oficial de Cálculo e Séries Numéricas", type: "pdf", size: "620 KB" },
    { title: "Notas de Aula: Limites, Derivadas e Regra da Cadeia", type: "pdf", size: "4.1 MB" },
    { title: "Lista Resolvida A1: Otimização de Funções com Gradiente", type: "pdf", size: "950 KB" },
    { title: "Diretrizes Oficiais da Banca do Projeto Integrador IV", type: "pdf", size: "510 KB" },
  ];

  for (let i = 0; i < materialTitles.length; i++) {
    const mat = materialTitles[i]!;
    const classCode = coreClasses[i % coreClasses.length]!;
    const teacher = teachers[i % teachers.length] ?? defaultTeacher;

    await upsertSync(
      "academic_materials",
      { classCode, title: mat.title },
      {
        classCode,
        title: mat.title,
        description: `Material oficial da disciplina sobre ${mat.title}.`,
        type: mat.type,
        fileName: `${mat.title.toLowerCase().replace(/[^a-z0-9]/g, "-")}.${mat.type === "code" ? "zip" : "pdf"}`,
        fileSize: mat.size,
        size: mat.size,
        uploadedBy: String(teacher._id),
        uploadedAt: now,
        downloadsCount: 15 + (i * 2),
        seedTag: SEED_TAG,
      },
    );
  }

  // 3. PELO MENOS 30 ATIVIDADES AVALIATIVAS (academic_assignments)
  const assignmentTemplates = [
    { key: "assign-aps-diagrama-uml", title: "Entrega do Diagrama de Casos de Uso e Especificação", weight: 2.0, stage: "N1" },
    { key: "assign-aps-estudo-caso", title: "Estudo de Caso 01: Arquitetura em Camadas vs Hexagonal", weight: 1.5, stage: "N1" },
    { key: "assign-aps-prototipo-orm", title: "Protótipo de Mapeamento Objeto-Relacional e Validação", weight: 2.5, stage: "N2" },
    { key: "assign-aps-artigo-pesquisa", title: "Artigo de Pesquisa: Microsserviços e Event-Driven", weight: 4.0, stage: "N2" },
    { key: "assign-pi4-api-rest", title: "Atividade Prática 03: Implementação de API REST com JWT", weight: 3.0, stage: "N1" },
    { key: "assign-pi4-nosql-model", title: "Modelagem de Agregados e Índices no MongoDB Atlas", weight: 2.0, stage: "N1" },
    { key: "assign-pi4-sprint-1", title: "Entrega da Sprint 1: Autenticação em 2 Fatores e Auditoria", weight: 2.5, stage: "N1" },
    { key: "assign-pi4-sprint-2", title: "Entrega da Sprint 2: Videochamada WebRTC e Ticket Efêmero", weight: 2.5, stage: "N2" },
    { key: "assign-pi4-banca-final", title: "Submissão Integrada da Banca: Código, Relatório e Deploy", weight: 5.0, stage: "N2" },
    { key: "assign-arq-adr-spec", title: "Especificação de Architecture Decision Records (ADRs)", weight: 2.0, stage: "N1" },
    { key: "assign-arq-clean-arch", title: "Refatoração de Monolito com Clean Architecture e DIP", weight: 3.0, stage: "N1" },
    { key: "assign-arq-outbox-resilience", title: "Implementação de Outbox Pattern com Garantia de Entrega", weight: 2.5, stage: "N2" },
    { key: "assign-arq-microservices-saga", title: "Projeto de Transação Distribuída com Padrão Saga", weight: 2.5, stage: "N2" },
    { key: "assign-bd2-sql-tuning", title: "Tuning SQL: Otimização de Consultas com EXPLAIN ANALYZE", weight: 2.0, stage: "N1" },
    { key: "assign-bd2-mvcc-concurrency", title: "Simulação de Anomalias Transacionais e Concorrência MVCC", weight: 2.0, stage: "N1" },
    { key: "assign-bd2-nosql-pipeline", title: "Construção de Aggregation Pipelines para Análise de Dados", weight: 3.0, stage: "N2" },
    { key: "assign-bd2-sharding-replica", title: "Configuração de Replica Set e Política de Sharding", weight: 3.0, stage: "N2" },
    { key: "assign-fis-ensaio-etica-ia", title: "Ensaio Crítico: Ética na Inteligência Artificial e Viés", weight: 2.5, stage: "N1" },
    { key: "assign-fis-debate-privacidade", title: "Fórum Avaliativo: Privacidade por Padrão e Vigilância", weight: 2.5, stage: "N1" },
    { key: "assign-fis-ripd-lgpd", title: "Elaboração de Relatório de Impacto à Proteção de Dados (RIPD)", weight: 5.0, stage: "N2" },
    { key: "assign-fso-shell-posix", title: "Laboratório 01: Desenvolvimento de Mini-Shell POSIX", weight: 2.0, stage: "N1" },
    { key: "assign-fso-thread-sync", title: "Sincronização de Threads com Mutex e Semáforos", weight: 3.0, stage: "N1" },
    { key: "assign-fso-mem-virtual", title: "Simulador de Gerenciamento de Memória Virtual e Páginas", weight: 2.5, stage: "N2" },
    { key: "assign-fso-containers-ns", title: "Laboratório Prático: Mini-Contêiner com Namespaces Linux", weight: 2.5, stage: "N2" },
    { key: "assign-mat-lista-derivadas", title: "Lista Avaliativa 01: Derivadas e Regra da Cadeia", weight: 2.5, stage: "N1" },
    { key: "assign-mat-otimizacao-grad", title: "Problemas de Otimização Não-Linear com Gradiente", weight: 2.5, stage: "N1" },
    { key: "assign-mat-integrais-mult", title: "Cálculo de Integrais Definidas Aplicadas a Modelos", weight: 2.5, stage: "N2" },
    { key: "assign-mat-series-converg", title: "Análise de Convergência de Séries Infinitas", weight: 2.5, stage: "N2" },
    { key: "assign-tqs-testes-unitarios", title: "Cobertura de Testes de Unidade com TDD e Mocks", weight: 3.0, stage: "N1" },
    { key: "assign-red-captura-wireshark", title: "Análise de Protocolos de Rede TCP/UDP com Wireshark", weight: 2.0, stage: "N1" },
  ];

  for (let i = 0; i < assignmentTemplates.length; i++) {
    const asg = assignmentTemplates[i]!;
    const classCode = coreClasses[i % coreClasses.length]!;
    const teacher = teachers[i % teachers.length] ?? defaultTeacher;

    const dueDate = new Date(Date.UTC(2026, 8 + Math.floor(i / 15), 15 + (i % 15), 23, 59, 0));
    const lowerTitle = asg.title.toLowerCase();
    const activityType = lowerTitle.includes("fórum") || lowerTitle.includes("forum")
      ? "forum"
      : lowerTitle.includes("atividade prática") || lowerTitle.includes("laboratório") || lowerTitle.includes("protótipo")
        ? "atividade_pratica"
        : lowerTitle.includes("lista") || lowerTitle.includes("avaliação") || lowerTitle.includes("tuning")
          ? "avaliacao_parcial"
          : "entrega";
    const typeLabel = activityType === "forum"
      ? "Fórum Temático"
      : activityType === "atividade_pratica"
        ? "Atividade Prática"
        : activityType === "avaliacao_parcial"
          ? "Avaliação Parcial"
          : "Entrega";
    const dueHour = i % 4 === 1 ? "18:00" : i % 4 === 3 ? "20:40" : "23:59";
    const isUrgent = i % 4 < 2;

    await upsertSync(
      "academic_assignments",
      { seedKey: asg.key },
      {
        seedKey: asg.key,
        classCode,
        moduleTag: `MÓDULO ${(i % 4) + 1}`,
        activityType,
        typeLabel,
        title: asg.title,
        description: `Submeter atividade avaliativa sobre ${asg.title} conforme rubrica técnica.`,
        dueDate,
        dueDateFormatted: dueDate.toLocaleDateString("pt-BR"),
        dueHour,
        isUrgent,
        weight: asg.weight,
        stage: asg.stage,
        modality: i % 3 === 0 ? "Equipe" : "Individual",
        allowLateWithPenalty: true,
        rubricCriteria: [
          {
            id: "rc-1",
            title: "Domínio Técnico e Implementação",
            maxPoints: 4.0,
            description: "Correção conceitual, funcionalidade completa e aderência ao enunciado.",
          },
          {
            id: "rc-2",
            title: "Qualidade Estrutural e Organização",
            maxPoints: 3.5,
            description: "Clareza arquitetural, boas práticas e legibilidade da entrega.",
          },
          {
            id: "rc-3",
            title: "Documentação e Fundamentação",
            maxPoints: 2.5,
            description: "Justificativas técnicas, evidências de execução e apresentação.",
          },
        ],
        createdBy: String(teacher._id),
        createdAt: now,
        updatedAt: now,
        seedTag: SEED_TAG,
      },
    );
  }

  // 4. PELO MENOS 30 TÓPICOS DE FÓRUNS ACADÊMICOS (academic_forum_topics)
  const forumTopicTitles = [
    "Dúvidas sobre o Padrão GRASP Especialista na Informação",
    "Como estruturar Agregados de Domínio sem acoplamento a ORM",
    "Debate: Circuit Breaker vs Retry com Backoff Exponencial",
    "Melhores práticas para modelar índices compostos no MongoDB Atlas",
    "Diferença prática entre Isolamento Read Committed e Serializable",
    "Impacto da LGPD na retenção de logs estruturados e auditoria",
    "Estratégia de Invalidação de Cache com Redis em Microsserviços",
    "Dúvidas na Implementação do Handshake WebSocket com Ticket SHA-256",
    "Padrão Outbox Transacional: Polling vs Change Streams",
    "Trade-offs entre WebRTC P2P e SFU (Selective Forwarding Unit)",
    "Dificuldades no Cálculo do Gradiente em Otimização Numérica",
    "Deadlocks em Threads POSIX: Como evitar inversão de prioridade",
    "Como modelar Diagrama de Sequência para Fluxos Alternativos",
    "TDD no Desenvolvimento de Camadas de Domínio Limpas",
    "Diferenças entre Monolito Modular e Microsserviços distribuídos",
    "Contratos de API REST: JSON Schema vs Zod vs OpenAPI",
    "Discussão sobre Explicabilidade e Viés Algorítmico em IA",
    "Simulação de Page Faults em Sistemas Operacionais com Memória Virtual",
    "Estratégias de versionamento de rotas em APIs corporativas",
    "Configuração de Servidores DNS para MongoDB Atlas (querySrv)",
    "Implementação de Rate Limiting com Janela Deslizante",
    "Boas práticas para nomes de commits e convenção SemVer",
    "Dúvidas sobre o Regulamento e Critérios da Banca do PI-IV",
    "Tratamento de Exceções sem Vazamento de Detalhes Internos",
    "Segurança da Informação: Prevenção contra Timing Attacks em OTP",
    "Discussão: Arquitetura Orientada a Eventos com RabbitMQ/Kafka",
    "Modelagem de Entidades de Domínio com Identificadores Fortes (UUID/ObjectId)",
    "Organização de Sprints Ágeis e Revisão de Pull Requests",
    "Dicas de Leitura: Livro Clean Architecture de Robert C. Martin",
    "Plantão de Dúvidas Geral para a Avaliação A1",
  ];

  for (let i = 0; i < forumTopicTitles.length; i++) {
    const title = forumTopicTitles[i]!;
    const classCode = coreClasses[i % coreClasses.length]!;
    const teacher = teachers[i % teachers.length] ?? defaultTeacher;

    const topicBody = `Tópico de discussão acadêmica aberto sobre "${title}". Participem com perguntas e reflexões.`;
    await upsertSync(
      "academic_forum_topics",
      { classCode, title },
      {
        classCode,
        title,
        content: topicBody,
        body: topicBody,
        authorIdentity: teacher.identity,
        authorName: teacher.displayName,
        authorProfile: "docente",
        repliesCount: (i % 8) + 2,
        createdAt: now,
        updatedAt: now,
        seedTag: SEED_TAG,
      },
    );
  }

  return summary;
}

export const teacherSeed: SeedModule = {
  id: "teacher",
  name: "04-teacher",
  description: "Popula 35+ diários de aula, 30+ materiais, 30+ tarefas avaliativas e 30+ fóruns de discussão",
  execute: seedTeacher,
};
