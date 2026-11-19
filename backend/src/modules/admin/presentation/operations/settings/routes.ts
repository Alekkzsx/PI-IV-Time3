// Desenvolvido por Guilherme Henrique Moreira
import type { Router } from "express";
import type { Db } from "mongodb";
import { z } from "zod";
import { parse } from "../../../../../shared/validation.js";
import { adminWrite, audit } from "../../../infrastructure/admin-support.js";

const resourceItemSchema = z.object({
	id: z.string().trim().min(1).max(80),
	title: z.string().trim().min(2).max(160),
	description: z.string().trim().max(400).optional(),
	subtitle: z.string().trim().max(400).optional(),
	category: z.string().trim().min(1).max(80).default("APOIO ACADÊMICO"),
	actionLabel: z.string().trim().min(1).max(60).default("Acessar"),
	url: z.string().trim().min(1).max(500),
	icon: z.string().trim().max(60).default("menu_book"),
}).strict();

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
		academicResources: z.array(resourceItemSchema).max(50).optional(),
	})
	.strict()
	.refine((value) => Object.keys(value).length > 0);

export function registerAdminSettingsRoutes(router: Router, database: Db): void {
	const settings = database.collection<{ _id: string; [key: string]: unknown }>("admin_settings");
	router.get("/settings", async (_request, response) => {
		const { _id, ...data } = ((await settings.findOne({ _id: "institutional" })) ?? {}) as Record<string, unknown>;
		response.json({
			regimentalLockActive: true,
			minimumGrade: Number(data.minimumGrade ?? data.passingGrade ?? 6),
			minimumAttendance: Number(data.minimumAttendance ?? 75),
			specialExamGrade: Number(data.specialExamGrade ?? 4),
			evaluationFormula: String(data.evaluationFormula ?? data.defaultFormula ?? "Média Semestral (MS) = (N1 x 0.4) + (N2 x 0.6)"),
			resolutionCode: String(data.resolutionCode ?? "RESOLUÇÃO CONSEPE 2026/04"),
			currentSemesterLabel: String(data.currentSemesterLabel ?? data.academicPeriod ?? "2026/2"),
			currentWeekLabel: String(data.currentWeekLabel ?? "Calendário Vigente 2026/2"),
			campusAlerts: {},
			systemPreferences: {},
			governanceLgpd: {},
			academicResources: [],
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