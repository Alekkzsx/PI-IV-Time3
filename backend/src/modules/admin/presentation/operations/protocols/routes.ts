// Desenvolvido por Guilherme Henrique Moreira
import { randomUUID } from "node:crypto";
import type { Router } from "express";
import { type Db, type Document } from "mongodb";
import { z } from "zod";
import { AuthError } from "../../../../../shared/auth-error.js";
import { objectId, parse } from "../../../../../shared/validation.js";
import { adminWrite, audit, publicRecord } from "../../../infrastructure/admin-support.js";
import type { UnifiedEmailService } from "../../../../notifications/domain/notification.types.js";

export function registerAdminProtocolRoutes(
	router: Router,
	database: Db,
	emailService?: UnifiedEmailService,
): void {
	const protocols = database.collection("academic_protocols");

	router.get("/protocols", async (_request, response) => {
		const list = await protocols
			.find({}, { projection: { attachmentBase64: 0 } })
			.sort({ createdAt: -1 })
			.limit(500)
			.toArray();
		response.json(list.map(publicRecord));
	});

	router.post("/protocols", async (request, response) => {
		const input = parse(
			z.object({
				studentIdentity: z.string().trim().min(1).max(254),
				requestType: z.string().trim().min(2).max(120),
				targetComponent: z.string().trim().max(120).default(""),
				justification: z.string().trim().min(5).max(3000),
				attachmentName: z.string().trim().max(200).default(""),
			}).strict(),
			request.body,
		);
		const created = await adminWrite(database, response.locals.adminId, async (session) => {
			const student = await database
				.collection("auth_users")
				.findOne({ normalizedIdentity: input.studentIdentity.toLowerCase(), profile: "aluno", active: true }, { session });
			if (!student) throw new AuthError(404, "student_not_found", "Aluno ativo não encontrado.");
			const record = {
				...input,
				code: `PROT-${randomUUID().slice(0, 8).toUpperCase()}`,
				studentId: String(student._id),
				studentRa: student.identity,
				studentName: student.displayName,
				status: "Aguardando Parecer",
				createdAt: new Date(),
				createdBy: response.locals.adminId,
			};
			const saved = await protocols.insertOne(record, { session });
			await audit(database, response.locals.adminId, "protocol_created", String(saved.insertedId), {}, session);
			return publicRecord({ _id: saved.insertedId, ...record });
		});
		response.status(201).json(created);
	});

	router.patch("/protocols/:id/decision", async (request, response) => {
		const id = objectId(request.params.id);
		const input = parse(
			z.object({ approved: z.boolean(), decisionNote: z.string().trim().min(5).max(3000) }).strict(),
			request.body,
		);
		const adminUser = response.locals.user as Document | undefined;
		const signedBy = adminUser?.displayName ?? "Secretaria Geral Acadêmica";
		const record = await adminWrite(database, response.locals.adminId, async (session) => {
			const updated = await protocols.findOneAndUpdate(
				{ _id: id, status: "Aguardando Parecer" },
				{
					$set: {
						status: input.approved ? "Deferido" : "Indeferido",
						decisionNote: input.decisionNote,
						decidedBy: response.locals.adminId,
						signedBy,
						decidedAt: new Date(),
					},
				},
				{ session, returnDocument: "after" },
			);
			if (!updated) throw new AuthError(409, "protocol_unavailable", "Protocolo inexistente ou já decidido.");

			const requestType = String(updated.requestType ?? "").toLowerCase();
			if (input.approved && ["abono", "atestado", "falta"].some((term) => requestType.includes(term))) {
				const targetFilter: Document = { studentId: String(updated.studentId), status: "active" };
				if (updated.targetComponent) targetFilter.classCode = updated.targetComponent;
				await database.collection("academic_enrollments").updateMany(
					targetFilter,
					{ $inc: { excusedAbsences: 2 } },
					{ session },
				);
			}
			await audit(database, response.locals.adminId, "protocol_decided", String(id), { approved: input.approved }, session);
			return publicRecord(updated);
		});

		if (emailService && record) {
			void database
				.collection("auth_users")
				.findOne({ _id: objectId(String(record.studentId)) })
				.then((student) => {
					if (student?.email) {
						return emailService.sendProtocolDecided({
							to: student.email,
							studentName: student.displayName ?? record.studentName,
							protocolCode: record.code,
							requestType: record.requestType,
							approved: input.approved,
							decisionNote: input.decisionNote,
							signedBy,
						});
					}
				})
				.catch((err) => {
					console.warn(`[admin-protocols] Falha ao notificar discente por e-mail: ${err?.message}`);
				});
		}

		response.json(record);
	});
}