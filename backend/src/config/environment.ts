// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import { z } from "zod";

const environmentSchema = z
  .object({
    NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
    AUTH_PORT: z.coerce.number().int().min(1).max(65_535).default(3001),
    AUTH_CORS_ORIGINS: z.string().default("http://localhost:5000"),
    MONGODB_URI: z.string().min(1),
    MONGODB_DATABASE: z.string().min(1).default("pi_iv_time3"),
    AUTH_JWT_SECRET: z.string().min(32),
    AUTH_OTP_SECRET: z.string().min(32),
    AUTH_JWT_TTL: z.string().regex(/^\d+[smhd]$/).default("15m"),
    AUTH_OTP_TTL_SECONDS: z.coerce.number().int().min(60).max(900).default(300),
    AUTH_OTP_MAX_ATTEMPTS: z.coerce.number().int().min(1).max(10).default(3),
    SMTP_HOST: z.string().optional(),
    SMTP_PORT: z.coerce.number().int().min(1).max(65_535).default(465),
    SMTP_SECURE: z.stringbool().default(true),
    SMTP_USER: z.string().optional(),
    SMTP_PASSWORD: z.string().optional(),
    SMTP_FROM: z.preprocess(
      (value) => (value === "" ? undefined : value),
      z.email().optional(),
    ),
  })
  .superRefine((env, context) => {
    if (env.AUTH_JWT_SECRET === env.AUTH_OTP_SECRET) {
      context.addIssue({
        code: "custom",
        message: "AUTH_JWT_SECRET e AUTH_OTP_SECRET devem ser diferentes.",
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
  mongoUri: string;
  mongoDatabase: string;
  jwtSecret: string;
  otpSecret: string;
  jwtTtl: string;
  otpTtlSeconds: number;
  otpMaxAttempts: number;
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
  const parsed = environmentSchema.safeParse(source);
  if (!parsed.success) {
    const details = parsed.error.issues
      .map((issue) => `${issue.path.join(".")}: ${issue.message}`)
      .join("; ");
    throw new Error(`Configuração de ambiente inválida: ${details}`);
  }

  const values = parsed.data;
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
    mongoUri: values.MONGODB_URI,
    mongoDatabase: values.MONGODB_DATABASE,
    jwtSecret: values.AUTH_JWT_SECRET,
    otpSecret: values.AUTH_OTP_SECRET,
    jwtTtl: values.AUTH_JWT_TTL,
    otpTtlSeconds: values.AUTH_OTP_TTL_SECONDS,
    otpMaxAttempts: values.AUTH_OTP_MAX_ATTEMPTS,
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
