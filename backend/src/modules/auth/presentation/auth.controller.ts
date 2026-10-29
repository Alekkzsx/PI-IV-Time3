// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import { Router, type Request, type RequestHandler } from "express";
import { z } from "zod";
import type { AuthService } from "../application/auth.service.js";
import { authProfiles } from "../domain/auth.types.js";
import { AuthError } from "../../../shared/auth-error.js";

const loginSchema = z.object({
  identity: z.string().trim().min(1).max(254),
  password: z.string().min(8).max(128),
  profile: z.enum(authProfiles),
});

const recoveryRequestSchema = z.object({
  identity: z.string().trim().min(1).max(254),
});

const recoveryVerificationSchema = z.object({
  identity: z.string().trim().min(1).max(254),
  code: z.string().regex(/^\d{6}$/),
});

const passwordResetSchema = z.object({
  identity: z.string().trim().min(1).max(254),
  resetToken: z.string().min(32).max(128),
  newPassword: z.string().min(8).max(128),
});

/** Expõe os casos de uso de autenticação sem incluir regras de negócio na camada HTTP. */
export function createAuthRouter(service: AuthService): Router {
  const router = Router();

  router.post("/login", asyncHandler(async (request, response) => {
    const body = parseBody(loginSchema, request);
    const result = await service.login(body);
    response.status(200).json({ success: true, ...result });
  }));

  router.post("/send-recovery-otp", asyncHandler(async (request, response) => {
    const body = parseBody(recoveryRequestSchema, request);
    const expiresInSeconds = await service.requestRecoveryCode(body.identity);
    response.status(200).json({
      success: true,
      expiresInSeconds,
      message: "Se a conta estiver cadastrada, um código será enviado ao e-mail institucional.",
    });
  }));

  router.post("/verify-recovery-otp", asyncHandler(async (request, response) => {
    const body = parseBody(recoveryVerificationSchema, request);
    const result = await service.verifyRecoveryCode(body);
    response.status(200).json(result);
  }));

  router.post("/reset-password", asyncHandler(async (request, response) => {
    const body = parseBody(passwordResetSchema, request);
    await service.resetPassword(body);
    response.status(204).end();
  }));

  return router;
}

function parseBody<T extends z.ZodType>(
  schema: T,
  request: Request,
): z.infer<T> {
  const parsed = schema.safeParse(request.body);
  if (!parsed.success) {
    throw new AuthError(400, "invalid_request", "Dados da solicitação inválidos.");
  }
  return parsed.data;
}

function asyncHandler(
  handler: RequestHandler,
): RequestHandler {
  return (request, response, next) => {
    Promise.resolve(handler(request, response, next)).catch(next);
  };
}
