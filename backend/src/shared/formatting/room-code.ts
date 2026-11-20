// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702

export function sanitizeRoomCode(raw: string): string {
  return raw
    .trim()
    .toUpperCase()
    .replace(/\s*-\s*/g, "-")
    .replace(/\s+/g, "-")
    .replace(/[^A-Z0-9._-]/g, "");
}
