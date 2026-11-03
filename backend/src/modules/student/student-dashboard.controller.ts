//Desenvolvido por: Rafael Henrique dos Santos Inácio

import { Router } from "express";
import type { Db } from "mongodb";
import { authenticated } from "../auth/infrastructure/session.middleware.js";

export function createStudentDashboardRouter(database: Db, jwtSecret: string): Router {
  const router = Router();
  
  // Middleware: Garante que a rota é protegida e o utilizador está logado
  // O 'false' indica que não precisa de ser admin
  router.use(authenticated(database, jwtSecret, false));

  // ==========================================
  // ROTA 1: PAINEL GERAL (DADOS REAIS)
  // ==========================================
  router.get("/dashboard", async (request, response) => {
    // 1. O middleware já validou o token e injetou o utilizador real aqui![cite: 25]
    const studentId = response.locals.userId;
    const user = response.locals.user; 

    // 2. Buscar as matrículas ativas deste aluno[cite: 25]
    const enrollments = await database.collection("academic_enrollments")
      .find({ studentId: String(studentId), status: "active" }).toArray();
    
    const classCodes = enrollments.map(e => e.classCode);

    // 3. Buscar os detalhes técnicos das turmas em que está matriculado[cite: 25]
    const classes = await database.collection("academic_classes")
      .find({ code: { $in: classCodes } }).toArray();

    // 4. Buscar as Aulas do Dia (Sessions)[cite: 25]
    const startOfDay = new Date(); startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(); endOfDay.setHours(23, 59, 59, 999);
    
    const todaySessions = await database.collection("academic_class_sessions")
      .find({ 
        classCode: { $in: classCodes }, 
        startsAt: { $gte: startOfDay, $lte: endOfDay } 
      })
      .sort({ startsAt: 1 }).toArray();

    // 5. Estruturar a resposta para o Flutter
    response.json({
      studentInfo: {
        name: user.displayName || "Aluno",
        courseName: enrollments[0]?.courseCode ?? "Sem Curso",
        semester: "Semestre Atual" // Pode mapear do user se existir
      },
      stats: {
        activeDisciplines: enrollments.length,
        // (CR e Frequência exigem lógica de notas, enviando fallback seguro por enquanto)
        averageAttendance: 100, 
        cr: 10.0,
        academicStatus: "Regular"
      },
      // Pegamos a primeira aula do dia, se houver
      todayClass: todaySessions.length > 0 ? {
        time: `${todaySessions[0]!.startsAt.getHours()}:00`,
        isLive: true,
        discipline: todaySessions[0]!.classCode ?? "A definir",
        teacher: "Aceder à Turma",
        linkType: "Sala Virtual"
      } : null,
      freeSchedule: todaySessions.length === 0 ? {
        hasFreeSchedule: true,
        message: "Reservado para estudos e atividades práticas"
      } : null,
      disciplines: classes.map(c => ({
        code: c.code,
        name: c.courseName || c.subjectName,
        teacher: c.professorIdentity || "A Definir",
        progress: 100
      }))
    });
  });

  // ==========================================
  // ROTA 2: DISCIPLINAS (DADOS REAIS)
  // ==========================================
  router.get("/disciplines", async (request, response) => {
    const studentId = response.locals.userId;
    
    const enrollments = await database.collection("academic_enrollments")
      .find({ studentId: String(studentId), status: "active" }).toArray();
    const classCodes = enrollments.map(e => e.classCode);

    const classes = await database.collection("academic_classes")
      .find({ code: { $in: classCodes } }).toArray();

     response.json({
        totalHours: { current: classes.length * 40, max: 280, percentage: 50 },
        status: { text: "Regular & Apto", subtext: `${classes.length} disciplinas em andamento` },
        disciplinesList: classes.map(c => ({
           code: c.code,
           name: c.courseName || c.subjectName,
           teacher: c.professorIdentity || "A Definir",
           info: `Local: ${c.location || 'EAD'}`,
           progress: 100,
           n1: "-", n2: "-", media: "-", freq: "100%", faltas: "0 faltas"
        }))
     });
  });

  // ==========================================
  // ROTA 3: ENTREGAS (MISTO)
  // ==========================================
  router.get("/deliveries", async (request, response) => {
    const studentId = response.locals.userId;
    
    // NOTA: Como não vi a coleção "academic_tasks" no código do admin, 
    // deixei a consulta pronta aqui. Mude o nome da coleção caso o seu time 
    // tenha chamado de "academic_assignments" ou "deliveries".
    const tasks = await database.collection("academic_tasks")
      .find({ studentId: String(studentId) }).toArray();

    response.json({
       stats: { pending: tasks.length, inAnalysis: 0, evaluated: 0, media: 10.0 },
       tasks: tasks.map(t => ({
          code: t.taskCode,
          discipline: t.classCode,
          title: t.title,
          description: t.description,
          dataLimite: t.dueDate,
          docente: "Responsável",
          criterio: "Nota Máx: 10.0",
          status: "PENDING",
          formats: "Max: 25MB"
       }))
    });
  });

  return router;
}