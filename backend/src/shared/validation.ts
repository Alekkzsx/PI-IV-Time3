// Desenvolvido por Guilherme Henrique Moreira
import { z } from "zod";
import { ObjectId } from "mongodb";
import { AuthError } from "./auth-error.js";

export const passwordSchema = z.string().min(8).max(72).refine(
  (value) => Buffer.byteLength(value, "utf8") <= 72 && value.trim().length >= 8,
  "A senha deve ter pelo menos 8 caracteres e no máximo 72 bytes.",
);
export const identitySchema = z.string().trim().min(3).max(100)
  .regex(/^[\p{L}\p{N}._@+-]+$/u);
export const emailSchema = z.string().trim().toLowerCase().pipe(z.email().max(254));

export function parse<T extends z.ZodType>(schema: T, value: unknown): z.infer<T> {
  const result = schema.safeParse(value);
  if (!result.success) throw new AuthError(400, "invalid_request", "Dados da solicitação inválidos.");
  return result.data;
}

export function objectId(value: unknown): ObjectId {
  if (typeof value !== "string" || !/^[a-f\d]{24}$/i.test(value)) {
    throw new AuthError(400, "invalid_id", "ID inválido.");
  }
  return new ObjectId(value);
}
