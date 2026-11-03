// Desenvolvido por: Rafael Henrique dos Santos Inácio
import { Router } from "express";
import { ObjectId, type Db } from "mongodb";
import { AuthError } from "../../../shared/auth-error.js";
import { authenticated } from "../../auth/infrastructure/session.middleware.js";

export function createFilesRouter(database: Db, jwtSecret: string): Router {
  const router = Router();
  router.use(authenticated(database, jwtSecret, false));

  router.get("/materials/:id", async (request, response) => {
    if (!ObjectId.isValid(request.params.id!)) throw new AuthError(400, "invalid_id", "Material inválido.");
    const material = await database.collection("academic_materials").findOne({ _id: new ObjectId(request.params.id!) });
    if (!material) throw new AuthError(404, "not_found", "Material não encontrado.");
    response.json({
      id: String(material._id),
      title: material.title,
      fileName: material.fileName ?? material.title,
      type: material.type ?? "PDF",
      size: material.size ?? "",
      contentBase64:
        material.contentBase64 ??
        Buffer.from(
          `AGMRM - Material Didático Oficial\nDisciplina: ${material.classCode}\nTítulo: ${material.title}\nPublicado em: ${material.dateLabel ?? ""}\n`,
          "utf8",
        ).toString("base64"),
    });
  });

  router.get("/submissions/:id", async (request, response) => {
    if (!ObjectId.isValid(request.params.id!)) throw new AuthError(400, "invalid_id", "Submissão inválida.");
    const submission = await database.collection("academic_submissions").findOne({ _id: new ObjectId(request.params.id!) });
    if (!submission) throw new AuthError(404, "not_found", "Entrega não encontrada.");
    response.json({
      id: String(submission._id),
      fileName: submission.fileName ?? `entrega_${submission.protocolCode ?? submission._id}.txt`,
      fileSize: submission.fileSize ?? "",
      sha256: submission.sha256 ?? "",
      gitUrl: submission.gitUrl ?? "",
      comments: submission.comments ?? "",
      contentBase64:
        submission.contentBase64 ??
        Buffer.from(
          `Comprovante e Submissão AGMRM\nProtocolo: ${submission.protocolCode}\nAluno: ${submission.studentName} (${submission.ra})\nArquivo: ${submission.fileName}\nRepositório: ${submission.gitUrl ?? "-"}\nComentários: ${submission.comments ?? "-"}\n`,
          "utf8",
        ).toString("base64"),
    });
  });

  router.get("/protocols/:id", async (request, response) => {
    if (!ObjectId.isValid(request.params.id!)) throw new AuthError(400, "invalid_id", "Protocolo inválido.");
    const protocol = await database.collection("academic_protocols").findOne({ _id: new ObjectId(request.params.id!) });
    if (!protocol) throw new AuthError(404, "not_found", "Protocolo não encontrado.");
    response.json({
      id: String(protocol._id),
      code: protocol.code,
      attachmentName: protocol.attachmentName || `${protocol.code}.txt`,
      contentBase64:
        protocol.attachmentBase64 ??
        Buffer.from(
          `Protocolo Secretaria Acadêmica AGMRM\nCódigo: ${protocol.code}\nDiscente: ${protocol.studentName} (${protocol.studentRa})\nTipo: ${protocol.requestType}\nJustificativa: ${protocol.justification}\nStatus: ${protocol.status}\n`,
          "utf8",
        ).toString("base64"),
    });
  });

  return router;
}