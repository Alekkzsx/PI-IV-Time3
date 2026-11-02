// Desenvolvido por Guilherme Henrique Moreira
import { config } from "dotenv";
import { setServers } from "node:dns";
import { isIP } from "node:net";
import { fileURLToPath } from "node:url";

config({ path: [
  fileURLToPath(new URL("../../.env.local", import.meta.url)),
  fileURLToPath(new URL("../../.env", import.meta.url)),
], quiet: true });

// Opcional, para redes cujo resolvedor local recusa consultas SRV do Atlas.
if (process.env.MONGODB_DNS_SERVERS) {
  const servers = process.env.MONGODB_DNS_SERVERS.split(",").map((value) => value.trim());
  if (servers.some((value) => !isIP(value))) throw new Error("MONGODB_DNS_SERVERS inválido.");
  setServers(servers);
}
