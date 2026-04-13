import { NextRequest, NextResponse } from "next/server";
import { db } from "@/lib/db";
import { students } from "@/lib/db/schema";
import { withTeacherAuth } from "@/lib/auth/middleware";
import { visibleStudentIds } from "@/lib/auth/teacher-access";
import { internalError } from "@/lib/api/errors";
import { inArray, asc } from "drizzle-orm";
import { TokenPayload } from "@/lib/auth/jwt";

export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  return withTeacherAuth(request, async (_req: NextRequest, teacher: TokenPayload) => {
    try {
      const visible = visibleStudentIds(teacher.sub);

      const allStudents = await db
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
        .orderBy(asc(students.name));

      return NextResponse.json({ students: allStudents });
    } catch (error) {
      console.error("Students list error:", error);
      return internalError();
    }
  });
}
