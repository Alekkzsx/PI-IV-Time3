// Testes unitários dos contratos das APIs Admin após correções da visão administrativa.
import assert from "node:assert/strict";
import { createServer, type Server } from "node:http";
import { after, before, describe, it } from "node:test";
import jwt from "jsonwebtoken";
import { ObjectId, type Db, type Document } from "mongodb";
import { createApp } from "../../app.js";

function matchesFilter(doc: Document, filter: Document): boolean {
  for (const [key, cond] of Object.entries(filter)) {
    if (key === "$or" && Array.isArray(cond)) {
      if (!cond.some((branch) => matchesFilter(doc, branch))) return false;
      continue;
    }
    const val = doc[key];
    if (cond && typeof cond === "object" && !(cond instanceof Date) && !(cond instanceof ObjectId) && !(cond instanceof RegExp)) {
      const op = cond as Record<string, unknown>;
      if ("$ne" in op && val === op.$ne) return false;
      if ("$gt" in op && !(val instanceof Date && val > (op.$gt as Date))) return false;
      if ("$in" in op && Array.isArray(op.$in) && !op.$in.map(String).includes(String(val))) return false;
      if ("$regex" in op) {
        const regex = op.$regex instanceof RegExp
          ? op.$regex
          : new RegExp(String(op.$regex), String(op.$options ?? ""));
        if (!regex.test(String(val ?? ""))) return false;
      }
      continue;
    }
    if (cond instanceof ObjectId) {
      if (String(val) !== String(cond)) return false;
      continue;
    }
    if (val instanceof ObjectId && typeof cond === "string") {
      if (String(val) !== cond) return false;
      continue;
    }
    if (String(val ?? "") !== String(cond ?? "")) return false;
  }
  return true;
}

function makeInMemoryDb(seed: Record<string, Document[]>): { db: Db; store: Record<string, Document[]> } {
  const store: Record<string, Document[]> = {};
  for (const [col, docs] of Object.entries(seed)) {
    store[col] = docs.map((d) => ({ ...d }));
  }
  const fakeSession = {
    async withTransaction<T>(fn: () => Promise<T>) {
      return fn();
    },
    async endSession() {},
  };
  const collection = (name: string) => {
    store[name] ??= [];
    const list = store[name]!;
    return {
      async findOne(filter: Document = {}) {
        return list.find((d) => matchesFilter(d, filter)) ?? null;
      },
      find(filter: Document = {}) {
        const filtered = list.filter((d) => matchesFilter(d, filter));
        return {
          sort() { return this; },
          skip(n: number) { return this; },
          limit() { return this; },
          project() { return this; },
          async toArray() { return filtered; },
        };
      },
      async countDocuments(filter: Document = {}) {
        return list.filter((d) => matchesFilter(d, filter)).length;
      },
      async insertOne(doc: Document) {
        const saved = { _id: doc._id ?? new ObjectId(), ...doc };
        list.push(saved);
        return { insertedId: saved._id };
      },
      async updateOne(filter: Document, update: Document, opts?: { upsert?: boolean }) {
        const idx = list.findIndex((d) => matchesFilter(d, filter));
        if (idx >= 0) {
          const cur = { ...list[idx]! };
          if (update.$set) Object.assign(cur, update.$set);
          if (update.$inc) {
            for (const [k, delta] of Object.entries(update.$inc as Record<string, number>)) {
              cur[k] = Number(cur[k] ?? 0) + delta;
            }
          }
          list[idx] = cur;
          return { matchedCount: 1, modifiedCount: 1 };
        }
        if (opts?.upsert) {
          const created = { _id: filter._id ?? new ObjectId(), ...filter, ...(update.$set ?? {}) };
          list.push(created);
          return { matchedCount: 0, upsertedCount: 1 };
        }
        return { matchedCount: 0, modifiedCount: 0 };
      },
      async updateMany(filter: Document, update: Document) {
        let count = 0;
        for (let i = 0; i < list.length; i++) {
          if (matchesFilter(list[i]!, filter)) {
            const cur = { ...list[i]! };
            if (update.$set) Object.assign(cur, update.$set);
            if (update.$inc) {
              for (const [k, delta] of Object.entries(update.$inc as Record<string, number>)) {
                cur[k] = Number(cur[k] ?? 0) + delta;
              }
            }
            list[i] = cur;
            count++;
          }
        }
        return { matchedCount: count, modifiedCount: count };
      },
      async findOneAndUpdate(filter: Document, update: Document) {
        const idx = list.findIndex((d) => matchesFilter(d, filter));
        if (idx < 0) return null;
        const cur = { ...list[idx]! };
        if (update.$set) Object.assign(cur, update.$set);
        list[idx] = cur;
        return cur;
      },
      aggregate() {
        return { async toArray() { return []; } };
      },
    };
  };
  return {
    db: {
      client: { startSession: () => fakeSession },
      collection,
    } as unknown as Db,
    store,
  };
}

