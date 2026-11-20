// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import type { RequestHandler } from "express";

export interface IdentityServerHealthOptions {
  baseUrl: string;
  okCacheTtlMs?: number;
  failCacheTtlMs?: number;
  timeoutMs?: number;
  probe?: (url: string) => Promise<boolean>;
}

async function defaultHealthProbe(url: string, timeoutMs: number): Promise<boolean> {
  try {
    const response = await fetch(url, {
      method: "GET",
      headers: { Accept: "application/json" },
      signal: AbortSignal.timeout(timeoutMs),
    });
    return response.ok;
  } catch {
    return false;
  }
}

/**
 * Middleware Fail-Closed da API Acadêmica (:3001):
 * bloqueia operações protegidas com HTTP 503 quando o Servidor Java de Identidade (:8080)
 * está desligado ou fora do ar, usando cache curto para evitar sobrecarga por requisição.
 */
export function createIdentityServerHealthMiddleware(
  options: IdentityServerHealthOptions,
): RequestHandler {
  const cleanBase = options.baseUrl.replace(/\/+$/, "");
  const healthUrl = `${cleanBase}/health`;
  const okCacheTtlMs = options.okCacheTtlMs ?? 3_000;
  const failCacheTtlMs = options.failCacheTtlMs ?? 1_000;
  const timeoutMs = options.timeoutMs ?? 2_000;
  const runProbe = options.probe ?? ((url: string) => defaultHealthProbe(url, timeoutMs));

  let lastCheckedAt = 0;
  let lastOnline = false;
  let inflight: Promise<boolean> | null = null;

  async function isIdentityServerOnline(): Promise<boolean> {
    const now = Date.now();
    const ttl = lastOnline ? okCacheTtlMs : failCacheTtlMs;
    if (lastCheckedAt > 0 && now - lastCheckedAt < ttl) {
      return lastOnline;
    }
    if (!inflight) {
      inflight = runProbe(healthUrl)
        .catch(() => false)
        .then((online) => {
          lastOnline = online;
          lastCheckedAt = Date.now();
          inflight = null;
          return online;
        });
    }
    return inflight;
  }

  return async (_request, response, next) => {
    const online = await isIdentityServerOnline();
    if (!online) {
      response.status(503).json({
        code: "identity_service_unavailable",
        message: "Servidor Java (:8080) desligado ou fora do ar. Operação bloqueada.",
      });
      return;
    }
    next();
  };
}
