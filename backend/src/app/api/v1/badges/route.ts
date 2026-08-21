import { NextRequest, NextResponse } from "next/server";
import { db } from "@/lib/db";
import { students, studentBadges } from "@/lib/db/schema";
import { withStudentAuth } from "@/lib/auth/middleware";
import { notFound, internalError } from "@/lib/api/errors";
import { eq } from "drizzle-orm";
import { TokenPayload } from "@/lib/auth/jwt";
import { getLevelInfo } from "@/lib/gamification/levels";
import { BADGE_DEFINITIONS } from "@/lib/db/badge-definitions";
import { checkAndAwardBadges } from "@/lib/gamification/badges";

export async function GET(request: NextRequest) {
  return withStudentAuth(request, async (_req: NextRequest, user: TokenPayload) => {
    try {
      // Retroactively award any badges the student has earned but not yet received.
      // Safe to call on every fetch — idempotent via composite PK + onConflictDoNothing.
      await checkAndAwardBadges(user.sub).catch((err) =>
        console.error("Badge retroactive check failed:", err)
      );

      const [earnedRows, studentRows] = await Promise.all([
        db
          .select({ badgeId: studentBadges.badgeId, earnedAt: studentBadges.earnedAt })
          .from(studentBadges)
          .where(eq(studentBadges.studentId, user.sub)),

        db
          .select({ xp: students.xp })
          .from(students)
          .where(eq(students.id, user.sub))
          .limit(1),
      ]);

      if (!studentRows.length) {
        return notFound("Student not found");
      }

      const earnedMap = new Map(earnedRows.map((r) => [r.badgeId, r.earnedAt]));
      const levelInfo = getLevelInfo(studentRows[0].xp);

      const badgeList = BADGE_DEFINITIONS.map((def) => ({
        ...def,
        earned: earnedMap.has(def.id),
        earnedAt: earnedMap.get(def.id) ?? null,
      }));

      return NextResponse.json({
        badges: badgeList,
        level: levelInfo,
        earnedCount: earnedRows.length,
        totalCount: BADGE_DEFINITIONS.length,
      });
    } catch (error) {
      console.error("Get badges error:", error);
      return internalError();
    }
  });
}
