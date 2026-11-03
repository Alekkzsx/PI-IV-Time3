// Desenvolvido por Guilherme Henrique Moreira
import type { Router } from "express";
import type { Db } from "mongodb";
import { z } from "zod";
import { parse } from "../../../../../shared/validation.js";
import { adminWrite, audit } from "../../../infrastructure/admin-support.js";

const settingsSchema = z
	.object({
		regimentalLockActive: z.boolean().optional(),
		minimumGrade: z.number().min(0).max(10).optional(),
		minimumAttendance: z.number().min(0).max(100).optional(),
		specialExamGrade: z.number().min(0).max(10).optional(),
		evaluationFormula: z.string().trim().min(1).max(200).optional(),
		resolutionCode: z.string().trim().max(80).optional(),
		currentSemesterLabel: z.string().trim().max(80).optional(),
		currentWeekLabel: z.string().trim().max(80).optional(),
		campusAlerts: z.record(z.string(), z.unknown()).optional(),
		systemPreferences: z.record(z.string(), z.unknown()).optional(),
		governanceLgpd: z.record(z.string(), z.unknown()).optional(),
	})
	.strict()
	.refine((value) => Object.keys(value).length > 0);

export function registerAdminSettingsRoutes(router: Router, database: Db): void {
	const settings = database.collection<{ _id: string; [key: string]: unknown }>("admin_settings");
	router.get("/settings", async (_request, response) => {
		const { _id, ...data } = (await settings.findOne({ _id: "institutional" })) ?? {};
		response.json({
			regimentalLockActive: true,
			minimumGrade: 6,
			minimumAttendance: 75,
			specialExamGrade: 4,
			evaluationFormula: "Média Semestral (MS) = (N1 x 0.4) + (N2 x 0.6)",
			resolutionCode: "RESOLUÇÃO CONSEPE 2026/04",
			currentSemesterLabel: "2026/2",
			currentWeekLabel: "Calendário Vigente 2026/2",
			campusAlerts: {},
			systemPreferences: {},
			governanceLgpd: {},
			...data,
		});
	});

	router.patch("/settings", async (request, response) => {
		const input = parse(settingsSchema, request.body);
		await adminWrite(database, response.locals.adminId, async (session) => {
			await settings.updateOne(
				{ _id: "institutional" },
				{ $set: { ...input, updatedAt: new Date(), updatedBy: response.locals.adminId } },
				{ upsert: true, session },
			);
			await audit(database, response.locals.adminId, "settings_updated", "institutional", { fields: Object.keys(input) }, session);
		});
		response.json({ ...input });
	});
}