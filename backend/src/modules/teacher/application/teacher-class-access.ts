// Desenvolvido por Murillo Caravita - RA: 25014012
import { ObjectId, type Db, type Document } from "mongodb";
import { AuthError } from "../../../shared/auth-error.js";

export class TeacherClassAccess {
  constructor(private readonly database: Db) {}

  async listClasses(userId: string, user: Document): Promise<Document[]> {
    const normalizedIdentity = String(user.normalizedIdentity ?? user.identity ?? "").toLowerCase();
    const filter: Document =
      user.profile === "admin"
        ? { active: { $ne: false } }
        : {
            active: { $ne: false },
            $or: [{ professorId: userId }, { professorIdentity: normalizedIdentity }],
          };
    return this.database.collection("academic_classes").find(filter).sort({ code: 1 }).toArray();
  }

  async requireOwnedClass(userId: string, user: Document, classCodeOrId: string): Promise<Document> {
    const normalizedIdentity = String(user.normalizedIdentity ?? user.identity ?? "").toLowerCase();
    const candidates: Document[] = [{ code: classCodeOrId }];
    if (ObjectId.isValid(classCodeOrId)) {
      candidates.push({ _id: new ObjectId(classCodeOrId) });
    }
    const classroom = await this.database.collection("academic_classes").findOne({
      active: { $ne: false },
      $or: candidates,
    });
    if (!classroom) throw new AuthError(404, "class_not_found", "Turma não encontrada.");
    if (
      user.profile !== "admin" &&
      classroom.professorId !== userId &&
      String(classroom.professorIdentity ?? "").toLowerCase() !== normalizedIdentity
    ) {
      throw new AuthError(403, "forbidden", "Você não está vinculado como docente desta turma.");
    }
    return classroom;
  }
}