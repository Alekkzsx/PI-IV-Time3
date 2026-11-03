import type { Db } from "mongodb";

export async function ensureVideoCallIndexes(database: Db): Promise<void> {
  await database.collection("video_call_ws_tickets").createIndex({ tokenDigest: 1 }, { unique: true });
  await database.collection("video_call_ws_tickets").createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
}