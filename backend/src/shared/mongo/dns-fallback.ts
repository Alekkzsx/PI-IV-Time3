// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
const DOH_ENDPOINTS = [
  "https://dns.google/resolve",
  "https://cloudflare-dns.com/dns-query",
] as const;

const DNS_ERROR_CODES = new Set([
  "ENOTFOUND",
  "ECONNREFUSED",
  "ETIMEOUT",
  "ESERVFAIL",
  "ENODATA",
  "EREFUSED",
]);

export function isDnsSrvFailure(error: unknown): boolean {
  let cursor: unknown = error;
  for (let depth = 0; depth < 6 && cursor && typeof cursor === "object"; depth++) {
    const code = "code" in cursor ? String((cursor as { code?: unknown }).code ?? "") : "";
    const msg = "message" in cursor ? String((cursor as { message?: unknown }).message ?? "") : "";
    if (DNS_ERROR_CODES.has(code.toUpperCase())) {
      return true;
    }
    if (/querySrv|queryTxt|_mongodb\._tcp/i.test(msg)) {
      return true;
    }
    cursor = "cause" in cursor ? (cursor as { cause?: unknown }).cause : undefined;
  }
  return false;
}

export function parseDohJsonAnswers(payload: unknown, expectedTypeCode: number): string[] {
  if (!payload || typeof payload !== "object") return [];
  const root = payload as { Status?: unknown; Answer?: unknown };
  if (typeof root.Status === "number" && root.Status !== 0) {
    return [];
  }
  if (!Array.isArray(root.Answer)) return [];

  const values: string[] = [];
  for (const item of root.Answer) {
    if (!item || typeof item !== "object") continue;
    const entry = item as { type?: unknown; data?: unknown };
    if (typeof entry.type === "number" && entry.type !== expectedTypeCode) continue;
    if (typeof entry.data !== "string" || !entry.data.trim()) continue;
    values.push(normalizeTxtOrSrvData(entry.data, expectedTypeCode));
  }
  return values;
}

function normalizeTxtOrSrvData(raw: string, expectedTypeCode: number): string {
  const trimmed = raw.trim();
  if (expectedTypeCode !== 16 || !trimmed.includes("\"")) {
    return trimmed.replace(/\s+/g, " ");
  }
  let out = "";
  let inQuotes = false;
  for (const ch of trimmed) {
    if (ch === "\"") {
      inQuotes = !inQuotes;
    } else if (inQuotes || !/\s/.test(ch)) {
      out += ch;
    }
  }
  return out;
}

export function buildDirectMongoUri(
  srvUri: string,
  srvRecords: string[],
  txtRecords: string[],
): string {
  if (!srvUri.startsWith("mongodb+srv://")) {
    return srvUri;
  }
  const parsed = new URL(srvUri.replace("mongodb+srv://", "https://"));
  const hosts: string[] = [];
  for (const record of srvRecords) {
    const parts = record.trim().split(/\s+/);
    if (parts.length < 4) continue;
    const port = parts[2] ?? "";
    const target = (parts[3] ?? "").replace(/\.$/, "");
    if (!target || !/^\d+$/.test(port)) continue;
    hosts.push(`${target}:${port}`);
  }
  if (hosts.length === 0) {
    throw new Error("Nenhum registro SRV valido encontrado para o cluster MongoDB.");
  }

  const mergedParams = new URLSearchParams();
  for (const txt of txtRecords) {
    const cleanTxt = txt.replace(/\s+/g, "");
    if (!cleanTxt) continue;
    const txtParams = new URLSearchParams(cleanTxt);
    txtParams.forEach((value, key) => {
      if (!mergedParams.has(key)) mergedParams.set(key, value);
    });
  }
  parsed.searchParams.forEach((value, key) => {
    mergedParams.set(key, value);
  });
  if (!mergedParams.has("ssl") && !mergedParams.has("tls")) {
    mergedParams.set("ssl", "true");
  }

  const auth = parsed.username
    ? `${parsed.username}${parsed.password ? `:${parsed.password}` : ""}@`
    : "";
  const pathname = parsed.pathname && parsed.pathname !== "/" ? parsed.pathname : "/";
  const query = mergedParams.toString();
  return `mongodb://${auth}${hosts.join(",")}${pathname}${query ? `?${query}` : ""}`;
}

async function queryDoh(name: string, type: "SRV" | "TXT", expectedTypeCode: number): Promise<string[]> {
  let lastError: unknown;
  for (const endpoint of DOH_ENDPOINTS) {
    try {
      const url = `${endpoint}?name=${encodeURIComponent(name)}&type=${type}`;
      const response = await fetch(url, {
        headers: { accept: "application/dns-json" },
        signal: AbortSignal.timeout(4_000),
      });
      if (!response.ok) {
        lastError = new Error(`DoH HTTP ${response.status}`);
        continue;
      }
      const json = await response.json();
      return parseDohJsonAnswers(json, expectedTypeCode);
    } catch (error) {
      lastError = error;
    }
  }
  throw lastError instanceof Error ? lastError : new Error("Falha ao consultar DNS-over-HTTPS.");
}

export async function resolveSrvUriViaDoh(srvUri: string): Promise<string> {
  if (!srvUri.startsWith("mongodb+srv://")) {
    return srvUri;
  }
  const parsed = new URL(srvUri.replace("mongodb+srv://", "https://"));
  const host = parsed.hostname;
  const srvRecords = await queryDoh(`_mongodb._tcp.${host}`, "SRV", 33);
  let txtRecords: string[] = [];
  try {
    txtRecords = await queryDoh(host, "TXT", 16);
  } catch {
    txtRecords = [];
  }
  return buildDirectMongoUri(srvUri, srvRecords, txtRecords);
}
