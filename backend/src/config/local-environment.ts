// Desenvolvido por Guilherme Henrique Moreira
import { config } from "dotenv";
import { setServers } from "node:dns";
import { isIP } from "node:net";
import { existsSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

/**
 * Localiza EXCLUSIVAMENTE o arquivo .env mestre na raiz do projeto AGMRM.
 */
export function resolveRootEnvPath(): string {
  // 1. Variável de ambiente explícita
  if (process.env.ENV_FILE && existsSync(process.env.ENV_FILE)) {
    return resolve(process.env.ENV_FILE);
  }

  // 2. Busca subindo a partir da localização deste arquivo no sistema de arquivos
  let current = dirname(fileURLToPath(import.meta.url));
  for (let i = 0; i < 6; i++) {
    const candidate = resolve(current, ".env");
    const hasServer = existsSync(resolve(current, "server"));
    const hasBackend = existsSync(resolve(current, "backend"));
    if (existsSync(candidate) && (hasServer || hasBackend)) {
      return candidate;
    }
    const parent = dirname(current);
    if (parent === current) break;
    current = parent;
  }

  // 3. Busca subindo a partir do diretório de trabalho atual (cwd)
  let cwd = process.cwd();
  for (let i = 0; i < 6; i++) {
    const candidate = resolve(cwd, ".env");
    const hasServer = existsSync(resolve(cwd, "server"));
    const hasBackend = existsSync(resolve(cwd, "backend"));
    if (existsSync(candidate) && (hasServer || hasBackend)) {
      return candidate;
    }
    const parent = dirname(cwd);
    if (parent === cwd) break;
    cwd = parent;
  }

  // 4. Fallback padrão: raiz do repositório (.../PI-IV-Time3/.env)
  return resolve(dirname(fileURLToPath(import.meta.url)), "../../../.env");
}

export const ROOT_ENV_PATH = resolveRootEnvPath();

// Carrega estritamente o .env da raiz do projeto todo
config({ path: ROOT_ENV_PATH, quiet: true });

// Opcional, para redes cujo resolvedor local recusa consultas SRV do Atlas.
if (process.env.MONGODB_DNS_SERVERS) {
  const servers = process.env.MONGODB_DNS_SERVERS.split(",").map((value) => value.trim());
  if (servers.some((value) => !isIP(value))) throw new Error("MONGODB_DNS_SERVERS inválido.");
  setServers(servers);
}
