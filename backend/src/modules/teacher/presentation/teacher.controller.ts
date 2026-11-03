// Desenvolvido por Murillo Caravita - RA: 25014012
import { Router, type RequestHandler } from "express";
import type { Db } from "mongodb";
import { z } from "zod";
import { AuthError } from "../../../shared/auth-error.js";
import { parse } from "../../../shared/validation.js";
import { authenticated } from "../../auth/infrastructure/session.middleware.js";
import { TeacherService } from "../application/index.js";

function teacherOrAdmin(): RequestHandler {
  return (_request, response, next) => {
    const profile = response.locals.user?.profile;
    if (profile !== "docente" && profile !== "admin") {
      next(new AuthError(403, "forbidden", "Acesso restrito ao corpo docente ou administração."));
      return;
    }
    next();
  };
}

export function createTeacherRouter(database: Db, jwtSecret: string): Router {
  const router = Router();
  const service = new TeacherService(database);

  router.use(authenticated(database, jwtSecret, false));
  router.use(teacherOrAdmin());

  router.get("/bootstrap", async (_request, response) => {
    const data = await service.getBootstrap(
      response.locals.userId,
      response.locals.user,
      response.locals.sessionId,
    );
    response.json(data);
  });

  router.post("/courses/:classCode/sessions", async (request, response) => {
    const body = parse(
      z.object({
        date: z.string().trim().min(4).max(60),
        hours: z.number().int().min(1).max(8).optional(),
      }).strict(),
      request.body,
    );
    const created = await service.createOrSelectSessionByDate(
      response.locals.userId,
      response.locals.user,
      request.params.classCode!,
      body.date,
      body.hours ?? 2,
    );
    response.status(created.created ? 201 : 200).json(created);
  });

  router.patch("/sessions/:sessionId", async (request, response) => {
    const body = parse(
      z.object({
        contentProgram: z.string().max(4000).optional(),
        methodology: z.string().max(2000).optional(),
        location: z.string().max(200).optional(),
        isHomologated: z.boolean().optional(),
        attendanceList: z
          .array(
            z.object({
              studentId: z.string().min(1).max(120),
              ra: z.string().max(120),
              name: z.string().max(160),
              status: z.enum(["presente", "ausente", "justificada"]),
              observation: z.string().max(500).optional(),
            }),
          )
          .max(500)
          .optional(),
      }).strict(),
      request.body,
    );
    const updated = await service.updateSessionAttendance(
      response.locals.userId,
      response.locals.user,
      request.params.sessionId!,
      body,
    );
    response.json(updated);
  });

  router.patch("/courses/:classCode/syllabus/:unitId", async (request, response) => {
    const result = await service.advanceSyllabusUnit(
      response.locals.userId,
      response.locals.user,
      request.params.classCode!,
      request.params.unitId!,
    );
    response.json(result);
  });

  router.post("/courses/:classCode/materials", async (request, response) => {
    const body = parse(
      z.object({
        title: z.string().trim().min(2).max(200),
        fileName: z.string().trim().max(200).optional(),
        mimeType: z.string().trim().max(120).optional(),
        size: z.string().trim().max(40).optional(),
        type: z.string().trim().max(20).optional(),
        unitAssociated: z.string().trim().max(80).optional(),
        contentBase64: z.string().max(12_000_000).optional(),
      }).strict(),
      request.body,
    );
    const created = await service.publishMaterial(
      response.locals.userId,
      response.locals.user,
      request.params.classCode!,
      body,
    );
    response.status(201).json(created);
  });

  router.post("/courses/:classCode/assignments", async (request, response) => {
    const body = parse(
      z.object({
        title: z.string().trim().min(2).max(160),
        description: z.string().trim().max(4000).optional(),
        weight: z.number().min(0.1).max(10),
        stage: z.string().trim().min(1).max(20),
        dueDate: z.string().trim().max(60).optional(),
        dueDateFormatted: z.string().trim().min(2).max(80),
        modality: z.string().trim().min(2).max(80),
        allowLateWithPenalty: z.boolean(),
        rubricCriteria: z
          .array(
            z.object({
              id: z.string().max(60).optional(),
              title: z.string().trim().min(1).max(160),
              maxPoints: z.number().min(0.1).max(10),
              description: z.string().max(500).optional(),
            }),
          )
          .max(20),
      }).strict(),
      request.body,
    );
    const created = await service.createAssignment(
      response.locals.userId,
      response.locals.user,
      request.params.classCode!,
      body,
    );
    response.status(201).json(created);
  });

  router.patch("/assignments/:assignmentId/evaluate", async (request, response) => {
    const body = parse(
      z.object({
        studentId: z.string().trim().min(1).max(120),
        calculatedGrade: z.number().min(0).max(10),
        feedback: z.string().trim().max(4000),
        evaluatedCriteria: z
          .array(
            z.object({
              id: z.string().max(60),
              title: z.string().max(160),
              maxPoints: z.number().min(0).max(10),
              assignedScore: z.number().min(0).max(10),
              description: z.string().max(500).optional(),
            }),
          )
          .max(20),
      }).strict(),
      request.body,
    );
    const result = await service.evaluateSubmission(
      response.locals.userId,
      response.locals.user,
      request.params.assignmentId!,
      body,
    );
    response.json(result);
  });

  router.post("/assignments/:assignmentId/doubts/:doubtId/reply", async (request, response) => {
    const body = parse(z.object({ reply: z.string().trim().min(1).max(2000) }).strict(), request.body);
    const result = await service.replyAssignmentDoubt(
      response.locals.userId,
      response.locals.user,
      request.params.assignmentId!,
      request.params.doubtId!,
      body.reply,
    );
    response.json(result);
  });

  router.patch("/courses/:classCode/grades/:studentId", async (request, response) => {
    const body = parse(
      z
        .object({
          assignmentsScore: z.number().min(0).max(10).optional(),
          p1Score: z.number().min(0).max(10).optional(),
          projectsScore: z.number().min(0).max(10).optional(),
          p2Score: z.number().min(0).max(10).optional(),
        })
        .strict()
        .refine((v) => Object.keys(v).length > 0),
      request.body,
    );
    const result = await service.updateStudentGrade(
      response.locals.userId,
      response.locals.user,
      request.params.classCode!,
      request.params.studentId!,
      body,
    );
    response.json(result);
  });

  router.post("/courses/:classCode/grades/homologate", async (request, response) => {
    const result = await service.homologateClassGrades(
      response.locals.userId,
      response.locals.user,
      request.params.classCode!,
    );
    response.json(result);
  });

  router.post("/courses/:classCode/grades/rectify", async (request, response) => {
    const body = parse(
      z.object({
        studentId: z.string().trim().min(1).max(120),
        stage: z.string().trim().min(1).max(40),
        newScore: z.number().min(0).max(10),
        justification: z.string().trim().min(3).max(2000),
      }).strict(),
      request.body,
    );
    const result = await service.requestGradeRectification(
      response.locals.userId,
      response.locals.user,
      request.params.classCode!,
      body,
    );
    response.json(result);
  });

  router.post("/courses/:classCode/forum", async (request, response) => {
    const body = parse(
      z.object({
        title: z.string().trim().min(2).max(160),
        body: z.string().trim().min(2).max(4000),
        category: z.string().trim().max(60).optional(),
      }).strict(),
      request.body,
    );
    const created = await service.createForumTopic(
      response.locals.userId,
      response.locals.user,
      request.params.classCode!,
      body,
    );
    response.status(201).json(created);
  });

  router.post("/courses/:classCode/forum/:topicId/reply", async (request, response) => {
    const body = parse(z.object({ body: z.string().trim().min(1).max(3000) }).strict(), request.body);
    const created = await service.replyForumTopic(
      response.locals.userId,
      response.locals.user,
      request.params.classCode!,
      request.params.topicId!,
      body.body,
    );
    response.status(201).json(created);
  });

  router.put("/courses/:classCode/squads", async (request, response) => {
    const body = parse(
      z.object({
        squads: z
          .array(
            z.object({
              id: z.string().max(60).optional(),
              name: z.string().trim().min(2).max(100),
              projectTitle: z.string().trim().min(2).max(160),
              repoUrl: z.string().trim().max(300).optional(),
              members: z.array(z.string().max(120)).max(20),
            }),
          )
          .max(50),
      }).strict(),
      request.body,
    );
    const saved = await service.saveClassSquads(
      response.locals.userId,
      response.locals.user,
      request.params.classCode!,
      body.squads,
    );
    response.json(saved);
  });

  router.post("/events", async (request, response) => {
    const body = parse(
      z.object({
        title: z.string().trim().min(2).max(160),
        date: z.string().trim().min(2).max(40),
        time: z.string().trim().min(2).max(40),
        type: z.string().trim().min(2).max(40),
        location: z.string().trim().min(2).max(160),
      }).strict(),
      request.body,
    );
    const created = await service.createEvent(response.locals.userId, body);
    response.status(201).json(created);
  });

  router.post("/notices", async (request, response) => {
    const body = parse(
      z.object({
        targetCourse: z.string().trim().min(1).max(120),
        targetAudience: z.string().trim().min(1).max(120),
        classification: z.string().trim().min(1).max(40),
        title: z.string().trim().min(2).max(160),
        message: z.string().trim().min(2).max(5000),
      }).strict(),
      request.body,
    );
    const created = await service.publishNotice(
      response.locals.userId,
      response.locals.user,
      body,
    );
    response.status(201).json(created);
  });

  router.get("/notices/:id/reads", async (request, response) => {
    const reads = await service.getNoticeReads(
      response.locals.userId,
      response.locals.user,
      request.params.id!,
    );
    response.json(reads);
  });

  return router;
}
