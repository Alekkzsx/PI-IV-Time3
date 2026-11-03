// Desenvolvido por Guilherme Henrique Moreira
import type { Router } from "express";
import { type Db, type Document } from "mongodb";
import { z } from "zod";
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
}