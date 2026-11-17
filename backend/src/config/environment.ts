// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import { createHash } from "node:crypto";
import { z } from "zod";

const environmentSchema = z
  .object({
    NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
    AUTH_PORT: z.coerce.number().int().min(1).max(65_535).default(3001),
    AUTH_CORS_ORIGINS: z.string().default("http://localhost:5000"),
    ALLOW_LAN_CORS: z.stringbool().default(false),
    MONGODB_URI: z.string().min(1),
    MONGODB_DIRECT_URI: z.string().min(1).optional(),
    MONGODB_DATABASE: z.string().min(1).default("pi_iv_time3"),
    AUTH_JWT_SECRET: z.string().min(32),
    INTERNAL_SERVICE_SECRET: z.string().min(32).optional(),
    AUTH_OTP_SECRET: z.string().min(32).optional(),
    AUTH_JWT_TTL: z.string().regex(/^[1-9]\d{0,3}[smhd]$/).default("15m"),
    AUTH_OTP_TTL_SECONDS: z.coerce.number().int().min(60).max(900).default(300),
    AUTH_OTP_MAX_ATTEMPTS: z.coerce.number().int().min(1).max(10).default(3),
    SMTP_HOST: z.string().optional(),
    SMTP_PORT: z.coerce.number().int().min(1).max(65_535).default(465),
    SMTP_SECURE: z.stringbool().default(true),
    SMTP_USER: z.string().optional(),
    SMTP_PASSWORD: z.string().optional(),
    SMTP_FROM: z.preprocess((value) => {
      if (typeof value !== "string" || value.trim() === "") return undefined;
      const match = value.match(/<([^>]+)>/);
      return match && match[1] ? match[1].trim() : value.trim();
    }, z.string().email().optional()),
    RESEND_API_KEY: z.string().optional(),
    BREVO_API_KEY: z.string().optional(),
    GMAIL_WEBHOOK_URL: z.preprocess((val) => {
      if (typeof val !== "string" || val.trim() === "") return undefined;
      return val.trim();
    }, z.string().url().optional()),
    EMAIL_FALLBACK_MODE: z.enum(["outbox", "strict"]).default("outbox"),
  })
  .superRefine((env, context) => {
    if (env.AUTH_OTP_SECRET && env.AUTH_JWT_SECRET === env.AUTH_OTP_SECRET) {
      context.addIssue({
        code: "custom",
        message: "AUTH_JWT_SECRET e AUTH_OTP_SECRET devem ser diferentes.",
      });
    }
    if (env.NODE_ENV === "production" && !env.INTERNAL_SERVICE_SECRET) {
      context.addIssue({
        code: "custom",
        message: "INTERNAL_SERVICE_SECRET é obrigatório em produção.",
      });
    }
    if (env.INTERNAL_SERVICE_SECRET && env.INTERNAL_SERVICE_SECRET === env.AUTH_JWT_SECRET) {
      context.addIssue({
        code: "custom",
        message: "INTERNAL_SERVICE_SECRET e AUTH_JWT_SECRET devem ser diferentes.",
      });
    }

    const smtpValues = [
      env.SMTP_HOST,
      env.SMTP_USER,
      env.SMTP_PASSWORD,
      env.SMTP_FROM,
    ];
    const smtpConfigured = smtpValues.every((value) => value?.trim());
    const smtpPartiallyConfigured = smtpValues.some((value) => value?.trim());

    if (smtpPartiallyConfigured && !smtpConfigured) {
      context.addIssue({
        code: "custom",
        message: "Configure todos os campos SMTP ou deixe todos vazios.",
      });
    }
  });

export type Environment = {
  nodeEnv: "development" | "test" | "production";
  port: number;
  corsOrigins: string[];
  allowLanCors: boolean;
  mongoUri: string;
  mongoDirectUri?: string;
  mongoDatabase: string;
  jwtSecret: string;
  internalServiceSecret: string;
  otpSecret: string;
  jwtTtl: string;
  otpTtlSeconds: number;
  otpMaxAttempts: number;
  emailProviders: {
    resendApiKey?: string;
    brevoApiKey?: string;
    gmailWebhookUrl?: string;
    fallbackMode: "outbox" | "strict";
  };
  smtp:
    | {
        host: string;
        port: number;
        secure: boolean;
        user: string;
        password: string;
        from: string;
      }
    | undefined;
};

