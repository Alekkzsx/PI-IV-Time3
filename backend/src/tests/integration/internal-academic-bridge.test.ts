// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import assert from "node:assert/strict";
import { createServer } from "node:http";
import { after, before, describe, it } from "node:test";
import { ObjectId, type Db, type Document } from "mongodb";
import { createApp } from "../../app.js";

const jwtSecret = "bridge-test-jwt-secret-with-at-least-32-chars";
const internalSecret = "bridge-test-internal-secret-with-at-least-32-chars";

const teacherId = new ObjectId().toHexString();
const studentId = new ObjectId().toHexString();
const otherStudentId = new ObjectId().toHexString();

const classDocs: Array<Record<string, any>> = [
  {
    _id: new ObjectId(),
    code: "ES-DEMO-4N",
    courseCode: "ES",
    subjectName: "Engenharia de Software IV",
    courseName: "Engenharia de Software",
    semester: "2026/2",
    shift: "Noturno",
    location: "Lab 04",
    professorId: teacherId,
    professorIdentity: "prof.demo",
    professorName: "Profa. Demo",
    active: true,
  },
];

const enrollmentDocs: Array<Record<string, any>> = [
  {
    _id: new ObjectId(),
    classCode: "ES-DEMO-4N",
    studentId,
    studentIdentity: "aluno.demo1",
    displayName: "Aluno Demo",
    status: "active",
  },
];

const sessionDocs: Array<Record<string, any>> = [
  {
    _id: new ObjectId(),
    classCode: "ES-DEMO-4N",
    sessionNumber: 1,
    startsAt: new Date(),
    attendanceList: [
      { studentId, ra: "aluno.demo1", isConnected: false },
    ],
  },
];

function makeCollection(list: Array<Record<string, any>>) {
  return {
    async findOne(query: Record<string, any>) {
      return (
        list.find((doc) => {
          if (query.code && typeof query.code === "object" && query.code.$regex) {
            return new RegExp(query.code.$regex, query.code.$options).test(String(doc.code));
          }
          if (query.code && doc.code !== query.code) return false;
          if (query.classCode && doc.classCode !== query.classCode) return false;
          if (query.professorId && doc.professorId !== query.professorId) return false;
          if (query.studentId && doc.studentId !== query.studentId) return false;
          if (query.status && doc.status !== query.status) return false;
          if (query.active?.$ne === false && doc.active === false) return false;
          return true;
        }) ?? null
      );
    },
    find(query: Record<string, any> = {}) {
      const matches = list.filter((doc) => {
        if (query.professorId && doc.professorId !== query.professorId) return false;
        if (query.studentId && doc.studentId !== query.studentId) return false;
        if (query.status && doc.status !== query.status) return false;
        if (query.code?.$in && !query.code.$in.includes(doc.code)) return false;
        return true;
      });
      return {
        sort() { return this; },
        async toArray() { return matches; },
      };
    },
    async updateOne(filter: Record<string, any>, update: Record<string, any>) {
      const target = list.find((d) => d._id === filter._id);
      if (target && update.$set) Object.assign(target, update.$set);
      return { matchedCount: target ? 1 : 0 };
    },
    async updateMany(filter: Record<string, any>, update: Record<string, any>) {
      let count = 0;
      for (const doc of list) {
        const matchProf = filter.professorId && doc.professorId === filter.professorId;
        const matchStud = filter.studentId && doc.studentId === filter.studentId;
        if (matchProf || matchStud) {
          if (update.$set) Object.assign(doc, update.$set);
          count++;
        }
      }
      return { modifiedCount: count };
    },
  };
}

const emptyCol = {
  async findOne() { return null; },
  find() {
    return {
      sort() { return this; },
      async toArray() { return []; },
    };
  },
};

const database = {
  collection(name: string): any {
    switch (name) {
      case "academic_classes": return makeCollection(classDocs);
      case "academic_enrollments": return makeCollection(enrollmentDocs);
      case "academic_class_sessions": return makeCollection(sessionDocs);
      default: return emptyCol;
    }
  },
} as unknown as Db;

const app = createApp(
  { nodeEnv: "test", corsOrigins: ["http://localhost:5000"] },
  { database, jwtSecret, internalServiceSecret: internalSecret },
);
const server = createServer(app);
let baseUrl = "";

before(async () => {
  await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
  const address = server.address();
  if (!address || typeof address === "string") throw new Error("Falha ao abrir servidor de teste.");
  baseUrl = `http://127.0.0.1:${address.port}`;
});

after(async () => {
  await new Promise<void>((resolve, reject) => server.close((err) => (err ? reject(err) : resolve())));
});

describe("ponte HTTP interna (/api/internal/academic/*)", () => {
  it("rejeita chamadas sem segredo ou com segredo inválido (401 / 403)", async () => {
    const missing = await fetch(`${baseUrl}/api/internal/academic/users/${studentId}/links`);
    assert.equal(missing.status, 401);

    const wrong = await fetch(`${baseUrl}/api/internal/academic/users/${studentId}/links`, {
      headers: { "x-internal-service-secret": "wrong-secret" },
    });
    assert.equal(wrong.status, 403);
  });

  it("lista e autoriza salas de videochamada, atualiza presença, sincroniza perfil e exporta LGPD", async () => {
    const headers = {
      "x-internal-service-secret": internalSecret,
      "content-type": "application/json",
    };

    const roomsRes = await fetch(
      `${baseUrl}/api/internal/academic/video-call/rooms?userId=${studentId}&profile=aluno&identity=aluno.demo1`,
      { headers },
    );
    assert.equal(roomsRes.status, 200);
    const rooms = (await roomsRes.json()) as Document[];
    assert.equal(rooms.length, 1);
    assert.equal(rooms[0]?.roomCode, "ES-DEMO-4N");

    const authOk = await fetch(
      `${baseUrl}/api/internal/academic/video-call/authorize?userId=${studentId}&profile=aluno&roomCode=es-demo-4n`,
      { headers },
    );
    assert.equal(authOk.status, 200);
    assert.equal((await authOk.json()).allowed, true);

    const authDenied = await fetch(
      `${baseUrl}/api/internal/academic/video-call/authorize?userId=${otherStudentId}&profile=aluno&roomCode=ES-DEMO-4N`,
      { headers },
    );
    assert.equal(authDenied.status, 403);

    const presence = await fetch(`${baseUrl}/api/internal/academic/video-call/presence`, {
      method: "POST",
      headers,
      body: JSON.stringify({ classCode: "ES-DEMO-4N", userId: studentId, isConnected: true }),
    });
    assert.equal(presence.status, 200);
    assert.equal(sessionDocs[0]?.attendanceList[0].isConnected, true);

    const links = await fetch(`${baseUrl}/api/internal/academic/users/${studentId}/links`, { headers });
    assert.equal(links.status, 200);
    assert.equal((await links.json()).hasEnrollmentLinks, true);

    const sync = await fetch(`${baseUrl}/api/internal/academic/users/${teacherId}/sync`, {
      method: "POST",
      headers,
      body: JSON.stringify({ displayName: "Profa. Atualizada" }),
    });
    assert.equal(sync.status, 200);
    assert.equal(classDocs[0]?.professorName, "Profa. Atualizada");

    const lgpd = await fetch(`${baseUrl}/api/internal/academic/users/${studentId}/lgpd-data`, { headers });
    assert.equal(lgpd.status, 200);
    const lgpdData = (await lgpd.json()) as Document;
    assert.equal(lgpdData.enrollments.length, 1);
    assert.ok(Array.isArray(lgpdData.grades));
    assert.ok(Array.isArray(lgpdData.classes));
  });
});
