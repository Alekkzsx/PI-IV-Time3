import { createHmac, timingSafeEqual } from "node:crypto";

export function digestSecret(secret: string, value: string): string {
  return createHmac("sha256", secret).update(value).digest("hex");
}

export function matchesSecretDigest(secret: string, value: string, expectedDigest: string): boolean {
  const actual = Buffer.from(digestSecret(secret, value), "hex");
  const expected = Buffer.from(expectedDigest, "hex");
  return actual.length === expected.length && timingSafeEqual(actual, expected);
}