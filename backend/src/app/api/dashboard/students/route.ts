import { NextRequest, NextResponse } from "next/server";
import { db } from "@/lib/db";
import { students, buildingStates } from "@/lib/db/schema";
import { withTeacherAuth } from "@/lib/auth/middleware";
import { visibleStudentIds } from "@/lib/auth/teacher-access";
import { internalError } from "@/lib/api/errors";
import { inArray, asc, sql } from "drizzle-orm";
import { TokenPayload } from "@/lib/auth/jwt";

export const dynamic = "force-dynamic";

const TOTAL_BUILDINGS = 8;

export async function GET(request: NextRequest) {
  return withTeacherAuth(request, async (_req: NextRequest, teacher: TokenPayload) => {
    try {
      const visible = visibleStudentIds(teacher.sub);

      const [allStudents, buildingCounts] = await Promise.all([
        db
          .select({
            id: students.id,
            name: students.name,
            email: students.email,
            username: students.username,
            readingLevel: students.readingLevel,
            xp: students.xp,
            streakDays: students.streakDays,
            lastActive: students.lastActive,
            onboardingDone: students.onboardingDone,
            createdAt: students.createdAt,
          })
          .from(students)
          .where(inArray(students.id, visible))
          .orderBy(asc(students.name)),
        db
          .select({
            studentId: buildingStates.studentId,
            unlocked: sql<number>`count(*) filter (where ${buildingStates.unlocked} = true)`,
          })
          .from(buildingStates)
          .where(inArray(buildingStates.studentId, visible))
          .groupBy(buildingStates.studentId),
      ]);

      const countMap = new Map(
        buildingCounts.map((r) => [r.studentId, Number(r.unlocked)])
      );

      const enriched = allStudents.map((s) => ({
        ...s,
        buildingsUnlocked: countMap.get(s.id) ?? 0,
        questComplete: (countMap.get(s.id) ?? 0) >= TOTAL_BUILDINGS,
      }));

      return NextResponse.json({ students: enriched });
    } catch (error) {
      console.error("Students list error:", error);
      return internalError();
    }
  });
}
