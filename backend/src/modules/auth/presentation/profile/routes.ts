// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import type { Router } from "express";
import { ObjectId, type Db } from "mongodb";
import { z } from "zod";
import { AuthError } from "../../../../shared/auth-error.js";
import { parse } from "../../../../shared/validation.js";

const profileUpdateSchema = z
  .object({
    displayName: z.string().trim().min(2).max(120).optional(),
    socialName: z.string().trim().max(120).optional(),
    phone: z.string().trim().max(40).optional(),
    personalEmail: z.string().trim().max(254).optional(),
    biography: z.string().trim().max(2000).optional(),
    departmentOrCourse: z.string().trim().max(160).optional(),
    department: z.string().trim().max(160).optional(),
    campus: z.string().trim().max(160).optional(),
    semester: z.string().trim().max(80).optional(),
    shift: z.string().trim().max(60).optional(),
    preferences: z.record(z.string(), z.unknown()).optional(),
  })
  .strict()
  .refine((value) => Object.keys(value).length > 0);

export function registerProfileRoutes(router: Router, database: Db): void {
  router.get("/me", (_request, response) => {
    const user = response.locals.user;
    response.json({
      id: String(user._id),
      identity: user.identity,
      displayName: user.displayName,
      socialName: user.socialName ?? "",
      email: user.email,
      personalEmail: user.personalEmail ?? "",
      phone: user.phone ?? "",
      biography: user.biography ?? "",
      profile: user.profile,
      departmentOrCourse: user.departmentOrCourse ?? user.department ?? "",
      department: user.department ?? user.departmentOrCourse ?? "",
      campus: user.campus ?? "Campus Central",
      semester: user.semester ?? "2026/2",
      shift: user.shift ?? "",
      requirePasswordChange: user.requirePasswordChange === true,
      twoFactorRequired: user.twoFactorRequired === true,
      preferences: user.preferences ?? {},
      lastLogin: user.lastLogin ?? null,
    });
  });

  router.patch("/profile", async (request, response) => {
    const fields = parse(profileUpdateSchema, request.body);
    const userId = response.locals.userId as string;
    const setFields: Record<string, unknown> = {
      ...fields,
      updatedAt: new Date(),
    };
    if (fields.department && !fields.departmentOrCourse) setFields.departmentOrCourse = fields.department;
    if (fields.departmentOrCourse && !fields.department) setFields.department = fields.departmentOrCourse;

    const updated = await database.collection("auth_users").findOneAndUpdate(
      { _id: new ObjectId(userId), active: true },
      { $set: setFields },
      { returnDocument: "after" },
    );
    if (!updated) throw new AuthError(404, "user_not_found", "Conta não encontrada.");

    if (fields.displayName) {
      await database.collection("academic_enrollments").updateMany(
        { studentId: userId },
        { $set: { displayName: fields.displayName } },
      );
      await database.collection("academic_classes").updateMany(
        { professorId: userId },
        { $set: { professorName: fields.displayName } },
      );
    }

    response.json({
      id: String(updated._id),
      identity: updated.identity,
      displayName: updated.displayName,
      socialName: updated.socialName ?? "",
      email: updated.email,
      personalEmail: updated.personalEmail ?? "",
      phone: updated.phone ?? "",
      biography: updated.biography ?? "",
      profile: updated.profile,
      departmentOrCourse: updated.departmentOrCourse ?? updated.department ?? "",
      department: updated.department ?? updated.departmentOrCourse ?? "",
      campus: updated.campus ?? "Campus Central",
      semester: updated.semester ?? "2026/2",
      shift: updated.shift ?? "",
      twoFactorRequired: updated.twoFactorRequired === true,
      preferences: updated.preferences ?? {},
    });
  });
}