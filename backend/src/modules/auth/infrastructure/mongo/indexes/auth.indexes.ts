import type { Db } from "mongodb";

export async function ensureAuthIndexes(database: Db): Promise<void> {
  await database.collection("auth_recovery").createIndex({ normalizedIdentity: 1 }, { unique: true });
  await database.collection("auth_recovery").createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
  await database.collection("auth_sessions").createIndex({ sessionId: 1 }, { unique: true });
  await database.collection("auth_sessions").createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
  await database.collection("auth_sessions").createIndex({ userId: 1 });
  await database.collection("auth_challenges").createIndex({ tokenDigest: 1 }, { unique: true });
  await database.collection("auth_challenges").createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
  await database.collection("auth_login_limits").createIndex({ key: 1 }, { unique: true });
  await database.collection("auth_login_limits").createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
  await database.collection("auth_users").createIndex({ email: 1 }, {
    unique: true,
    collation: { locale: "en", strength: 2 },
    partialFilterExpression: { email: { $type: "string" } },
  });
  await database.collection("auth_users").createIndex({ normalizedIdentity: 1 }, { unique: true });
}