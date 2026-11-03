// Desenvolvido por Guilherme Henrique Moreira
import type { ClientSession, Db, Document } from "mongodb";
import { ObjectId } from "mongodb";
import { transaction } from "../../../shared/transaction.js";
import { AuthError } from "../../../shared/auth-error.js";

export function publicRecord(record: Document): Document {
  const { _id, passwordHash: _hash, normalizedEmail: _email, sessionVersion: _version, ...fields } = record;
  return { id: String(_id), ...fields };
}

export function publicUser(document: Document): Document {
  return {
    id: String(document._id),
    identity: document.identity,
    email: document.email,
    displayName: document.displayName,
    profile: document.profile,
    active: document.active,
    departmentOrCourse: document.departmentOrCourse ?? "",
    twoFactorRequired: document.twoFactorRequired === true,
    suspensionReason: document.suspensionReason ?? null,
    lastLogin: document.lastLogin ?? null,
    requirePasswordChange: document.requirePasswordChange === true,
  };
}

export async function audit(
  database: Db,
  actorId: string,
  action: string,
  target: string,
  details: Document = {},
  session?: ClientSession,
): Promise<void> {
  const collection = database.collection("admin_audit_logs");
  if (typeof collection.insertOne !== "function") {
    return;
  }
  await collection.insertOne(
    {
      actorId,
      action,
      target,
      details,
      createdAt: new Date(),
    },
    { session },
  );
}

// Serializa mudanças administrativas para preservar o último admin e a capacidade das turmas.
export async function adminWrite<T>(
  database: Db,
  actorId: string,
  work: (session: ClientSession) => Promise<T>,
): Promise<T> {
  return transaction(database, async (session) => {
    await database
      .collection<{ _id: string; revision: number }>("admin_write_guard")
      .updateOne({ _id: "admin" }, { $inc: { revision: 1 } }, { upsert: true, session });
    const actor = await database
      .collection("auth_users")
      .findOne({ _id: new ObjectId(actorId), profile: "admin", active: true }, { session });
    if (!actor) throw new AuthError(403, "forbidden", "Acesso administrativo revogado.");
    return work(session);
  });
}

