// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import { ObjectId, type Db, type Document } from "mongodb";
import type { EmailDeliveryResult } from "./notification.types.js";

export type RegisteredRecipient = {
  userId: string;
  email: string;
  displayName: string;
  identity: string;
  profile: string;
};

const SIMPLE_EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/**
 * Valida sintaticamente se uma string representa um endereço de e-mail utilizável.
 */
export function isSyntacticallyValidEmail(value: unknown): value is string {
  if (typeof value !== "string") return false;
  const trimmed = value.trim();
  return trimmed.length >= 5 && trimmed.length <= 254 && SIMPLE_EMAIL_REGEX.test(trimmed);
}

function mapUserToRecipient(user: Document | null | undefined): RegisteredRecipient | null {
  if (!user || user.active !== true || !isSyntacticallyValidEmail(user.email)) {
    return null;
  }
  return {
    userId: String(user._id),
    email: user.email.trim(),
    displayName: String(user.displayName ?? user.identity ?? "Usuário AGMRM"),
    identity: String(user.identity ?? ""),
    profile: String(user.profile ?? ""),
  };
}

/**
 * Localiza um usuário ativo na coleção `auth_users` cujo e-mail corresponda (case-insensitive).
 * Retorna `null` se o e-mail não estiver cadastrado ou se a conta estiver inativa.
 */
export async function resolveActiveRegisteredRecipientByEmail(
  database: Db,
  rawEmail: string,
): Promise<RegisteredRecipient | null> {
  if (!isSyntacticallyValidEmail(rawEmail)) return null;
  const normalized = rawEmail.trim().toLowerCase();
  const user = await database.collection("auth_users").findOne(
    {
      active: true,
      $or: [
        { normalizedEmail: normalized },
        { email: normalized },
        { email: rawEmail.trim() },
      ],
    },
    { collation: { locale: "en", strength: 2 } },
  );
  return mapUserToRecipient(user);
}

/**
 * Localiza um usuário ativo na coleção `auth_users` pelo `_id` garantindo e-mail válido cadastrado.
 */
export async function resolveActiveRegisteredRecipientById(
  database: Db,
  userId: string,
): Promise<RegisteredRecipient | null> {
  if (!userId || !ObjectId.isValid(String(userId).trim())) return null;
  const user = await database.collection("auth_users").findOne({
    _id: new ObjectId(String(userId).trim()),
    active: true,
  });
  return mapUserToRecipient(user);
}

/**
 * Resolve em lote todos os alunos com matrícula ativa na turma que possuam conta ativa e e-mail válido em `auth_users`.
 */
export async function resolveActiveEnrolledRecipients(
  database: Db,
  classCode: string,
): Promise<RegisteredRecipient[]> {
  const enrollments = await database
    .collection("academic_enrollments")
    .find({ classCode, status: "active" }, { projection: { studentId: 1 } })
    .toArray();
  const objectIds = Array.from(
    new Set(enrollments.map((e) => String(e.studentId ?? "").trim()).filter((id) => ObjectId.isValid(id))),
  ).map((id) => new ObjectId(id));

  if (objectIds.length === 0) return [];

  const users = await database
    .collection("auth_users")
    .find({ _id: { $in: objectIds }, active: true })
    .toArray();

  const seenEmails = new Set<string>();
  const recipients: RegisteredRecipient[] = [];
  for (const user of users) {
    const rec = mapUserToRecipient(user);
    if (!rec) continue;
    const key = rec.email.toLowerCase();
    if (seenEmails.has(key)) continue;
    seenEmails.add(key);
    recipients.push(rec);
  }
  return recipients;
}

/**
 * Executa um disparo assíncrono de notificação registrando falha ou retenção em outbox sem derrubar a rota chamadora.
 */
export function dispatchNotificationSafe(
  context: string,
  recipientEmail: string,
  sendTask: () => Promise<EmailDeliveryResult>,
): void {
  void sendTask()
    .then((result) => {
      const deliveredExternally = result.deliveredExternally ?? result.provider !== "outbox";
      if (!deliveredExternally) {
        console.warn(
          `[${context}] E-mail para ${recipientEmail} retido em OUTBOX (canal=${result.provider}): ${(result.errorTrail ?? []).join(" | ")}`,
        );
      }
    })
    .catch((err: any) => {
      console.warn(`[${context}] Falha ao disparar e-mail para ${recipientEmail}: ${err?.message ?? err}`);
    });
}
