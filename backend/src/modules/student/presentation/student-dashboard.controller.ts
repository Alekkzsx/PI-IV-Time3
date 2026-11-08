// Desenvolvido por: Rafael Henrique dos Santos Inácio
import { Router } from "express";
import type { Db } from "mongodb";
import { z } from "zod";
import { AuthError } from "../../../shared/auth-error.js";
import { parse } from "../../../shared/validation.js";
import { authenticated } from "../../auth/infrastructure/session.middleware.js";
import { StudentDashboardService } from "../application/index.js";
import type { UnifiedEmailService } from "../../notifications/domain/notification.types.js";

export { createFilesRouter } from "./student-files.controller.js";

export function createStudentDashboardRouter(
  database: Db,
  jwtSecret: string,
  emailService?: UnifiedEmailService,
): Router {
  const router = Router();
  const service = new StudentDashboardService(database, emailService);

  router.use(authenticated(database, jwtSecret, false));
  router.use((_request, response, next) => {
    if (response.locals.user?.profile !== "aluno") {
      next(new AuthError(403, "student_access_required", "Acesso permitido somente a estudantes."));
      return;
    }
    next();
  });

  router.get("/bootstrap", async (_request, response) => {
    const data = await service.getBootstrap(
      response.locals.userId,
      response.locals.user,
      response.locals.sessionId,
    );
    response.json(data);
  });

  router.get("/dashboard", async (_request, response) => {
    const data = await service.getDashboardOverview(response.locals.userId, response.locals.user);
    response.json(data);
  });

  router.get("/timeline", async (request, response) => {
    const customNow = typeof request.query.now === "string" ? new Date(request.query.now) : undefined;
    const data = await service.getTimeline(response.locals.userId, customNow);
    response.json(data);
  });

  router.get("/disciplines", async (_request, response) => {
    const data = await service.getStudentDisciplines(response.locals.userId, response.locals.user);
    response.json(data);
  });

  router.get("/boletim", async (_request, response) => {
    const data = await service.getStudentBoletim(response.locals.userId, response.locals.user);
    response.json(data);
  });

  router.get("/deliveries", async (_request, response) => {
    const data = await service.getStudentDeliveries(response.locals.userId, response.locals.user);
    response.json(data);
  });

  router.post("/deliveries/:assignmentId/submit", async (request, response) => {
    const body = parse(
      z.object({
        fileName: z.string().trim().min(1).max(240),
        mimeType: z.string().trim().max(120).optional(),
        fileSize: z.string().trim().max(40).optional(),
        contentBase64: z.string().max(12_000_000).optional(),
        gitUrl: z.string().trim().max(400).optional(),
        comments: z.string().trim().max(3000).optional(),
      }).strict(),
      request.body,
    );
    const receipt = await service.submitDelivery(
      response.locals.userId,
      response.locals.user,
      request.params.assignmentId!,
      body,
    );
    response.status(201).json(receipt);
  });

  router.post("/assignments/:assignmentId/doubts", async (request, response) => {
    const body = parse(z.object({ question: z.string().trim().min(2).max(2000) }).strict(), request.body);
    const created = await service.postAssignmentDoubt(
      response.locals.userId,
      response.locals.user,
      request.params.assignmentId!,
      body.question,
    );
    response.status(201).json(created);
  });

  router.post("/calendar/reminders", async (request, response) => {
    const body = parse(
      z.object({
        title: z.string().trim().min(2).max(160),
        date: z.string().trim().min(4).max(60),
        timeRange: z.string().trim().max(60).optional(),
        courseCode: z.string().trim().max(60).optional(),
        location: z.string().trim().max(160).optional(),
      }).strict(),
      request.body,
    );
    const created = await service.addReminder(response.locals.userId, body);
    response.status(201).json(created);
  });

  router.patch("/messages/:id/read", async (request, response) => {
    const result = await service.markMessageRead(response.locals.userId, request.params.id!);
    response.json(result);
  });

  router.post("/messages/read-all", async (_request, response) => {
    const result = await service.markAllMessagesRead(response.locals.userId);
    response.json(result);
  });

  router.post("/protocols", async (request, response) => {
    const body = parse(
      z.object({
        requestType: z.string().trim().min(2).max(160),
        targetComponent: z.string().trim().max(120).default("Geral"),
        justification: z.string().trim().min(5).max(3000),
        attachmentName: z.string().trim().max(240).optional(),
        attachmentBase64: z.string().max(12_000_000).optional(),
      }).strict(),
      request.body,
    );
    const created = await service.submitProtocol(
      response.locals.userId,
      response.locals.user,
      body,
    );
    response.status(201).json(created);
  });

  router.post("/enrollment-declaration", async (_request, response) => {
    parse(z.object({}).strict(), _request.body);
    const declaration = await service.issueEnrollmentDeclaration(
      response.locals.userId,
      response.locals.user,
    );
    response.status(201).json(declaration);
  });

  router.put("/disciplines/:classCode/notes", async (request, response) => {
    const body = parse(z.object({ content: z.string().max(20_000) }).strict(), request.body);
    const result = await service.savePersonalNote(
      response.locals.userId,
      request.params.classCode!,
      body.content,
    );
    response.json(result);
  });

  router.post("/disciplines/:classCode/forum", async (request, response) => {
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

  router.post("/disciplines/:classCode/forum/:topicId/reply", async (request, response) => {
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

  return router;
}
