import type { Db } from "mongodb";

export async function ensureAdminIndexes(database: Db): Promise<void> {
  await database.collection<{ _id: string; revision: number }>("admin_write_guard")
    .updateOne({ _id: "admin" }, { $setOnInsert: { revision: 0 } }, { upsert: true });
  await database.collection("admin_audit_logs").createIndex({ createdAt: -1 });
}