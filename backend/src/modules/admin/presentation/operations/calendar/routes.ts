// Desenvolvido por Guilherme Henrique Moreira
import type { Router } from "express";
import type { Db } from "mongodb";
import { z } from "zod";
import { AuthError } from "../../../../../shared/auth-error.js";
import { objectId, parse } from "../../../../../shared/validation.js";
import { adminWrite, audit, publicRecord } from "../../../infrastructure/admin-support.js";

const eventSchema = z.object({
  title: z.string().trim().min(2).max(160),
  startsAt: z.string().datetime({ offset: true }),
  endsAt: z.string().datetime({ offset: true }).nullable().optional(),
  type: z.enum(["academic", "deadline", "holiday"]).default("academic"),
  statusLabel: z.string().trim().max(40).optional(),
  description: z.string().trim().max(2000).default(""),
}).strict();

export function registerAdminCalendarRoutes(router: Router, database: Db): void {
  router.get("/calendar", async (_request, response) => {
    response.json(
      (await database.collection("academic_calendar").find({}).sort({ startsAt: 1 }).limit(500).toArray())
        .map(publicRecord),
    );
  });

  router.post("/calendar", async (request, response) => {
    const input = parse(eventSchema, request.body);
    if (input.endsAt && new Date(input.endsAt) < new Date(input.startsAt)) {
      throw new AuthError(400, "invalid_dates", "Término anterior ao início.");
    }
    const record = await adminWrite(database, response.locals.adminId, async (session) => {
      const data = {
        ...input,
        startsAt: new Date(input.startsAt),
        endsAt: input.endsAt ? new Date(input.endsAt) : null,
        createdAt: new Date(),
        createdBy: response.locals.adminId,
      };
      const inserted = await database.collection("academic_calendar").insertOne(data, { session });
      await audit(database, response.locals.adminId, "calendar_event_created", String(inserted.insertedId), {}, session);
      return publicRecord({ _id: inserted.insertedId, ...data });
    });
    response.status(201).json(record);
  });

  router.patch("/calendar/:id", async (request, response) => {
    const id = objectId(request.params.id);
    const input = parse(eventSchema.partial().refine((value) => Object.keys(value).length > 0), request.body);
    const record = await adminWrite(database, response.locals.adminId, async (session) => {
      const current = await database.collection("academic_calendar").findOne({ _id: id }, { session });
      if (!current) throw new AuthError(404, "event_not_found", "Marco do calendário não encontrado.");
      const startsAt = input.startsAt ? new Date(input.startsAt) : current.startsAt;
      const endsAt = input.endsAt === undefined ? current.endsAt : input.endsAt ? new Date(input.endsAt) : null;
      if (endsAt && endsAt < startsAt) throw new AuthError(400, "invalid_dates", "Término anterior ao início.");
      const updated = await database.collection("academic_calendar").findOneAndUpdate(
        { _id: id },
        { $set: { ...input, startsAt, endsAt, updatedAt: new Date() } },
        { session, returnDocument: "after" },
      );
      await audit(database, response.locals.adminId, "calendar_event_updated", String(id), {}, session);
      return publicRecord(updated!);
    });
    response.json(record);
  });

  router.delete("/calendar/:id", async (request, response) => {
    const id = objectId(request.params.id);
    await adminWrite(database, response.locals.adminId, async (session) => {
      const deleted = await database.collection("academic_calendar").deleteOne({ _id: id }, { session });
      if (!deleted.deletedCount) throw new AuthError(404, "event_not_found", "Marco do calendário não encontrado.");
      await audit(database, response.locals.adminId, "calendar_event_deleted", String(id), {}, session);
    });
    response.status(204).end();
  });
}