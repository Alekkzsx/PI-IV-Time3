// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import assert from "node:assert/strict";
import { describe, it } from "node:test";
import type { Document } from "mongodb";
import {
  mapStudentDeliveries,
  mapStudentHistoricalBoletim,
} from "../../modules/student/application/dashboard/index.js";
import {
  mapTeacherAssignments,
  mapTeacherGrades,
} from "../../modules/teacher/application/dashboard/index.js";

const documents = (records: Record<string, unknown>[]) => records as Document[];

describe("dashboard mappers", () => {
  it("preserves pending delivery status and its linked discipline display values", () => {
    const [delivery] = mapStudentDeliveries(
      documents([{ _id: "assignment-1", classCode: "CS101", title: "Projeto" }]),
      new Map([["CS101", { name: "Algoritmos", professor: "Docente" }]]),
      new Map(),
    );

    assert.equal(delivery?.status, "Pendente");
    assert.equal(delivery?.disciplineName, "Algoritmos");
    assert.equal(delivery?.professor, "Docente");
    assert.equal(delivery?.score, null);
  });

  it("keeps the existing academic outcome rules in historical records", () => {
    const [period] = mapStudentHistoricalBoletim([
      {
        code: "CS101",
        semester: "2026/2",
        name: "Algoritmos",
        n1: 8,
        n2: 7,
        partialAverage: 7.6,
        absences: 2,
        attendancePercentage: 90,
      },
    ]);

    assert.equal(period?.period, "2026/2");
    assert.deepEqual(period?.items[0], {
      codigo: "CS101",
      disciplina: "Algoritmos",
      n1: "8.0",
      n2: "7.0",
      media: "7.6",
      faltas: "2h (90%)",
      situacao: "Aprovado",
    });
  });

  it("creates a pending row for each enrolled student in teacher assignments", () => {
    const [assignment] = mapTeacherAssignments(
      documents([{ _id: "assignment-1", classCode: "CS101", title: "Projeto" }]),
      [],
      new Map([["CS101", documents([{ studentId: "student-1", studentIdentity: "RA-1", displayName: "Estudante" }])]]),
    );

    assert.equal(assignment?.submissions.length, 1);
    assert.equal(assignment?.submissions[0]?.status, "pendente");
    assert.equal(assignment?.submissions[0]?.studentId, "student-1");
  });

  it("recalculates attendance while preserving recorded grade values", () => {
    const [grade] = mapTeacherGrades(
      documents([{ code: "CS101", totalHours: 40 }]),
      new Map([["CS101", documents([{ studentId: "student-1", studentIdentity: "RA-1", displayName: "Estudante" }])]]),
      documents([{ _id: "grade-1", classCode: "CS101", studentId: "student-1", p1Score: 8, attendanceRate: 90 }]),
      new Map([["CS101:student-1", 4]]),
    );

    assert.equal(grade?.id, "grade-1");
    assert.equal(grade?.p1Score, 8);
    assert.equal(grade?.attendanceRate, 90);
    assert.equal(grade?.absences, 4);
  });
});