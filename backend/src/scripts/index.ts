// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702
import { fileURLToPath } from "node:url";
import type { Db } from "mongodb";
import { withSeedDatabase, handleSeedError } from "./shared/seed.runner.js";
import { usersSeed } from "./modules/01-users.seed.js";
import { coursesSeed } from "./modules/02-courses.seed.js";
import { classesSeed } from "./modules/03-classes.seed.js";
import { teacherSeed } from "./modules/04-teacher.seed.js";
import { studentSeed } from "./modules/05-student.seed.js";
import { institutionalSeed } from "./modules/06-institutional.seed.js";
import type { SeedModule, SeedSummary } from "./shared/seed.types.js";

export const allSeeds: SeedModule[] = [
  usersSeed,
  coursesSeed,
  classesSeed,
  teacherSeed,
  studentSeed,
  institutionalSeed,
];

export async function runSeeds(
  database: Db,
  password: string,
  targetModuleId?: string,
): Promise<SeedSummary> {
  const aggregated: SeedSummary = {};
  const context: Record<string, any> = {
    users: new Map(),
    courses: new Map(),
    classes: new Map(),
  };

  const modulesToRun = targetModuleId
    ? allSeeds.filter((mod) => mod.id === targetModuleId)
    : allSeeds;

  if (modulesToRun.length === 0) {
    throw new Error(`Módulo de seed não encontrado: "${targetModuleId}". Módulos disponíveis: ${allSeeds.map((s) => s.id).join(", ")}`);
  }

  for (const module of modulesToRun) {
    console.info(`\n🚀 Executando módulo: [${module.name}] - ${module.description}`);
    const summary = await module.execute(database, password, context);

    for (const [col, stats] of Object.entries(summary)) {
      const bucket = (aggregated[col] ??= { created: 0, reused: 0 });
      bucket.created += stats.created;
      bucket.reused += stats.reused;
    }
  }

  return aggregated;
}

function parseCliArgument(): string | undefined {
  const args = process.argv.slice(2);

  if (args.includes("--help") || args.includes("-h")) {
    console.info(`
Uso: npm run seed [opções]
ou:  npx tsx src/scripts/index.ts [opções]

Opções:
  (sem argumentos)    Executa todas as 6 seeds na ordem relacional canônica
  --users             Executa apenas o provisionamento de contas (Admin, Docentes e Alunos)
  --courses           Executa apenas o curso real e matriz curricular
  --classes           Executa apenas as turmas e matrículas ativas
  --teacher           Executa apenas o domínio do docente (diário, materiais, tarefas)
  --student           Executa apenas o domínio do aluno (entregas, notas, protocolos)
  --institutional     Executa apenas o domínio institucional (calendário, mural e parâmetros)
  --only=<modulo>     Executa um módulo específico por identificador
  --help, -h          Exibe esta mensagem de ajuda
`);
    process.exit(0);
  }

  for (const arg of args) {
    if (arg.startsWith("--only=")) return arg.split("=")[1]?.trim();
    if (arg === "--users") return "users";
    if (arg === "--courses") return "courses";
    if (arg === "--classes") return "classes";
    if (arg === "--teacher") return "teacher";
    if (arg === "--student") return "student";
    if (arg === "--institutional") return "institutional";
  }

  return undefined;
}

const isMain =
  process.argv[1] &&
  fileURLToPath(import.meta.url).toLowerCase() === process.argv[1].toLowerCase();

if (isMain) {
  const targetModule = parseCliArgument();
  withSeedDatabase((database, password) => runSeeds(database, password, targetModule)).catch(handleSeedError);
}
