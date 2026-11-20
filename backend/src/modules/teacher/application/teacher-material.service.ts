// Desenvolvido por Murillo Caravita - RA: 25014012
import { ObjectId, type Db, type Document } from "mongodb";
import { AuthError } from "../../../shared/auth-error.js";
import { TeacherClassAccess } from "./teacher-class-access.js";
import { formatShortDate } from "../../../shared/formatting/date-formatters.js";

export class TeacherMaterialService {
  constructor(
    private readonly database: Db,
    private readonly classAccess: TeacherClassAccess,
  ) {}

  async publishMaterial(
    userId: string,
    user: Document,
    classCode: string,
    input: {
      title: string;
      fileName?: string;
      size?: string;
      type?: string;
      unitAssociated?: string;
      category?: string;
      contentBase64?: string;
    },
  ) {
    const classroom = await this.classAccess.requireOwnedClass(userId, user, classCode);
    const now = new Date();
    const ext = (input.fileName ?? input.title).split(".").pop()?.toUpperCase() ?? "PDF";
    const doc = {
      classCode: classroom.code,
      courseCode: classroom.courseCode,
      title: input.title,
      fileName: input.fileName ?? input.title,
      size: input.size ?? "1.2 MB",
      type: input.type ?? (["PDF", "ZIP", "PPTX", "DOCX", "MD"].includes(ext) ? ext : "PDF"),
      unitAssociated: input.unitAssociated ?? "Unidade 1",
      category: input.category?.trim() || "Material Complementar",
      contentBase64: input.contentBase64 ?? null,
      uploadedBy: userId,
      uploadedByName: user.displayName,
      dateLabel: `Hoje, ${formatShortDate(now)}`,
      createdAt: now,
    };
    const inserted = await this.database.collection("academic_materials").insertOne(doc);
    return {
      id: String(inserted.insertedId),
      courseId: classroom.code,
      title: doc.title,
      fileName: doc.fileName,
      date: doc.dateLabel,
      size: doc.size,
      type: doc.type,
      unitAssociated: doc.unitAssociated,
      category: doc.category,
      downloadUrl: `/api/files/materials/${String(inserted.insertedId)}`,
    };
  }

  async deleteMaterial(userId: string, user: Document, classCode: string, materialId: string) {
    if (!ObjectId.isValid(materialId)) throw new AuthError(400, "invalid_id", "Material inválido.");
    const classroom = await this.classAccess.requireOwnedClass(userId, user, classCode);
    const deleted = await this.database.collection("academic_materials").deleteOne({
      _id: new ObjectId(materialId),
      classCode: classroom.code,
    });
    if (deleted.deletedCount === 0) throw new AuthError(404, "not_found", "Material não encontrado.");
    return { ok: true, id: materialId };
  }
}