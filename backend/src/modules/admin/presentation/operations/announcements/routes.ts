// Desenvolvido por Guilherme Henrique Moreira
import type { Router } from "express";
import { ObjectId, type Db, type Document } from "mongodb";
import { z } from "zod";
import { AuthError } from "../../../../../shared/auth-error.js";
import { parse } from "../../../../../shared/validation.js";
import { adminWrite, audit, publicRecord } from "../../../infrastructure/admin-support.js";

export function registerAdminAnnouncementRoutes(router: Router, database: Db): void {
	router.get("/announcements", async (_request, response) => {
		response.json(
			(await database.collection("academic_announcements").find({}).sort({ createdAt: -1 }).limit(100).toArray())
				.map(publicRecord),
		);
	});

	router.post("/announcements", async (request, response) => {
		const input = parse(
			z.object({
				title: z.string().trim().min(2).max(160),
				body: z.string().trim().min(2).max(5000),
				audience: z.string().trim().min(1).max(120),
				category: z.string().trim().min(1).max(80),
			}).strict(),
			request.body,
		);
		const adminUser = response.locals.user as Document | undefined;
		const record = await adminWrite(database, response.locals.adminId, async (session) => {
			const data = {
				...input,
				authorName: adminUser?.displayName ?? "Secretaria Geral Acadêmica",
				senderRole: "admin",
				isInstitutional: true,
				readBy: [],
				createdAt: new Date(),
				createdBy: response.locals.adminId,
			};
			const inserted = await database.collection("academic_announcements").insertOne(data, { session });
			await audit(database, response.locals.adminId, "announcement_created", String(inserted.insertedId), {}, session);
			return publicRecord({ _id: inserted.insertedId, ...data });
		});
		response.status(201).json(record);
	});

	router.patch("/announcements/:id", async (request, response) => {
		if (!ObjectId.isValid(request.params.id ?? "")) {
			throw new AuthError(400, "invalid_id", "Comunicado inválido.");
		}
		const input = parse(
			z.object({
				title: z.string().trim().min(2).max(160).optional(),
				body: z.string().trim().min(2).max(5000).optional(),
				audience: z.string().trim().min(1).max(120).optional(),
				category: z.string().trim().min(1).max(80).optional(),
			}).strict().refine((value) => Object.keys(value).length > 0),
			request.body,
		);
		const id = new ObjectId(request.params.id);
		const record = await adminWrite(database, response.locals.adminId, async (session) => {
			const updated = await database.collection("academic_announcements").findOneAndUpdate(
				{ _id: id },
				{
					$set: {
						...input,
						updatedAt: new Date(),
						updatedBy: response.locals.adminId,
					},
				},
				{ session, returnDocument: "after" },
			);
			if (!updated) {
				throw new AuthError(404, "announcement_not_found", "Comunicado não encontrado.");
			}
			await audit(
				database,
				response.locals.adminId,
				"announcement_updated",
				String(id),
				input,
				session,
			);
			return publicRecord(updated);
		});
		response.json(record);
	});
}