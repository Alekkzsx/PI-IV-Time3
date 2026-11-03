// Desenvolvido por Guilherme Henrique Moreira
import type { ClientSession, Db } from "mongodb";

export async function transaction<T>(database: Db, work: (session: ClientSession) => Promise<T>): Promise<T> {
  const session = database.client.startSession();
  try {
    return await session.withTransaction(() => work(session), {
      readConcern: { level: "snapshot" }, writeConcern: { w: "majority" },
    });
  } finally {
    await session.endSession();
  }
}
