// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702
import type { Db } from "mongodb";

export type SeedStats = { created: number; reused: number };
export type SeedSummary = Record<string, SeedStats>;

export interface SeedModule {
  id: string;
  name: string;
  description: string;
  execute: (database: Db, password: string, context?: Record<string, any>) => Promise<SeedSummary>;
}

export interface SeedContext {
  users?: Map<string, any>;
  courses?: Map<string, any>;
  classes?: Map<string, any>;
}
