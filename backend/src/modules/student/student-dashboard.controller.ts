// backend/src/modules/student/student-dashboard.controller.ts

import { Router, type RequestHandler } from "express";
import { type Db, type Document } from "mongodb";
import { AuthError } from "../../shared/auth-error.js";
import { authenticated } from "../auth/infrastructure/session.middleware.js";

// Middleware genérico para garantir que é um Aluno e injetar o studentId
export function studentOnly(jwtSecret: string, database: Db): RequestHandler {
  return authenticated(database, jwtSecret, false);
}

export function createStudentDashboardRouter(database: Db, jwtSecret: string): Router {
  const router = Router();
  
  // Exige token de aluno para todas as rotas abaixo
  router.use(studentOnly(jwtSecret, database));
  
  // Atalho para extrair o ID do estudante a partir do token
  const getStudentId = (response: { locals: Record<string, any> }) => response.locals.userId as string;

  // ==========================================
  // ROTA 1: PAINEL GERAL (/api/student/dashboard)
  // ==========================================
  router.get("/dashboard", async (request, response) => {
    // const studentId = getStudentId(response);
    
    // Dados mockados baseados no protótipo "Painel Geral"
    response.json({
      studentInfo: {
        name: "Gabriel",
        courseName: "Engenharia de Software",
        semester: "5º Semestre"
      },
      stats: {
        activeDisciplines: 4,
        averageAttendance: 94.8,
        monthlyDeliveries: 4,
        nextDelivery: "Hoje, 23:59",
        cr: 8.8,
        academicStatus: "Regular",
        complementaryHours: 140,
        totalComplementaryHours: 180,
        hoursProgress: 77.7
      },
      todayClass: {
        time: "19:00 - 20:40",
        isLive: true,
        discipline: "Análise e Projeto de Sistemas II",
        teacher: "Profa. Dra. Helena Bittencourt",
        linkType: "Teams Link"
      },
      freeSchedule: {
        hasFreeSchedule: true,
        message: "Reservado para estudos e atividades práticas"
      },
      disciplines: [
        { code: "218131 - APS-II", name: "Análise e Projeto de Sistemas II", teacher: "Profa. Dra. Helena Bittencourt", progress: 68 },
        { code: "218131 - BD-II", name: "Estudos de Banco de Dados II", teacher: "Profa. Dra. Helena Bittencourt", progress: 75 },
        { code: "218131 - FIS", name: "Filosofia, Informação e Sociedade", teacher: "Prof. Dr. Marcos Vinícius Ferreira", progress: 82 },
        { code: "218131 - FSO", name: "Fundamentos de Sistemas Operacionais", teacher: "Prof. Esp. André Luiz Silveira", progress: 54 }
      ],
      pendingDeadlines: {
        count: 4,
        tasks: [
          { title: "Entrega: Diagrama de Classes e Se...", discipline: "Análise e Projeto de Sistemas II", time: "Hoje, 20/09 às 23:59" },
          { title: "Fórum Temático: Ética na Inteligên...", discipline: "Filosofia, Informação e Sociedade", time: "Amanhã, 21/09 às 18:00" },
          { title: "Atividade Prática: Modelagem Rel...", discipline: "Estudos de Banco de Dados II", time: "Quinta, 24/09 às 23:59" },
          { title: "Avaliação Parcial: Gerenciamento ...", discipline: "Fundamentos de Sistemas Operacionais", time: "Terça, 29/09 às 20:40" }
        ]
      },
      notices: [
        { sender: "Prof. Carlos Eduardo (APS-II)", time: "Hoje, 14:10", title: "Feedback da Sprint 1 e Orientações para o Diagrama UML", preview: "Prezados alunos, os apontamentos da primeira etapa do projeto de sistemas já..." },
        { sender: "Profª. Eliane Ramos (BD-II)", time: "Ontem, 17:45", title: "Material de Apoio: Normalização em 3FN e BCNF", preview: "Disponibilizei os slides com os exercícios resolvidos em aula sobre dependências..." },
        { sender: "Secretaria Acadêmica AGMRM", time: "18 de set", title: "Prazo para Validação de Atividades Complementares 2026/2", preview: "Lembramos a todos os estudantes que o envio de certificados de cursos e palestras..." }
      ]
    });
  });

  // ==========================================
  // ROTA 2: DISCIPLINAS (/api/student/disciplines)
  // ==========================================
  router.get("/disciplines", async (request, response) => {
     response.json({
        totalHours: { current: 190, max: 280, percentage: 68 },
        cr: { value: 8.63, status: "Aprovado em todas", min: 6.0 },
        attendance: { value: 95.7, subtitle: "Excelente assiduidade presencial", misses: 12 },
        status: { text: "Regular & Apto", subtext: "4 disciplinas em andamento" },
        disciplinesList: [
           { code: "218131 - APS-II", name: "Análise e Projeto de Sistemas II", teacher: "Profa. Dra. Helena Bittencourt", info: "Lab 04 - Bloco C (Noturno) • Segundas-feiras, 19:00 às 22:30", progress: 68, n1: 8.5, n2: 9.0, media: 8.8, pendingTask: "1 tarefa pendente", freq: "Freq. 97.5%", faltas: "2 faltas (limite: 20h)" },
           // (adicione as outras aqui...)
        ]
     });
  });

  // ==========================================
  // ROTA 3: ENTREGAS (/api/student/deliveries)
  // ==========================================
  router.get("/deliveries", async (request, response) => {
    response.json({
       stats: { pending: 4, inAnalysis: 2, evaluated: 3, media: 9.7 },
       tasks: [
          { code: "APS-ATV-04", discipline: "Análise e Projeto de Sistemas II", title: "Modelagem de Domínio e Diagramas de Casos de Uso com Padrões GoF", description: "Elaboração de documento técnico...", dataLimite: "02 de Outubro, 23:59", docente: "Profa. Dra. Helena Bittencourt", criterio: "Peso 2.5 • Nota Máx: 10.0", status: "PENDING_URGENT", formats: ".pdf, .zip • Max: 25MB" }
       ]
    });
  });

  return router;
}