describe("admin API contracts", () => {
  const jwtSecret = "unit-test-secret-key-32-chars-minimum";
  const adminId = new ObjectId();
  const studentId = new ObjectId();
  const pendingSeedProtocolId = new ObjectId();
  const aguardandoProtocolId = new ObjectId();
  const token = jwt.sign({ sub: String(adminId), profile: "admin" }, jwtSecret, { expiresIn: "15m" });

  let server: Server;
  let baseUrl: string;
  let store: Record<string, Document[]>;

  before(async () => {
    const dbSetup = makeInMemoryDb({
      auth_users: [
        { _id: adminId, identity: "admin.demo", displayName: "Secretaria Geral", profile: "admin", active: true },
        { _id: studentId, identity: "aluno.demo1", email: "aluno1@example.com", displayName: "Aluno Um", profile: "aluno", active: true },
      ],
      academic_courses: [
        { _id: new ObjectId(), code: "ES-2026", name: "Engenharia de Software", active: true },
      ],
      academic_classes: [
        {
          _id: new ObjectId(),
          code: "218131 - APS-II",
          courseCode: "ES-2026",
          subjectName: "Análise e Projeto de Sistemas II",
          courseName: "Engenharia de Software",
          semester: "2026/2",
          shift: "Noturno",
          location: "Lab 04",
          maxCapacity: 40,
          formulaRegime: "autonomia_docente",
          evaluationFormula: "(N1 × 0.4) + (N2 × 0.6)",
          gradeLocked: false,
          pautaHomologated: false,
          active: true,
        },
      ],
      academic_enrollments: [
        {
          _id: new ObjectId(),
          classCode: "218131 - APS-II",
          courseCode: "ES-2026",
          studentId: String(studentId),
          studentIdentity: "aluno.demo1",
          displayName: "Aluno Um",
          status: "active",
        },
      ],
      academic_grades: [
        {
          _id: new ObjectId(),
          classCode: "218131 - APS-II",
          studentId: String(studentId),
          assignmentsScore: 8,
          p1Score: 9,
          projectsScore: 7,
          p2Score: 10,
          attendanceRate: 95,
          absences: 2,
        },
      ],
      academic_protocols: [
        {
          _id: pendingSeedProtocolId,
          code: "PROT - 2026/0542",
          studentId: String(studentId),
          studentRa: "aluno.demo1",
          studentName: "Aluno Um",
          requestType: "Segunda Chamada",
          targetComponent: "218131 - APS-II",
          justification: "Solicitação de substitutiva.",
          status: "pendente",
          createdAt: new Date(),
        },
        {
          _id: aguardandoProtocolId,
          code: "PROT - 2026/0543",
          studentId: String(studentId),
          studentRa: "aluno.demo1",
          studentName: "Aluno Um",
          requestType: "Abono de Faltas",
          targetComponent: "218131 - APS-II",
          justification: "Atestado médico.",
          status: "Aguardando Parecer",
          createdAt: new Date(),
        },
        {
          _id: new ObjectId(),
          code: "PROT - 2026/0541",
          studentId: String(studentId),
          status: "deferido",
          createdAt: new Date(),
        },
      ],
    });
    store = dbSetup.store;

    const app = createApp(
      { nodeEnv: "test", corsOrigins: [] },
      {
        database: dbSetup.db,
        jwtSecret,
        internalServiceSecret: "test-internal-secret-32-characters",
      },
    );

    server = createServer(app);
    await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
    const addr = server.address();
    if (!addr || typeof addr === "string") throw new Error("Failed to bind test server");
    baseUrl = `http://127.0.0.1:${addr.port}`;
  });

  after(async () => {
    await new Promise<void>((resolve) => server.close(() => resolve()));
  });

  async function api(method: string, path: string, body?: unknown) {
    const res = await fetch(`${baseUrl}${path}`, {
      method,
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
      },
      ...(body !== undefined ? { body: JSON.stringify(body) } : {}),
    });
    const text = await res.text();
    return { status: res.status, body: text ? JSON.parse(text) : null };
  }

  it("GET /api/admin/classes/:classCode/grades returns metadata wrapper with nested grades list", async () => {
    const res = await api("GET", `/api/admin/classes/${encodeURIComponent("218131 - APS-II")}/grades`);
    assert.equal(res.status, 200);
    assert.equal(res.body.classCode, "218131 - APS-II");
    assert.ok(Array.isArray(res.body.grades));
    assert.equal(res.body.grades.length, 1);
    assert.equal(res.body.grades[0].studentName, "Aluno Um");
    assert.equal(res.body.grades[0].hasGrades, true);
  });

  it("PATCH /api/admin/classes/:code accepts formulaRegime, evaluationFormula, and justificationNote", async () => {
    const res = await api("PATCH", `/api/admin/classes/${encodeURIComponent("218131 - APS-II")}`, {
      formulaRegime: "admin",
      evaluationFormula: "(N1 + N2) / 2",
      justificationNote: "Autorizado via despacho colegiado.",
    });
    assert.equal(res.status, 200);
    assert.equal(res.body.formulaRegime, "admin");
    assert.equal(res.body.evaluationFormula, "(N1 + N2) / 2");
    assert.equal(store.academic_classes?.[0]?.justificationNote, "Autorizado via despacho colegiado.");
  });

  it("GET /api/admin/dashboard counts both 'pendente' and 'Aguardando Parecer' protocols accurately", async () => {
    const dash = await api("GET", "/api/admin/dashboard");
    assert.equal(dash.status, 200);
    assert.equal(dash.body.pendingProtocols, 2);
    assert.equal(dash.body.decidedProtocols, 1);
  });

  it("PATCH /api/admin/protocols/:id/decision decides both seeded 'pendente' and 'Aguardando Parecer' protocols", async () => {
    const seedRes = await api("PATCH", `/api/admin/protocols/${pendingSeedProtocolId}/decision`, {
      approved: true,
      decisionNote: "Segunda chamada autorizada pela Secretaria.",
    });
    assert.equal(seedRes.status, 200);
    assert.equal(seedRes.body.status, "Deferido");

    const retrySeed = await api("PATCH", `/api/admin/protocols/${pendingSeedProtocolId}/decision`, {
      approved: false,
      decisionNote: "Tentativa duplicada.",
    });
    assert.equal(retrySeed.status, 409);

    const stdRes = await api("PATCH", `/api/admin/protocols/${aguardandoProtocolId}/decision`, {
      approved: false,
      decisionNote: "Documentação incompleta.",
    });
    assert.equal(stdRes.status, 200);
    assert.equal(stdRes.body.status, "Indeferido");
  });
});