/** Valida e normaliza variáveis de ambiente antes de iniciar qualquer serviço. */
export function loadEnvironment(
  source: NodeJS.ProcessEnv = process.env,
): Environment {
  const normalizedSource: NodeJS.ProcessEnv = { ...source };

  // Fallback interoperável com chaves equivalentes da raiz (.env)
  if (!normalizedSource.AUTH_PORT && normalizedSource.ACADEMIC_PORT) {
    normalizedSource.AUTH_PORT = normalizedSource.ACADEMIC_PORT;
  }
  if (!normalizedSource.AUTH_JWT_SECRET && normalizedSource.JWT_SECRET) {
    normalizedSource.AUTH_JWT_SECRET = normalizedSource.JWT_SECRET;
  }
  for (const key of [
    "INTERNAL_SERVICE_SECRET",
    "AUTH_OTP_SECRET",
    "MONGODB_DIRECT_URI",
    "ALLOW_LAN_CORS",
    "SMTP_SECURE",
    "SMTP_SSL",
    "EMAIL_FALLBACK_MODE",
  ] as const) {
    if (typeof normalizedSource[key] === "string" && normalizedSource[key].trim() === "") {
      delete normalizedSource[key];
    }
  }
  if (!normalizedSource.SMTP_SECURE && normalizedSource.SMTP_SSL) {
    normalizedSource.SMTP_SECURE = normalizedSource.SMTP_SSL;
  }

  const parsed = environmentSchema.safeParse(normalizedSource);
  if (!parsed.success) {
    const details = parsed.error.issues
      .map((issue) => `${issue.path.join(".")}: ${issue.message}`)
      .join("; ");
    throw new Error(`Configuração de ambiente inválida: ${details}`);
  }

  const values = parsed.data;
  const internalServiceSecret =
    values.INTERNAL_SERVICE_SECRET ??
    createHash("sha256")
      .update(`agmrm-internal-bridge:${values.AUTH_JWT_SECRET}`)
      .digest("hex");
  const otpSecret =
    values.AUTH_OTP_SECRET ??
    createHash("sha256")
      .update(`agmrm-otp-fallback:${values.AUTH_JWT_SECRET}`)
      .digest("hex");
  const smtpConfigured = Boolean(
    values.SMTP_HOST &&
      values.SMTP_USER &&
      values.SMTP_PASSWORD &&
      values.SMTP_FROM,
  );

  return {
    nodeEnv: values.NODE_ENV,
    port: values.AUTH_PORT,
    corsOrigins: values.AUTH_CORS_ORIGINS.split(",")
      .map((origin) => origin.trim())
      .filter(Boolean),
    allowLanCors: values.ALLOW_LAN_CORS,
    mongoUri: values.MONGODB_URI,
    mongoDirectUri: values.MONGODB_DIRECT_URI,
    mongoDatabase: values.MONGODB_DATABASE,
    jwtSecret: values.AUTH_JWT_SECRET,
    internalServiceSecret,
    otpSecret,
    jwtTtl: values.AUTH_JWT_TTL,
    otpTtlSeconds: values.AUTH_OTP_TTL_SECONDS,
    otpMaxAttempts: values.AUTH_OTP_MAX_ATTEMPTS,
    emailProviders: {
      resendApiKey: values.RESEND_API_KEY?.trim() || undefined,
      brevoApiKey: values.BREVO_API_KEY?.trim() || undefined,
      gmailWebhookUrl: values.GMAIL_WEBHOOK_URL || undefined,
      fallbackMode: values.EMAIL_FALLBACK_MODE,
    },
    smtp: smtpConfigured
      ? {
          host: values.SMTP_HOST!,
          port: values.SMTP_PORT,
          secure: values.SMTP_SECURE,
          user: values.SMTP_USER!,
          password: values.SMTP_PASSWORD!,
          from: values.SMTP_FROM!,
        }
      : undefined,
  };
}
